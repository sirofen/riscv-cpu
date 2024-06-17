`ifndef GPIO_MMIO
`define GPIO_MMIO

`include "peripherals/system_bus_if.sv"

module gpio_mmio #(
    parameter integer GPIO_WIDTH = 8,
    parameter integer BASE_ADDR  = 32'h2000_0000
) (
    input  logic                  i_clk,
    input  logic                  i_rstn,
    output logic [GPIO_WIDTH-1:0] o_gpio,
    input  logic [          31:0] i_mmio_addr,
    input  logic [           7:0] i_mmio_data_in,
    output logic [           7:0] o_mmio_data_out,
    input  logic                  i_mmio_we,
    input  logic                  i_mmio_re
);
  localparam MMIO_GPIO_OUTPUT_ADDR = BASE_ADDR;
  localparam MMIO_GPIO_INPUT_ADDR = BASE_ADDR + 4;

  bit [GPIO_WIDTH-1:0] gpio_reg;

  bit [GPIO_WIDTH-1:0] gpio_input_reg;

  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      gpio_reg <= {GPIO_WIDTH{1'b0}};
    end else begin
      if (i_mmio_we && i_mmio_addr == MMIO_GPIO_OUTPUT_ADDR) begin
        gpio_reg <= i_mmio_data_in;
      end

      gpio_input_reg <= {GPIO_WIDTH{1'b0}};
    end
  end

  assign o_gpio = gpio_reg;

  always_comb begin
    if (i_mmio_re) begin
      case (i_mmio_addr)
        MMIO_GPIO_OUTPUT_ADDR: o_mmio_data_out = gpio_reg;
        MMIO_GPIO_INPUT_ADDR:  o_mmio_data_out = gpio_input_reg;
        default:               o_mmio_data_out = 8'h00;
      endcase
    end else begin
      o_mmio_data_out = 8'h00;
    end
  end

endmodule
`endif
