/*
 * tb_pq_common.sv - Simple testbench for a HW priority queue
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

`timescale 1ns/1ps
//`define GOLDEN

module tb_pq_common ();
  import pq_pkg::*;

localparam VERBOSE = 0;

logic clk, rst_n;    
logic push, pop, drop;             
logic push_rdy, pop_rdy, drop_rdy;
logic full, empty, peek_vld;
logic [ CNT_WIDTH-1:0] cnt;            
logic [  ID_WIDTH-1:0] drop_id, push_id;            
logic [DATA_WIDTH-1:0] data_i, data_o, data_overflow, peek_data;    
logic                  overflow;

int golden_queue[$];

task print_queue ();
  for (int it = 0; it < QUEUE_DEPTH; it++) begin
    $write("[%2h]", golden_queue[it]);
  end
  $write("\n");
endtask

task insert_val( int insert_data );
  push   =  1;
  data_i =  insert_data;
  golden_queue.push_back(insert_data);
  golden_queue.sort();
  $display("push data %04h to queue", insert_data);
  @(negedge clk);
  while(~push_rdy) begin
    @(negedge clk);
  end
  @(posedge clk);
  push   =  0;
  data_i = '0;
  #0;
  print_queue();
endtask

task pop_val();
  pop    =  1;
  @(negedge clk);
  while(~pop_rdy) begin
    @(negedge clk);
  end
  golden_queue.pop_front();
  $display("popped data %h from queue", data_o);
  @(posedge clk);
  pop   =  0;
  #0;
  print_queue();
endtask

task drop_val( int dropped_id );
  drop    = 1;
  drop_id = dropped_id;
  for (int it = 0; it < QUEUE_DEPTH; it++) begin
    
  end
  $display("dropped data with ID: %04h from queue", dropped_id);
  #0;
  while(~drop_rdy) begin
    @(negedge clk);
  end
  @(posedge clk);
  drop    =  0;
  drop_id = '0;
  #0;
endtask

// helper tasks to clean up tb code
task insert_sequence( int vals[$] );
  for(int it=0; it < vals.size; it++) 
  begin
    insert_val(vals[it]);
  end
endtask

task delay( int cycles );
  repeat(cycles) @(posedge clk);
endtask

task pop_sequence( int nr );
  for (int it=0; it < nr; it++)
  begin
    pop_val();
  end
endtask

task flush();
  while(!empty) pop_val;
endtask

initial begin
  clk     =  0;
  rst_n   =  0;
  push    =  0;
  pop     =  0;
  drop    =  0;
  drop_id = '0;
  data_i  = '0;

  #13;
  rst_n  =  1;
  #45;
  
  print_queue();
  // basic push + pop
  insert_sequence({'hF0, 'h15, 'h87});
  pop_sequence(3);
  delay(5);

  // pop, then drop
  insert_sequence({'h01, 'hEB, 'hAF});
  pop_sequence(1);
  drop_val('d3);
  pop_sequence(1);
  delay(10);

  // data collision test
  insert_sequence({'h01, 'h11, 'h12});
  pop_val();
  insert_sequence({'h13});
  //insert_sequence({'h0F});
end

always #5 clk = ~clk; // clk gen

`ifdef GOLDEN
golden_model #(
`else
pq #(
`endif
  .DEPTH ( QUEUE_DEPTH ),
  .DW    ( DATA_WIDTH  )
) i_dut (
  .clk_i           ( clk           ),
  .rst_ni          ( rst_n         ),
  .push_i          ( push          ),
  .pop_i           ( pop           ),
  .drop_i          ( drop          ),
  .drop_id_i       ( drop_id       ),
  .push_id_o       ( push_id       ),
  .push_rdy_o      ( push_rdy      ),
  .pop_rdy_o       ( pop_rdy       ),
  .drop_rdy_o      ( drop_rdy      ),
  .full_o          ( full          ),
  .empty_o         ( empty         ),
  .cnt_o           ( cnt           ),
  .data_i          ( data_i        ),
  .data_o          ( data_o        ),
  .peek_vld_o      ( peek_vld      ),
  .peek_data_o     ( peek_data     ),
  .overflow_o      ( overflow      ),
  .data_overflow_o ( data_overflow )
);

endmodule // tb_pq
