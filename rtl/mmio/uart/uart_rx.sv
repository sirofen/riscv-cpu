`ifndef UART_RX
`define UART_RX

module uart_rx #(
    parameter integer CLOCK_HZ  = 50_000_000,
    parameter integer BAUD_RATE = 115_200
) (
    input  logic       i_clk,
    input  logic       i_rstn,
    input  logic       i_uart_rx,
    input  logic       i_read_ack,
    output logic [7:0] o_data,
    output logic       o_valid
);
  localparam integer CLK_PER_BIT = CLOCK_HZ / BAUD_RATE;
  localparam integer CB = CLK_PER_BIT - 1;

  typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    DATA,
    STOP_BIT
  } state_t;

  state_t state = IDLE;
  logic [2:0] bit_index = 0;
  integer clk_cnt = 0;

  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      state <= IDLE;
      o_valid <= 1'b0;
      o_data <= 8'b0;
      clk_cnt <= 0;
      bit_index <= 0;
    end else begin
      if (o_valid && i_read_ack) begin
        o_valid <= 1'b0;
      end
      case (state)
        IDLE: begin
          if (i_uart_rx == 1'b0) begin
            state   <= START_BIT;
            clk_cnt <= 0;
          end
        end
        START_BIT: begin
          if (clk_cnt == CB / 2) begin
            if (i_uart_rx == 1'b0) begin
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
          if (clk_cnt == CB) begin
            clk_cnt <= 0;
            o_valid <= 1'b1;
            state   <= IDLE;
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
