`ifndef IF_STAGE
`define IF_STAGE

`include "rv_pkg.sv"

`include "pc.sv"
`include "inst_mem.sv"

module if_stage
  import rv_pkg::*;
(
    input logic i_clk,
    input logic i_rst,
    input logic i_stall,
    input logic i_do_branch,
    input logic [63:0] i_branch_target,
    output if_id_regs_t o_if_id_regs
);

  // program counter signals
  logic [63:0] program_counter;
  logic [63:0] new_pc_val;
  logic pc_we;

  assign new_pc_val = i_branch_target;
  assign pc_we      = i_do_branch;

  pc pc_module (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_stall(i_stall),
      .i_we(pc_we),
      .i_pc(new_pc_val),
      .o_pc(program_counter)
  );

  logic [31:0] instruction = 0;

  inst_mem idata (
      .i_read_addr  (program_counter[31:0]),
      .o_instruction(instruction)
  );

  assign o_if_id_regs.inst = instruction;
  assign o_if_id_regs.pc   = program_counter;

endmodule

`endif
