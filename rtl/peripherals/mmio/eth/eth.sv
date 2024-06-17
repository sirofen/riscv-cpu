`ifndef ETH
`define ETH

`include "gmii_to_rgmii.sv"
`include "mdio_driver.sv"
`include "mdio_read_write.sv"
`include "arp_top.sv"
`include "udp_top.sv"

module eth #(
    parameter integer BUF_SIZE = 1024
) (
    input logic clk,
    input logic rst_n,

    input  logic       phy_rxc,
    input  logic       phy_rx_ctrl,
    input  logic [3:0] phy_rxd,
    output logic       phy_txc,
    output logic       phy_tx_ctrl,
    output logic [3:0] phy_txd,
    output logic       phy_rstn,

    output logic mdc,
    inout  logic mdio,

    output logic [1:0] linkspeed,

    input logic [47:0] self_mac,
    input logic [31:0] self_ip,
    input logic [31:0] gateway_ip,

    output logic [BUF_SIZE-1:0] recv_buf,
    input  logic [BUF_SIZE-1:0] send_buf,

    input logic [31:0] send_dest_ip,
    input logic [15:0] send_src_port,
    input logic [15:0] send_dest_port,
    input logic [15:0] send_length,
    input logic send_trigger,

    output logic [15:0] recv_src_port,
    output logic [15:0] recv_dest_port,
    output logic [15:0] recv_length,
    output logic recv_complete,

    input logic recv_buf_full
);

  logic send_arp_request;

  // Clock signals
  logic iodelay_ref_clk;
  logic mdio_clk;
  logic mdio_divid_clk;
  logic gmii_rxc;
  logic gmii_rxdv;
  logic [7:0] gmii_rxd;
  logic gmii_txc;
  logic gmii_txen;
  logic [7:0] gmii_txd;

  logic [7:0] arp_txd;
  logic arp_txen;

  logic [7:0] udp_txd;
  logic udp_txen;

  // Internal signals for ARP
  logic arp_busy;
  logic mac_ready;
  logic [47:0] resolved_mac;

  logic [47:0] udp_dest_mac;

  // Internal signals for MDIO
  logic mdio_triger;
  logic write_read;
  logic [4:0] reg_addr;
  logic [15:0] write_data;
  logic [15:0] read_data;
  logic read_ack;
  logic mdio_done;

  // Function to reverse bytes in a 32-bit word
  function [31:0] reverse_bytes(input [31:0] data);
    reverse_bytes = {data[7:0], data[15:8], data[23:16], data[31:24]};
  endfunction

  // Clock wizard instance
  clk_wiz_1 clk_wiz_inst1 (
      .clk_in1 (clk),
      .clk_out1(iodelay_ref_clk),
      .clk_out2(mdio_clk),
      .resetn  (rst_n)
  );

  // GMII to RGMII converter
  gmii_to_rgmii gmii_to_rgmii_inst (
      .refclk_200m  (iodelay_ref_clk),
      .gmii_rxc     (gmii_rxc),
      .gmii_rxdv    (gmii_rxdv),
      .gmii_rxd     (gmii_rxd),
      .gmii_txc     (gmii_txc),
      .gmii_txen    (gmii_txen),
      .gmii_txd     (gmii_txd),
      .rgmii_rxc    (phy_rxc),
      .rgmii_rx_ctrl(phy_rx_ctrl),
      .rgmii_rxd    (phy_rxd),
      .rgmii_txc    (phy_txc),
      .rgmii_tx_ctrl(phy_tx_ctrl),
      .rgmii_txd    (phy_txd)
  );

  // MDIO driver
  mdio_driver mdio_driver_inst (
      .clk        (mdio_clk),
      .rst_n      (rst_n),
      .mdio_triger(mdio_triger),
      .write_read (write_read),
      .reg_addr   (reg_addr),
      .write_data (write_data),
      .done       (mdio_done),
      .read_data  (read_data),
      .read_ack   (read_ack),
      .divid_clk  (mdio_divid_clk),
      .phy_mdc    (mdc),
      .phy_mdio   (mdio)
  );

  // MDIO read/write control
  mdio_read_write mdio_read_write_inst (
      .clk        (mdio_divid_clk),
      .rst_n      (rst_n),
      .rst_trig   (1'b1),
      .done       (mdio_done),
      .read_data  (read_data),
      .read_ack   (read_ack),
      .mdio_triger(mdio_triger),
      .write_read (write_read),
      .reg_addr   (reg_addr),
      .write_data (write_data),
      .linkspeed  (linkspeed)
  );

  // ARP module
  arp_top arp_top_inst (
      .rst_n       (rst_n),
      .gmii_rxc    (gmii_rxc),
      .gmii_rxdv   (gmii_rxdv),
      .gmii_rxd    (gmii_rxd),
      .gmii_txc    (gmii_txc),
      .gmii_txen   (arp_txen),
      .gmii_txd    (arp_txd),
      .arp_request (send_arp_request),
      .target_ip   (gateway_ip),
      .arp_busy    (arp_busy),
      .mac_ready   (mac_ready),
      .resolved_mac(resolved_mac),
      .self_mac    (self_mac),
      .self_ip     (self_ip)
  );

  // UDP module
  udp_top udp_top_inst (
      .rst_n          (rst_n),
      .gmii_rxc       (gmii_rxc),
      .gmii_rxdv      (gmii_rxdv && !recv_buf_full),
      .gmii_rxd       (gmii_rxd),
      .gmii_txc       (gmii_txc),
      .gmii_txen      (udp_txen),
      .gmii_txd       (udp_txd),
      .rxd_pkt_done   (rxd_pkt_done),
      .rxd_wr_en      (rxd_wr_en),
      .rxd_wr_data    (rxd_wr_data),
      .rxd_wr_byte_num(rxd_wr_byte_num),
      .rx_src_port    (recv_src_port),
      .rx_dest_port   (recv_dest_port),
      .tx_start_en    (tx_start_en),
      .tx_data        (tx_data),
      .tx_byte_num    (tx_byte_num),
      .tx_src_port    (send_src_port),
      .tx_dest_port   (send_dest_port),
      .tx_dest_mac    (udp_dest_mac),
      .tx_dest_ip     (send_dest_ip),
      .self_mac       (self_mac),
      .self_ip        (self_ip),
      .tx_done        (tx_done),
      .tx_request     (tx_request)
  );

  assign phy_rstn = rst_n;

  // Receive signals
  logic rxd_pkt_done;
  logic rxd_wr_en;
  logic [31:0] rxd_wr_data;
  logic [15:0] rxd_wr_byte_num;

  logic [31:0] rxd_data_trimmed;
  logic recv_complete_gmii;

  // Transfer signals
  logic tx_start_en;
  logic [31:0] tx_data;
  logic [15:0] tx_byte_num;

  logic tx_done;
  logic tx_request;

  // State definitions for send logic
  typedef enum logic [2:0] {
    SEND_IDLE,
    RESOLVE_MAC,
    SEND_START,
    SEND_DATA,
    SEND_COMPLETE
  } send_state_t;

  send_state_t send_state, next_send_state;

  logic [16:0] tx_buf_ptr;

  // Signal to hold recv_complete_gmii high for a few gmii_rxc cycles
  logic [ 2:0] pulse_counter;
  logic [15:0] recv_buf_ptr;

  // Receive logic
  always_ff @(posedge gmii_rxc or negedge rst_n) begin
    if (!rst_n) begin
      recv_buf_ptr <= 16'h0;
      recv_complete_gmii <= 1'b0;
      recv_length <= 16'h0;
      pulse_counter <= 3'b000;
    end else begin
      if (rxd_pkt_done) begin
        recv_complete_gmii <= 1'b1;
        recv_length <= rxd_wr_byte_num;
        recv_buf_ptr <= 16'h0;
        pulse_counter <= 3'b100;
      end else if (pulse_counter > 3'b000) begin
        pulse_counter <= pulse_counter - 3'b001;
        if (pulse_counter == 3'b001) begin
          recv_complete_gmii <= 1'b0;
        end
      end else if (rxd_wr_en) begin
        recv_buf_ptr <= recv_buf_ptr + 16'd32;
      end
    end
  end

  logic [1:0] data_remaind;
  assign data_remaind = rxd_wr_byte_num[1:0];

  // Data trimming and buffer writing logic
  always_ff @(posedge gmii_rxc) begin
    if (rxd_pkt_done) begin
      case (data_remaind)
        1: recv_buf[recv_buf_ptr+:8] <= rxd_wr_data[31:24];
        2: begin
          recv_buf[recv_buf_ptr+:8]   <= rxd_wr_data[31:24];
          recv_buf[recv_buf_ptr+8+:8] <= rxd_wr_data[23:16];
        end
        3: begin
          recv_buf[recv_buf_ptr+:8] <= rxd_wr_data[31:24];
          recv_buf[recv_buf_ptr+8+:8] <= rxd_wr_data[23:16];
          recv_buf[recv_buf_ptr+16+:8] <= rxd_wr_data[15:8];
        end
        0: recv_buf[recv_buf_ptr+:32] <= reverse_bytes(rxd_wr_data);
        default: recv_buf[recv_buf_ptr+:32] <= 32'h0;
      endcase
    end else if (rxd_wr_en) begin
      recv_buf[recv_buf_ptr+:32] <= reverse_bytes(rxd_wr_data);
    end
  end

  // Cross-domain signal transfer for recv_complete
  logic recv_complete_sync1, recv_complete_sync2, recv_complete_sync3;
  logic recv_complete_pulse;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      recv_complete_sync1 <= 1'b0;
      recv_complete_sync2 <= 1'b0;
      recv_complete_sync3 <= 1'b0;
      recv_complete_pulse <= 1'b0;
    end else begin
      recv_complete_sync1 <= recv_complete_gmii;
      recv_complete_sync2 <= recv_complete_sync1;
      recv_complete_sync3 <= recv_complete_sync2;
      recv_complete_pulse <= recv_complete_sync2 && !recv_complete_sync3;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      recv_complete <= 1'b0;
    end else begin
      recv_complete <= recv_complete_pulse;
    end
  end

  // Send logic state machine
  always_ff @(posedge gmii_txc or negedge rst_n) begin
    if (!rst_n) begin
      send_state <= SEND_IDLE;
    end else begin
      send_state <= next_send_state;
    end
  end

  always_comb begin
    next_send_state = send_state;
    case (send_state)
      SEND_IDLE: if (send_trigger) next_send_state = RESOLVE_MAC;
      RESOLVE_MAC: if (mac_ready) next_send_state = SEND_START;
      SEND_START: next_send_state = SEND_DATA;
      SEND_DATA: if (tx_done) next_send_state = SEND_COMPLETE;
      SEND_COMPLETE: next_send_state = SEND_IDLE;
    endcase
  end

  always_ff @(posedge gmii_txc or negedge rst_n) begin
    if (!rst_n) begin
      tx_buf_ptr <= 17'h0;
      tx_start_en <= 1'b0;
      tx_byte_num <= 16'h0;
      tx_data <= 32'h0;
    end else begin
      case (send_state)
        SEND_IDLE: tx_start_en <= 1'b0;
        RESOLVE_MAC: if (!arp_busy) send_arp_request <= 1'b1;
        SEND_START: begin
          tx_start_en <= 1'b1;
          tx_byte_num <= send_length;
          tx_data <= reverse_bytes(send_buf[tx_buf_ptr+:32]);
        end
        SEND_DATA:
        if (tx_request) begin
          tx_buf_ptr <= tx_buf_ptr + 17'd32;
          tx_data <= reverse_bytes(send_buf[tx_buf_ptr+:32]);
        end
        SEND_COMPLETE: tx_buf_ptr <= 17'h0;
      endcase
    end
  end

  // GMII signal multiplexer
  always_comb begin
    case (send_state)
      RESOLVE_MAC: begin
        gmii_txen = arp_txen;
        gmii_txd  = arp_txd;
      end
      SEND_START, SEND_DATA, SEND_COMPLETE: begin
        gmii_txen = udp_txen;
        gmii_txd  = udp_txd;
      end
      default: begin
        gmii_txen = arp_txen;
        gmii_txd  = arp_txd;
      end
    endcase
  end

endmodule

`endif  // ETH
