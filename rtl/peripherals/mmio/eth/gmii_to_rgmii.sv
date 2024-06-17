`ifndef GMII_TO_RGMII
`define GMII_TO_RGMII

`include "rgmii_rxd.sv"
`include "rgmii_txd.sv"

module gmii_to_rgmii (
    input  logic       refclk_200m,
    // GMII
    output logic       gmii_rxc,
    output logic       gmii_rxdv,
    output logic [7:0] gmii_rxd,
    output logic       gmii_txc,
    input  logic       gmii_txen,
    input  logic [7:0] gmii_txd,
    // RGMII
    input  logic       rgmii_rxc,
    input  logic       rgmii_rx_ctrl,
    input  logic [3:0] rgmii_rxd,
    output logic       rgmii_txc,
    output logic       rgmii_tx_ctrl,
    output logic [3:0] rgmii_txd
);

  assign gmii_txc = gmii_rxc;

  // RGMII RX DATA
  rgmii_rxd rgmii_rxd_inst (
      .refclk_200m  (refclk_200m),
      .gmii_rxc     (gmii_rxc),
      .rgmii_rxc    (rgmii_rxc),
      .rgmii_rx_ctrl(rgmii_rx_ctrl),
      .rgmii_rxd    (rgmii_rxd),
      .gmii_rxdv    (gmii_rxdv),
      .gmii_rxd     (gmii_rxd)
  );

  // RGMII TX DATA
  rgmii_txd rgmii_txd_inst (
      .gmii_txc     (gmii_txc),
      .gmii_txen    (gmii_txen),
      .gmii_txd     (gmii_txd),
      .rgmii_txc    (rgmii_txc),
      .rgmii_tx_ctrl(rgmii_tx_ctrl),
      .rgmii_txd    (rgmii_txd)
  );

endmodule

`endif  // GMII_TO_RGMII
