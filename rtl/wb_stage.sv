`ifndef WB_STAGE
`define WB_STAGE

`include "rv_pkg.sv"

module wb_stage
  import rv_pkg::*;
(
    input mem_wb_regs_t i_mem_wb_regs,
    output logic o_reg_we,
    output logic [4:0] o_reg,
    output logic [31:0] o_reg_data
);
  wb_ctrl_reg_t wb_ctrl;
  mem_wb_regs_t mem_wb_regs;

  assign wb_ctrl = i_mem_wb_regs.wb_ctrl;
  assign mem_wb_regs = i_mem_wb_regs;

  assign o_reg_we   = wb_ctrl.reg_we;
  assign o_reg      = mem_wb_regs.inst_rd;
  assign o_reg_data = wb_ctrl.mem_to_reg ? mem_wb_regs.read_mem_data : mem_wb_regs.alu_out[31:0];

endmodule
`endif
