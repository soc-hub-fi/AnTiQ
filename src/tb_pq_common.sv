/*
 * tb_pq_common.sv - Simple testbench for a HW priority queue
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

`timescale 1ns/1ps

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

typedef enum int { NOP, PUSH, POP, DROP } op_t;
op_t ops;

tb_cell_t value_queue[$];
int id_queue[$];

task print_queue ();
  $write("time: %06t queue:", $time);
  for (int it = 0; it < QUEUE_DEPTH; it++) begin
    $write("[%2h:%1h]", value_queue[it].data,value_queue[it].id);
  end
  $write(" q_size: %2d", value_queue.size());
  $write("\n");
endtask

task insert_val( int insert_data );
  automatic tb_cell_t tmp;
  push   =  1;
  data_i =  insert_data;
  @(negedge clk);
  while(~push_rdy) begin
    @(negedge clk);
  end
  @(posedge clk);
  push   =  0;
  data_i = '0;
  tmp.data = insert_data;
  tmp.id = push_id;
  if(value_queue.size() == QUEUE_DEPTH) begin
    if(insert_data < value_queue[QUEUE_DEPTH-1].data) begin
      void'(value_queue.pop_back());
      value_queue.push_back(tmp);
      value_queue.sort();
    end
  end else if (value_queue.size() < QUEUE_DEPTH) begin
    value_queue.push_back(tmp);
    value_queue.sort();
  end
  $write("[PUSH] data:%2h, id:%2h ", insert_data, push_id);
  print_queue();

  #0;
endtask

task pop_val();
  automatic tb_cell_t tmp;
  if(~empty) begin
    pop    =  1;
    @(negedge clk);
    tmp = value_queue.pop_front();
    $write("[POP ] data:%2h, id:%2h ", tmp.data, tmp.id);
    while(~pop_rdy) begin
      @(negedge clk);
    end
    @(posedge clk);
    pop   =  0;
    #0;
    print_queue();
    assert (data_o == tmp.data) 
    else   $fatal("pop data mismatch with reference! data_o: %2h, tmp.data: %2h", data_o, tmp.data);
  end
endtask

task drop_val( int dropped_id );
  automatic int idx[$];
  drop    = 1;
  drop_id = dropped_id;
  for (int it = 0; it < QUEUE_DEPTH; it++) begin
    if(value_queue[it].id == dropped_id)
      $write("[DROP] data:%2h, id:%2h ",value_queue[it].data, value_queue[it].id);
  end
  //idx = value_queue.find_first_index with (item == dropped_id);
  //foreach(value_queue[del]) value_queue.delete(del);
  for (int it = 0; it<value_queue.size(); it++)
    if (value_queue[it].id == dropped_id) begin
      //$display("VALUE FOUND!");
      value_queue.delete(it--);
    end
  #0;
  while(~drop_rdy) begin
    @(negedge clk);
  end
  @(posedge clk);
  drop    =  0;
  drop_id = '0;
  #0;
  print_queue();
endtask

task nop();
  @(negedge clk);
  @(posedge clk);
  $write("[NOP ]\t        ");
  print_queue();
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
  

  //print_queue();
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

  for (int op = 0; op < TEST_OPS; op++) begin 
    // TODO: random stimulus gen
    void'(randomize(ops));
    case (ops)
      NOP: begin
        nop();
      end
      PUSH: begin
        $display("PUSH");
        @(negedge clk);
        @(posedge clk);
      end
      POP: begin
        pop_val();
      end
      DROP: begin
        $display("DROP");
        @(negedge clk);
        @(posedge clk);
      end 
      default: begin
        nop();
      end 
    endcase
  end

end

always #5 clk = ~clk; // clk gen

pq #(
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
