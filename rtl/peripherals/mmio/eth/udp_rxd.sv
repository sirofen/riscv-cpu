`ifndef UDP_RXD
`define UDP_RXD

module udp_rxd (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        gmii_rxdv,
    input  logic [ 7:0] gmii_rxd,
    output logic        rxd_pkt_done,
    output logic        rxd_wr_en,
    output logic [31:0] rxd_wr_data,
    output logic [15:0] rxd_wr_byte_num,
    input  logic [47:0] self_mac,
    input  logic [31:0] self_ip,
    output logic [15:0] src_port,
    output logic [15:0] dest_port
);

  localparam ETH_TYPE = 16'h0800;

  typedef enum logic [6:0] {
    STATE_IDLE,
    STATE_PREAMBLE,
    STATE_ETH_HEAD,
    STATE_IP_HEAD,
    STATE_UDP_HEAD,
    STATE_RX_DATA,
    STATE_RX_END
  } state_t;

  state_t cur_state, next_state;
  logic        skip_en;
  logic        error_en;
  logic [ 4:0] cnt;
  logic [47:0] destination_mac;
  logic [15:0] eth_type;
  logic [31:0] destination_ip;
  logic [ 5:0] ip_head_byte_num;
  logic [15:0] udp_byte_num;
  logic [15:0] data_byte_num;
  logic [15:0] data_cnt;
  logic [ 1:0] rxd_wr_en_cnt;
  logic [15:0] src_port_reg;
  logic [15:0] dest_port_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cur_state <= STATE_IDLE;
    else cur_state <= next_state;
  end

  always_comb begin
    next_state = STATE_IDLE;
    case (cur_state)
      STATE_IDLE: next_state = skip_en ? STATE_PREAMBLE : STATE_IDLE;
      STATE_PREAMBLE:
      next_state = skip_en ? STATE_ETH_HEAD : (error_en ? STATE_RX_END : STATE_PREAMBLE);
      STATE_ETH_HEAD:
      next_state = skip_en ? STATE_IP_HEAD : (error_en ? STATE_RX_END : STATE_ETH_HEAD);
      STATE_IP_HEAD:
      next_state = skip_en ? STATE_UDP_HEAD : (error_en ? STATE_RX_END : STATE_IP_HEAD);
      STATE_UDP_HEAD: next_state = skip_en ? STATE_RX_DATA : STATE_UDP_HEAD;
      STATE_RX_DATA: next_state = skip_en ? STATE_RX_END : STATE_RX_DATA;
      STATE_RX_END: next_state = skip_en ? STATE_IDLE : STATE_RX_END;
      default: next_state = STATE_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      skip_en <= 1'b0;
      error_en <= 1'b0;
      cnt <= 5'd0;
      destination_mac <= 48'd0;
      eth_type <= 16'd0;
      destination_ip <= 32'd0;
      ip_head_byte_num <= 6'd0;
      udp_byte_num <= 16'd0;
      data_byte_num <= 16'd0;
      data_cnt <= 16'd0;
      rxd_wr_en_cnt <= 2'd0;
      rxd_wr_en <= 1'b0;
      rxd_wr_data <= 32'd0;
      rxd_pkt_done <= 1'b0;
      rxd_wr_byte_num <= 16'd0;
      src_port_reg <= 16'd0;
      dest_port_reg <= 16'd0;
    end else begin
      skip_en <= 1'b0;
      error_en <= 1'b0;
      rxd_wr_en <= 1'b0;
      rxd_pkt_done <= 1'b0;
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
          cnt <= cnt + 5'd1;
          case (cnt)
            5'd0, 5'd1, 5'd2, 5'd3, 5'd4, 5'd5:
            destination_mac <= {destination_mac[39:0], gmii_rxd};
            5'd12: eth_type[15:8] <= gmii_rxd;
            5'd13: begin
              eth_type[7:0] <= gmii_rxd;
              cnt <= 5'd0;
              if (((destination_mac == self_mac) || (destination_mac == 48'hff_ff_ff_ff_ff_ff)) &&
                    eth_type[15:8] == ETH_TYPE[15:8] && gmii_rxd == ETH_TYPE[7:0])
                skip_en <= 1'b1;
              else error_en <= 1'b1;
            end
          endcase
        end
        STATE_IP_HEAD:
        if (gmii_rxdv) begin
          cnt <= cnt + 5'd1;
          case (cnt)
            5'd0: ip_head_byte_num <= {gmii_rxd[3:0], 2'd0};
            5'd16, 5'd17, 5'd18: destination_ip <= {destination_ip[23:0], gmii_rxd};
            5'd19: begin
              destination_ip <= {destination_ip[23:0], gmii_rxd};
              if ((destination_ip[23:0] == self_ip[31:8]) && (gmii_rxd == self_ip[7:0])) begin
                if (cnt == ip_head_byte_num - 1'b1) begin
                  skip_en <= 1'b1;
                  cnt <= 5'd0;
                end
              end else begin
                error_en <= 1'b1;
                cnt <= 5'd0;
              end
            end
            default:
            if (cnt == ip_head_byte_num - 1'b1) begin
              skip_en <= 1'b1;
              cnt <= 5'd0;
            end
          endcase
        end
        STATE_UDP_HEAD:
        if (gmii_rxdv) begin
          cnt <= cnt + 5'd1;
          case (cnt)
            5'd0: src_port_reg[15:8] <= gmii_rxd;
            5'd1: src_port_reg[7:0] <= gmii_rxd;
            5'd2: dest_port_reg[15:8] <= gmii_rxd;
            5'd3: dest_port_reg[7:0] <= gmii_rxd;
            5'd4: udp_byte_num[15:8] <= gmii_rxd;
            5'd5: udp_byte_num[7:0] <= gmii_rxd;
            5'd7: begin
              data_byte_num <= udp_byte_num - 16'd8;
              skip_en <= 1'b1;
              cnt <= 5'd0;
            end
          endcase
        end
        STATE_RX_DATA:
        if (gmii_rxdv) begin
          data_cnt <= data_cnt + 16'd1;
          rxd_wr_en_cnt <= rxd_wr_en_cnt + 2'd1;
          if (data_cnt == data_byte_num - 16'd1) begin
            skip_en <= 1'b1;
            data_cnt <= 16'd0;
            rxd_wr_en_cnt <= 2'd0;
            rxd_pkt_done <= 1'b1;
            rxd_wr_en <= 1'b1;
            rxd_wr_byte_num <= data_byte_num;
          end
          case (rxd_wr_en_cnt)
            2'd0: rxd_wr_data[31:24] <= gmii_rxd;
            2'd1: rxd_wr_data[23:16] <= gmii_rxd;
            2'd2: rxd_wr_data[15:8] <= gmii_rxd;
            2'd3: begin
              rxd_wr_en <= 1'b1;
              rxd_wr_data[7:0] <= gmii_rxd;
            end
          endcase
        end
        STATE_RX_END: if (gmii_rxdv == 1'b0 && skip_en == 1'b0) skip_en <= 1'b1;
        default: ;
      endcase
    end
  end

  assign src_port  = src_port_reg;
  assign dest_port = dest_port_reg;

endmodule

`endif  // UDP_RXD
