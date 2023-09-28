/*
 * pq.sv - Systolic array priority queue supporting push, push & drop
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

module pq 
  import pq_pkg::*;
#(
  parameter  DEPTH = QUEUE_DEPTH,
  parameter  TW = TIME_WIDTH,
  localparam CNT_WIDTH   = $clog2(DEPTH)    
)(
  input  logic                  clk_i,           
  input  logic                  rst_ni,          
  input  logic                  push_i,          
  input  logic                  pop_i,           
  input  logic                  drop_i,          
  input  logic [        TW-1:0] drop_id_i,       
  input  logic [        TW-1:0] push_id_i,       
  output logic                  push_rdy_o,      
  output logic                  pop_rdy_o,       
  output logic                  drop_rdy_o,      
  output logic                  full_o,          
  output logic                  empty_o,         
  output logic [ CNT_WIDTH-1:0] cnt_o,           
  input  logic [        TW-1:0] data_i,          
  output logic [        TW-1:0] data_o,          
  output logic                  peek_vld_o,          
  output logic [        TW-1:0] peek_data_o,          
  output logic                  overflow_o,      
  output logic [        TW-1:0] data_overflow_o 
);

cell_t push_struct  [DEPTH-0:0];
cell_t pop_struct   [DEPTH-0:0];
 
logic  push         [DEPTH-0:0];
logic  pop          [DEPTH-0:0];
logic  drop         [DEPTH-0:0];
 
logic  push_vld     [DEPTH-0:0];
logic  pop_vld      [DEPTH-0:0];
logic  drop_vld     [DEPTH-0:0];

logic  full         [DEPTH-1:0];
logic  peek_vld     [DEPTH-1:0];
logic [ TW-1:0]      peek_data [DEPTH-1:0];

logic [ TW-1:0]        drop_id [DEPTH-0:0];

for (genvar ii=0; ii<DEPTH; ii++) 
  begin : cell_gen
    pq_cell #(
      .TW ( TW       ),
      //.IW ( ID_WIDTH ),
      .ID ( ii )
    ) i_pq_cell (
      .clk_i         ( clk_i             ),
      .rst_ni        ( rst_ni            ),
      .full_o        ( full[ii]          ),
      .peek_vld_o    ( peek_vld [ii]     ),
      .peek_data_o   ( peek_data[ii]     ),
      .push_i        ( push[ii]          ),
      .pop_i         ( pop [ii]          ),
      .drop_i        ( drop[ii]          ),
      .drop_id_i     ( drop_id [ii]      ),
      .push_vld_o    ( push_vld[ii]      ),   
      .pop_vld_o     ( pop_vld [ii]      ),  
      .drop_vld_o    ( drop_vld[ii]      ),
      .push_o        ( push[ii+1]        ),
      .pop_o         ( pop [ii+1]        ),
      .drop_o        ( drop[ii+1]        ),
      .drop_id_o     ( drop_id [ii+1]    ),
      .push_vld_i    ( push_vld[ii+1]    ),
      .pop_vld_i     ( pop_vld [ii+1]    ),
      .drop_vld_i    ( drop_vld[ii+1]    ),
      .push_struct_i ( push_struct[ii]   ),
      .pop_struct_o  ( pop_struct [ii]   ),
      .push_struct_o ( push_struct[ii+1] ),
      .pop_struct_i  ( pop_struct [ii+1] )
    );
  end

assign push[0] = push_i;
assign drop[0] = drop_i;
assign  pop[0] = pop_i;

assign push_rdy_o = push_vld[0];
assign pop_rdy_o  = pop_vld [0];
assign drop_rdy_o = drop_vld[0];
assign drop_id[0] = drop_id_i;

assign push_vld[DEPTH] = 0;
assign pop_vld [DEPTH] = 0;
assign drop_vld[DEPTH] = 0;

assign cnt_o       =  '0; // TODO: implement
assign full_o      =  full[DEPTH-1];
assign empty_o     = ~full[0];
assign peek_data_o = peek_data[0];
assign peek_vld_o  = peek_vld[0];

assign push_struct[0].data = data_i;
assign push_struct[0].id   = push_id_i;
assign data_o              = pop_struct[0].data;
assign pop_struct[DEPTH]   = '0;
assign data_overflow_o     = push_struct[DEPTH].data;
assign overflow_o          = push[DEPTH] & push_vld[DEPTH-1];

endmodule : pq