module binary_tree #(
  parameter  int unsigned Depth        = 8,
  parameter  int unsigned TimeWidth    = 24,
  parameter  int unsigned PayloadWidth = 3,
  parameter  bit          MaxTree      = 0,
  localparam int unsigned IdxWidth     = $clog2(Depth)
)(
  input  logic [Depth-1:0]                valid_i,
  input  logic [Depth-1:0][ IdxWidth-1:0] idx_i,
  input  logic [Depth-1:0][TimeWidth-1:0] dispatch_i,
  output logic             [IdxWidth-1:0] top_idx_o
);

// # of internal nets
localparam int unsigned NrResultNets  = Depth-2;
localparam int unsigned NrComparators = Depth-1;

typedef struct packed {
  logic [TimeWidth-1:0] key;
  logic  [IdxWidth-1:0] idx;
  logic                 valid;
} heap_t;

heap_t [NrResultNets-1:0] res;

for (genvar i=0; i<IdxWidth; i++) begin

  if (i==0) begin : top
    if (MaxTree) begin
      assign top_idx_o = ((res[0].valid & (res[0].key > res[1].key))| ~res[1].valid)
        ? res[0].idx : res[1].idx;
    end else begin
      assign top_idx_o = ((res[0].valid & (res[0].key < res[1].key))| ~res[1].valid)
        ? res[0].idx : res[1].idx;
    end
  end else if (i==IdxWidth-1) begin : bottom
    for (genvar j=0; j<(2**i); j++) begin // i==2

      localparam int unsigned IdxRes = i+j;
      localparam int unsigned IdxA   = 2*j;
      localparam int unsigned IdxB   = (2*j)+1;

      if (MaxTree) begin
        always_comb begin
          res[IdxRes].key   = dispatch_i[IdxA];
          res[IdxRes].idx   = idx_i[IdxA];
          res[IdxRes].valid = valid_i[IdxA];
          if ((dispatch_i[IdxA] < dispatch_i[IdxB])
            & valid_i[IdxB]) begin
            res[IdxRes].key   = dispatch_i[IdxB];
            res[IdxRes].idx   = idx_i[IdxB];
            res[IdxRes].valid = valid_i[IdxB];
          end
        end
      end else begin
        always_comb begin
          res[IdxRes].key   = dispatch_i[IdxA];
          res[IdxRes].idx   = idx_i[IdxA];
          res[IdxRes].valid = valid_i[IdxA];
          if ((dispatch_i[IdxA] > dispatch_i[IdxB])
            & valid_i[IdxB]) begin
            res[IdxRes].key   = dispatch_i[IdxB];
            res[IdxRes].idx   = idx_i[IdxB];
            res[IdxRes].valid = valid_i[IdxB];
          end
        end
      end

    end
  end else begin : middle
    for (genvar j=0; j<(2**i); j++) begin // i==1
      
      localparam int unsigned IdxRes = (i-1)+j;
      localparam int unsigned IdxA   = 2*(i+j);
      localparam int unsigned IdxB   = 2*(i+j)+1;
      
      if (MaxTree) begin
        assign res[IdxRes] = ((res[IdxA].key < res[IdxB].key) & res[IdxB].valid)
          ? res[IdxB] : res[IdxA];
      end else begin
        assign res[IdxRes] = ((res[IdxA].key > res[IdxB].key) & res[IdxB].valid)
          ? res[IdxB] : res[IdxA];
      end
    end
  end

end

endmodule : binary_tree

