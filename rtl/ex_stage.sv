`ifndef EX_STAGE
`define EX_STAGE

`include "rv_pkg.sv"

`include "alu.sv"

module ex_stage
  import rv_pkg::*;
(
    input id_ex_regs_t i_id_ex_regs,
    input logic [31:0] i_reg_data1,
    input logic [31:0] i_reg_data2,
    output ex_mem_regs_t o_ex_mem_regs,
    output logic [63:0] o_bt,
    output logic o_do_branch
);

  logic [63:0] add_op_a;
  logic [63:0] alu_op_b;
  logic [63:0] alu_out_val;
  logic [63:0] next_pc;
  logic [63:0] imm_sl;

  logic do_branch;

  assign add_op_a = {32'b0, i_reg_data1};

  assign alu_op_b = (i_id_ex_regs.alu_src_mux == REG_2) ? {32'b0, i_reg_data2} : i_id_ex_regs.imm;

  // ALU_ADD is set for alu JALR instruction
  assign o_do_branch = (i_id_ex_regs.do_branch && (!do_branch || i_id_ex_regs.alu_ctrl == ALU_ADD));

  alu alu (
      .i_a_op({32'b0, i_reg_data1}),
      .i_b_op(alu_op_b),
      .i_pc(i_id_ex_regs.pc),
      .i_alu_ctrl(i_id_ex_regs.alu_ctrl),
      .o_zero_flag(do_branch),
      .o_res(alu_out_val)
  );

  assign o_ex_mem_regs.read_data2 = i_reg_data2;
  assign o_ex_mem_regs.inst_rd = i_id_ex_regs.inst_rd;

  assign o_ex_mem_regs.wb_ctrl = i_id_ex_regs.wb_ctrl;
  assign o_ex_mem_regs.mem_ctrl = i_id_ex_regs.mem_ctrl;

  assign next_pc = i_id_ex_regs.pc + 4;
  assign imm_sl = i_id_ex_regs.imm;

  always_comb begin
    unique case (i_id_ex_regs.alu_out_mux)
      ALU:     o_ex_mem_regs.alu_out = alu_out_val;
      NEXT_PC: o_ex_mem_regs.alu_out = i_id_ex_regs.pc + 4;
      default: ;
    endcase
  end
  always_comb begin
    unique case (i_id_ex_regs.branch_target_mux)
      PC_OFFSET: o_bt = i_id_ex_regs.pc + imm_sl;
      REG_OFFSET: o_bt = add_op_a + imm_sl;
      default: ;
    endcase
  end

endmodule
`endif
