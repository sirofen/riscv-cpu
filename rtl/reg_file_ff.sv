`ifndef REG_FILE_FF
`define REG_FILE_FF

module reg_file_ff #(
    parameter int unsigned DataWidth = 32,
    parameter logic [DataWidth-1:0] EmptyReg = 0
) (
    input logic i_clk,
    input logic i_rstn,

    // read reg line 0
    input logic [4:0] i_rreg_0,
    output logic [DataWidth-1:0] o_rdata_0,

    // read reg line 1
    input logic [4:0] i_rreg_1,
    output logic [DataWidth-1:0] o_rdata_1,

    // write reg line 0
    input logic [4:0] i_wreg_0,
    input logic [DataWidth-1:0] i_wdata_0,
    input logic i_we_0
);
  localparam int unsigned REGS_NUM = 2 ** 5;

  logic [DataWidth-1:0] regs[REGS_NUM];
  logic [REGS_NUM-1:0] write_enable_dec_0;

  assign o_rdata_0 = (i_wreg_0 == i_rreg_0 && i_we_0 && i_rreg_0 != 0) ? i_wdata_0 : regs[i_rreg_0];
  assign o_rdata_1 = (i_wreg_0 == i_rreg_1 && i_we_0 && i_rreg_1 != 0) ? i_wdata_0 : regs[i_rreg_1];

  always_comb begin : write_enable_dec
    for (int unsigned i = 0; i < REGS_NUM; i++) begin
      write_enable_dec_0[i] = (i_wreg_0 == 5'(i)) ? i_we_0 : 1'b0;
    end
  end

  // '0' reg is always zero
  generate
    genvar i;
    for (i = 1; i < REGS_NUM; i++) begin : gen_reg_file_flops
      always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
          regs[i] <= EmptyReg;
        end else if (write_enable_dec_0[i]) begin
          regs[i] <= i_wdata_0;
        end
      end
    end
  endgenerate

endmodule

`endif
