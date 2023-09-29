## Parameters

| Name  | Description                             |
|-------|-----------------------------------------|
| DEPTH | Depth of the queue / number of elements |
| TW    | Width of time repsesentation            |

## Ports

| Name              | Description                             |
|-------------------|-----------------------------------------|
| clk_i             | Clock input
| rst_ni            | Active-low reset
| push_i            | Request to push new data to queue
| pop_i             | Request to pop front element from queue
| drop_i            | Request to drop element with ID from queue
| drop_id_i         | ID of element to be dropped
| push_id_i         | ID of last elemtent pushed
| push_rdy_o        | Previous push operation complete
| pop_rdy_o         | Previous pop operation complete
| drop_rdy_o        | Previous drop operation complete
| full_o            | Queue is full
| empty_o           | Queue is empty
| cnt_o             | Count of values in the queue
| data_i            | TW-wide input data
| data_o            | TW-wide output data
| overflow_o        | Indicator that queue has overflown
| data_overflow_o   | TW-wide overflow data that could not fit to queue