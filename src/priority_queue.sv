module priority_queue #(
  parameter  int unsigned Depth        = 8,
  parameter  int unsigned TimeWidth    = 24,
  parameter  int unsigned PayloadWidth = 3,
  parameter  bit          BtmArbTree   = 0,
  localparam int unsigned IdxWidth     = $clog2(Depth)
)(
  input  logic                    clk_i,
  input  logic                    rst_ni,
  output logic                    full_o,
  output logic                    empty_o,
  input  logic                    push_i,
  input  logic                    pop_i,
  input  logic                    drop_i,
  input  logic    [TimeWidth-1:0] push_dispatch_i,
  output logic     [IdxWidth-1:0] free_ptr_o,
  output logic     [IdxWidth-1:0] top_ptr_o,
  output logic     [IdxWidth-1:0] btm_ptr_o,
  input  logic     [IdxWidth-1:0] drop_ptr_i,
  input  logic [PayloadWidth-1:0] payload_i,
  output logic [PayloadWidth-1:0] payload_o,
  output logic    [TimeWidth-1:0] peek_data_o
);

typedef struct packed {
  logic    [TimeWidth-1:0] dispatch;
  logic [PayloadWidth-1:0] payload;
  logic     [IdxWidth-1:0] idx;
  logic                    valid;
} queue_entry_t;

queue_entry_t [Depth-1:0]                entry_d, entry_q;
logic         [Depth-1:0]                valid;
logic         [Depth-1:0][ IdxWidth-1:0] idx;
logic         [Depth-1:0][TimeWidth-1:0] dispatch;
logic                     [IdxWidth-1:0] top_idx;
logic                     [IdxWidth-1:0] top_ptr_d, top_ptr_q;
logic                     [IdxWidth-1:0] free_ptr_d, free_ptr_q;


assign full_o  =   &valid;
assign empty_o = ~(|valid);

assign top_ptr_d   = entry_q[top_idx].idx;
assign peek_data_o = entry_q[top_idx].dispatch;
assign free_ptr_o  = free_ptr_q;
assign top_ptr_o   = top_ptr_q;

always_comb begin : access_logic

  entry_d   = entry_q;
  payload_o = PayloadWidth'('0);

  if (push_i) begin
    entry_d[free_ptr_q].dispatch = push_dispatch_i;
    entry_d[free_ptr_q].payload  = payload_i;
    entry_d[free_ptr_q].valid    = 1'b1;
  end

  if (pop_i) begin
    entry_d[top_ptr_q].valid = 1'b0;
    payload_o                = entry_q[top_ptr_q].payload;
  end

  if (drop_i) begin
    entry_d[drop_ptr_i].valid = 1'b0;
  end

end

always_ff @(posedge clk_i or negedge rst_ni) begin : ptr_ff
  if (~rst_ni) begin
    top_ptr_q  <= IdxWidth'('0);
    free_ptr_q <= IdxWidth'('0);
  end else begin
    top_ptr_q  <= top_ptr_d;
    free_ptr_q <= free_ptr_d;
  end
end

always_comb begin : free_logic
  free_ptr_d = IdxWidth'('0);
  for (int i=Depth-1; i >= 0; i--) begin
    // Get first free entry index
    if (~entry_q[i].valid) free_ptr_d = entry_q[i].idx;
  end
end

for (genvar i=0; i<Depth; i++) begin : depth_loop
  always_ff @(posedge clk_i) begin : ff_no_rst
    entry_q[i].dispatch <= entry_d[i].dispatch;
    entry_q[i].payload  <= entry_d[i].payload;
    entry_q[i].valid    <= entry_d[i].valid;
  end

  // No reg for static idx
  assign entry_q[i].idx = i;

  // Extract from struct
  assign valid[i]    = entry_q[i].valid;
  assign dispatch[i] = entry_q[i].dispatch;
  assign idx[i]      = entry_q[i].idx;
end

binary_tree #(
  .TimeWidth    (TimeWidth),
  .PayloadWidth (PayloadWidth),
  .Depth        (Depth),
  .MaxTree      (1'b0)
) i_min_heap (
  .valid_i    (valid),
  .idx_i      (idx),
  .dispatch_i (dispatch),
  .top_idx_o  (top_idx)
);

if (BtmArbTree) begin

  binary_tree #(
    .TimeWidth    (TimeWidth),
    .PayloadWidth (PayloadWidth),
    .Depth        (Depth),
    .MaxTree      (1'b1)
  ) i_max_heap (
    .valid_i    (valid),
    .idx_i      (idx),
    .dispatch_i (dispatch),
    .top_idx_o  (btm_ptr_o)
  );

end else begin
  assign btm_ptr_o = IdxWidth'('0);
end

endmodule : priority_queue

