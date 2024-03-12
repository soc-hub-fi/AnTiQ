/*
 * pq_pkg.sv - Package to store constants and types for hw_pq. Modified to allow
 *             easy setting of parameters for synthesis.
 * 
 * author(s): Antti Nurmi    : antti.nurmi@tuni.fi
 *            Tom Szymkowiak : thomas.szymkowiak@tuni.fi
 */

package pq_pkg;

  localparam QUEUE_DEPTH = `Q_DEPTH;
  localparam TIME_WIDTH  = `D_WIDTH;
  localparam CNT_WIDTH   = $clog2(QUEUE_DEPTH);
  localparam ID_WIDTH    = CNT_WIDTH + 1;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [  ID_WIDTH-1:0] id;
  } cell_t;

endpackage