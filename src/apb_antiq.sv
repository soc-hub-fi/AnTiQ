module apb_antiq #()(
  input  logic clk_i,
  input  logic rst_ni
);

pq #()i_pq_core (
  .clk_i,
  .rst_ni
);

endmodule : apb_antiq

