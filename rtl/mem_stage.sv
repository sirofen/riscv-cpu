`ifndef MEM_STAGE
`define MEM_STAGE

`include "rv_pkg.sv"

`include "data_mem.sv"
`include "mmio/uart_mmio.sv"
`include "mmio/gpio_mmio.sv"

module mem_stage
  import rv_pkg::*;
(
    input logic i_clk,
    input logic i_rstn,
    input logic i_uart_rx,
    output logic o_uart_tx,
    output logic [3:0] o_gpio,
    input ex_mem_regs_t i_ex_mem_regs,
    output mem_wb_regs_t o_mem_wb_regs,
    output logic o_mem_hazard
);

  localparam MMIO_UART_ADDR = 32'h100;
  localparam MMIO_GPIO_ADDR = 32'h200;
  localparam MMIO_BASE_ADDR = 32'h100;
  localparam MMIO_ADDR_MASK = 32'hF00;

  mem_ctrl_reg_t mem_ctrl;
  assign mem_ctrl = i_ex_mem_regs.mem_ctrl;

  logic [31:0] raw_mem_data;
  logic [31:0] mmio_data_out;
  logic [31:0] addr_read;
  logic mmio_re;
  logic mmio_we;

  logic data_mem_re;
  logic data_mem_we;

  logic read_data_ready;
  logic write_data_ready;

  assign addr_read = i_ex_mem_regs.alu_out[31:0];
  assign mmio_re = mem_ctrl.mem_read && (addr_read & MMIO_ADDR_MASK) == MMIO_BASE_ADDR;
  assign mmio_we = mem_ctrl.mem_write && (addr_read & MMIO_ADDR_MASK) == MMIO_BASE_ADDR;

  assign data_mem_re = !o_mem_hazard && mem_ctrl.mem_write && (addr_read < MMIO_UART_ADDR);
  assign data_mem_we = !o_mem_hazard && mem_ctrl.mem_read && (addr_read < MMIO_UART_ADDR);

  data_mem memory (
      .i_clk(i_clk),
      .i_rstn(i_rstn),
      .i_we(data_mem_we),
      .i_re(data_mem_re),
      .i_addr(addr_read),
      .i_data(i_ex_mem_regs.read_data2),
      .i_mem_size(mem_ctrl.rw_sz),
      .o_data(raw_mem_data),
      .o_data_ready(read_data_ready),
      .o_write_ready(write_data_ready)
  );

  logic [7:0] uart_mmio_data_out;
  logic [7:0] gpio_mmio_data_out;

  uart_mmio #(
      .BASE_ADDR(MMIO_UART_ADDR)
  ) uart (
      .i_clk(i_clk),
      .i_rstn(i_rstn),
      .i_uart_rx(i_uart_rx),
      .o_uart_tx(o_uart_tx),
      .i_mmio_addr(addr_read),
      .i_mmio_data_in(i_ex_mem_regs.read_data2[7:0]),
      .o_mmio_data_out(uart_mmio_data_out),
      .i_mmio_we(mem_ctrl.mem_write && (addr_read & MMIO_ADDR_MASK) == MMIO_UART_ADDR),
      .i_mmio_re(mem_ctrl.mem_read && (addr_read & MMIO_ADDR_MASK) == MMIO_UART_ADDR)
  );

  gpio_mmio #(
      .GPIO_WIDTH(4),
      .BASE_ADDR (MMIO_GPIO_ADDR)
  ) gpio (
      .i_clk(i_clk),
      .i_rstn(i_rstn),
      .o_gpio(o_gpio),
      .i_mmio_addr(addr_read),
      .i_mmio_data_in(i_ex_mem_regs.read_data2[7:0]),
      .o_mmio_data_out(gpio_mmio_data_out),
      .i_mmio_we(mem_ctrl.mem_write && (addr_read & MMIO_ADDR_MASK) == MMIO_GPIO_ADDR),
      .i_mmio_re(mem_ctrl.mem_read && (addr_read & MMIO_ADDR_MASK) == MMIO_GPIO_ADDR)
  );

  always_comb begin
    if ((addr_read & MMIO_ADDR_MASK) == MMIO_UART_ADDR) begin
      mmio_data_out = {24'b0, uart_mmio_data_out};
    end else if ((addr_read & MMIO_ADDR_MASK) == MMIO_GPIO_ADDR) begin
      mmio_data_out = {24'b0, gpio_mmio_data_out};
    end else begin
      mmio_data_out = 32'b0;
    end
  end

  always_comb begin
    if (addr_read >= MMIO_BASE_ADDR) begin
      o_mem_wb_regs.read_mem_data = mmio_data_out;
    end else begin
      case (mem_ctrl.rw_sz)
        BYTE:
        o_mem_wb_regs.read_mem_data = mem_ctrl.sign_ext ?
                    {{24{raw_mem_data[7]}}, raw_mem_data[7:0]} :
                    {24'b0, raw_mem_data[7:0]};
        HWORD:
        o_mem_wb_regs.read_mem_data = mem_ctrl.sign_ext ?
                    {{16{raw_mem_data[15]}}, raw_mem_data[15:0]} :
                    {16'b0, raw_mem_data[15:0]};
        WORD: o_mem_wb_regs.read_mem_data = raw_mem_data;
        default: o_mem_wb_regs.read_mem_data = 32'b0;
      endcase
    end
  end

  assign o_mem_wb_regs.alu_out = i_ex_mem_regs.alu_out;
  assign o_mem_wb_regs.inst_rd = i_ex_mem_regs.inst_rd;
  assign o_mem_wb_regs.wb_ctrl = i_ex_mem_regs.wb_ctrl;

  typedef enum logic [1:0] {
    IDLE,
    READ_PENDING,
    WRITE_PENDING
  } mem_state_t;

  mem_state_t mem_state;

  always_ff @(posedge i_clk) begin
    if (data_mem_re) begin
      o_mem_hazard <= !read_data_ready;
      mem_state <= READ_PENDING;
    end else if (data_mem_we) begin
      o_mem_hazard <= !write_data_ready;
      mem_state <= WRITE_PENDING;
    end else begin
      case (mem_state)
        READ_PENDING: begin
          if (read_data_ready) begin
            o_mem_hazard <= 1'b0;
            mem_state <= IDLE;
          end
        end
        WRITE_PENDING: begin
          if (write_data_ready) begin
            o_mem_hazard <= 1'b0;
            mem_state <= IDLE;
          end
        end
        IDLE: ;
        default: ;
      endcase
    end
  end
endmodule

`endif
