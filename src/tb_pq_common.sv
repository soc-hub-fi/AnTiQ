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

logic [DATA_WIDTH-1:0] rand_data;
logic [DATA_WIDTH-1:0] unin_data;
logic [  ID_WIDTH-1:0] rand_id;

cell_t value_queue[$];

task print_queue ();
  $write("time: %06t queue:", $time);
  for (int it = 0; it < QUEUE_DEPTH; it++) begin
    $write("[%2h:%1h]", value_queue[it].data,value_queue[it].id);
  end
  $write(" q_size: %2d", value_queue.size());
  $write("\n");
endtask

task insert_val( logic [DATA_WIDTH-1:0] insert_data );
  automatic cell_t tmp;
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
  automatic cell_t tmp;
  if(~empty) begin
    pop    =  1;
    @(negedge clk);
    tmp = value_queue.pop_front();
    $write("[POP ] data:%h, id:%2h ", tmp.data, tmp.id);
    while(~pop_rdy) begin
      @(negedge clk);
    end
    @(posedge clk);
    pop   =  0;
    #0;
    print_queue();
    assert (data_o == tmp.data) 
    else   $fatal(1, "pop data mismatch with reference! data_o: %2h, tmp.data: %2h", data_o, tmp.data);
  end
endtask

task drop_val( int dropped_id );
  automatic int idx[$];
  automatic bit found = 0;
  drop    = 1;
  drop_id = dropped_id;
  for (int it = 0; it < QUEUE_DEPTH; it++) begin
    if(value_queue[it].id == dropped_id) begin
      $write("[DROP] data:%2h, id:%2h ",value_queue[it].data, value_queue[it].id);
      found = 1;
    end
  end
  if (~found)
    $write("[DROP] data:%2h, id:%2h ",unin_data, dropped_id);
  for (int it = 0; it<value_queue.size(); it++)
    if (value_queue[it].id == dropped_id) begin
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

  for (int op = 0; op < TEST_OPS; op++) begin 
    // TODO: random stimulus gen
    void'(randomize(      ops));
    void'(randomize(rand_data));
    void'(randomize(  rand_id));
    case (ops)
      NOP: begin
        nop();
      end
      PUSH: begin
        insert_val(rand_data);
      end
      POP: begin
        pop_val();
      end
      DROP: begin
        drop_val(rand_id);
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

always @(*) begin
  // TODO: implement logic to check only one *_rdy can be high at a time
  //assert (drop_rdy | push_rdy | pop_rdy)
  //else $fatal(1, "Multiple top handshakes active!");
  end
endmodule // tb_pq
