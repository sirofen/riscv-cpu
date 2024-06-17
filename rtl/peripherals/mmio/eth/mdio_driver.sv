`ifndef MDIO_DRIVER
`define MDIO_DRIVER

module mdio_driver (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        mdio_triger,
    input  logic        write_read,
    input  logic [ 4:0] reg_addr,
    input  logic [15:0] write_data,
    output logic        done,
    output logic [15:0] read_data,
    output logic        read_ack,
    output logic        divid_clk,
    output logic        phy_mdc,
    inout  logic        phy_mdio
);

  localparam PHY_ADDR = 5'b00001;
  localparam CLK_DIVIDE = 6'd10;

  typedef enum logic [5:0] {
    state_idle    = 6'b00_0001,
    state_pre     = 6'b00_0010,
    state_start   = 6'b00_0100,
    state_addr    = 6'b00_1000,
    state_wr_data = 6'b01_0000,
    state_rd_data = 6'b10_0000
  } state_t;

  state_t now_state, next_state;

  logic [ 5:0] clk_cnt;
  logic [15:0] wr_data_t;
  logic [ 4:0] addr_t;
  logic [ 6:0] cnt;
  logic        state_done;
  logic [ 1:0] op_code;
  logic        mdio_dir;
  logic        mdio_out;
  logic [15:0] rd_data_reg;

  logic [ 5:0] clk_divide;

  assign clk_divide = CLK_DIVIDE >> 1;
  assign phy_mdio   = mdio_dir ? mdio_out : 'z;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      divid_clk <= 1'b0;
      clk_cnt   <= 1'b0;
    end else if (clk_cnt == clk_divide[5:1] - 1) begin
      clk_cnt   <= 1'b0;
      divid_clk <= ~divid_clk;
    end else begin
      clk_cnt <= clk_cnt + 1;
    end
  end

  always_ff @(posedge divid_clk or negedge rst_n) begin
    if (!rst_n) begin
      phy_mdc <= 1'b1;
    end else if (cnt[0] == 1'b0) begin
      phy_mdc <= 1'b1;
    end else begin
      phy_mdc <= 1'b0;
    end
  end

  always_ff @(posedge divid_clk or negedge rst_n) begin
    if (!rst_n) begin
      now_state <= state_idle;
    end else begin
      now_state <= next_state;
    end
  end

  always_comb begin
    next_state = state_idle;
    case (now_state)
      state_idle: if (mdio_triger) next_state = state_pre;
      state_pre: if (state_done) next_state = state_start;
      state_start: if (state_done) next_state = state_addr;
      state_addr: if (state_done) next_state = (op_code == 2'b01) ? state_wr_data : state_rd_data;
      state_wr_data: if (state_done) next_state = state_idle;
      state_rd_data: if (state_done) next_state = state_idle;
      default: next_state = state_idle;
    endcase
  end

  always_ff @(posedge divid_clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= 5'd0;
      op_code <= 1'b0;
      addr_t <= 1'b0;
      wr_data_t <= 1'b0;
      rd_data_reg <= 1'b0;
      done <= 1'b0;
      state_done <= 1'b0;
      read_data <= 1'b0;
      read_ack <= 1'b1;
      mdio_dir <= 1'b0;
      mdio_out <= 1'b1;
    end else begin
      state_done <= 1'b0;
      cnt <= cnt + 1;
      case (now_state)
        state_idle: begin
          mdio_out <= 1'b1;
          mdio_dir <= 1'b0;
          done <= 1'b0;
          cnt <= 7'b0;
          if (mdio_triger) begin
            op_code <= {write_read, ~write_read};
            addr_t <= reg_addr;
            wr_data_t <= write_data;
            read_ack <= 1'b1;
          end
        end
        state_pre: begin
          mdio_dir <= 1'b1;
          mdio_out <= 1'b1;
          if (cnt == 7'd62) state_done <= 1'b1;
          else if (cnt == 7'd63) cnt <= 7'b0;
        end
        state_start: begin
          case (cnt)
            7'd1: mdio_out <= 1'b0;
            7'd3: mdio_out <= 1'b1;
            7'd5: mdio_out <= op_code[1];
            7'd6: state_done <= 1'b1;
            7'd7: begin
              mdio_out <= op_code[0];
              cnt <= 7'b0;
            end
            default: ;
          endcase
        end
        state_addr: begin
          case (cnt)
            7'd1: mdio_out <= PHY_ADDR[4];
            7'd3: mdio_out <= PHY_ADDR[3];
            7'd5: mdio_out <= PHY_ADDR[2];
            7'd7: mdio_out <= PHY_ADDR[1];
            7'd9: mdio_out <= PHY_ADDR[0];
            7'd11: mdio_out <= addr_t[4];
            7'd13: mdio_out <= addr_t[3];
            7'd15: mdio_out <= addr_t[2];
            7'd17: mdio_out <= addr_t[1];
            7'd18: state_done <= 1'b1;
            7'd19: begin
              mdio_out <= addr_t[0];
              cnt <= 7'd0;
            end
            default: ;
          endcase
        end
        state_wr_data: begin
          case (cnt)
            7'd1: mdio_out <= 1'b1;
            7'd3: mdio_out <= 1'b0;
            7'd5: mdio_out <= wr_data_t[15];
            7'd7: mdio_out <= wr_data_t[14];
            7'd9: mdio_out <= wr_data_t[13];
            7'd11: mdio_out <= wr_data_t[12];
            7'd13: mdio_out <= wr_data_t[11];
            7'd15: mdio_out <= wr_data_t[10];
            7'd17: mdio_out <= wr_data_t[9];
            7'd19: mdio_out <= wr_data_t[8];
            7'd21: mdio_out <= wr_data_t[7];
            7'd23: mdio_out <= wr_data_t[6];
            7'd25: mdio_out <= wr_data_t[5];
            7'd27: mdio_out <= wr_data_t[4];
            7'd29: mdio_out <= wr_data_t[3];
            7'd31: mdio_out <= wr_data_t[2];
            7'd33: mdio_out <= wr_data_t[1];
            7'd35: mdio_out <= wr_data_t[0];
            7'd37: begin
              mdio_dir <= 1'b0;
              mdio_out <= 1'b1;
            end
            7'd39: state_done <= 1'b1;
            7'd40: begin
              cnt  <= 7'b0;
              done <= 1'b1;
            end
            default: ;
          endcase
        end
        state_rd_data: begin
          case (cnt)
            7'd1: begin
              mdio_dir <= 1'b0;
              mdio_out <= 1'b1;
            end
            7'd2: ;
            7'd4: read_ack <= phy_mdio;
            7'd6: rd_data_reg[15] <= phy_mdio;
            7'd8: rd_data_reg[14] <= phy_mdio;
            7'd10: rd_data_reg[13] <= phy_mdio;
            7'd12: rd_data_reg[12] <= phy_mdio;
            7'd14: rd_data_reg[11] <= phy_mdio;
            7'd16: rd_data_reg[10] <= phy_mdio;
            7'd18: rd_data_reg[9] <= phy_mdio;
            7'd20: rd_data_reg[8] <= phy_mdio;
            7'd22: rd_data_reg[7] <= phy_mdio;
            7'd24: rd_data_reg[6] <= phy_mdio;
            7'd26: rd_data_reg[5] <= phy_mdio;
            7'd28: rd_data_reg[4] <= phy_mdio;
            7'd30: rd_data_reg[3] <= phy_mdio;
            7'd32: rd_data_reg[2] <= phy_mdio;
            7'd34: rd_data_reg[1] <= phy_mdio;
            7'd36: rd_data_reg[0] <= phy_mdio;
            7'd39: state_done <= 1'b1;
            7'd40: begin
              done <= 1'b1;
              read_data <= rd_data_reg;
              rd_data_reg <= 16'd0;
              cnt <= 7'd0;
            end
            default: ;
          endcase
        end
        default: ;
      endcase
    end
  end

endmodule

`endif  // MDIO_DRIVER
