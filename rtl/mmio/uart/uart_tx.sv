`ifndef UART_TX
`define UART_TX

module uart_tx #(
    parameter integer CLOCK_HZ  = 50_000_000,
    parameter integer BAUD_RATE = 115_200
) (
    input  logic       i_clk,
    input  logic       i_rst,
    input  logic       i_rdy,
    input  logic [7:0] i_data,
    output logic       o_uart_tx,
    output logic       o_busy
);
  localparam integer CLK_PER_BIT = CLOCK_HZ / BAUD_RATE;
  localparam integer CB = CLK_PER_BIT - 1;

  typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    TRANSFER,
    STOP_BIT
  } state_t;

  state_t state = IDLE;
  logic [2:0] bit_index = 0;
  integer clk_cnt = 0;
  logic [7:0] data;

  initial begin
    o_uart_tx = 1'b1;
  end

  always_ff @(posedge i_clk or negedge i_rst) begin
    if (!i_rst) begin
      state <= IDLE;
      o_uart_tx <= 1'b1;
      o_busy <= 1'b0;
      clk_cnt <= 0;
      bit_index <= 0;
    end else begin
      case (state)
        IDLE: begin
          if (i_rdy) begin
            data   <= i_data;
            state  <= START_BIT;
            o_busy <= 1'b1;
          end else begin
            o_busy <= 1'b0;
          end
        end
        START_BIT: begin
          o_uart_tx <= 1'b0;
          if (clk_cnt >= CB) begin
            clk_cnt <= 0;
            state <= TRANSFER;
            bit_index <= 0;
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
        TRANSFER: begin
          o_uart_tx <= data[bit_index];
          if (clk_cnt >= CB) begin
            if (bit_index < 7) begin
              bit_index <= bit_index + 1;
              clk_cnt   <= 0;
            end else begin
              state   <= STOP_BIT;
              clk_cnt <= 0;
            end
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
        STOP_BIT: begin
          o_uart_tx <= 1'b1;
          if (clk_cnt >= CB) begin
            state   <= IDLE;
            o_busy  <= 1'b0;
            clk_cnt <= 0;
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
