`ifndef RGMII_RXD
`define RGMII_RXD

module rgmii_rxd (
    input  logic       refclk_200m,
    input  logic       rgmii_rxc,
    input  logic       rgmii_rx_ctrl,
    input  logic [3:0] rgmii_rxd,
    output logic       gmii_rxc,
    output logic       gmii_rxdv,
    output logic [7:0] gmii_rxd
);

  localparam int IDELAY_VALUE = 0;
  localparam real REFCLK_FREQUENCY = 200.0;

  logic       rgmii_rxc_buf;
  logic [3:0] rgmii_rxd_delay;
  logic       rgmii_rx_ctl_delay;
  logic [1:0] gmii_rxdv_t;

  assign gmii_rxdv = gmii_rxdv_t[0] & gmii_rxdv_t[1];

  BUFG bufg_inst (
      .I(rgmii_rxc),
      .O(gmii_rxc)
  );

  BUFIO bufio_inst (
      .I(rgmii_rxc),
      .O(rgmii_rxc_buf)
  );

  IDELAYCTRL idelayctrl_inst (
      .RDY(),
      .REFCLK(refclk_200m),
      .RST(1'b0)
  );

  IDELAYE2 #(
      .IDELAY_TYPE("FIXED"),
      .IDELAY_VALUE(IDELAY_VALUE),
      .REFCLK_FREQUENCY(REFCLK_FREQUENCY)
  ) idelaye2_rx_ctrl_inst (
      .CNTVALUEOUT(),
      .DATAOUT(rgmii_rx_ctl_delay),
      .C(1'b0),
      .CE(1'b0),
      .CINVCTRL(1'b0),
      .CNTVALUEIN(5'b0),
      .DATAIN(1'b0),
      .IDATAIN(rgmii_rx_ctrl),
      .INC(1'b0),
      .LD(1'b0),
      .LDPIPEEN(1'b0),
      .REGRST(1'b0)
  );

  IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
      .INIT_Q1(1'b0),
      .INIT_Q2(1'b0),
      .SRTYPE("SYNC")
  ) iddr_rx_ctrl_inst (
      .Q1(gmii_rxdv_t[0]),
      .Q2(gmii_rxdv_t[1]),
      .C (rgmii_rxc_buf),
      .CE(1'b1),
      .D (rgmii_rx_ctl_delay),
      .R (1'b0),
      .S (1'b0)
  );

  genvar i;
  generate
    for (i = 0; i < 4; i++) begin : rxdata_bus
      IDELAYE2 #(
          .IDELAY_TYPE("FIXED"),
          .IDELAY_VALUE(IDELAY_VALUE),
          .REFCLK_FREQUENCY(REFCLK_FREQUENCY)
      ) idelaye2_rxd_inst (
          .CNTVALUEOUT(),
          .DATAOUT(rgmii_rxd_delay[i]),
          .C(1'b0),
          .CE(1'b0),
          .CINVCTRL(1'b0),
          .CNTVALUEIN(5'b0),
          .DATAIN(1'b0),
          .IDATAIN(rgmii_rxd[i]),
          .INC(1'b0),
          .LD(1'b0),
          .LDPIPEEN(1'b0),
          .REGRST(1'b0)
      );

      IDDR #(
          .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
          .INIT_Q1(1'b0),
          .INIT_Q2(1'b0),
          .SRTYPE("SYNC")
      ) iddr_rxd_inst (
          .Q1(gmii_rxd[i]),
          .Q2(gmii_rxd[4+i]),
          .C (rgmii_rxc_buf),
          .CE(1'b1),
          .D (rgmii_rxd_delay[i]),
          .R (1'b0),
          .S (1'b0)
      );
    end
  endgenerate

endmodule

`endif  // RGMII_RXD
