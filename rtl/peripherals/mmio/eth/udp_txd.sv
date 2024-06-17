`ifndef UDP_TXD
`define UDP_TXD 

module udp_txd (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        tx_start_en,
    input  logic [31:0] tx_data,
    input  logic [15:0] tx_byte_num,
    input  logic [47:0] dest_mac,
    input  logic [31:0] dest_ip,
    input  logic [31:0] crc_data,
    input  logic [ 7:0] crc_next,
    output logic        tx_done,
    output logic        tx_request,
    output logic        gmii_txen,
    output logic [ 7:0] gmii_txd,
    output logic        crc_en,
    output logic        crc_clear,
    input  logic [47:0] self_mac,
    input  logic [31:0] self_ip,
    input  logic [15:0] src_port,
    input  logic [15:0] dest_port
);

  localparam ETH_TYPE = 16'h0800;
  localparam MIN_DATA_NUM = 16'd18;

  typedef enum logic [6:0] {
    STATE_IDLE,
    STATE_CHECK_SUM,
    STATE_PREAMBLE,
    STATE_ETH_HEAD,
    STATE_IP_HEAD,
    STATE_TX_DATA,
    STATE_CRC
  } state_t;

  state_t cur_state, next_state;
  logic [ 7:0] preamble[ 7:0];
  logic [ 7:0] eth_head[13:0];
  logic [31:0] ip_head [ 6:0];

  logic start_en_d0, start_en_d1;
  logic [15:0] tx_data_num;
  logic [15:0] total_num;
  logic trig_tx_en;
  logic [15:0] udp_num;
  logic skip_en;
  logic [4:0] cnt;
  logic [31:0] check_buffer;
  logic [1:0] tx_bit_sel;
  logic [15:0] data_cnt;
  logic tx_done_reg;
  logic [4:0] real_add_cnt;

  logic pos_start_en;
  logic [15:0] real_tx_data_num;

  assign pos_start_en = (~start_en_d1) & start_en_d0;
  assign real_tx_data_num = (tx_data_num >= MIN_DATA_NUM) ? tx_data_num : MIN_DATA_NUM;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      start_en_d0 <= 1'b0;
      start_en_d1 <= 1'b0;
    end else begin
      start_en_d0 <= tx_start_en;
      start_en_d1 <= start_en_d0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_num <= 16'd0;
      total_num <= 16'd0;
      udp_num <= 16'd0;
    end else begin
      if (pos_start_en && cur_state == STATE_IDLE) begin
        tx_data_num <= tx_byte_num;
        total_num <= tx_byte_num + 16'd28;
        udp_num <= tx_byte_num + 16'd8;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) trig_tx_en <= 1'b0;
    else trig_tx_en <= pos_start_en;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) cur_state <= STATE_IDLE;
    else cur_state <= next_state;
  end

  always_comb begin
    next_state = STATE_IDLE;
    case (cur_state)
      STATE_IDLE: if (skip_en) next_state = STATE_CHECK_SUM;
      STATE_CHECK_SUM: if (skip_en) next_state = STATE_PREAMBLE;
      STATE_PREAMBLE: if (skip_en) next_state = STATE_ETH_HEAD;
      STATE_ETH_HEAD: if (skip_en) next_state = STATE_IP_HEAD;
      STATE_IP_HEAD: if (skip_en) next_state = STATE_TX_DATA;
      STATE_TX_DATA: if (skip_en) next_state = STATE_CRC;
      STATE_CRC: if (skip_en) next_state = STATE_IDLE;
      default: next_state = STATE_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      skip_en <= 1'b0;
      cnt <= 5'd0;
      check_buffer <= 32'd0;
      ip_head[1][31:16] <= 16'd0;
      tx_bit_sel <= 2'b0;
      crc_en <= 1'b0;
      gmii_txen <= 1'b0;
      gmii_txd <= 8'd0;
      tx_request <= 1'b0;
      tx_done_reg <= 1'b0;
      data_cnt <= 16'd0;
      real_add_cnt <= 5'd0;
      preamble[0] <= 8'h55;
      preamble[1] <= 8'h55;
      preamble[2] <= 8'h55;
      preamble[3] <= 8'h55;
      preamble[4] <= 8'h55;
      preamble[5] <= 8'h55;
      preamble[6] <= 8'h55;
      preamble[7] <= 8'hd5;
      eth_head[0] <= self_mac[47:40];
      eth_head[1] <= self_mac[39:32];
      eth_head[2] <= self_mac[31:24];
      eth_head[3] <= self_mac[23:16];
      eth_head[4] <= self_mac[15:8];
      eth_head[5] <= self_mac[7:0];
      eth_head[6] <= self_mac[47:40];
      eth_head[7] <= self_mac[39:32];
      eth_head[8] <= self_mac[31:24];
      eth_head[9] <= self_mac[23:16];
      eth_head[10] <= self_mac[15:8];
      eth_head[11] <= self_mac[7:0];
      eth_head[12] <= ETH_TYPE[15:8];
      eth_head[13] <= ETH_TYPE[7:0];
    end else begin
      skip_en <= 1'b0;
      tx_request <= 1'b0;
      crc_en <= 1'b0;
      gmii_txen <= 1'b0;
      tx_done_reg <= 1'b0;
      case (next_state)
        STATE_IDLE: begin
          if (trig_tx_en) begin
            skip_en <= 1'b1;
            ip_head[0] <= {8'h45, 8'h00, total_num};
            ip_head[1][31:16] <= ip_head[1][31:16] + 1'b1;
            ip_head[1][15:0] <= 16'h4000;
            ip_head[2] <= {8'h40, 8'd17, 16'h0};
            ip_head[3] <= self_ip;
            ip_head[4] <= dest_ip;
            ip_head[5] <= {src_port, dest_port};
            ip_head[6] <= {udp_num, 16'h0000};
            if (dest_mac != 48'b0) begin
              eth_head[0] <= dest_mac[47:40];
              eth_head[1] <= dest_mac[39:32];
              eth_head[2] <= dest_mac[31:24];
              eth_head[3] <= dest_mac[23:16];
              eth_head[4] <= dest_mac[15:8];
              eth_head[5] <= dest_mac[7:0];
            end
          end
        end
        STATE_CHECK_SUM: begin
          cnt <= cnt + 5'd1;
          if (cnt == 5'd0) begin
            check_buffer <= ip_head[0][31:16] + ip_head[0][15:0]
                                    + ip_head[1][31:16] + ip_head[1][15:0]
                                    + ip_head[2][31:16] + ip_head[2][15:0]
                                    + ip_head[3][31:16] + ip_head[3][15:0]
                                    + ip_head[4][31:16] + ip_head[4][15:0];
          end else if (cnt == 5'd1) begin
            check_buffer <= check_buffer[31:16] + check_buffer[15:0];
          end else if (cnt == 5'd2) begin
            check_buffer <= check_buffer[31:16] + check_buffer[15:0];
          end else if (cnt == 5'd3) begin
            skip_en <= 1'b1;
            cnt <= 5'd0;
            ip_head[2][15:0] <= ~check_buffer[15:0];
          end
        end
        STATE_PREAMBLE: begin
          gmii_txen <= 1'b1;
          gmii_txd  <= preamble[cnt];
          if (cnt == 5'd7) begin
            skip_en <= 1'b1;
            cnt <= 5'd0;
          end else begin
            cnt <= cnt + 5'd1;
          end
        end
        STATE_ETH_HEAD: begin
          gmii_txen <= 1'b1;
          crc_en <= 1'b1;
          gmii_txd <= eth_head[cnt];
          if (cnt == 5'd13) begin
            skip_en <= 1'b1;
            cnt <= 5'd0;
          end else begin
            cnt <= cnt + 5'd1;
          end
        end
        STATE_IP_HEAD: begin
          crc_en <= 1'b1;
          gmii_txen <= 1'b1;
          tx_bit_sel <= tx_bit_sel + 2'd1;
          if (tx_bit_sel == 3'd0) gmii_txd <= ip_head[cnt][31:24];
          else if (tx_bit_sel == 3'd1) gmii_txd <= ip_head[cnt][23:16];
          else if (tx_bit_sel == 3'd2) begin
            gmii_txd <= ip_head[cnt][15:8];
            if (cnt == 5'd6) tx_request <= 1'b1;
          end else if (tx_bit_sel == 3'd3) begin
            gmii_txd <= ip_head[cnt][7:0];
            if (cnt == 5'd6) begin
              skip_en <= 1'b1;
              cnt <= 5'd0;
            end else begin
              cnt <= cnt + 5'd1;
            end
          end
        end
        STATE_TX_DATA: begin
          crc_en <= 1'b1;
          gmii_txen <= 1'b1;
          tx_bit_sel <= tx_bit_sel + 3'd1;
          if (data_cnt < tx_data_num - 16'd1) data_cnt <= data_cnt + 16'd1;
          else if (data_cnt == tx_data_num - 16'd1) begin
            gmii_txd <= 8'd0;
            if (data_cnt + real_add_cnt < real_tx_data_num - 16'd1)
              real_add_cnt <= real_add_cnt + 5'd1;
            else begin
              skip_en <= 1'b1;
              data_cnt <= 16'd0;
              real_add_cnt <= 5'd0;
              tx_bit_sel <= 3'd0;
            end
          end
          if (tx_bit_sel == 1'b0) gmii_txd <= tx_data[31:24];
          else if (tx_bit_sel == 3'd1) gmii_txd <= tx_data[23:16];
          else if (tx_bit_sel == 3'd2) begin
            gmii_txd <= tx_data[15:8];
            if (data_cnt != tx_data_num - 16'd1) tx_request <= 1'b1;
          end else if (tx_bit_sel == 3'd3) begin
            gmii_txd <= tx_data[7:0];
          end
        end
        STATE_CRC: begin
          gmii_txen  <= 1'b1;
          tx_bit_sel <= tx_bit_sel + 3'd1;
          if (tx_bit_sel == 3'd0)
            gmii_txd <= {
              ~crc_next[0],
              ~crc_next[1],
              ~crc_next[2],
              ~crc_next[3],
              ~crc_next[4],
              ~crc_next[5],
              ~crc_next[6],
              ~crc_next[7]
            };
          else if (tx_bit_sel == 3'd1)
            gmii_txd <= {
              ~crc_data[16],
              ~crc_data[17],
              ~crc_data[18],
              ~crc_data[19],
              ~crc_data[20],
              ~crc_data[21],
              ~crc_data[22],
              ~crc_data[23]
            };
          else if (tx_bit_sel == 3'd2) begin
            gmii_txd <= {
              ~crc_data[8],
              ~crc_data[9],
              ~crc_data[10],
              ~crc_data[11],
              ~crc_data[12],
              ~crc_data[13],
              ~crc_data[14],
              ~crc_data[15]
            };
          end else if (tx_bit_sel == 3'd3) begin
            gmii_txd <= {
              ~crc_data[0],
              ~crc_data[1],
              ~crc_data[2],
              ~crc_data[3],
              ~crc_data[4],
              ~crc_data[5],
              ~crc_data[6],
              ~crc_data[7]
            };
            tx_done_reg <= 1'b1;
            skip_en <= 1'b1;
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

`endif  // UDP_TXD
