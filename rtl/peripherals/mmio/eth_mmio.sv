/*
### Register Map

Control Registers
-----------------------------
Address        | Register
-----------------------------
0x1000_0000    | SELF_MAC_L
0x1000_0004    | SELF_MAC_H
0x1000_0008    | SELF_IP
0x1000_000C    | GATEWAY_IP
0x1000_0010    | SEND_DEST_IP
0x1000_0014    | SEND_SRC_PORT
0x1000_0016    | SEND_DEST_PORT
0x1000_0018    | SEND_LENGTH
0x1000_001A    | SEND_TRIGGER

Status Registers
-----------------------------
Address        | Register
-----------------------------
0x1000_0100    | RECV_COMPLETE
0x1000_0104    | RECV_BUF_FULL
0x1000_0108    | RECV_SRC_PORT
0x1000_010C    | RECV_DEST_PORT
0x1000_0110    | RECV_LENGTH
0x1000_0114    | LINK_SPEED

Buffer Addresses
-----------------------------
Address Range               | Buffer
-----------------------------
0x1000_1000 - 0x1000_13FF   | SEND_BUF
0x1000_2000 - 0x1000_23FF   | RECV_BUF
*/

`ifndef ETH_MMIO
`define ETH_MMIO

`include "peripherals/system_bus_if.sv"
`include "peripherals/mmio/eth/eth.sv"

