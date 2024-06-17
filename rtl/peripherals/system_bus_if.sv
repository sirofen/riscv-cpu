`ifndef SYSTEM_BUS_IF
`define SYSTEM_BUS_IF

interface system_bus_if;
    logic uart_rx;
    logic uart_tx;

    logic [3:0] led;

    // ddr3
    logic [31:0] ddr3_dq;
    logic [3:0] ddr3_dqs_n;
    logic [3:0] ddr3_dqs_p;
    logic [14:0] ddr3_addr;
    logic [2:0] ddr3_ba;
    logic ddr3_ras_n;
    logic ddr3_cas_n;
    logic ddr3_we_n;
    logic ddr3_reset_n;
    logic [0:0] ddr3_ck_p;
    logic [0:0] ddr3_ck_n;
    logic [0:0] ddr3_cke;
    logic [0:0] ddr3_cs_n;
    logic [3:0] ddr3_dm;
    logic [0:0] ddr3_odt;

    // pcie
    logic pcie_ref_clk_n;
    logic pcie_ref_clk_p;
    logic [3:0] pcie_rx_n;
    logic [3:0] pcie_rx_p;
    logic [3:0] pcie_tx_n;
    logic [3:0] pcie_tx_p;

    // eth
    logic eth_phy_rxc;
    logic eth_phy_rx_ctrl;
    logic [3:0] eth_phy_rxd;
    logic eth_phy_txc;
    logic eth_phy_tx_ctrl;
    logic [3:0] eth_phy_txd;
    logic eth_phy_rstn;

    logic eth_mdc;
    logic eth_mdio;

    modport uart(
        input uart_rx,
        output uart_tx
    );

    modport gpio(
        output led
    );

    modport ddr3(
        inout ddr3_dq,
        inout ddr3_dqs_n,
        inout ddr3_dqs_p,
        output ddr3_addr,
        output ddr3_ba,
        output ddr3_ras_n,
        output ddr3_cas_n,
        output ddr3_we_n,
        output ddr3_reset_n,
        output ddr3_ck_p,
        output ddr3_ck_n,
        output ddr3_cke,
        output ddr3_cs_n,
        output ddr3_dm,
        output ddr3_odt
    );

    modport pcie(
        input pcie_ref_clk_n,
        input pcie_ref_clk_p,
        input pcie_rx_n,
        input pcie_rx_p,
        output pcie_tx_n,
        output pcie_tx_p
    );

    modport eth(
        input  eth_phy_rxc,
        input  eth_phy_rx_ctrl,
        input  eth_phy_rxd,
        output eth_phy_txc,
        output eth_phy_tx_ctrl,
        output eth_phy_txd,
        output eth_phy_rstn,

        output eth_mdc,
        inout  eth_mdio
    );

endinterface

`endif
