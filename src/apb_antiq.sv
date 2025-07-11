module apb_antiq #(
  // assume Depth == NrIrqs for now
  parameter int unsigned Depth = 8
)(
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic      [63:0] mtime_i,
  output logic [Depth-1:0] irqs_o,
  output logic             irq_full_o,
  APB.Slave                apb_sbr
);

localparam int unsigned TimestampWidth = 24;
localparam int unsigned PayloadWidth   = $clog2(Depth);

logic               [31:0] reg_status_q, reg_status_d;
logic   [PayloadWidth-1:0] reg_last_q, reg_last_d;
logic [TimestampWidth-1:0] ts_peek, ts_push;
logic   [PayloadWidth-1:0] ptr_drop, ptr_top, ptr_last;
logic   [PayloadWidth-1:0] pop_payload, push_payload;
logic                      full, empty;
logic                      push, pop, drop;
logic                      apb_write, apb_read;

assign apb_write = apb_sbr.psel & apb_sbr.penable &  apb_sbr.pwrite;
assign apb_read  = apb_sbr.psel & apb_sbr.penable & ~apb_sbr.pwrite;

assign apb_sbr.pready = apb_sbr.psel & apb_sbr.penable;

logic [7:0] status_top;
assign status_top = PayloadWidth'(ptr_top);
assign reg_status_d = {status_top ,15'h0, empty, 7'h0, full};

assign pop = (ts_peek <= mtime_i[TimestampWidth-1:0]) & ~empty;


assign irq_full_o = full & ~reg_status_q[0];

always_comb begin : irq_decoder
  irqs_o = Depth'('0);
  for (int i=0; i<Depth; i++) begin
    if ((i == pop_payload) & pop) irqs_o[i] = 1'b1;
  end
end

always_comb begin : read_logic

  apb_sbr.prdata = 32'h0;
  
  if (apb_read) begin
    unique case (apb_sbr.paddr[7:0])
      8'h00: apb_sbr.prdata = reg_status_q;
      8'h04: apb_sbr.prdata = 32'(reg_last_q);
      default:;
    endcase
  end

end

always_comb begin : write_logic

  reg_last_d   = reg_last_q;
  ts_push      = TimestampWidth'('h0);
  push_payload = PayloadWidth'('h0);
  ptr_drop     = PayloadWidth'('h0);
  push         = 1'b0;
  pop          = 1'b0;
  drop         = 1'b0;

  if (apb_write) begin
    unique case (apb_sbr.paddr[7:0])
      8'h08: begin // PUSH_REL
        push         = 1'b1;
        ts_push      = mtime_i[TimestampWidth-1:0] + apb_sbr.pwdata[TimestampWidth-1:0];
        reg_last_d   = ptr_last;
        push_payload = apb_sbr.pwdata[(PayloadWidth + 24)-1:24];
      end
      8'h0C: begin // PUSH_ABS
        push         = 1'b1;
        ts_push      = apb_sbr.pwdata[TimestampWidth-1:0];
        reg_last_d   = ptr_last;
        push_payload = apb_sbr.pwdata[(PayloadWidth + 24)-1:24];
      end
      8'h10: begin // DROP
        drop         = 1'b1;
        ptr_drop     = apb_sbr.pwdata[PayloadWidth-1:0];
      end
      default:;
    endcase
  end

end

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (~rst_ni) begin
    reg_status_q <= 32'h0;
    reg_last_q   <= 32'h0;
  end else begin
    reg_status_q <= reg_status_d;
    reg_last_q   <= reg_last_d;
  end
end

priority_queue #(
  .Depth        (Depth),
  .TimeWidth    (TimestampWidth),
  .PayloadWidth (PayloadWidth)
) i_pq (
  .clk_i,
  .rst_ni,
  .full_o          (full),
  .empty_o         (empty),
  .push_i          (push),
  .pop_i           (pop),
  .drop_i          (drop),
  .free_ptr_o      (ptr_last),
  .top_ptr_o       (ptr_top),
  .drop_ptr_i      (ptr_drop),
  .push_dispatch_i (ts_push),
  .payload_o       (pop_payload),
  .payload_i       (push_payload),
  .peek_data_o     (ts_peek)
);

endmodule : apb_antiq

