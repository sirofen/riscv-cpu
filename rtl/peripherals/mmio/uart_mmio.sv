`ifndef UART_MMIO
`define UART_MMIO

`include "peripherals/system_bus_if.sv"

`include "peripherals/mmio/uart/uart_rx.sv"
`include "peripherals/mmio/uart/uart_tx.sv"

module uart_mmio #(
    parameter integer CLOCK_HZ  = 50_000_000,
    parameter integer BAUD_RATE = 115200,
    parameter integer BASE_ADDR = 32'h1000_0000
) (
    input  logic        i_clk,
    input  logic        i_rstn,
    system_bus_if.uart  io_uart,
    input  logic [31:0] i_mmio_addr,
    input  logic [ 7:0] i_mmio_data_in,
    output logic [ 7:0] o_mmio_data_out,
    input  logic        i_mmio_we,
    input  logic        i_mmio_re
);

  localparam MMIO_RX_DATA_REG = BASE_ADDR;
  localparam MMIO_TX_DATA_REG = BASE_ADDR + 4;
  localparam MMIO_STATUS_REG = BASE_ADDR + 8;

  logic [7:0] rx_data;
  logic rx_valid;
  logic read_ack;
  logic tx_busy;

  uart_rx #(
      .CLOCK_HZ (CLOCK_HZ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_rx_inst (
      .i_clk(i_clk),
      .i_rstn(i_rstn),
      .i_uart_rx(io_uart.uart_rx),
      .i_read_ack(read_ack),
      .o_data(rx_data),
      .o_valid(rx_valid)
  );

  uart_tx #(
      .CLOCK_HZ (CLOCK_HZ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_tx_inst (
      .i_clk(i_clk),
      .i_rstn(i_rstn),
      .i_rdy(i_mmio_we && (i_mmio_addr == MMIO_TX_DATA_REG) && !tx_busy),
      .i_data(i_mmio_data_in),
      .o_uart_tx(io_uart.uart_tx),
      .o_busy(tx_busy)
  );

  always_comb begin
    o_mmio_data_out = 8'h00;
    read_ack = 1'b0;
    if (i_mmio_re) begin
      case (i_mmio_addr)
        MMIO_RX_DATA_REG: begin
          if (rx_valid) begin
            o_mmio_data_out = rx_data;
            read_ack = 1'b1;
          end
        end
        MMIO_STATUS_REG: begin
          o_mmio_data_out = {6'b0, tx_busy, rx_valid};
        end
        default: ;
      endcase
    end
  end

endmodule

`endif
