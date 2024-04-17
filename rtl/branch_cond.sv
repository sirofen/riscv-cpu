`ifndef BRANCH_COND
`define BRANCH_COND

`include "rv_pkg.sv"

module branch_cond
  import rv_pkg::*;
(
    input logic [31:0] i_reg_data_1,
    input logic [31:0] i_reg_data_2,
    input logic [63:0] i_imm,
    input alu_ctrl_e i_alu_ctrl,
    output logic o_new_pc
);

  logic cmp_res;

  logic is_less_than;
  logic is_less_than_signed;
  logic is_eq;
  assign is_eq = i_reg_data_1 == i_reg_data_2;

  assign is_less_than = i_reg_data_1 < i_reg_data_2;
  assign is_less_than_signed = $signed(i_reg_data_1) < $signed(i_reg_data_2);

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
