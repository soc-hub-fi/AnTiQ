/*
 * pq_cell.sv - AnTiQ cell instance
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

module pq_cell 
  import pq_pkg::*;
#(
  parameter TW = 16,
  //parameter IW = 4,
  parameter ID = 0        
)(
  input  logic          clk_i,
  input  logic          rst_ni,
  output logic          full_o,
  output logic          peek_vld_o,
  output logic [TW-1:0] peek_data_o,
  // n-1 interface
  input  logic          push_i,
  input  logic          pop_i,
  input  logic          drop_i,
  input  logic [TW-1:0] drop_id_i,
  output logic          push_vld_o,
  output logic          pop_vld_o,
  output logic          drop_vld_o,
  input  cell_t         push_struct_i,
  output cell_t         pop_struct_o,
  // n+1 interface
  output logic          push_o,
  output logic          pop_o,
  output logic          drop_o,
  output logic [TW-1:0] drop_id_o,
  input  logic          push_vld_i,
  input  logic          pop_vld_i,
  input  logic          drop_vld_i,
  output cell_t         push_struct_o,
  input  cell_t         pop_struct_i
);

cell_t cell_s;
cell_t cell_r;
cell_t push_s;
cell_t push_r;
cell_t pop_s;
cell_t pop_r;

logic [1:0] in_sel;
logic [1:0] out_sel;
logic       push_bypass;
logic       pop_bypass;

logic curr_comp; // push.data higher priority than current
logic pop_comp;  // push.data higher priority than pop_i
assign curr_comp = ( (push_struct_i.data < cell_r.data      ) | (cell_r.data       == '0)) ? 1 : 0;
assign pop_comp  = ( (push_struct_i.data < pop_struct_i.data) | (pop_struct_i.data == '0)) ? 1 : 0;

always_comb
  begin
    case (in_sel)
      2'b00: 
        cell_s = cell_r;
      2'b01: 
        cell_s = push_struct_i;
      2'b10: 
        cell_s = pop_struct_i;
      2'b11:
        cell_s = '0;
      default: 
        cell_s = '0;
    endcase
  end

always_ff @(posedge clk_i or negedge rst_ni)
  begin : cell_output_reg
    if (~rst_ni) begin
      cell_r <= '0;
      push_r <= '0;
      pop_r  <= '0;
    end
    else begin
      cell_r <= cell_s;
      push_r <= push_s;
      pop_r  <= pop_s; 
    end
  end

always_comb
  begin
    case (out_sel)
    2'b00: begin
      push_s = '0;
      pop_s  = '0;
    end
    2'b01: begin
      push_s = (push_bypass) ? push_struct_i : cell_r;
      pop_s  = '0;
    end
    2'b10: begin
      push_s = '0;
      pop_s  = (pop_bypass) ? pop_struct_i : cell_r;
    end
    2'b11: begin
      push_s = pop_struct_i;
      pop_s  = '0;
    end 
    default: begin
      push_s = '0;
      pop_s  = '0;
    end
  endcase
  end

assign push_struct_o = push_r;
assign pop_struct_o  = pop_r;
assign peek_data_o   = cell_r.data;

pq_cell_fsm #(
  .TW ( TW )
) i_fsm (
  .clk_i         ( clk_i            ),
  .rst_ni        ( rst_ni           ),
  .push_i        ( push_i           ),
  .pop_i         ( pop_i            ),
  .drop_i        ( drop_i           ),
  .push_vld_o    ( push_vld_o       ),   
  .pop_vld_o     ( pop_vld_o        ),  
  .drop_vld_o    ( drop_vld_o       ),
  .curr_comp_i   ( curr_comp        ),
  .pop_comp_i    ( pop_comp         ),
  .push_o        ( push_o           ),
  .pop_o         ( pop_o            ),
  .drop_o        ( drop_o           ),
  .push_vld_i    ( push_vld_i       ),
  .pop_vld_i     ( pop_vld_i        ),
  .drop_vld_i    ( drop_vld_i       ),
  .push_bypass_o ( push_bypass      ),
  .pop_bypass_o  ( pop_bypass       ),
  .full_o        ( full_o           ),
  .peek_vld_o    ( peek_vld_o       ),
  .curr_id_i     ( cell_r.id        ),
  .next_id_i     ( pop_struct_i.id  ),
  .drop_id_i     ( drop_id_i        ),
  .drop_id_o     ( drop_id_o        ),
  .in_sel_o      ( in_sel           ),
  .out_sel_o     ( out_sel          )
);

endmodule : pq_cell