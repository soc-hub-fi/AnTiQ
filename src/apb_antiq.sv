module apb_antiq #()(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic [63:0] mtime_i,
  APB.Slave           apb_sbr
);

pq #()i_pq_core (
  .clk_i,
  .rst_ni
);

endmodule : apb_antiq

