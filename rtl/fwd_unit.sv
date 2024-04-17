
`include "rv_pkg.sv"

module fwd_unit
  import rv_pkg::*;
(
    input logic [4:0] i_mem_rd,
    input logic i_mem_r_we,
    input logic [4:0] i_wb_rd,
    input logic i_wb_r_we,
    input logic [4:0] i_ex_rs1,
    input logic [4:0] i_ex_rs2,
    output add_op_fwd_t o_fwd_a,
    output add_op_fwd_t o_fwd_b
);

  always_comb begin
    o_fwd_a = FWD_ID_EX;
    o_fwd_b = FWD_ID_EX;

    if (i_mem_r_we && i_mem_rd != 0) begin
      if (i_mem_rd == i_ex_rs1) begin
        o_fwd_a = FWD_EX_MEM;
      end
      if (i_mem_rd == i_ex_rs2) begin
        o_fwd_b = FWD_EX_MEM;
      end
    end

    if (i_wb_r_we && (i_wb_rd != 0)) begin
      if (!(i_mem_r_we && (i_mem_rd != 0) && (i_mem_rd == i_ex_rs1)) && (i_wb_rd == i_ex_rs1)) begin
        o_fwd_a = FWD_MEM_WB;
      end
      if (!(i_mem_r_we && (i_mem_rd != 0) && (i_mem_rd == i_ex_rs2)) && (i_wb_rd == i_ex_rs2)) begin
        o_fwd_b = FWD_MEM_WB;
      end
    end

  end

endmodule
