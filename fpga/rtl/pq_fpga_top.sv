module pq_fpga_top 
  import pq_pkg::*;
#(
  parameter  DEPTH = QUEUE_DEPTH,
  parameter  TW = TIME_WIDTH,
  localparam CNT_WIDTH   = $clog2(DEPTH),
  localparam ID_WIDTH    = CNT_WIDTH + 1
)(
  input  logic                  clk_i_p,
  input  logic                  clk_i_n,
  input  logic                  rst_ni,
  input  logic                  push_i,
  input  logic                  pop_i,
  input  logic                  drop_i,
  input  logic [  ID_WIDTH-1:0] drop_id_i,
  input  logic [  ID_WIDTH-1:0] push_id_i,
  output logic                  push_rdy_o,
  output logic                  pop_rdy_o,
  output logic                  drop_rdy_o,
  output logic                  full_o,
  output logic                  empty_o,
  output logic [ CNT_WIDTH-1:0] cnt_o,
  input  logic [        TW-1:0] data_i,
  output logic [        TW-1:0] data_o,
  output logic                  peek_vld_o,
  output logic [        TW-1:0] peek_data_o,
  output logic                  overflow_o,
  output logic [        TW-1:0] data_overflow_o
);

  logic int_reset_s;
  wire gen_clk_s;
  wire int_rst_n_s;

  // clock generation instance
  clk_wiz_0 i_clk_gen (
    .clk_out1  ( gen_clk_s    ),
    .resetn    ( rst_ni       ),
    .locked    ( int_reset_s  ), // locked used for sync reset
    .clk_in1_p ( clk_i_p      ),
    .clk_in1_n ( clk_i_n      )
  );

  // design instance
  pq #(
    .DEPTH (DEPTH),
    .TW    (TW   )
  ) i_pq (
    .clk_i           (gen_clk_s       ),
    .rst_ni          (int_rst_n_s     ),
    .push_i          (push_i          ),
    .pop_i           (pop_i           ),
    .drop_i          (drop_i          ),
    .drop_id_i       (drop_id_i       ),
    .push_id_i       (push_id_i       ),
    .push_rdy_o      (push_rdy_o      ),
    .pop_rdy_o       (pop_rdy_o       ),
    .drop_rdy_o      (drop_rdy_o      ),
    .full_o          (full_o          ),
    .empty_o         (empty_o         ),
    .cnt_o           (cnt_o           ),
    .data_i          (data_i          ),
    .data_o          (data_o          ),
    .peek_vld_o      (peek_vld_o      ),
    .peek_data_o     (peek_data_o     ),
    .overflow_o      (overflow_o      ),
    .data_overflow_o (data_overflow_o )
  );

  // invert synchronous reset signal
  assign int_rst_n_s = ~int_reset_s;


endmodule // pq_fpga_top
