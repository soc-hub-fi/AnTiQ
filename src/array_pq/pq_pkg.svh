/*
 * pq_pkg.sv - Package to store constants and types for hw_pq
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

package pq_pkg;

  localparam QUEUE_DEPTH = 8;
  localparam TIME_WIDTH  = 16;
  localparam CNT_WIDTH   = $clog2(QUEUE_DEPTH);
  localparam TEST_OPS    = 800;

  typedef struct packed {
    logic [TIME_WIDTH-1:0] data;
    logic [TIME_WIDTH-1:0] id;
  } cell_t;

endpackage