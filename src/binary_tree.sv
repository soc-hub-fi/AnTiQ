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

heap_t [(Depth-1)-1:0] result_nodes;

// TODO: Could be refactored & made neater
for (genvar i=0; i<IdxWidth; i++) begin : g_levels

  if (i==0) begin : g_top

    localparam int unsigned InputBase = Depth-4;

    heap_t [1:0] inputs;
    heap_t top;

    for (genvar j=0; j<2; j++) begin : g_input_assign
      assign inputs[j] = result_nodes[j+InputBase];
    end

    logic switch;
    logic k_gt;

    always_comb begin : select_logic

      switch = 1'b1;

      if (inputs[1].valid) begin
        switch = (MaxTree) ? k_gt : ~k_gt;
      end
    end

    assign k_gt = inputs[0].key > inputs[1].key;
    assign top = (switch) ? inputs[0] : inputs[1];
    assign top_idx_o = top.idx;

  end else if (i==IdxWidth-1) begin : g_bottom

    heap_t [Depth-1:0] inputs;

    for (genvar j=0; j<Depth; j++) begin : g_input_assign
      assign inputs[j].key   = dispatch_i[j];
      assign inputs[j].idx   = idx_i[j];
      assign inputs[j].valid = valid_i[j];
    end

    for (genvar k=0; k<Depth/2; k++) begin : g_result

      logic switch;
      logic k_gt;

      always_comb begin : select_logic

        switch = 1'b1;

        if (inputs[k+1].valid) begin
          switch = (MaxTree) ? k_gt : ~k_gt;
        end
      end

      assign k_gt = inputs[k].key > inputs[k+1].key;
      assign result_nodes[k] = (switch) ? inputs[k] : inputs[k+1];

    end

  end else begin : g_middle

    localparam int unsigned LocalBase = Depth-(2**(i+1));
    localparam int unsigned InputBase = Depth-(2**(i+2));
    localparam int unsigned LocalInWidth  = 2**(i+1);
    localparam int unsigned LocalOutWidth = 2**i;

    heap_t [LocalInWidth-1:0] inputs;

    for (genvar j=0; j<LocalInWidth; j++) begin : g_input_assign
      assign inputs[j] = result_nodes[j+InputBase];
    end

    for (genvar k=0; k<LocalOutWidth; k++) begin : g_results

      localparam int unsigned ResIdx = k+LocalBase;

      logic switch;
      logic k_gt;
      heap_t int_node;

      always_comb begin : select_logic

        switch = 1'b1;

        if (inputs[k+1].valid) begin
          switch = (MaxTree) ? k_gt : ~k_gt;
        end

      end

      assign k_gt = inputs[k].key > inputs[k+1].key;
      assign result_nodes[ResIdx] = (switch) ? inputs[k] : inputs[k+1];


    end
  end
end

endmodule : binary_tree

