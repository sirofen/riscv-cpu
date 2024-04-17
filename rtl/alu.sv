`ifndef ALU
`define ALU

`include "rv_pkg.sv"

module alu
  import rv_pkg::*;
(
    input logic [63:0] i_a_op,
    input logic [63:0] i_b_op,
    input logic [63:0] i_pc,
    input alu_ctrl_e i_alu_ctrl,

    output logic o_zero_flag,
    output logic [63:0] o_res
);

  logic cmp_res;
  logic [63:0] res;

  logic is_less_than;
  logic is_less_than_signed;
  logic is_eq;

  assign o_zero_flag = (cmp_res == 0 && res == 0);
  assign o_res = res;

  assign is_less_than = i_a_op < i_b_op;
  assign is_less_than_signed = $signed(i_a_op) < $signed(i_b_op);

  assign is_eq = i_a_op == i_b_op;

  always_comb begin
    unique case (i_alu_ctrl)
      ALU_ADD: res = i_a_op + i_b_op;
      ALU_SUB: res = i_a_op - i_b_op;

      ALU_AND: res = i_a_op & i_b_op;
      ALU_OR:  res = i_a_op | i_b_op;
      ALU_XOR: res = i_a_op ^ i_b_op;

      ALU_SLL: res = i_a_op << i_b_op;
      ALU_SRL: res = i_a_op >> i_b_op;
      ALU_SRA: res = i_a_op >>> i_b_op;

      ALU_LUI:   res = i_b_op;
      ALU_AUIPC: res = i_b_op + i_pc;

      ALU_SLT, ALU_SLTU, ALU_GE, ALU_GEU, ALU_EQ, ALU_NE: res = {63'b0, cmp_res};
      default: res = 64'b0;
    endcase
  end

  always_comb begin
    unique case (i_alu_ctrl)
      ALU_GEU:  cmp_res = !is_less_than;
      ALU_SLTU: cmp_res = is_less_than;
      ALU_SLT:  cmp_res = is_less_than_signed;
      ALU_GE:   cmp_res = !is_less_than_signed;
      ALU_EQ:   cmp_res = is_eq;
      ALU_NE:   cmp_res = !is_eq;
      default:  cmp_res = is_eq;
    endcase
  end

endmodule

`endif
