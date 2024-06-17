`ifndef ARP_TXD
`define ARP_TXD

module arp_txd (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        arp_tx_en,
    input  logic        arp_tx_type,
    input  logic [47:0] dest_mac,
    input  logic [31:0] dest_ip,
    input  logic [31:0] crc_data,
    input  logic [ 7:0] crc_next,
    output logic        tx_done,
    output logic        gmii_txen,
    output logic [ 7:0] gmii_txd,
    output logic        crc_en,
    output logic        crc_clear,
    input  logic [47:0] self_mac,
    input  logic [31:0] self_ip
);

  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_PREAMBLE,
    STATE_ETH_HEAD,
    STATE_ARP_DATA,
    STATE_CRC
  } state_t;

  localparam ETH_TYPE = 16'h0806;
  localparam HD_TYPE = 16'h0001;
  localparam PROTOCOL_TYPE = 16'h0800;
  localparam MIN_DATA_NUM = 6'd46;

  state_t cur_state, next_state;

  logic [7:0] preamble[ 7:0];
  logic [7:0] eth_head[13:0];
  logic [7:0] arp_data[27:0];

  logic tx_en_d0, tx_en_d1;
  logic skip_en;
  logic [5:0] cnt = 6'd0;
  logic [4:0] data_cnt;
  logic tx_done_reg;
  logic pos_tx_en;

  assign pos_tx_en = (~tx_en_d1) & tx_en_d0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_en_d0 <= 1'b0;
      tx_en_d1 <= 1'b0;
    end else begin
      tx_en_d0 <= arp_tx_en;
      tx_en_d1 <= tx_en_d0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cur_state <= STATE_IDLE;
    else cur_state <= next_state;
  end

  always_comb begin
    next_state = STATE_IDLE;
    case (cur_state)
      STATE_IDLE: if (skip_en) next_state = STATE_PREAMBLE;
      STATE_PREAMBLE: if (skip_en) next_state = STATE_ETH_HEAD;
      STATE_ETH_HEAD: if (skip_en) next_state = STATE_ARP_DATA;
      STATE_ARP_DATA: if (skip_en) next_state = STATE_CRC;
      STATE_CRC: if (skip_en) next_state = STATE_IDLE;
      default: next_state = STATE_IDLE;
    endcase
  end

  initial begin
    preamble[0]  = 8'h55;
    preamble[1]  = 8'h55;
    preamble[2]  = 8'h55;
    preamble[3]  = 8'h55;
    preamble[4]  = 8'h55;
    preamble[5]  = 8'h55;
    preamble[6]  = 8'h55;
    preamble[7]  = 8'hd5;

    eth_head[12] = ETH_TYPE[15:8];
    eth_head[13] = ETH_TYPE[7:0];

    arp_data[0]  = HD_TYPE[15:8];
    arp_data[1]  = HD_TYPE[7:0];
    arp_data[2]  = PROTOCOL_TYPE[15:8];
    arp_data[3]  = PROTOCOL_TYPE[7:0];
    arp_data[4]  = 8'h06;
    arp_data[5]  = 8'h04;
    arp_data[6]  = 8'h00;
    arp_data[7]  = 8'h01;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      skip_en <= 1'b0;
      cnt <= 6'd0;
      data_cnt <= 5'd0;
      crc_en <= 1'b0;
      gmii_txen <= 1'b0;
      gmii_txd <= 8'd0;
      tx_done_reg <= 1'b0;
    end else begin
      skip_en <= 1'b0;
      crc_en <= 1'b0;
      gmii_txen <= 1'b0;
      tx_done_reg <= 1'b0;
      case (next_state)
        STATE_IDLE:
        if (pos_tx_en) begin
          skip_en <= 1'b1;
          if ((dest_mac != 48'b0) || (dest_ip != 32'd0)) begin
            eth_head[0]  <= dest_mac[47:40];
            eth_head[1]  <= dest_mac[39:32];
            eth_head[2]  <= dest_mac[31:24];
            eth_head[3]  <= dest_mac[23:16];
            eth_head[4]  <= dest_mac[15:8];
            eth_head[5]  <= dest_mac[7:0];
            eth_head[6]  <= self_mac[47:40];
            eth_head[7]  <= self_mac[39:32];
            eth_head[8]  <= self_mac[31:24];
            eth_head[9]  <= self_mac[23:16];
            eth_head[10] <= self_mac[15:8];
            eth_head[11] <= self_mac[7:0];

            arp_data[8]  <= self_mac[47:40];
            arp_data[9]  <= self_mac[39:32];
            arp_data[10] <= self_mac[31:24];
            arp_data[11] <= self_mac[23:16];
            arp_data[12] <= self_mac[15:8];
            arp_data[13] <= self_mac[7:0];
            arp_data[14] <= self_ip[31:24];
            arp_data[15] <= self_ip[23:16];
            arp_data[16] <= self_ip[15:8];
            arp_data[17] <= self_ip[7:0];
            arp_data[18] <= dest_mac[47:40];
            arp_data[19] <= dest_mac[39:32];
            arp_data[20] <= dest_mac[31:24];
            arp_data[21] <= dest_mac[23:16];
            arp_data[22] <= dest_mac[15:8];
            arp_data[23] <= dest_mac[7:0];
            arp_data[24] <= dest_ip[31:24];
            arp_data[25] <= dest_ip[23:16];
            arp_data[26] <= dest_ip[15:8];
            arp_data[27] <= dest_ip[7:0];
          end
          arp_data[7] <= (arp_tx_type == 1'b0) ? 8'h01 : 8'h02;
        end
        STATE_PREAMBLE: begin
          gmii_txen <= 1'b1;
          gmii_txd  <= preamble[cnt];
          if (cnt == 6'd7) begin
            skip_en <= 1'b1;
            cnt <= 6'd0;
          end else cnt <= cnt + 6'd1;
        end
        STATE_ETH_HEAD: begin
          gmii_txen <= 1'b1;
          crc_en <= 1'b1;
          gmii_txd <= eth_head[cnt];
          if (cnt == 6'd13) begin
            skip_en <= 1'b1;
            cnt <= 6'd0;
          end else cnt <= cnt + 6'd1;
        end
        STATE_ARP_DATA: begin
          crc_en <= 1'b1;
          gmii_txen <= 1'b1;
          if (cnt == MIN_DATA_NUM - 1'b1) begin
            skip_en <= 1'b1;
            cnt <= 6'd0;
            data_cnt <= 1'b0;
          end else cnt <= cnt + 6'd1;
          gmii_txd <= (data_cnt <= 6'd27) ? arp_data[data_cnt] : 8'd0;
          if (data_cnt <= 6'd27) data_cnt <= data_cnt + 1'b1;
        end
        STATE_CRC: begin
          gmii_txen <= 1'b1;
          cnt <= cnt + 6'd1;
          gmii_txd <= (cnt == 6'd0) ? ~crc_next :
                      (cnt == 6'd1) ? ~crc_data[23:16] :
                      (cnt == 6'd2) ? ~crc_data[15:8] : ~crc_data[7:0];
          if (cnt == 6'd3) begin
            tx_done_reg <= 1'b1;
            skip_en <= 1'b1;
            cnt <= 6'd0;
          end
        end
        default: ;
      endcase
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_done   <= 1'b0;
      crc_clear <= 1'b0;
    end else begin
      tx_done   <= tx_done_reg;
      crc_clear <= tx_done_reg;
    end
  end

endmodule

`endif  // ARP_TXD
