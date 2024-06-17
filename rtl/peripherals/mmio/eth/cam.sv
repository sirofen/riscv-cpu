`ifndef CAM
`define CAM

module cam #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 48,
    parameter int DEPTH = 16
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  search_en,
    input  logic [ADDR_WIDTH-1:0] search_key,
    output logic [DATA_WIDTH-1:0] search_data,
    output logic                  match,
    input  logic                  write_en,
    input  logic [ADDR_WIDTH-1:0] write_key,
    input  logic [DATA_WIDTH-1:0] write_data
);

  typedef struct packed {
    logic [ADDR_WIDTH-1:0] key;
    logic [DATA_WIDTH-1:0] data;
  } cam_entry_t;

  cam_entry_t cam_mem[DEPTH];
  logic [DEPTH-1:0] valid;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < DEPTH; i++) begin
        cam_mem[i].key <= '0;
        cam_mem[i].data <= '0;
        valid[i] <= 1'b0;
      end
      match <= 1'b0;
      search_data <= '0;
    end else begin
      if (write_en) begin
        for (int i = 0; i < DEPTH; i++) begin
          if (!valid[i]) begin
            cam_mem[i].key  = write_key;
            cam_mem[i].data = write_data;
            valid[i] <= 1'b1;
            break;
          end
        end
      end

      if (search_en) begin
        match <= 1'b0;
        search_data <= '0;
        for (int i = 0; i < DEPTH; i++) begin
          if (search_key == cam_mem[i].key && valid[i]) begin
            search_data <= cam_mem[i].data;
            match <= 1'b1;
            break;
          end
        end
      end else begin
        search_data <= 0;
        match <= 1'b0;
      end
    end
  end

endmodule

`endif  // CAM
