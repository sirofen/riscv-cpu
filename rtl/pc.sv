`ifndef PROGRAM_COUNTER
`define PROGRAM_COUNTER

module pc (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_stall,
    input  logic        i_we,
    input  logic [63:0] i_pc,
    output logic [63:0] o_pc
);

  logic [63:0] counter = 0;

  always_ff @(posedge i_clk or negedge i_rst) begin
    if (!i_rst) begin
      counter <= 64'b0;
    end else if (i_we) begin
      counter <= i_pc;
    end else if (!i_stall) begin
      counter <= counter + 4;
    end
  end

  assign o_pc = counter;

endmodule

`endif
