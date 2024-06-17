`ifndef ARP_TOP
`define ARP_TOP

`include "crc32.sv"
`include "arp_rxd.sv"
`include "arp_txd.sv"
`include "cam.sv"

module arp_top (
    input logic rst_n,

    // GMII RX Interface
    input logic       gmii_rxc,
    input logic       gmii_rxdv,
    input logic [7:0] gmii_rxd,

    // GMII TX Interface
    input  logic       gmii_txc,
    output logic       gmii_txen,
    output logic [7:0] gmii_txd,

    // ARP Control
    input logic        arp_request,
    input logic [31:0] target_ip,

    // ARP Status
    output logic        arp_busy,
    output logic        mac_ready,
    output logic [47:0] resolved_mac,

    // Board Configuration
    input logic [47:0] self_mac,
    input logic [31:0] self_ip
);

  // Internal signals
  logic [31:0] crc_data;
  logic [31:0] crc_next;
  logic        crc_en;
  logic        crc_clear;
  logic [ 7:0] crc_d8;
  logic [47:0] destination_mac;
  logic [31:0] destination_ip;
  logic        arp_tx_en;
  logic        arp_tx_type;
  logic        tx_done;
  logic        arp_rx_done;
  logic        arp_rx_type;
  logic [31:0] source_ip;
  logic [47:0] source_mac;
  logic        search_en;
  logic [47:0] cam_mac;
  logic        cam_match;
  logic        cam_write_en;

  assign crc_d8 = gmii_txd;
  assign cam_write_en = arp_rx_done && arp_rx_type == 1'b1;

  // CRC32 Module Instance
  crc32 crc32_inst (
      .clk(gmii_txc),
      .rst_n(rst_n),
      .data_in(crc_d8),
      .crc_en(crc_en),
      .crc_clear(crc_clear),
      .crc_data(crc_data),
      .crc_next(crc_next)
  );

  // ARP RXD Module Instance
  arp_rxd arp_rxd_inst (
      .clk(gmii_rxc),
      .rst_n(rst_n),
      .gmii_rxdv(gmii_rxdv),
      .gmii_rxd(gmii_rxd),
      .self_mac(self_mac),
      .self_ip(self_ip),
      .arp_rx_done(arp_rx_done),
      .arp_rx_type(arp_rx_type),
      .source_mac(source_mac),
      .source_ip(source_ip)
  );

  // ARP TXD Module Instance
  arp_txd arp_txd_inst (
      .clk(gmii_txc),
      .rst_n(rst_n),
      .arp_tx_en(arp_tx_en),
      .arp_tx_type(arp_tx_type),
      .dest_mac(destination_mac),
      .dest_ip(destination_ip),
      .crc_data(crc_data),
      .crc_next(crc_next[31:24]),
      .tx_done(tx_done),
      .gmii_txen(gmii_txen),
      .gmii_txd(gmii_txd),
      .crc_en(crc_en),
      .crc_clear(crc_clear),
      .self_mac(self_mac),
      .self_ip(self_ip)
  );

  // CAM instance for IP-MAC mapping
  cam #(
      .ADDR_WIDTH(32),
      .DATA_WIDTH(48),
      .DEPTH(16)
  ) cam_inst (
      .clk(gmii_txc),
      .rst_n(rst_n),
      .search_en(search_en),
      .search_key(target_ip),
      .search_data(cam_mac),
      .match(cam_match),
      .write_en(cam_write_en),
      .write_key(source_ip),
      .write_data(source_mac)
  );

  // State machine for ARP resolution
  typedef enum logic [2:0] {
    IDLE,
    CHECK_CAM,
    REQUEST,
    WAIT_RESPONSE,
    RESPOND_ARP_REQUEST
  } arp_state_t;

  arp_state_t state, next_state;

  always_ff @(posedge gmii_txc or negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else state <= next_state;
  end

  always_comb begin
    next_state = state;
    arp_tx_en = 1'b0;
    arp_tx_type = 1'b0;
    destination_mac = 48'hFF_FF_FF_FF_FF_FF;
    destination_ip = target_ip;
    arp_busy = 1'b1;
    mac_ready = 1'b0;
    resolved_mac = 48'd0;
    search_en = 1'b0;

    case (state)
      IDLE: begin
        arp_busy = 1'b0;
        if (arp_request) begin
          search_en  = 1'b1;
          next_state = CHECK_CAM;
        end else if (arp_rx_done && arp_rx_type == 1'b0) begin
          next_state = RESPOND_ARP_REQUEST;
        end
      end
      CHECK_CAM: begin
        if (cam_match) begin
          mac_ready = 1'b1;
          resolved_mac = cam_mac;
          next_state = IDLE;
        end else begin
          next_state = REQUEST;
        end
      end
      REQUEST: begin
        arp_tx_en   = 1'b1;
        arp_tx_type = 1'b0;
        if (tx_done) next_state = WAIT_RESPONSE;
      end
      WAIT_RESPONSE: begin
        if (arp_rx_done && arp_rx_type == 1'b1) begin
          mac_ready = 1'b1;
          resolved_mac = source_mac;
          next_state = IDLE;
        end
      end
      RESPOND_ARP_REQUEST: begin
        arp_tx_en = 1'b1;
        arp_tx_type = 1'b1;
        destination_mac = source_mac;
        destination_ip = source_ip;
        if (tx_done) next_state = IDLE;
      end
    endcase
  end

endmodule

`endif  // ARP_TOP
