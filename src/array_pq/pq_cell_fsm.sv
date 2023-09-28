/*
 * pq_cell_fsm.sv - Finite state machine to control priority queue cells
 * 
 * author(s): Antti Nurmi : antti.nurmi@tuni.fi
 */

module pq_cell_fsm #(
  parameter TW = 4
)(
  input  logic          clk_i,
  input  logic          rst_ni,
  input  logic          push_i,
  input  logic          pop_i,
  input  logic          drop_i,
  output logic          push_vld_o,
  output logic          pop_vld_o,
  output logic          drop_vld_o,
  input  logic          curr_comp_i,
  input  logic          pop_comp_i,
  output logic          push_o,
  output logic          pop_o,
  output logic          drop_o,
  input  logic          push_vld_i,
  input  logic          pop_vld_i,
  input  logic          drop_vld_i,
  output logic          push_bypass_o,
  output logic          pop_bypass_o,
  output logic          full_o,
  output logic          peek_vld_o,
  input  logic [TW-1:0] curr_id_i,
  input  logic [TW-1:0] next_id_i,
  input  logic [TW-1:0] drop_id_i,
  output logic [TW-1:0] drop_id_o,
  output logic [   1:0] in_sel_o,
  output logic [   1:0] out_sel_o
);

enum logic [2:0] {  
  EMPTY,
  PUSH,
  POP_REQ,
  POP_VLD,
  PUSH_POP,
  DROP_VLD,
  DROP_DONE,
  IDLE  
} curr_state, next_state;

logic          empty;
logic          push_s;
logic          pop_s;
logic          drop_s;

logic [TW-1:0] drop_id_r;
logic          empty_r;
logic          push_r;
logic          pop_r;
logic          drop_r;

always_ff @(posedge clk_i or negedge rst_ni)
  begin : state_reg
    if (~rst_ni) begin
      curr_state <= EMPTY;
    end else begin
      curr_state <= next_state;
    end
  end

always_ff @(posedge clk_i or negedge rst_ni)
  begin : regs
    if (~rst_ni) begin
      drop_id_r <= '0;
      empty_r   <= '0;
      push_r    <=  0;
      pop_r     <=  0;
      drop_r    <=  0;
    end else begin
      drop_id_r <= drop_id_i;
      empty_r   <= empty;
      push_r    <= push_s;
      pop_r     <= pop_s;
      drop_r    <= drop_s;
    end
  end

always_comb
  begin : main_fsm
    
      push_s        =  0;
      pop_s         =  0;
      drop_s        =  0;
      push_vld_o    =  0;  
      pop_vld_o     =  0;
      push_bypass_o =  0;
      pop_bypass_o  =  0;
      full_o        =  0;
      drop_vld_o    =  0;
      in_sel_o      = '0;
      out_sel_o     = '0;
      peek_vld_o    =  0;
      next_state    = curr_state;

    case (curr_state)
      EMPTY: begin
        if (curr_id_i == drop_id_i)
          in_sel_o = 2'b00;
        if (push_i & pop_vld_i) begin
          if (~pop_comp_i) begin
            in_sel_o      = 2'b01;
            out_sel_o     = 2'b01;
            push_bypass_o = 1;
          end
          else begin
            in_sel_o      = 2'b01;
            out_sel_o     = 2'b11;
          end
          next_state = PUSH_POP;
        end else if (pop_vld_i & ~empty & ~drop_i) begin
          in_sel_o   = 2'b10;
          out_sel_o  = 2'b10;
          pop_s      = 1;
          next_state = POP_REQ;
        end else if(drop_i & ~empty_r) begin
          drop_s     = 1;
          if (next_id_i == drop_id_i) begin
            in_sel_o  = 2'b11;
            out_sel_o = 2'b00;
          end
          next_state = DROP_VLD;
        end else if (push_i) begin
          in_sel_o   = 2'b01;
          out_sel_o  = 2'b01;
          next_state = PUSH;
        end else if (pop_i) begin
          in_sel_o   = 2'b10;
          out_sel_o  = 2'b10;
          pop_s      = 1;
          next_state = POP_REQ;
        end else if (drop_i) begin
          drop_s = 1;
          next_state = DROP_DONE;
        end else
          in_sel_o   = 2'b10;
      end
      PUSH: begin
        push_vld_o  = 1;
        if (~empty_r) begin
          if (~curr_comp_i)
            push_bypass_o = 1;
          push_s    = 1;
          out_sel_o = 2'b01;
        end
        next_state  = IDLE;
      end
      POP_REQ: begin
        in_sel_o   = 2'b10;
        out_sel_o  = 2'b10;
        pop_s      = 1;
        next_state = POP_VLD;
      end
      POP_VLD: begin
        pop_s      = 1;
        in_sel_o   = 2'b10;
        out_sel_o  = 2'b10;
        pop_vld_o  = 1;
        if (empty & ~pop_comp_i)
          next_state = EMPTY;
        else
          next_state = IDLE;
      end
      PUSH_POP: begin
        if(pop_comp_i) begin
          out_sel_o = 2'b10;
        end 
        in_sel_o   = 2'b01;
        push_vld_o = 1;
        next_state = IDLE;
      end
      DROP_VLD: begin
        next_state = DROP_DONE;
      end
      DROP_DONE: begin
        drop_vld_o = 1;
          if (drop_id_i == curr_id_i) begin
          in_sel_o   = 2'b11;
          pop_s      = 1;
          out_sel_o  = 2'b10;
        end else begin          
          drop_s   = 1;
        end
        if(empty_r)
          next_state = EMPTY;
        else
          next_state = IDLE;
      end
      IDLE: begin
        full_o     = 1;
        peek_vld_o = 1;
        out_sel_o  = 2'b01;
        if (push_i) begin
          if (~curr_comp_i) begin
            push_bypass_o = 1;
          end
          else begin
            in_sel_o = 2'b01;
          end
          push_s     = 1;
          next_state = PUSH;
        end
        else if (drop_i) begin
          if (curr_id_i == drop_id_i) begin
            in_sel_o   = 2'b11;
            out_sel_o  = 2'b00;
            pop_s      = 1;
            next_state = POP_REQ;
          end else begin
            drop_s     = 1;
            next_state = DROP_VLD;
          end
        end else if (pop_i) begin
          out_sel_o  = 2'b10;
          pop_s      = 1;
          next_state = POP_REQ;
        end else if (pop_vld_i) begin
          in_sel_o   = 2'b00;
        end
      end
      default: begin
        next_state = EMPTY;
      end
    endcase
  end

assign empty     = (curr_id_i == '0) ? 1 : 0;
assign push_o    = push_r;
assign pop_o     = pop_r;
assign drop_o    = drop_r;
assign drop_id_o = drop_id_r;

endmodule : pq_cell_fsm