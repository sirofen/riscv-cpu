`ifndef UART_TX
`define UART_TX

module uart_tx #(
    parameter integer CLOCK_HZ = 50_000_000,  // Clock frequency
    parameter integer BAUD_RATE = 115_200  // Baud rate for UART
) (
    input  logic       i_clk,
    input  logic       i_rst,
    input  logic       i_rdy,
    input  logic [7:0] i_data,
    output logic       o_uart_tx,
    output logic       o_busy
);
  localparam integer CLK_PER_BIT = CLOCK_HZ / BAUD_RATE;  // Clock cycles per bit
  localparam integer CB = CLK_PER_BIT - 1;  // Clocks per bit minus one for counting

  typedef enum logic [1:0] {
    IDLE,
    TRANSFER,
    STOP_BIT
  } state_t;

  state_t       state = IDLE;

  logic   [2:0] bit_index = 0;  // Index of the bit currently being sent
  integer       clk_cnt = 0;  // Clock count to measure bit width

  // Initialize outputs
  initial begin
    o_busy = 1'b1;
    o_uart_tx = 1'b1;  // Idle state of UART line is high
  end

  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      state <= IDLE;
      o_uart_tx <= 1'b1;  // Default high (idle state)
      o_busy <= 1'b0;
      clk_cnt <= 0;
      bit_index <= 0;
    end else begin
      case (state)
        IDLE: begin
          o_uart_tx <= 1'b1;  // Idle state of the UART line
          o_busy <= 1'b0;
          if (i_rdy) begin
            o_busy <= 1'b1;
            o_uart_tx <= 1'b0;  // Start bit
            state <= TRANSFER;
            clk_cnt <= 0;  // Reset clock count
          end
        end
        TRANSFER: begin
          if (clk_cnt == CB) begin
            clk_cnt <= 0;  // Reset clock count
            if (bit_index == 7) begin
              bit_index <= 0;
              state <= STOP_BIT;  // Move to sending stop bit
            end else begin
              bit_index <= bit_index + 1;
              o_uart_tx <= i_data[bit_index];  // Transmit next bit
            end
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
        STOP_BIT: begin
          if (clk_cnt == CB) begin
            clk_cnt <= 0;
            o_uart_tx <= 1'b1;  // Stop bit
            state <= IDLE;
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
        default: state <= IDLE;
      endcase
    end
  end
endmodule
`endif
