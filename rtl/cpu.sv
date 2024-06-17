`ifndef cpu
`define CPU

`include "rv_pkg.sv"

`include "if_stage.sv"
`include "id_stage.sv"
`include "ex_stage.sv"
`include "mem_stage.sv"
`include "wb_stage.sv"

`include "fwd_unit.sv"

`include "peripherals/system_bus_if.sv"

module cpu
  import rv_pkg::*;
(
    input logic i_clk,
    input logic i_rstn,
    // uart
    input logic i_uart_rx,
    output logic o_uart_tx,
    // led
    output logic [3:0] o_led,

    // ddr3
    inout wire [31:0] ddr3_dq,
    inout wire [ 3:0] ddr3_dqs_n,
    inout wire [ 3:0] ddr3_dqs_p,

    output wire [14:0] ddr3_addr,
    output wire [2:0] ddr3_ba,
    output wire ddr3_ras_n,
    output wire ddr3_cas_n,
    output wire ddr3_we_n,
    output wire ddr3_reset_n,
    output wire [0:0] ddr3_ck_p,
    output wire [0:0] ddr3_ck_n,
    output wire [0:0] ddr3_cke,
    output wire [0:0] ddr3_cs_n,
    output wire [3:0] ddr3_dm,
    output wire [0:0] ddr3_odt,

    // pcie
    input pcie_ref_clk_n,
    input pcie_ref_clk_p,
    input  [3:0] pcie_rx_n,
    input  [3:0] pcie_rx_p,
    output [3:0] pcie_tx_n,
    output [3:0] pcie_tx_p,

    // eth
    input  logic       eth_phy_rxc,
    input  logic       eth_phy_rx_ctrl,
    input  logic [3:0] eth_phy_rxd,
    output logic       eth_phy_txc,
    output logic       eth_phy_tx_ctrl,
    output logic [3:0] eth_phy_txd,
    output logic       eth_phy_rstn,
    output logic       eth_mdc,
    inout  logic       eth_mdio
);

  system_bus_if system_bus ();

  // UART
  assign system_bus.uart_rx = i_uart_rx;
  assign system_bus.uart_tx = o_uart_tx;

  // LED
  assign system_bus.led = o_led;

  // DDR3
  assign system_bus.ddr3_dq = ddr3_dq;
  assign system_bus.ddr3_dqs_n = ddr3_dqs_n;
  assign system_bus.ddr3_dqs_p = ddr3_dqs_p;
  assign system_bus.ddr3_addr = ddr3_addr;
  assign system_bus.ddr3_ba = ddr3_ba;
  assign system_bus.ddr3_ras_n = ddr3_ras_n;
  assign system_bus.ddr3_cas_n = ddr3_cas_n;
  assign system_bus.ddr3_we_n = ddr3_we_n;
  assign system_bus.ddr3_reset_n = ddr3_reset_n;
  assign system_bus.ddr3_ck_p = ddr3_ck_p;
  assign system_bus.ddr3_ck_n = ddr3_ck_n;
  assign system_bus.ddr3_cke = ddr3_cke;
  assign system_bus.ddr3_cs_n = ddr3_cs_n;
  assign system_bus.ddr3_dm = ddr3_dm;
  assign system_bus.ddr3_odt = ddr3_odt;

  // PCIe
  assign system_bus.pcie_ref_clk_n = pcie_ref_clk_n;
  assign system_bus.pcie_ref_clk_p = pcie_ref_clk_p;
  assign system_bus.pcie_rx_n = pcie_rx_n;
  assign system_bus.pcie_rx_p = pcie_rx_p;
  assign system_bus.pcie_tx_n = pcie_tx_n;
  assign system_bus.pcie_tx_p = pcie_tx_p;

  // Ethernet
  assign system_bus.eth_phy_rxc = eth_phy_rxc;
  assign system_bus.eth_phy_rx_ctrl = eth_phy_rx_ctrl;
  assign system_bus.eth_phy_rxd = eth_phy_rxd;
  assign system_bus.eth_phy_txc = eth_phy_txc;
  assign system_bus.eth_phy_tx_ctrl = eth_phy_tx_ctrl;
  assign system_bus.eth_phy_txd = eth_phy_txd;
  assign system_bus.eth_phy_rstn = eth_phy_rstn;
  assign system_bus.eth_mdc = eth_mdc;
  assign system_bus.eth_mdio = eth_mdio;

  // stall signals
  logic load_mem_stall;
  logic mem_hazard;

  logic stall_if;
  logic stall_id;
  logic stall_ex;
  logic stall_mem;
  logic stall_wb;

  // if
  logic do_branch_to_if;
  logic [63:0] branch_target_to_if;

  // if/id
  if_id_regs_t if_id_regs_from_if;
  if_id_regs_t if_id_regs_to_id;

  // id
  logic reg_we_to_id;
  logic [4:0] write_reg_to_id;
  logic [31:0] write_reg_data_to_id;

  // id/ex
  id_ex_regs_t id_ex_regs_from_id;
  id_ex_regs_t id_ex_regs_to_ex;
  logic [31:0] reg_data1_from_id;
  logic [31:0] reg_data2_from_id;

  // ex
  logic [31:0] reg_data1_to_ex;
  logic [31:0] reg_data2_to_ex;

  // ex/mem
  ex_mem_regs_t ex_mem_regs_from_ex;
  ex_mem_regs_t ex_mem_regs_to_mem;

  logic [63:0] branch_addr_from_ex;
  logic do_branch_from_ex;

  // mem/wb
  mem_wb_regs_t mem_wb_regs_from_mem;
  mem_wb_regs_t mem_wb_regs_to_wb;

  // wb
  logic reg_we_from_wb;
  logic [4:0] reg_from_wb;
  logic [31:0] reg_data_from_wb;

  if_stage if_stage (
      .i_clk(i_clk),
      .i_rstn(i_rstn),
      .i_stall(stall_if),
      .i_do_branch(do_branch_to_if),
      .i_branch_target(branch_target_to_if),
      .o_if_id_regs(if_id_regs_from_if)
  );

  id_stage id_stage (
      .i_clk(i_clk),
      .i_rstn(i_rstn),
      .i_reg_we(reg_we_to_id),
      .i_write_reg(write_reg_to_id),
      .i_write_reg_data(write_reg_data_to_id),
      .i_if_id_regs(if_id_regs_to_id),
      .i_stall(stall_id),
      .o_id_ex_regs(id_ex_regs_from_id),
      .o_reg_data1(reg_data1_from_id),
      .o_reg_data2(reg_data2_from_id)
  );

  ex_stage ex_stage (
      .i_id_ex_regs(id_ex_regs_to_ex),
      .i_reg_data1(reg_data_fwd_a),
      .i_reg_data2(reg_data_fwd_b),
      .o_ex_mem_regs(ex_mem_regs_from_ex),
      .o_bt(branch_addr_from_ex),
      .o_do_branch(do_branch_from_ex)
  );

  mem_stage #(
      .MEM_TYPE("DDR3")
  ) mem_stage (
      .i_clk(i_clk),
      .i_rstn(i_rstn),
      .i_ex_mem_regs(ex_mem_regs_to_mem),
      .o_mem_wb_regs(mem_wb_regs_from_mem),
      .o_mem_hazard(mem_hazard),
      .system_bus(system_bus)
  );

  wb_stage wb_stage (
      .i_mem_wb_regs(mem_wb_regs_to_wb),
      .o_reg_we(reg_we_from_wb),
      .o_reg(reg_from_wb),
      .o_reg_data(reg_data_from_wb)
  );

  // forward reg unit

  add_op_fwd_t fwd_a;
  add_op_fwd_t fwd_b;

  logic [31:0] reg_data_fwd_a;
  logic [31:0] reg_data_fwd_b;

  fwd_unit rf_fwd (
      .i_mem_rd(ex_mem_regs_to_mem.inst_rd),
      .i_mem_r_we(ex_mem_regs_to_mem.wb_ctrl.reg_we),
      .i_wb_rd(reg_from_wb),
      .i_wb_r_we(reg_we_from_wb),
      .i_ex_rs1(id_ex_regs_to_ex.reg_rs1),
      .i_ex_rs2(id_ex_regs_to_ex.reg_rs2),
      .o_fwd_a(fwd_a),
      .o_fwd_b(fwd_b)
  );

  always_comb begin
    unique case (fwd_a)
      FWD_MEM_WB: reg_data_fwd_a = reg_data_from_wb;
      FWD_EX_MEM: reg_data_fwd_a = ex_mem_regs_to_mem.alu_out[31:0];
      default: reg_data_fwd_a = reg_data1_to_ex;
    endcase

    unique case (fwd_b)
      FWD_MEM_WB: reg_data_fwd_b = reg_data_from_wb;
      FWD_EX_MEM: reg_data_fwd_b = ex_mem_regs_to_mem.alu_out[31:0];
      default: reg_data_fwd_b = reg_data2_to_ex;
    endcase
  end

  // load mem hazard
  always_comb begin
    load_mem_stall = id_ex_regs_to_ex.mem_ctrl.mem_read
      && (id_ex_regs_to_ex.inst_rd == id_ex_regs_from_id.reg_rs1
      || id_ex_regs_to_ex.inst_rd == id_ex_regs_from_id.reg_rs2);
  end

  always_comb begin
    stall_if  = load_mem_stall || mem_hazard;
    stall_id  = load_mem_stall || mem_hazard;
    stall_ex  = load_mem_stall || mem_hazard;
    stall_mem = mem_hazard;
    stall_wb  = mem_hazard;
  end


  logic flush_if_id;
  logic flush_id_ex;

  assign flush_if_id = do_branch_from_ex;
  assign flush_id_ex = do_branch_from_ex;

  assign reg_we_to_id = reg_we_from_wb;
  assign write_reg_to_id = reg_from_wb;
  assign write_reg_data_to_id = reg_data_from_wb;

  assign branch_target_to_if = branch_addr_from_ex;
  assign do_branch_to_if = do_branch_from_ex;

  always_ff @(posedge i_clk) begin
    if (stall_ex) begin
      id_ex_regs_to_ex <= mem_hazard ? id_ex_regs_to_ex : 0;
    end else begin
      // flush if/id if/ex regs if branch was taken
      // id
      if_id_regs_to_id <= flush_if_id ? 0 : if_id_regs_from_if;
      // ex
      id_ex_regs_to_ex <= flush_id_ex ? 0 : id_ex_regs_from_id;
    end

    // ex
    if (!stall_ex) begin
      reg_data1_to_ex <= reg_data1_from_id;
      reg_data2_to_ex <= reg_data2_from_id;
    end

    // mem
    if (!stall_mem) begin
      ex_mem_regs_to_mem <= ex_mem_regs_from_ex;
    end

    // wb
    if (!stall_wb) begin
      mem_wb_regs_to_wb <= mem_wb_regs_from_mem;
    end

  end

endmodule
`endif
