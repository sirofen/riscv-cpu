`ifndef cpu
`define CPU

`include "rv_pkg.sv"

`include "if_stage.sv"
`include "id_stage.sv"
`include "ex_stage.sv"
`include "mem_stage.sv"
`include "wb_stage.sv"

`include "fwd_unit.sv"

module cpu
  import rv_pkg::*;
(
    input logic i_clk,
    // active low reset
    input logic i_rst,
    input logic i_uart_rx,
    output logic o_uart_tx,
    output logic [3:0] o_led
);

  logic load_mem_stall;

  // if
  logic do_branch_to_if;
  logic [63:0] branch_target_to_if;

  // if/id
  if_id_regs_t if_id_regs_from_if;
  if_id_regs_t if_id_regs_to_id;

  // id
  logic reg_we_to_id;
  logic [4:0] write_reg_to_id;
  logic [31:0] write_reg_data_to_id;

  // id/ex
  id_ex_regs_t id_ex_regs_from_id;
  id_ex_regs_t id_ex_regs_to_ex;
  logic [31:0] reg_data1_from_id;
  logic [31:0] reg_data2_from_id;

  // ex
  logic [31:0] reg_data1_to_ex;
  logic [31:0] reg_data2_to_ex;

  // ex/mem
  ex_mem_regs_t ex_mem_regs_from_ex;
  ex_mem_regs_t ex_mem_regs_to_mem;

  logic [63:0] branch_addr_from_ex;
  logic do_branch_from_ex;

  // mem/wb
  mem_wb_regs_t mem_wb_regs_from_mem;
  mem_wb_regs_t mem_wb_regs_to_wb;

  // wb
  logic reg_we_from_wb;
  logic [4:0] reg_from_wb;
  logic [31:0] reg_data_from_wb;

  if_stage if_stage (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_stall(load_mem_stall),
      .i_do_branch(do_branch_to_if),
      .i_branch_target(branch_target_to_if),
      .o_if_id_regs(if_id_regs_from_if)
  );

  id_stage id_stage (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_reg_we(reg_we_to_id),
      .i_write_reg(write_reg_to_id),
      .i_write_reg_data(write_reg_data_to_id),
      .i_if_id_regs(if_id_regs_to_id),
      .i_stall(load_mem_stall),
      .o_id_ex_regs(id_ex_regs_from_id),
      .o_reg_data1(reg_data1_from_id),
      .o_reg_data2(reg_data2_from_id)
  );

  ex_stage ex_stage (
      .i_id_ex_regs(id_ex_regs_to_ex),
      .i_reg_data1(reg_data1_to_ex),
      .i_reg_data2(reg_data2_to_ex),
      .o_ex_mem_regs(ex_mem_regs_from_ex),
      .o_bt(branch_addr_from_ex),
      .o_do_branch(do_branch_from_ex)
  );

  mem_stage mem_stage (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_uart_rx(i_uart_rx),
      .o_uart_tx(o_uart_tx),
      .o_gpio(o_led),
      .i_ex_mem_regs(ex_mem_regs_to_mem),
      .o_mem_wb_regs(mem_wb_regs_from_mem)
  );

  wb_stage wb_stage (
      .i_mem_wb_regs(mem_wb_regs_to_wb),
      .o_reg_we(reg_we_from_wb),
      .o_reg(reg_from_wb),
      .o_reg_data(reg_data_from_wb)
  );

  // forward reg unit

  add_op_fwd_t fwd_a;
  add_op_fwd_t fwd_b;

  logic [31:0] reg_data_fwd_a;
  logic [31:0] reg_data_fwd_b;

  fwd_unit rf_fwd (
      .i_mem_rd(ex_mem_regs_to_mem.inst_rd),
      .i_mem_r_we(ex_mem_regs_to_mem.wb_ctrl.reg_we),
      .i_wb_rd(reg_from_wb),
      .i_wb_r_we(reg_we_from_wb),
      .i_ex_rs1(id_ex_regs_to_ex.reg_rs1),
      .i_ex_rs2(id_ex_regs_to_ex.reg_rs2),
      .o_fwd_a(fwd_a),
      .o_fwd_b(fwd_b)
  );

  always_comb begin
    unique case (fwd_a)
      FWD_MEM_WB: reg_data_fwd_a = reg_data_from_wb;
      FWD_EX_MEM: reg_data_fwd_a = ex_mem_regs_to_mem.alu_out[31:0];
      default: reg_data_fwd_a = reg_data1_from_id;
    endcase

    unique case (fwd_b)
      FWD_MEM_WB: reg_data_fwd_b = reg_data_from_wb;
      FWD_EX_MEM: reg_data_fwd_b = ex_mem_regs_to_mem.alu_out[31:0];
      default: reg_data_fwd_b = reg_data2_from_id;
    endcase
  end

  // load mem hazard
  always_comb begin
    load_mem_stall = id_ex_regs_to_ex.mem_ctrl.mem_read
      && (id_ex_regs_to_ex.inst_rd == id_ex_regs_from_id.reg_rs1
      || id_ex_regs_to_ex.inst_rd == id_ex_regs_from_id.reg_rs2);
  end

  logic flush_if_id;
  logic flush_id_ex;

  assign flush_if_id = do_branch_from_ex;
  assign flush_id_ex = do_branch_from_ex;

  always_ff @(posedge i_clk) begin
    if (load_mem_stall) begin
      id_ex_regs_to_ex <= 0;
    end else begin
      // flush if/id if/ex regs if branch was taken
      // id
      if_id_regs_to_id <= flush_if_id ? 0 : if_id_regs_from_if;
      // ex
      id_ex_regs_to_ex <= flush_id_ex ? 0 : id_ex_regs_from_id;
    end

    // ex
    reg_data1_to_ex <= reg_data_fwd_a;
    reg_data2_to_ex <= reg_data_fwd_b;

    branch_target_to_if <= branch_addr_from_ex;
    do_branch_to_if <= do_branch_from_ex;

    // mem
    ex_mem_regs_to_mem <= ex_mem_regs_from_ex;

    // wb
    mem_wb_regs_to_wb <= mem_wb_regs_from_mem;
    reg_we_to_id <= reg_we_from_wb;
    write_reg_to_id <= reg_from_wb;
    write_reg_data_to_id <= reg_data_from_wb;

  end

endmodule
`endif
