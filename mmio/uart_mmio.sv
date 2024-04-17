`ifndef UART_MMIO
`define UART_MMIO

`include "mmio/uart/uart_rx.sv"
`include "mmio/uart/uart_tx.sv"

module uart_mmio #(
    parameter integer CLOCK_HZ  = 50_000_000,
    parameter integer BAUD_RATE = 115_200,
    parameter integer BASE_ADDR = 32'h1000_0000  // Programmable base address for UART MMIO
) (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_uart_rx,
    output logic        o_uart_tx,
    input  logic [31:0] i_mmio_addr,      // Full address for MMIO
    input  logic [ 7:0] i_mmio_data_in,   // Data for MMIO write operations
    output logic [ 7:0] o_mmio_data_out,  // Data for MMIO read operations
    input  logic        i_mmio_we,        // Write enable for MMIO
    input  logic        i_mmio_re         // Read enable for MMIO
);

  // Fixed offsets for MMIO registers
  localparam MMIO_RX_DATA_REG = BASE_ADDR;
  localparam MMIO_TX_DATA_REG = BASE_ADDR + 4;
  localparam MMIO_STATUS_REG = BASE_ADDR + 8;

  // UART RX and TX Instances
  logic [7:0] rx_data;
  logic rx_valid, tx_ready;

  uart_rx #(
      .CLOCK_HZ (CLOCK_HZ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_rx_inst (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_uart_rx(i_uart_rx),
      .o_data(rx_data),
      .o_valid(rx_valid)
  );

  uart_tx #(
      .CLOCK_HZ (CLOCK_HZ),
      .BAUD_RATE(BAUD_RATE)
  ) uart_tx_inst (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_rdy(i_mmio_we && (i_mmio_addr == MMIO_TX_DATA_REG)),
      .i_data(i_mmio_data_in),
      .o_uart_tx(o_uart_tx),
      .o_busy(tx_ready)
  );

  // Initialize output
  initial begin
    o_mmio_data_out = 8'b0;
  end

  // MMIO Read and Write Logic
  always_ff @(posedge i_clk or negedge i_rst) begin
    if (!i_rst) begin
      o_mmio_data_out <= 8'b0;
    end else begin
      // Handle MMIO read operations
      if (i_mmio_re) begin
        case (i_mmio_addr)
          MMIO_RX_DATA_REG: begin
            if (rx_valid) begin
              o_mmio_data_out <= rx_data;
            end
          end
          MMIO_STATUS_REG: begin
            o_mmio_data_out <= {6'b0, tx_ready, rx_valid};
          end
          default: o_mmio_data_out <= 8'h00;
        endcase
      end

      // Handle MMIO write operations
      if (i_mmio_we && (i_mmio_addr == MMIO_TX_DATA_REG) && tx_ready) begin
        // Data is written directly to UART transmit buffer through uart_tx_inst
        // No need to store data in an internal register here
      end
    end
  end

endmodule

`endif
