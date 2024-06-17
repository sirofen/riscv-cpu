`ifndef MDIO_READ_WRITE
`define MDIO_READ_WRITE

module mdio_read_write (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        rst_trig,     // Soft reset trigger signal
    input  logic        done,         // Read and write completed
    input  logic [15:0] read_data,    // Read data
    input  logic        read_ack,     // Read response signal 0: response 1: no response
    output logic        mdio_triger,  // Trigger start signal
    output logic        write_read,   // Low level write, high level read
    output logic [ 4:0] reg_addr,     // Register address
    output logic [15:0] write_data,   // Data written to register
    output logic [ 1:0] linkspeed     // LED lights indicate Ethernet connection status
);

  localparam SOFT_RESET_CMD = 16'hB100;
  localparam REG_BMCR = 5'h00;
  localparam REG_BMSR = 5'h01;
  localparam REG_PHYSR = 5'h11;

  logic        rst_trig_d0;
  logic        rst_trig_d1;
  logic        rst_trig_flag;
  logic [23:0] timer_cnt;
  logic        timer_done;
  logic        start_next;
  logic        read_next;
  logic        link_error;
  logic [ 2:0] flow_cnt;
  logic [ 1:0] speed_status;

  logic        pos_rst_trig;

  assign pos_rst_trig = ~rst_trig_d1 & rst_trig_d0;
  assign linkspeed = link_error ? 2'b00 : speed_status;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rst_trig_d0 <= 1'b0;
      rst_trig_d1 <= 1'b0;
    end else begin
      rst_trig_d0 <= rst_trig;
      rst_trig_d1 <= rst_trig_d0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      timer_cnt  <= 1'b0;
      timer_done <= 1'b0;
    end else begin
      if (timer_cnt == 24'd1_000_000 - 1'b1) begin
        timer_done <= 1'b1;
        timer_cnt  <= 1'b0;
      end else begin
        timer_done <= 1'b0;
        timer_cnt  <= timer_cnt + 1'b1;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      flow_cnt <= 3'd0;
      rst_trig_flag <= 1'b0;
      speed_status <= 2'b00;
      mdio_triger <= 1'b0;
      write_read <= 1'b0;
      reg_addr <= 1'b0;
      write_data <= 1'b0;
      start_next <= 1'b0;
      read_next <= 1'b0;
      link_error <= 1'b0;
    end else begin
      mdio_triger <= 1'b0;
      if (pos_rst_trig) rst_trig_flag <= 1'b1;

      case (flow_cnt)
        2'd0: begin
          if (rst_trig_flag) begin
            mdio_triger <= 1'b1;
            write_read <= 1'b0;
            reg_addr <= REG_BMCR;
            write_data <= SOFT_RESET_CMD;
            flow_cnt <= 3'd1;
          end else if (timer_done) begin
            mdio_triger <= 1'b1;
            write_read <= 1'b1;
            reg_addr <= REG_BMSR;
            flow_cnt <= 3'd2;
          end else if (start_next) begin
            mdio_triger <= 1'b1;
            write_read <= 1'b1;
            reg_addr <= REG_PHYSR;
            flow_cnt <= 3'd2;
            start_next <= 1'b0;
            read_next <= 1'b1;
          end
        end
        2'd1: begin
          if (done) begin
            flow_cnt <= 3'd0;
            rst_trig_flag <= 1'b0;
          end
        end
        2'd2: begin
          if (done) begin
            if (read_ack == 1'b0 && read_next == 1'b0) flow_cnt <= 3'd3;
            else if (read_ack == 1'b0 && read_next == 1'b1) begin
              read_next <= 1'b0;
              flow_cnt  <= 3'd4;
            end else begin
              flow_cnt <= 3'd0;
            end
          end
        end
        2'd3: begin
          flow_cnt <= 3'd0;
          if (read_data[5] == 1'b1 && read_data[2] == 1'b1) begin
            start_next <= 1;
            link_error <= 0;
          end else begin
            link_error <= 1'b1;
          end
        end
        3'd4: begin
          flow_cnt <= 3'd0;
          if (read_data[15:14] == 2'b10) speed_status <= 2'b11;
          else if (read_data[15:14] == 2'b01) speed_status <= 2'b10;
          else if (read_data[15:14] == 2'b00) speed_status <= 2'b01;
          else speed_status <= 2'b00;
        end
      endcase
    end
  end

endmodule

`endif  // MDIO_READ_WRITE
