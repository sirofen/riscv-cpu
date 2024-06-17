# Clock Input
create_clock -period 20.000 -name clk [get_ports i_clk]
set_property IOSTANDARD LVCMOS33 [get_ports i_clk]
set_property PACKAGE_PIN G22 [get_ports i_clk]

# Reset Input
set_property IOSTANDARD LVCMOS33 [get_ports i_rstn]
set_property PACKAGE_PIN D26 [get_ports i_rstn]

# UART Ports
set_property IOSTANDARD LVCMOS33 [get_ports i_uart_rx]
set_property PACKAGE_PIN B20 [get_ports i_uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports o_uart_tx]
set_property PACKAGE_PIN C22 [get_ports o_uart_tx]

# LED Outputs
set_property IOSTANDARD LVCMOS33 [get_ports {o_led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_led[0]}]
set_property PACKAGE_PIN A23 [get_ports {o_led[0]}]
set_property PACKAGE_PIN A24 [get_ports {o_led[1]}]
set_property PACKAGE_PIN D23 [get_ports {o_led[2]}]
set_property PACKAGE_PIN C24 [get_ports {o_led[3]}]

# PCIE
set_property PACKAGE_PIN J4 [get_ports {pcie_rx_p[0]}]
set_property PACKAGE_PIN L4 [get_ports {pcie_rx_p[1]}]
set_property PACKAGE_PIN N4 [get_ports {pcie_rx_p[2]}]
set_property PACKAGE_PIN R4 [get_ports {pcie_rx_p[3]}]

set_property PACKAGE_PIN H2 [get_ports {pcie_tx_p[0]}]
set_property PACKAGE_PIN K2 [get_ports {pcie_tx_p[1]}]
set_property PACKAGE_PIN M2 [get_ports {pcie_tx_p[2]}]
set_property PACKAGE_PIN P2 [get_ports {pcie_tx_p[3]}]

set_property PACKAGE_PIN K6 [get_ports pcie_ref_clk_p]

# ETH
set_property IOSTANDARD LVCMOS18 [get_ports eth_phy_rxc]
set_property IOSTANDARD LVCMOS18 [get_ports eth_phy_txc]
set_property IOSTANDARD LVCMOS18 [get_ports {eth_phy_rxd[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {eth_phy_rxd[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {eth_phy_rxd[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {eth_phy_rxd[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {eth_phy_txd[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {eth_phy_txd[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {eth_phy_txd[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {eth_phy_txd[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports eth_mdc]
set_property IOSTANDARD LVCMOS18 [get_ports eth_mdio]
set_property IOSTANDARD LVCMOS18 [get_ports eth_phy_rx_ctrl]
set_property IOSTANDARD LVCMOS18 [get_ports eth_phy_rstn]
set_property IOSTANDARD LVCMOS18 [get_ports eth_phy_tx_ctrl]

set_property PACKAGE_PIN W1  [get_ports eth_mdc]
set_property PACKAGE_PIN AF5 [get_ports eth_mdio]
set_property PACKAGE_PIN Y2  [get_ports eth_phy_rstn]
set_property PACKAGE_PIN AF4 [get_ports eth_phy_rx_ctrl]
set_property PACKAGE_PIN Y1  [get_ports eth_phy_tx_ctrl]
set_property PACKAGE_PIN AC2 [get_ports eth_phy_txc]
set_property PACKAGE_PIN AC1 [get_ports {eth_phy_txd[0]}]
set_property PACKAGE_PIN AB1 [get_ports {eth_phy_txd[1]}]
set_property PACKAGE_PIN AB4 [get_ports {eth_phy_txd[2]}]
set_property PACKAGE_PIN Y3  [get_ports {eth_phy_txd[3]}]
set_property PACKAGE_PIN AB2 [get_ports eth_phy_rxc]
set_property PACKAGE_PIN AF3 [get_ports {eth_phy_rxd[0]}]
set_property PACKAGE_PIN AC3 [get_ports {eth_phy_rxd[1]}]
set_property PACKAGE_PIN AE2 [get_ports {eth_phy_rxd[2]}]
set_property PACKAGE_PIN AE1 [get_ports {eth_phy_rxd[3]}]
