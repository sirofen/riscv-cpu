`ifndef RGMII_TXD
`define RGMII_TXD

module rgmii_txd (
    input  logic       gmii_txc,
    input  logic       gmii_txen,
    input  logic [7:0] gmii_txd,
    output logic       rgmii_txc,
    output logic       rgmii_tx_ctrl,
    output logic [3:0] rgmii_txd
);

  assign rgmii_txc = gmii_txc;

  // TX CTRL DDR OUTPUT
  ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"),
      .INIT        (1'b0),
      .SRTYPE      ("SYNC")
  ) oddr_tx_ctrl_inst (
      .Q (rgmii_tx_ctrl),
      .C (gmii_txc),
      .CE(1'b1),
      .D1(gmii_txen),
      .D2(gmii_txen),
      .R (1'b0),
      .S (1'b0)
  );

  genvar i;
  generate
    for (i = 0; i < 4; i++) begin : txd_ddr
      // TXD DDR OUTPUT
      ODDR #(
          .DDR_CLK_EDGE("SAME_EDGE"),
          .INIT        (1'b0),
          .SRTYPE      ("SYNC")
      ) oddr_txd_inst (
          .Q (rgmii_txd[i]),
          .C (gmii_txc),
          .CE(1'b1),
          .D1(gmii_txd[i]),
          .D2(gmii_txd[4+i]),
          .R (1'b0),
          .S (1'b0)
      );
    end
  endgenerate

endmodule

`endif  // RGMII_TXD
