`timescale 1 ns / 1 ps

module axi4_simple_master_rw_v1_0_M00_AXI #(
    parameter unsigned C_M_TARGET_SLAVE_BASE_ADDR = 32'h0
) (
    input  logic        i_clk,
    input  logic        i_rstn,
    input  logic        i_we,
    input  logic        i_re,
    input  logic [31:0] i_addr,
    input  logic [31:0] i_data,
    input  logic [ 1:0] i_mem_size,
    output logic [31:0] o_data,
    output logic        o_data_ready,
    output logic        o_write_ready,

    output logic        ERROR,
    output logic        M_AXI_ACLK,
    output logic        M_AXI_ARESETN,
    output logic [31:0] M_AXI_AWADDR,
    output logic [ 2:0] M_AXI_AWPROT,
    output logic        M_AXI_AWVALID,
    input  logic        M_AXI_AWREADY,
    output logic [31:0] M_AXI_WDATA,
    output logic [ 3:0] M_AXI_WSTRB,
    output logic        M_AXI_WVALID,
    input  logic        M_AXI_WREADY,
    input  logic [ 1:0] M_AXI_BRESP,
    input  logic        M_AXI_BVALID,
    output logic        M_AXI_BREADY,
    output logic [31:0] M_AXI_ARADDR,
    output logic [ 2:0] M_AXI_ARPROT,
    output logic        M_AXI_ARVALID,
    input  logic        M_AXI_ARREADY,
    input  logic [31:0] M_AXI_RDATA,
    input  logic [ 1:0] M_AXI_RRESP,
    input  logic        M_AXI_RVALID,
    output logic        M_AXI_RREADY
);

    // state change signal
    logic start_single_write = 1'b0;
    logic start_single_read = 1'b0;

    logic write_issued = 1'b0;
    logic read_issued = 1'b0;

    // Logic for ARVALID, AWVALID, WVALID, BREADY, and RREADY
    logic arvalid, awvalid, wvalid, bready, rready;
    logic [3:0] wstrb;
    logic write_resp_error;
    logic read_resp_error;

    // Registers to store input signals
    logic [31:0] original_addr, aligned_addr, data_reg, data_aligned;
    logic [1:0] mem_size_reg;
    logic error_reg;

    // control signals
    assign o_data_ready = M_AXI_RVALID;
    //assign o_write_ready = M_AXI_WREADY;
    assign o_write_ready = M_AXI_BVALID;

    // Align address to 4-byte boundary
    assign aligned_addr = {original_addr[31:2], 2'b00};

    // Assigning outputs
    assign M_AXI_AWADDR = C_M_TARGET_SLAVE_BASE_ADDR + aligned_addr;
    assign M_AXI_AWPROT = 3'b000;  // Normal, secure, data access
    assign M_AXI_AWVALID = awvalid;
    assign M_AXI_WDATA = data_aligned;
    assign M_AXI_WSTRB = wstrb;
    assign M_AXI_WVALID = wvalid;
    assign M_AXI_BREADY = bready;
    assign M_AXI_ARADDR = C_M_TARGET_SLAVE_BASE_ADDR + aligned_addr;
    assign M_AXI_ARPROT = 3'b000;  // Normal, secure, data access
    assign M_AXI_ARVALID = arvalid;
    assign M_AXI_RREADY = rready;

    assign M_AXI_ACLK = i_clk;
    assign M_AXI_ARESETN = i_rstn;

    // Determine WSTRB and align data based on address offset and memory size
    always_comb begin
        case (mem_size_reg)
            2'b00: begin // 32-bit
                wstrb = 4'b1111;
                data_aligned = data_reg;
            end
            2'b01: begin // 16-bit
                case (original_addr[1])
                    1'b0: begin
                        wstrb = 4'b0011;
                        data_aligned = {16'b0, data_reg[15:0]};
                    end
                    1'b1: begin
                        wstrb = 4'b1100;
                        data_aligned = {data_reg[15:0], 16'b0};
                    end
                endcase
            end
            2'b10: begin // 8-bit
                case (original_addr[1:0])
                    2'b00: begin
                        wstrb = 4'b0001;
                        data_aligned = {24'b0, data_reg[7:0]};
                    end
                    2'b01: begin
                        wstrb = 4'b0010;
                        data_aligned = {16'b0, data_reg[7:0], 8'b0};
                    end
                    2'b10: begin
                        wstrb = 4'b0100;
                        data_aligned = {8'b0, data_reg[7:0], 16'b0};
                    end
                    2'b11: begin
                        wstrb = 4'b1000;
                        data_aligned = {data_reg[7:0], 24'b0};
                    end
                endcase
            end
            default: begin
                wstrb = 4'b0000;
                data_aligned = 32'b0;
            end
        endcase
    end

    // addr write state machine
    always_ff @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            awvalid <= 1'b0;
        end
        if (start_single_write) begin
            awvalid <= 1'b1;
        end
        if (M_AXI_AWREADY && awvalid) begin
            awvalid <= 1'b0;
        end
    end

    // write data state machine
    always_ff @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            wvalid <= 1'b0;
        end
        if (start_single_write) begin
            wvalid <= 1'b1;
        end
        if (M_AXI_WREADY && wvalid) begin
            wvalid <= 1'b0;
        end
    end

    // write response channel
    always_ff @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            bready <= 1'b0;
        end else begin
            bready <= 1'b1;
        end
    end

    assign write_resp_error = (bready & M_AXI_BVALID & M_AXI_BRESP[1]);

    // addr read state machine
    always_ff @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            arvalid <= 1'b0;
        end
        if (start_single_read) begin
            arvalid <= 1'b1;
        end
        if (M_AXI_ARREADY && arvalid) begin
            arvalid <= 1'b0;
        end
    end

    // read data response channel
    always_ff @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN || rready) begin
            rready <= 1'b0;
        end else if (M_AXI_RVALID) begin
            rready <= 1'b1;
        end
    end

    assign read_resp_error = (rready & M_AXI_RVALID & M_AXI_RRESP[1]);


    // State transition
    always_ff @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            original_addr <= 32'b0; // Reset the original address
            data_reg <= 32'b0;
            mem_size_reg <= 2'b0;
        end else begin
            if (i_we || i_re) begin
                original_addr <= i_addr;  // Store the original unaligned address
                data_reg <= i_data;
                mem_size_reg <= i_mem_size;
            end
            if (i_we) begin
                start_single_write <= 1'b1;
                write_issued <= 1'b1;
            end else begin
                start_single_write <= 1'b0;
            end
            if (i_re) begin
                start_single_read <= 1'b1;
                read_issued <= 1'b1;
            end else begin
                start_single_read <= 1'b0;
            end
            if (M_AXI_BVALID) begin
                write_issued <= 1'b0;
            end
            if (M_AXI_RVALID) begin
                read_issued <= 1'b0;
            end
        end
    end

    always_comb begin
        case (mem_size_reg)
            2'b00: o_data = M_AXI_RDATA; // 32-bit
            2'b01: begin // 16-bit
                case (original_addr[1])
                    1'b0: o_data = {16'b0, M_AXI_RDATA[15:0]};
                    1'b1: o_data = {16'b0, M_AXI_RDATA[31:16]};
                endcase
            end
            2'b10: begin // 8-bit
                case (original_addr[1:0])
                    2'b00: o_data = {24'b0, M_AXI_RDATA[7:0]};
                    2'b01: o_data = {24'b0, M_AXI_RDATA[15:8]};
                    2'b10: o_data = {24'b0, M_AXI_RDATA[23:16]};
                    2'b11: o_data = {24'b0, M_AXI_RDATA[31:24]};
                endcase
            end
            default: o_data = 32'b0;
        endcase
    end

    always_ff @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0) begin
            error_reg <= 1'b0;
        end else if (write_resp_error || read_resp_error) begin
            error_reg <= 1'b1;
        end
    end

    assign ERROR = error_reg;

endmodule
