/*
 * pq_pkg.sv - Package to store constants and types for AnTiQ
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

package pq_pkg;

  localparam QUEUE_DEPTH                = 16;
  localparam TIME_WIDTH                 = 24;
  localparam PAYLOAD_WIDTH              = 8;
  localparam CNT_WIDTH                  = $clog2(QUEUE_DEPTH);
  localparam TEST_OPS                   = 1000000;
  localparam longint unsigned MAX_TIME  = 2**(TIME_WIDTH);
  localparam DELTA_MAX                  = 20;
  localparam VERBOSE                    = 0;

  typedef enum int { 
    PUSH, 
    POP, 
    NOP, 
    DROP,
    DROP_RAND 
  } op_t;

  typedef struct packed {
    logic [   TIME_WIDTH-1:0] data;
    logic [   TIME_WIDTH-1:0] id;
    logic [PAYLOAD_WIDTH-1:0] payload;
  } cell_t;

endpackage