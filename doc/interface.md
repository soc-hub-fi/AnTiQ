## Parameters

| Name  | Description                             |
|-------|-----------------------------------------|
| DEPTH | Depth of the queue / number of elements |
| DW    | Data width of queue elements            |

## Ports

| Name              | Description                             |
|-------------------|-----------------------------------------|
| clk_i             | Clock input
| rst_ni            | Active-low reset
| push_i            | Request to push new data to queue
| pop_i             | Request to pop front element from queue
| drop_i            | Request to drop element with ID from queue
| drop_id_i         | ID of element to be dropped
| push_id_o         | ID of last elemtent pushed [raised along push_rdy_o]
| push_rdy_o        | Queue is ready to be pushed into
| pop_rdy_o         | Queue is ready to be popped from
| full_o            | Queue is full
| empty_o           | Queue is empty
| cnt_o             | Count of values in the queue
| data_i            | DW-wide input data
| data_o            | DW-wide output data
| overflow_o        | Indicator that queue has overflown
| data_overflow_o   | DW-wide overflow data that could not fit to queue