
`include "rv_pkg.sv"

module control
  import rv_pkg::*;
(
    input logic [31:0] i_instr,
    output wb_ctrl_reg_t o_wb_ctrl,
    output mem_ctrl_reg_t o_mem_ctrl,
    output alu_ctrl_e o_alu_ctrl,
    output alu_op_mux_t o_alu_op_mux,
    output alu_out_mux_t o_alu_out_mux,
    output branch_target_mux_t o_branch_target_mux,
    output logic o_do_branch
);

  logic [31:0] instr;

  wb_ctrl_reg_t wb_ctrl;
  mem_ctrl_reg_t mem_ctrl;
  alu_ctrl_e alu_ctrl;

  alu_op_mux_t alu_op_mux;
  alu_out_mux_t alu_out_mux;
  branch_target_mux_t branch_target_mux;

  assign instr = i_instr;

  assign o_wb_ctrl = wb_ctrl;
  assign o_mem_ctrl = mem_ctrl;
  assign o_alu_ctrl = alu_ctrl;
  assign o_alu_op_mux = alu_op_mux;
  assign o_alu_out_mux = alu_out_mux;
  assign o_branch_target_mux = branch_target_mux;

  logic [6:0] funct7;
  logic [2:0] funct3;

  assign funct7 = instr[31:25];
  assign funct3 = instr[14:12];

  always_comb begin
    // execute pipeline regs setup
    alu_op_mux = REG_2;
    alu_out_mux = ALU;
    branch_target_mux = PC_OFFSET;

    alu_ctrl = ALU_ADD;

    // memory pipeline regs setup
    o_do_branch = 1'b0;
    mem_ctrl.mem_read = 1'b0;
    mem_ctrl.mem_write = 1'b0;

    mem_ctrl.sign_ext = 1'b0;
    mem_ctrl.rw_sz = WORD;


    // writeback pipeline regs setup
    wb_ctrl.reg_we = 1'b0;
    wb_ctrl.mem_to_reg = 1'b0;

    unique case (instr[6:0])
      OPCODE_REG_OPS: begin
        wb_ctrl.reg_we = 1'b1;

        unique case ({
          funct7, funct3
        })
          {7'b000_0000, 3'b000} : alu_ctrl = ALU_ADD;
          {7'b010_0000, 3'b000} : alu_ctrl = ALU_SUB;
          {7'b000_0000, 3'b001} : alu_ctrl = ALU_SLL;
          {7'b000_0000, 3'b010} : alu_ctrl = ALU_SLT;
          {7'b000_0000, 3'b011} : alu_ctrl = ALU_SLTU;
          {7'b000_0000, 3'b100} : alu_ctrl = ALU_XOR;
          {7'b000_0000, 3'b101} : alu_ctrl = ALU_SRL;
          {7'b010_0000, 3'b101} : alu_ctrl = ALU_SRA;
          {7'b000_0000, 3'b110} : alu_ctrl = ALU_OR;
          {7'b000_0000, 3'b111} : alu_ctrl = ALU_AND;
          default: alu_ctrl = ALU_ADD;
        endcase

      end
      OPCODE_IMM_OPS: begin
        alu_op_mux = IMM;

        wb_ctrl.reg_we = 1'b1;

        unique case (funct3)
          3'b000:  alu_ctrl = ALU_ADD;
          3'b010:  alu_ctrl = ALU_SLT;
          3'b011:  alu_ctrl = ALU_SLTU;
          3'b100:  alu_ctrl = ALU_XOR;
          3'b110:  alu_ctrl = ALU_OR;
          3'b111:  alu_ctrl = ALU_AND;
          default: alu_ctrl = ALU_ADD;
        endcase
      end
      OPCODE_LOAD: begin
        alu_op_mux = IMM;

        mem_ctrl.mem_read = 1'b1;

        wb_ctrl.reg_we = 1'b1;
        wb_ctrl.mem_to_reg = 1'b1;
        unique case (funct3)
          3'b000: begin
            mem_ctrl.rw_sz = BYTE;
            mem_ctrl.sign_ext = 1'b1;
          end
          3'b001: begin
            mem_ctrl.rw_sz = HWORD;
            mem_ctrl.sign_ext = 1'b1;
          end
          3'b010: begin
            mem_ctrl.rw_sz = WORD;
            mem_ctrl.sign_ext = 1'b1;
          end
          3'b100: begin
            mem_ctrl.rw_sz = BYTE;
          end
          3'b101: begin
            mem_ctrl.rw_sz = HWORD;
          end
          default: ;
        endcase
      end
      OPCODE_STORE: begin
        alu_op_mux = IMM;

        mem_ctrl.mem_write = 1'b1;
        case (funct3)
          3'b000: begin
            mem_ctrl.rw_sz = BYTE;
          end
          3'b001: begin
            mem_ctrl.rw_sz = HWORD;
          end
          3'b010: begin
            mem_ctrl.rw_sz = WORD;
          end
          default:;
        endcase
      end
      OPCODE_BRANCH: begin
        o_do_branch = 1'b1;

        unique case (funct3)
          3'b000:  alu_ctrl = ALU_EQ;
          3'b001:  alu_ctrl = ALU_NE;
          3'b100:  alu_ctrl = ALU_LT;
          3'b101:  alu_ctrl = ALU_GE;
          3'b110: begin
            alu_ctrl = ALU_LTU;
          end
          3'b111: begin
            alu_ctrl = ALU_GE;
          end
          default: ;
        endcase
      end
      OPCODE_JAL: begin
        o_do_branch = 1'b1;

        wb_ctrl.reg_we = 1'b1;

        alu_out_mux = NEXT_PC;
      end
      OPCODE_JALR: begin
        o_do_branch = 1'b1;

        wb_ctrl.reg_we = 1'b1;

        alu_out_mux = NEXT_PC;

        branch_target_mux = REG_OFFSET;
      end
      OPCODE_LUI: begin
        alu_op_mux = IMM;

        wb_ctrl.reg_we = 1'b1;

        alu_ctrl = ALU_LUI;
      end
        OPCODE_AUIPC: begin
          alu_op_mux = IMM;

          wb_ctrl.reg_we = 1'b1;

          alu_ctrl = ALU_AUIPC;
        end
      default: ;
    endcase
  end

endmodule
