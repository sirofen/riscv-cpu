`ifndef UDP_TOP
`define UDP_TOP 

`include "udp_rxd.sv"
`include "udp_txd.sv"
`include "crc32.sv"

module udp_top (
    input logic rst_n,
    // GMII
    input logic gmii_rxc,
    input logic gmii_rxdv,
    input logic [7:0] gmii_rxd,
    input logic gmii_txc,
    output logic gmii_txen,
    output logic [7:0] gmii_txd,
    // UDP port
    output logic rxd_pkt_done,
    output logic rxd_wr_en,
    output logic [31:0] rxd_wr_data,
    output logic [15:0] rxd_wr_byte_num,
    output logic [15:0] rx_src_port,
    output logic [15:0] rx_dest_port,
    input logic tx_start_en,
    input logic [31:0] tx_data,
    input logic [15:0] tx_byte_num,
    input logic [15:0] tx_src_port,
    input logic [15:0] tx_dest_port,
    input logic [47:0] tx_dest_mac,
    input logic [31:0] tx_dest_ip,
    input logic [47:0] self_mac,
    input logic [31:0] self_ip,
    output logic tx_done,
    output logic tx_request
);

  logic crc_en;
  logic crc_clear;
  logic [7:0] crc_d8;

  logic [31:0] crc_data;
  logic [31:0] crc_next;

  assign crc_d8 = gmii_txd;

  // UDP RXD module
  udp_rxd udp_rx_inst (
      .clk(gmii_rxc),
      .rst_n(rst_n),
      .gmii_rxdv(gmii_rxdv),
      .gmii_rxd(gmii_rxd),
      .rxd_pkt_done(rxd_pkt_done),
      .rxd_wr_en(rxd_wr_en),
      .rxd_wr_data(rxd_wr_data),
      .rxd_wr_byte_num(rxd_wr_byte_num),
      .self_mac(self_mac),
      .self_ip(self_ip),
      .src_port(rx_src_port),
      .dest_port(rx_dest_port)
  );

  // Ethernet sending module
  udp_txd udp_tx_inst (
      .clk(gmii_txc),
      .rst_n(rst_n),
      .tx_start_en(tx_start_en),
      .tx_data(tx_data),
      .tx_byte_num(tx_byte_num),
      .dest_mac(tx_dest_mac),
      .dest_ip(tx_dest_ip),
      .crc_data(crc_data),
      .crc_next(crc_next[31:24]),
      .tx_done(tx_done),
      .tx_request(tx_request),
      .gmii_txen(gmii_txen),
      .gmii_txd(gmii_txd),
      .crc_en(crc_en),
      .crc_clear(crc_clear),
      .self_mac(self_mac),
      .self_ip(self_ip),
      .src_port(tx_src_port),
      .dest_port(tx_dest_port)
  );

  // ARP TXD module
  crc32 crc32_inst (
      .clk(gmii_txc),
      .rst_n(rst_n),
      .data_in(crc_d8),
      .crc_en(crc_en),
      .crc_clear(crc_clear),
      .crc_data(crc_data),
      .crc_next(crc_next)
  );

endmodule

`endif  // UDP_TOP
