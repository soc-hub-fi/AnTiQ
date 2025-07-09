module priority_queue #(
  parameter int unsigned Depth        = 8,
  parameter int unsigned TimeWidth    = 24,
  parameter int unsigned PayloadWidth = 3
)(
  input  logic                    clk_i,
  input  logic                    rst_ni,
  output logic                    full_o,
  output logic                    empty_o,
  input  logic                    push_i,
  input  logic                    pop_i,
  input  logic                    drop_i,
  input  logic    [TimeWidth-1:0] push_id_i,
  input  logic    [TimeWidth-1:0] push_data_i,
  input  logic [PayloadWidth-1:0] payload_i,
  output logic [PayloadWidth-1:0] payload_o,
  output logic    [TimeWidth-1:0] peek_data_o
);

typedef struct packed {
  logic    [TimeWidth-1:0] data, id;
  logic [PayloadWidth-1:0] payload;
  logic                    valid;
} queue_entry_t;

queue_entry_t [Depth-1:0] entry_d, entry_q;
logic         [Depth-1:0] valid;

for (genvar i=0; i<Depth; i++) begin : status_unpack
  assign valid[i] = entry_q[i].valid;
end

assign full_o  =   &valid;
assign empty_o = ~(|valid);

always_ff @(posedge clk_i) begin : ff_no_rst
  entry_q <= entry_d;
end


endmodule : priority_queue

