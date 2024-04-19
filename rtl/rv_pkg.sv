`ifndef RV_PKG
`define RV_PKG

package rv_pkg;
  typedef struct packed {
    logic [6:0] funct7;
    logic [4:0] rs2;
    logic [4:0] rs1;
    logic [2:0] funct3;
    logic [4:0] rd;
    logic [6:0] opcode;
  } instr_t;

  typedef enum logic [6:0] {
    OPCODE_REG_OPS = 7'b0110011,
    OPCODE_IMM_OPS = 7'b0010011,
    OPCODE_LOAD    = 7'b0000011,
    OPCODE_STORE   = 7'b0100011,
    OPCODE_BRANCH  = 7'b1100011,
    OPCODE_JAL     = 7'b1101111,
    OPCODE_JALR    = 7'b1100111,
    OPCODE_LUI     = 7'b0110111,
    OPCODE_AUIPC   = 7'b0010111
  } opcode_e;

  typedef enum logic [2:0] {
    I_TYPE = 3'b000,
    S_TYPE = 3'b001,
    B_TYPE = 3'b010,
    U_TYPE = 3'b011,
    J_TYPE = 3'b100
  } instr_type_e;

  typedef enum logic [5:0] {
    ALU_ADD,
    ALU_SUB,

    ALU_AND,
    ALU_OR,
    ALU_XOR,

    ALU_SLL,
    ALU_SRL,
    ALU_SRA,

    ALU_SLT,
    ALU_SLTU,

    ALU_LT,
    ALU_LTU,
    ALU_GE,
    ALU_GEU,
    ALU_EQ,
    ALU_NE,

    ALU_LUI,
    ALU_AUIPC
  } alu_ctrl_e;

  typedef struct packed {
    logic reg_we;
    logic mem_to_reg;
  } wb_ctrl_reg_t;

  typedef enum logic [1:0] {
    WORD,
    HWORD,
    BYTE
  } mem_op_sz_e;

  typedef struct packed {
    logic sign_ext;
    mem_op_sz_e rw_sz;

    logic mem_read;
    logic mem_write;
  } mem_ctrl_reg_t;


  typedef struct packed {
    logic [63:0] pc;
    logic [31:0] inst;
  } if_id_regs_t;

  typedef enum logic [0:0] {
    REG_2,
    IMM
  } alu_op_mux_t;

  typedef enum logic [0:0] {
    ALU,
    NEXT_PC
  } alu_out_mux_t;

  typedef enum logic [0:0] {
    PC_OFFSET,
    REG_OFFSET
  } branch_target_mux_t;

  typedef struct packed {
    logic [63:0] pc;
    logic do_branch;

    logic [4:0] reg_rs1;
    logic [4:0] reg_rs2;

    logic [63:0] imm;

    logic [4:0] inst_rd;  // [11-7]

    // later stages control signals
    wb_ctrl_reg_t  wb_ctrl;
    mem_ctrl_reg_t mem_ctrl;

    alu_ctrl_e alu_ctrl;
    alu_op_mux_t alu_src_mux;
    alu_out_mux_t alu_out_mux;

    branch_target_mux_t branch_target_mux;
  } id_ex_regs_t;

  typedef struct packed {
    logic [63:0] branch_dest;
    logic [63:0] alu_out;

    logic [31:0] read_data2;  // data to write

    logic [4:0] inst_rd;

    // later stages control signals
    wb_ctrl_reg_t  wb_ctrl;
    mem_ctrl_reg_t mem_ctrl;

  } ex_mem_regs_t;

  typedef struct packed {
    logic [63:0] alu_out;
    logic [31:0] read_mem_data;

    logic [4:0] inst_rd;

    wb_ctrl_reg_t wb_ctrl;
  } mem_wb_regs_t;

  typedef enum logic [1:0] {
    FWD_ID_EX,
    FWD_MEM_WB,
    FWD_EX_MEM
  } add_op_fwd_t;

endpackage
`endif
