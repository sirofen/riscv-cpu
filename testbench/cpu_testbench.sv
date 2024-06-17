
`include "cpu.sv"

module cpu_testbench (
    input logic i_clk,
    input logic uart_rx
);
  logic        rst = 1;
  // logic uart_rx;
  logic        uart_tx;
  logic [ 3:0] led;

  logic [31:0] ddr3_dq;
  logic [ 3:0] ddr3_dqs_n;
  logic [ 3:0] ddr3_dqs_p;

  logic [14:0] ddr3_addr;
  logic [ 2:0] ddr3_ba;
  logic        ddr3_ras_n;
  logic        ddr3_cas_n;
  logic        ddr3_we_n;
  logic        ddr3_reset_n;
  logic [ 0:0] ddr3_ck_p;
  logic [ 0:0] ddr3_ck_n;
  logic [ 0:0] ddr3_cke;
  logic [ 0:0] ddr3_cs_n;
  logic [ 3:0] ddr3_dm;
  logic [ 0:0] ddr3_odt;

  logic        pcie_ref_clk_n;
  logic        pcie_ref_clk_p;
  logic [ 3:0] pcie_rx_n;
  logic [ 3:0] pcie_rx_p;
  logic [ 3:0] pcie_tx_n;
  logic [ 3:0] pcie_tx_p;

  logic        eth_phy_rxc;
  logic        eth_phy_rx_ctrl;
  logic [ 3:0] eth_phy_rxd;
  logic        eth_phy_txc;
  logic        eth_phy_tx_ctrl;
  logic [ 3:0] eth_phy_txd;
  logic        eth_phy_rstn;
  logic        eth_mdc;
  logic        eth_mdio;

  cpu cpu (
      .i_clk(i_clk),
      .i_rstn(rst),
      .i_uart_rx(uart_rx),
      .o_uart_tx(uart_tx),
      .o_led(led),

      .ddr3_dq(ddr3_dq),
      .ddr3_dqs_n(ddr3_dqs_n),
      .ddr3_dqs_p(ddr3_dqs_p),

      .ddr3_addr(ddr3_addr),
      .ddr3_ba(ddr3_ba),
      .ddr3_ras_n(ddr3_ras_n),
      .ddr3_cas_n(ddr3_cas_n),
      .ddr3_we_n(ddr3_we_n),
      .ddr3_reset_n(ddr3_reset_n),
      .ddr3_ck_p(ddr3_ck_p),
      .ddr3_ck_n(ddr3_ck_n),
      .ddr3_cke(ddr3_cke),
      .ddr3_cs_n(ddr3_cs_n),
      .ddr3_dm(ddr3_dm),
      .ddr3_odt(ddr3_odt),

      .pcie_ref_clk_n(pcie_ref_clk_n),
      .pcie_ref_clk_p(pcie_ref_clk_p),
      .pcie_rx_n(pcie_rx_n),
      .pcie_rx_p(pcie_rx_p),
      .pcie_tx_n(pcie_tx_n),
      .pcie_tx_p(pcie_tx_p),

      .eth_phy_rxc(eth_phy_rxc),
      .eth_phy_rx_ctrl(eth_phy_rx_ctrl),
      .eth_phy_rxd(eth_phy_rxd),
      .eth_phy_txc(eth_phy_txc),
      .eth_phy_tx_ctrl(eth_phy_tx_ctrl),
      .eth_phy_txd(eth_phy_txd),
      .eth_phy_rstn(eth_phy_rstn),
      .eth_mdc(eth_mdc),
      .eth_mdio(eth_mdio)
  );

  initial begin
    #40 $finish;
  end

endmodule
