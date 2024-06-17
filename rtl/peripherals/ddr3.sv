`ifndef DDR3
`define DDR3

`include "peripherals/system_bus_if.sv"
`include "rv_pkg.sv"

module ddr3
  import rv_pkg::*;
(
    input  logic              i_clk,
    input  logic              i_rstn,
    input  logic              i_we,
    input  logic              i_re,
    input  logic       [31:0] i_addr,
    input  logic       [31:0] i_data,
    input  mem_op_sz_e        i_mem_size,
    output logic       [31:0] o_data,
    output logic              o_data_ready,
    output logic              o_write_ready,
    system_bus_if             sys_bus
);

  // Instantiate the DDR3 interface module
  ddr3_interface u_ddr3_interface (
    .clk_in(i_clk),
    .ddr3_addr(sys_bus.ddr3_addr),
    .ddr3_ba(sys_bus.ddr3_ba),
    .ddr3_cas_n(sys_bus.ddr3_cas_n),
    .ddr3_ck_n(sys_bus.ddr3_ck_n),
    .ddr3_ck_p(sys_bus.ddr3_ck_p),
    .ddr3_cke(sys_bus.ddr3_cke),
    .ddr3_cs_n(sys_bus.ddr3_cs_n),
    .ddr3_dm(sys_bus.ddr3_dm),
    .ddr3_dq(sys_bus.ddr3_dq),
    .ddr3_dqs_n(sys_bus.ddr3_dqs_n),
    .ddr3_dqs_p(sys_bus.ddr3_dqs_p),
    .ddr3_odt(sys_bus.ddr3_odt),
    .ddr3_ras_n(sys_bus.ddr3_ras_n),
    .ddr3_reset_n(sys_bus.ddr3_reset_n),
    .ddr3_we_n(sys_bus.ddr3_we_n),
    .i_addr(i_addr),
    .i_data(i_data),
    .i_mem_sz(i_mem_size),
    .i_re(i_re),
    .i_we(i_we),
    .o_data(o_data),
    .o_data_ready(o_data_ready),
    .o_write_ready(o_write_ready),
    .pcie_ref_clk_clk_n(sys_bus.pcie_ref_clk_n),
    .pcie_ref_clk_clk_p(sys_bus.pcie_ref_clk_p),
    .pcie_mgt_0_rxn(sys_bus.pcie_rx_n),
    .pcie_mgt_0_rxp(sys_bus.pcie_rx_p),
    .pcie_mgt_0_txn(sys_bus.pcie_tx_n),
    .pcie_mgt_0_txp(sys_bus.pcie_tx_p),
    .user_lnk_up_0(),
    .rst_n(i_rstn)
  );

endmodule
`endif
