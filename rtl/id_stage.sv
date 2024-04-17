`ifndef ID_STAGE
`define ID_STAGE

`include "rv_pkg.sv"

`include "reg_file_ff.sv"
`include "imm_gen.sv"
`include "control.sv"

module id_stage
  import rv_pkg::*;
(
    input logic i_clk,
    input logic i_rst,
    input logic i_reg_we,
    input logic [4:0] i_write_reg,
    input logic [31:0] i_write_reg_data,
    input logic i_stall,
    input if_id_regs_t i_if_id_regs,
    output id_ex_regs_t o_id_ex_regs,
    output logic [31:0] o_reg_data1,
    output logic [31:0] o_reg_data2
);

  logic [4:0] read_reg_0;
  logic [4:0] read_reg_1;

  logic [31:0] reg_data_0;
  logic [31:0] reg_data_1;

  logic [31:0] write_reg_data;
  logic [4:0] write_reg;
  logic reg_we;

  logic [31:0] instr;
  logic [63:0] immediate;

  assign reg_we = i_reg_we;
  assign write_reg = i_write_reg;
  assign write_reg_data = i_write_reg_data;

  assign instr = i_if_id_regs.inst;

  assign read_reg_0 = instr[19:15];
  assign read_reg_1 = instr[24:20];

  assign o_id_ex_regs.pc = i_if_id_regs.pc;

  assign o_reg_data1 = reg_data_0;
  assign o_reg_data2 = reg_data_1;

  assign o_id_ex_regs.imm = immediate;
  assign o_id_ex_regs.inst_rd = instr[11:7];

  assign o_id_ex_regs.reg_rs1 = read_reg_0;
  assign o_id_ex_regs.reg_rs2 = read_reg_1;

  reg_file_ff reg_file (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_rreg_0(read_reg_0),
      .o_rdata_0(reg_data_0),
      .i_rreg_1(read_reg_1),
      .o_rdata_1(reg_data_1),
      .i_wreg_0(write_reg),
      .i_wdata_0(write_reg_data),
      .i_we_0(reg_we)
  );

  imm_gen imm_generate (
      .i_instr(instr),
      .o_imm  (immediate)
  );

  control control (
      .i_instr(instr),
      .o_wb_ctrl(o_id_ex_regs.wb_ctrl),
      .o_mem_ctrl(o_id_ex_regs.mem_ctrl),
      .o_alu_ctrl(o_id_ex_regs.alu_ctrl),
      .o_alu_op_mux(o_id_ex_regs.alu_src_mux),
      .o_alu_out_mux(o_id_ex_regs.alu_out_mux),
      .o_branch_target_mux(o_id_ex_regs.branch_target_mux),
      .o_do_branch(o_id_ex_regs.do_branch)
  );

endmodule

`endif