module eth_mmio #(
    parameter integer BASE_ADDR = 32'h1000_0000,
    parameter integer BUF_SIZE  = 1024
) (
    input  logic                i_clk,
    input  logic                i_rstn,
    input  logic                i_we,
    input  logic                i_re,
    input  logic         [31:0] i_addr,
    input  logic         [31:0] i_data,
    input  logic         [ 1:0] i_mem_size,     // WORD(00)/HWORD(01)/BYTE(10)
    output logic         [31:0] o_data,
           system_bus_if        sys_bus
);

  localparam integer BUF_BYTE_SIZE = BUF_SIZE / 8;

  // Internal signals for eth module
  logic [BUF_SIZE-1:0] recv_buf;
  logic [BUF_SIZE-1:0] send_buf;

  logic recv_buf_full = 1'b0;

  logic [31:0] send_dest_ip;
  logic [15:0] send_src_port;
  logic [15:0] send_dest_port;
  logic [15:0] send_length;
  logic send_trigger;

  logic [15:0] recv_src_port;
  logic [15:0] recv_dest_port;
  logic [15:0] recv_length;
  logic recv_complete;

  logic recv_complete_latch;
  logic send_trigger_pulse;

  logic [47:0] self_mac;
  logic [31:0] self_ip;
  logic [31:0] gateway_ip;

  logic [1:0] link_speed;

  // MMIO address mapping
  localparam integer CONTROL_ADDR_BASE = BASE_ADDR;
  localparam integer STATUS_ADDR_BASE = BASE_ADDR + 32'h100;
  localparam integer SEND_BUF_ADDR_BASE = BASE_ADDR + 32'h1000;
  localparam integer RECV_BUF_ADDR_BASE = BASE_ADDR + 32'h2000;

  // Control registers
  localparam integer SELF_MAC_ADDR = CONTROL_ADDR_BASE;
  localparam integer SELF_IP_ADDR = CONTROL_ADDR_BASE + 8;
  localparam integer GATEWAY_IP_ADDR = CONTROL_ADDR_BASE + 12;
  localparam integer SEND_DEST_IP_ADDR = CONTROL_ADDR_BASE + 16;
  localparam integer SEND_SRC_PORT_ADDR = CONTROL_ADDR_BASE + 20;
  localparam integer SEND_DEST_PORT_ADDR = CONTROL_ADDR_BASE + 22;
  localparam integer SEND_LENGTH_ADDR = CONTROL_ADDR_BASE + 24;
  localparam integer SEND_TRIGGER_ADDR = CONTROL_ADDR_BASE + 26;

  // Status registers
  localparam integer RECV_COMPLETE_ADDR = STATUS_ADDR_BASE;
  localparam integer RECV_BUF_FULL_ADDR = STATUS_ADDR_BASE + 4;
  localparam integer RECV_SRC_PORT_ADDR = STATUS_ADDR_BASE + 8;
  localparam integer RECV_DEST_PORT_ADDR = STATUS_ADDR_BASE + 12;
  localparam integer RECV_LENGTH_ADDR = STATUS_ADDR_BASE + 16;
  localparam integer LINK_SPEED_ADDR = STATUS_ADDR_BASE + 20;

  // Reading from MMIO
  always_comb begin
    case (i_addr)
      SELF_MAC_ADDR:       o_data = {16'b0, self_mac[31:0]};
      SELF_MAC_ADDR + 4:   o_data = {16'b0, self_mac[47:32]};
      SELF_IP_ADDR:        o_data = self_ip;
      GATEWAY_IP_ADDR:     o_data = gateway_ip;
      SEND_DEST_IP_ADDR:   o_data = send_dest_ip;
      SEND_SRC_PORT_ADDR:  o_data = {16'b0, send_src_port};
      SEND_DEST_PORT_ADDR: o_data = {16'b0, send_dest_port};
      SEND_LENGTH_ADDR:    o_data = {16'b0, send_length};
      SEND_TRIGGER_ADDR:   o_data = {31'b0, send_trigger};
      RECV_COMPLETE_ADDR:  o_data = {31'b0, recv_complete_latch};
      RECV_BUF_FULL_ADDR:  o_data = {31'b0, recv_buf_full};
      RECV_SRC_PORT_ADDR:  o_data = {16'b0, recv_src_port};
      RECV_DEST_PORT_ADDR: o_data = {16'b0, recv_dest_port};
      RECV_LENGTH_ADDR:    o_data = {16'b0, recv_length};
      LINK_SPEED_ADDR:     o_data = {30'b0, link_speed};
      default: begin
        if (i_addr >= RECV_BUF_ADDR_BASE && i_addr < RECV_BUF_ADDR_BASE + BUF_BYTE_SIZE) begin
          case (i_mem_size)
            2'b00:
            o_data = {
              recv_buf[(i_addr-RECV_BUF_ADDR_BASE)*8+31-:8],
              recv_buf[(i_addr-RECV_BUF_ADDR_BASE)*8+23-:8],
              recv_buf[(i_addr-RECV_BUF_ADDR_BASE)*8+15-:8],
              recv_buf[(i_addr-RECV_BUF_ADDR_BASE)*8+7-:8]
            };
            2'b01:
            o_data = {
              16'b0,
              recv_buf[(i_addr-RECV_BUF_ADDR_BASE)*8+15-:8],
              recv_buf[(i_addr-RECV_BUF_ADDR_BASE)*8+7-:8]
            };
            2'b10: o_data = {24'b0, recv_buf[(i_addr-RECV_BUF_ADDR_BASE)*8+7-:8]};
            default: o_data = 32'h0;
          endcase
        end else begin
          o_data = 32'h0;
        end
      end
    endcase
  end

  // Writing to MMIO
  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      self_mac            <= 48'b0;
      self_ip             <= 32'b0;
      gateway_ip          <= 32'b0;
      send_dest_ip        <= 32'b0;
      send_src_port       <= 16'b0;
      send_dest_port      <= 16'b0;
      send_length         <= 16'b0;
      send_trigger        <= 1'b0;
      recv_complete_latch <= 1'b0;
    end else if (send_trigger) begin
        send_trigger <= 1'b0;
    end else if (i_we) begin
      case (i_addr)
        SELF_MAC_ADDR: begin
          if (i_mem_size == 2'b10) begin
            self_mac[7:0] <= i_data[7:0];
          end else if (i_mem_size == 2'b01) begin
            self_mac[15:0] <= i_data[15:0];
          end else begin
            self_mac[31:0] <= i_data[31:0];
          end
        end
        SELF_MAC_ADDR + 4: begin
          if (i_mem_size == 2'b10) begin
            self_mac[39:32] <= i_data[7:0];
          end else if (i_mem_size == 2'b01) begin
            self_mac[47:32] <= i_data[15:0];
          end else begin
            self_mac[47:32] <= i_data[31:0];
          end
        end
        SELF_IP_ADDR: begin
          if (i_mem_size == 2'b10) begin
            self_ip[7:0] <= i_data[7:0];
          end else if (i_mem_size == 2'b01) begin
            self_ip[15:0] <= i_data[15:0];
          end else begin
            self_ip[31:0] <= i_data[31:0];
          end
        end
        GATEWAY_IP_ADDR: begin
          if (i_mem_size == 2'b10) begin
            gateway_ip[7:0] <= i_data[7:0];
          end else if (i_mem_size == 2'b01) begin
            gateway_ip[15:0] <= i_data[15:0];
          end else begin
            gateway_ip[31:0] <= i_data[31:0];
          end
        end
        SEND_DEST_IP_ADDR: begin
          if (i_mem_size == 2'b10) begin
            send_dest_ip[7:0] <= i_data[7:0];
          end else if (i_mem_size == 2'b01) begin
            send_dest_ip[15:0] <= i_data[15:0];
          end else begin
            send_dest_ip[31:0] <= i_data[31:0];
          end
        end
        SEND_SRC_PORT_ADDR: begin
          if (i_mem_size == 2'b10) begin
            send_src_port[7:0] <= i_data[7:0];
          end else if (i_mem_size == 2'b01) begin
            send_src_port[15:0] <= i_data[15:0];
          end else begin
            send_src_port <= i_data[15:0];
          end
        end
        SEND_DEST_PORT_ADDR: begin
          if (i_mem_size == 2'b10) begin
            send_dest_port[7:0] <= i_data[7:0];
          end else if (i_mem_size == 2'b01) begin
            send_dest_port[15:0] <= i_data[15:0];
          end else begin
            send_dest_port <= i_data[15:0];
          end
        end
        SEND_LENGTH_ADDR: begin
          if (i_mem_size == 2'b10) begin
            send_length[7:0] <= i_data[7:0];
          end else if (i_mem_size == 2'b01) begin
            send_length[15:0] <= i_data[15:0];
          end else begin
            send_length <= i_data[15:0];
          end
        end
        SEND_TRIGGER_ADDR: begin
          send_trigger <= i_data[0];
        end
        RECV_COMPLETE_ADDR: begin
          recv_complete_latch <= i_data[0];
        end
        default: begin
          if (i_addr >= SEND_BUF_ADDR_BASE && i_addr < SEND_BUF_ADDR_BASE + BUF_BYTE_SIZE) begin
            case (i_mem_size)
              2'b00: begin
                send_buf[(i_addr-SEND_BUF_ADDR_BASE)*8+7-:8]  <= i_data[7:0];
                send_buf[(i_addr-SEND_BUF_ADDR_BASE)*8+15-:8] <= i_data[15:8];
                send_buf[(i_addr-SEND_BUF_ADDR_BASE)*8+23-:8] <= i_data[23:16];
                send_buf[(i_addr-SEND_BUF_ADDR_BASE)*8+31-:8] <= i_data[31:24];
              end
              2'b01: begin
                send_buf[(i_addr-SEND_BUF_ADDR_BASE)*8+7-:8]  <= i_data[7:0];
                send_buf[(i_addr-SEND_BUF_ADDR_BASE)*8+15-:8] <= i_data[15:8];
              end
              2'b10: begin
                send_buf[(i_addr-SEND_BUF_ADDR_BASE)*8+7-:8] <= i_data[7:0];
              end
            endcase
          end
        end
      endcase
    end else if (recv_complete) begin
      recv_complete_latch <= 1'b1;
      recv_buf_full <= 1'b1;
    end else if (!recv_complete_latch) begin
      recv_buf_full <= 1'b0;
    end
  end

  logic [31:0] gateway;
  assign gateway = gateway_ip != 32'h0 ? gateway_ip : send_dest_ip;

  // Instantiate the eth module
  eth #(
      .BUF_SIZE(BUF_SIZE)
  ) eth_inst (
      .clk(i_clk),
      .rst_n(i_rstn),
      .phy_rxc(sys_bus.eth_phy_rxc),
      .phy_rx_ctrl(sys_bus.eth_phy_rx_ctrl),
      .phy_rxd(sys_bus.eth_phy_rxd),
      .phy_txc(sys_bus.eth_phy_txc),
      .phy_tx_ctrl(sys_bus.eth_phy_tx_ctrl),
      .phy_txd(sys_bus.eth_phy_txd),
      .phy_rstn(sys_bus.eth_phy_rstn),
      .mdc(sys_bus.eth_mdc),
      .mdio(sys_bus.eth_mdio),
      .linkspeed(link_speed),
      .self_mac(self_mac),
      .self_ip(self_ip),
      .gateway_ip(gateway),
      .recv_buf(recv_buf),
      .send_buf(send_buf),
      .send_dest_ip(send_dest_ip),
      .send_src_port(send_src_port),
      .send_dest_port(send_dest_port),
      .send_length(send_length),
      .send_trigger(send_trigger),
      .recv_src_port(recv_src_port),
      .recv_dest_port(recv_dest_port),
      .recv_length(recv_length),
      .recv_complete(recv_complete),
      .recv_buf_full(recv_buf_full)
  );

endmodule
`endif
