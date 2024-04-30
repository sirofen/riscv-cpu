`ifndef INST_MEM
`define INST_MEM

module inst_mem #(
    parameter integer MemoryBytesSize = 256,
    parameter Firware = "bin/fw.bin"
) (
    input  logic [31:0] i_read_addr,
    output logic [31:0] o_instruction
);

  logic [31:0] memory[MemoryBytesSize];

  initial begin
    $readmemh(Firware, memory);

    $display("Instruction memory initialized from %s", Firware);
  end

  always_comb begin
    if (i_read_addr >= MemoryBytesSize) begin
      o_instruction = 32'b0;
    end else begin
      o_instruction = memory[{2'b0, i_read_addr[31:2]}];
    end
  end

endmodule

`endif
