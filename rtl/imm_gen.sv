`ifndef IMM_GEN
`define IMM_GEN

`include "rv_pkg.sv"

module imm_gen
  import rv_pkg::*;
(
    input  logic [31:0] i_instr,
    output logic [63:0] o_imm
);

  logic [31:0] instr;
  logic [63:0] imm;
  logic [ 2:0] imm_type;

  assign instr = i_instr;
  assign o_imm = imm;

  always_comb begin
    case (instr[6:0])
      OPCODE_LOAD, OPCODE_IMM_OPS, OPCODE_JALR: imm_type = I_TYPE;
      OPCODE_STORE: imm_type = S_TYPE;
      OPCODE_BRANCH: imm_type = B_TYPE;
      OPCODE_LUI, OPCODE_AUIPC: imm_type = U_TYPE;
      OPCODE_JAL: imm_type = J_TYPE;
      default: imm_type = I_TYPE;
    endcase
  end

  always_comb begin
    case (imm_type)
      I_TYPE:  imm = {{52{instr[31]}}, instr[31:20]};
      S_TYPE:  imm = {{52{instr[31]}}, instr[31:25], instr[11:7]};
      B_TYPE:  imm = {{52{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      U_TYPE:  imm = {{32{instr[31]}}, instr[31:12], 12'b0};
      J_TYPE:  imm = {{44{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
      default: imm = 64'b0;
    endcase
  end

endmodule
`endif
