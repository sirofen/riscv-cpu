`ifndef UART_RX
`define UART_RX

module uart_rx #(
    parameter integer CLOCK_HZ = 50000000,
    parameter integer BAUD_RATE = 115200
    //parameter integer CLK_PER_BIT = CLOCK_HZ / BAUD_RATE
) (
    input  wire       i_clk,
    input  wire       i_rst,
    input  wire       i_uart_rx,
    output reg  [7:0] o_data,
    output reg        o_valid
);
  localparam integer CLK_PER_BIT = CLOCK_HZ / BAUD_RATE;
  localparam integer CB = CLK_PER_BIT - 1;

  localparam reg [2:0] IDLE = 3'h0;
  localparam reg [2:0] START_BIT = 3'h1;
  localparam reg [2:0] DATA = 3'h2;
  localparam reg [2:0] STOP_BIT = 3'h3;

  reg [ 2:0] state = IDLE;
  reg [ 2:0] bit_index;

  reg [31:0] clk_cnt;

  always @(posedge i_clk) begin
    if (i_rst) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          o_valid <= 1'b0;
          if (i_uart_rx == 0) begin
            state <= START_BIT;
          end
        end
        START_BIT: begin
          if (clk_cnt == CB / 2) begin
            if (i_uart_rx == 0) begin
              clk_cnt <= 0;
              state   <= DATA;
            end else begin
              state <= IDLE;
            end
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
        DATA: begin
          if (clk_cnt == CB) begin
            clk_cnt <= 0;
            o_data[bit_index] <= i_uart_rx;
            if (bit_index == 7) begin
              bit_index <= 0;
              state <= STOP_BIT;
            end else begin
              bit_index <= bit_index + 1;
            end
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
        STOP_BIT: begin
          o_valid <= 1'b1;
          if (clk_cnt == CB) begin
            clk_cnt <= 0;
            state   <= IDLE;
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end
endmodule
`endif
