/*
 * pq_pkg.sv - Package to store constants and types for hw_pq
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

package pq_pkg;

  localparam QUEUE_DEPTH = 3;
  localparam DATA_WIDTH  = 16;
  localparam CNT_WIDTH   = $clog2(QUEUE_DEPTH);
  localparam ID_WIDTH    = CNT_WIDTH + 1;
  localparam TEST_OPS    = 25;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [  ID_WIDTH-1:0] id;
  } cell_t;

  typedef struct packed {
    int data;
    int id;
  } tb_cell_t;


endpackage