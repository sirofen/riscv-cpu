`ifndef ARP_RXD
`define ARP_RXD

module arp_rxd (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        gmii_rxdv,
    input  logic [ 7:0] gmii_rxd,
    input  logic [47:0] self_mac,
    input  logic [31:0] self_ip,
    output logic        arp_rx_done,
    output logic        arp_rx_type,
    output logic [47:0] source_mac,
    output logic [31:0] source_ip
);

  typedef enum logic [4:0] {
    STATE_IDLE,
    STATE_PREAMBLE,
    STATE_ETH_HEAD,
    STATE_ARP_DATA,
    STATE_RX_END
  } state_t;

  localparam logic [15:0] ETH_TYPE = 16'h0806;

  state_t cur_state, next_state;

  logic        skip_en;
  logic        error_en;
  logic [ 4:0] cnt;
  logic [47:0] destination_mac_t;
  logic [31:0] destination_ip_t;
  logic [47:0] source_mac_t;
  logic [31:0] source_ip_t;
  logic [15:0] eth_type;
  logic [15:0] op_data;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cur_state <= STATE_IDLE;
    else cur_state <= next_state;
  end

  always_comb begin
    next_state = STATE_IDLE;
    case (cur_state)
      STATE_IDLE: if (skip_en) next_state = STATE_PREAMBLE;
      STATE_PREAMBLE:
      if (skip_en) next_state = STATE_ETH_HEAD;
      else if (error_en) next_state = STATE_RX_END;
      STATE_ETH_HEAD:
      if (skip_en) next_state = STATE_ARP_DATA;
      else if (error_en) next_state = STATE_RX_END;
      STATE_ARP_DATA:
      if (skip_en) next_state = STATE_RX_END;
      else if (error_en) next_state = STATE_RX_END;
      STATE_RX_END: if (skip_en) next_state = STATE_IDLE;
      default: next_state = STATE_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      skip_en <= 1'b0;
      error_en <= 1'b0;
      cnt <= 5'd0;
      destination_mac_t <= 48'd0;
      destination_ip_t <= 32'd0;
      source_mac_t <= 48'd0;
      source_ip_t <= 32'd0;
      eth_type <= 16'd0;
      op_data <= 16'd0;
      arp_rx_done <= 1'b0;
      arp_rx_type <= 1'b0;
      source_mac <= 48'd0;
      source_ip <= 32'd0;
    end else begin
      skip_en <= 1'b0;
      error_en <= 1'b0;
      arp_rx_done <= 1'b0;
      case (next_state)
        STATE_IDLE: if ((gmii_rxdv == 1'b1) && (gmii_rxd == 8'h55)) skip_en <= 1'b1;
        STATE_PREAMBLE:
        if (gmii_rxdv) begin
          cnt <= cnt + 5'd1;
          if ((cnt < 5'd6) && (gmii_rxd != 8'h55)) error_en <= 1'b1;
          else if (cnt == 5'd6) begin
            cnt <= 5'd0;
            if (gmii_rxd == 8'hd5) skip_en <= 1'b1;
            else error_en <= 1'b1;
          end
        end
        STATE_ETH_HEAD:
        if (gmii_rxdv) begin
          cnt <= cnt + 5'b1;
          if (cnt < 5'd6) destination_mac_t <= {destination_mac_t[39:0], gmii_rxd};
          else if (cnt == 5'd6) begin
            if ((destination_mac_t != self_mac) && (destination_mac_t != 48'hff_ff_ff_ff_ff_ff))
              error_en <= 1'b1;
          end else if (cnt == 5'd12) eth_type[15:8] <= gmii_rxd;
          else if (cnt == 5'd13) begin
            eth_type[7:0] <= gmii_rxd;
            cnt <= 5'd0;
            if (eth_type[15:8] == ETH_TYPE[15:8] && gmii_rxd == ETH_TYPE[7:0]) skip_en <= 1'b1;
            else error_en <= 1'b1;
          end
        end
        STATE_ARP_DATA:
        if (gmii_rxdv) begin
          cnt <= cnt + 5'd1;
          if (cnt == 5'd6) op_data[15:8] <= gmii_rxd;
          else if (cnt == 5'd7) op_data[7:0] <= gmii_rxd;
          else if (cnt >= 5'd8 && cnt < 5'd14) source_mac_t <= {source_mac_t[39:0], gmii_rxd};
          else if (cnt >= 5'd14 && cnt < 5'd18) source_ip_t <= {source_ip_t[23:0], gmii_rxd};
          else if (cnt >= 5'd24 && cnt < 5'd28)
            destination_ip_t <= {destination_ip_t[23:0], gmii_rxd};
          else if (cnt == 5'd28) begin
            cnt <= 5'd0;
            if (destination_ip_t == self_ip) begin
              if ((op_data == 16'd1) || (op_data == 16'd2)) begin
                skip_en <= 1'b1;
                arp_rx_done <= 1'b1;
                source_mac <= source_mac_t;
                source_ip <= source_ip_t;
                source_mac_t <= 48'd0;
                source_ip_t <= 32'd0;
                destination_mac_t <= 48'd0;
                destination_ip_t <= 32'd0;
                if (op_data == 16'd1) arp_rx_type <= 1'b0;
                else arp_rx_type <= 1'b1;
              end else error_en <= 1'b1;
            end else error_en <= 1'b1;
          end
        end
        STATE_RX_END: begin
          cnt <= 5'd0;
          if (gmii_rxdv == 1'b0 && skip_en == 1'b0) skip_en <= 1'b1;
        end
        default: ;
      endcase
    end
  end

endmodule

`endif  // ARP_RXD
