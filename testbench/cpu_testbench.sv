
`include "cpu.sv"

module cpu_testbench (
    input logic i_clk
);
  logic rst = 1;
  logic uart_rx;
  logic uart_tx;
  logic [3:0] led;

  cpu cpu (
      .i_clk(i_clk),
      .i_rst(rst),
      .i_uart_rx(uart_rx),
      .o_uart_tx(uart_tx),
      .o_led(led)
  );

  initial begin
    #40 $finish;
  end

endmodule
