/*
 * golden_model.sv - A reference model for the AnTiQ
 * NOT UP TO DATE -> DISFUNCTIONAL
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

module golden_model #(
  parameter int DEPTH = 5,
  parameter int DW    = 16,

  localparam CNT_W  = $clog2(DEPTH),
  localparam ID_W   = CNT_W + 1 
)(
  input  logic             clk_i, rst_ni,
  input  logic             push_i, pop_i, drop_i,
  output logic             push_rdy_o, pop_rdy_o, drop_rdy_o,
  output logic             full_o, empty_o,
  input  logic [ ID_W-1:0] drop_id_i,
  output logic [CNT_W-1:0] cnt_o,
  output logic [ ID_W-1:0] push_id_o,
  input  logic [   DW-1:0] data_i, 
  output logic [   DW-1:0] data_o, data_overflow_o,
  output logic             overflow_o
);

typedef struct {
  logic [   DW-1:0 ] data;
  logic [ ID_W-1:0 ] id;
} queue_t;

queue_t queue[DEPTH-1:0];
logic [CNT_W-1:0] cnt;
logic [ ID_W-1:0] id;
bit found = 0;

initial begin : reset
  for (int i; i < DEPTH; i++) begin
    queue[i].data = '1;
    queue[i].id   = '0;
  end
  cnt             =  0;
  push_rdy_o      =  0;
  pop_rdy_o       =  0;
  drop_rdy_o      =  0;
  overflow_o      =  0;
  data_overflow_o = '0;
  push_id_o       = '0;
  id              = '0;
end

initial begin
  forever 
    begin : insert
      wait(push_i);
      if (cnt == DEPTH) begin
        data_overflow_o = data_i;
        overflow_o = 1;
      end
      else begin
        id++;
        queue[cnt].data = data_i;
        if (id == 0)
          id++;
        queue[cnt].id   = id;
        queue.rsort(item) with (item.data);
        push_id_o = id;
        cnt++;
      end
      push_rdy_o = 0;
      pop_rdy_o  = 0;
      drop_rdy_o = 0;
      @(posedge clk_i);
      push_rdy_o = 1;
      pop_rdy_o  = 1;
      drop_rdy_o = 1;
      push_id_o  ='0;
      @(posedge clk_i);
      #0;
      end
    end

initial begin
  forever 
    begin : dequeue
      wait(pop_i);
      if (cnt == 0) begin
        $warning("attempting to pop from empty queue");
      end
      else begin
        push_rdy_o = 0;
        pop_rdy_o  = 0;
        drop_rdy_o = 0;
        @(posedge clk_i);
        if (cnt == DEPTH) begin
          overflow_o      = 0;
          data_overflow_o = 0;
        end
        queue[0].data = '1;
        queue[0].id   = '0;
        queue.rsort(item) with (item.data);
        cnt--;
      end
      push_rdy_o = 1;
      pop_rdy_o  = 1;
      drop_rdy_o = 1;
      @(posedge clk_i);
      #0;    
    end
end

initial begin
  forever 
  begin : drop
    wait(drop_i);
    if (cnt == 0) begin
      $warning("attempting to drop from empty queue");
    end
    else begin
      push_rdy_o = 0;
      pop_rdy_o  = 0;
      drop_rdy_o = 0;
      @(posedge clk_i);
      found = 0;
      for(int ii=0; ii<DEPTH; ii++) begin
        if (queue[ii].id == drop_id_i) begin
          found          =  1; 
          queue[ii].data = '1;
          queue[ii].id   = '0;
          queue.rsort(item) with (item.data);
          cnt--;
        end
      end
      if( ~found ) begin
        $warning("item with drop ID not found");
      end
      push_rdy_o = 1;
      pop_rdy_o  = 1;
      drop_rdy_o = 1;
      @(posedge clk_i);
      #0;    
    end 
  end
end

always_comb
  begin : output_assign
    full_o  = (cnt == DEPTH) ? 1 : 0;
    empty_o = (cnt ==     0) ? 1 : 0;
    cnt_o   =  cnt;
    data_o  = (cnt ==     0) ? 0 : queue[0].data;
  end

endmodule : golden_model