/*
 * pq_pkg.sv - Package to store constants and types for hw_pq
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

package pq_pkg;

  localparam QUEUE_DEPTH = 8;
  localparam DATA_WIDTH  = 8;
  localparam CNT_WIDTH   = $clog2(QUEUE_DEPTH);
  localparam ID_WIDTH    = CNT_WIDTH + 1;
  localparam TEST_OPS    = 35;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [  ID_WIDTH-1:0] id;
  } cell_t;

endpackage