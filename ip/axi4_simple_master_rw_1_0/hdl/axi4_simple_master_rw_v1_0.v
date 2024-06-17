`timescale 1 ns / 1 ps

module axi_master_rw_v1_0 #(
    // Parameters of Axi Master Bus Interface M00_AXI
    parameter unsigned C_M00_AXI_TARGET_SLAVE_BASE_ADDR = 32'h0,
    parameter integer C_M00_AXI_ADDR_WIDTH = 32,
    parameter integer C_M00_AXI_DATA_WIDTH = 32
) (
    // Users to add ports here
    input  wire        i_clk,
    input  wire        i_rstn,
    input  wire        i_we,
    input  wire        i_re,
    input  wire [31:0] i_addr,
    input  wire [31:0] i_data,
    input  wire [ 1:0] i_mem_size,   // 4/2/1
    output wire [31:0] o_data,
    output wire        o_data_ready,
    output wire        o_write_ready,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Master Bus Interface M00_AXI
    output wire m00_axi_error,
    output wire m00_axi_aclk,
    output wire m00_axi_aresetn,
    output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
    output wire [2 : 0] m00_axi_awprot,
    output wire m00_axi_awvalid,
    input wire m00_axi_awready,
    output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
    output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
    output wire m00_axi_wvalid,
    input wire m00_axi_wready,
    input wire [1 : 0] m00_axi_bresp,
    input wire m00_axi_bvalid,
    output wire m00_axi_bready,
    output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
    output wire [2 : 0] m00_axi_arprot,
    output wire m00_axi_arvalid,
    input wire m00_axi_arready,
    input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
    input wire [1 : 0] m00_axi_rresp,
    input wire m00_axi_rvalid,
    output wire m00_axi_rready
);
  // Instantiation of Axi Bus Interface M00_AXI
  axi4_simple_master_rw_v1_0_M00_AXI #(
      .C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR)
  ) axi4_simple_master_rw_v1_0_M00_AXI_inst (
      .i_clk(i_clk),
      .i_rstn(i_rstn),
      .i_we(i_we),
      .i_re(i_re),
      .i_addr(i_addr),
      .i_data(i_data),
      .i_mem_size(i_mem_size),
      .o_data(o_data),
      .o_data_ready(o_data_ready),
      .o_write_ready(o_write_ready),
      .ERROR(m00_axi_error),
      .M_AXI_ACLK(m00_axi_aclk),
      .M_AXI_ARESETN(m00_axi_aresetn),
      .M_AXI_AWADDR(m00_axi_awaddr),
      .M_AXI_AWPROT(m00_axi_awprot),
      .M_AXI_AWVALID(m00_axi_awvalid),
      .M_AXI_AWREADY(m00_axi_awready),
      .M_AXI_WDATA(m00_axi_wdata),
      .M_AXI_WSTRB(m00_axi_wstrb),
      .M_AXI_WVALID(m00_axi_wvalid),
      .M_AXI_WREADY(m00_axi_wready),
      .M_AXI_BRESP(m00_axi_bresp),
      .M_AXI_BVALID(m00_axi_bvalid),
      .M_AXI_BREADY(m00_axi_bready),
      .M_AXI_ARADDR(m00_axi_araddr),
      .M_AXI_ARPROT(m00_axi_arprot),
      .M_AXI_ARVALID(m00_axi_arvalid),
      .M_AXI_ARREADY(m00_axi_arready),
      .M_AXI_RDATA(m00_axi_rdata),
      .M_AXI_RRESP(m00_axi_rresp),
      .M_AXI_RVALID(m00_axi_rvalid),
      .M_AXI_RREADY(m00_axi_rready)
  );

endmodule
