`ifndef DATA_MEM
`define DATA_MEM

`include "rv_pkg.sv"

module data_mem
  import rv_pkg::*;
#(
    parameter unsigned MemoryBytesSize = 'h4
) (
    input  logic              i_clk,
    input  logic              i_rst,
    input  logic              i_we,
    input  logic              i_re,
    input  logic       [31:0] i_addr,
    input  logic       [31:0] i_data,
    input  mem_op_sz_e        i_mem_size,
    output logic       [31:0] o_data
);

  bit [7:0] memory[MemoryBytesSize*4-1];

  always_comb begin
    if (i_addr >= MemoryBytesSize * 4) begin
      o_data = 32'b0;
    end else begin
      case (i_mem_size)
        BYTE: begin
          o_data = {24'b0, memory[i_addr]};
        end
        HWORD: begin
          o_data = {16'b0, memory[i_addr+1], memory[i_addr]};
        end
        WORD: begin
          o_data = {memory[i_addr+3], memory[i_addr+2], memory[i_addr+1], memory[i_addr]};
        end
        default: o_data = 32'b0;
      endcase
    end
  end

  always_ff @(posedge i_clk or negedge i_rst) begin
    if (!i_rst) begin
      for (int i = 0; i < MemoryBytesSize * 4 - 1; i++) begin
        memory[i] <= 8'b0;
      end
    end else if (i_we && i_addr < MemoryBytesSize * 4) begin
      case (i_mem_size)
        BYTE: begin
          memory[i_addr] <= i_data[7:0];
        end
        HWORD: begin
          memory[i_addr]   <= i_data[7:0];
          memory[i_addr+1] <= i_data[15:8];
        end
        WORD: begin
          memory[i_addr]   <= i_data[7:0];
          memory[i_addr+1] <= i_data[15:8];
          memory[i_addr+2] <= i_data[23:16];
          memory[i_addr+3] <= i_data[31:24];
        end
        default: ;
      endcase
    end
  end

endmodule
`endif
