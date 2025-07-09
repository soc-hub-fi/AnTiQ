module apb_antiq #(
  // assume Depth == NrIrqs for now
  parameter int unsigned Depth = 8
)(
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic      [63:0] mtime_i,
  output logic [Depth-1:0] irqs_o,
  APB.Slave                apb_sbr
);

localparam int unsigned TimestampWidth = 24;
localparam int unsigned PayloadWidth   = $clog2(Depth);

logic               [31:0] reg_status_q, reg_status_d;
logic               [31:0] reg_last_q, reg_last_d;
logic [TimestampWidth-1:0] ts_peek, ts_push, ts_id;
logic [  PayloadWidth-1:0] pop_payload, push_payload;
logic                      full, empty;
logic                      push, pop, drop;
logic                      apb_write, apb_read;

assign apb_write = apb_sbr.psel & apb_sbr.penable &  apb_sbr.pwrite;
assign apb_read  = apb_sbr.psel & apb_sbr.penable & ~apb_sbr.pwrite;

assign apb_sbr.pready = apb_sbr.psel & apb_sbr.penable;
assign reg_status_d = {23'h0, empty, 7'h0, full};

assign pop = (ts_peek <= mtime_i[TimestampWidth-1:0]) & ~empty;

always_comb begin : apb_demux

  apb_sbr.prdata = 32'h0;
  
    if (apb_write) begin
      unique case (apb_sbr.paddr[7:0])
        8'h08:;
        8'h0C:;
        8'h10:;
        default:;
      endcase
    end else if (apb_read) begin
      unique case (apb_sbr.paddr[7:0])
        8'h00: apb_sbr.prdata = reg_status_q;
        8'h04: apb_sbr.prdata = reg_last_q;
        default:;
      endcase
    end

end

always_comb begin : tq_ctrl

  reg_last_d   = reg_last_q;
  ts_push      = TimestampWidth'('h0);
  ts_id        = TimestampWidth'('h0);
  push_payload = PayloadWidth'('h0);
  push         = 1'b0;
  pop          = 1'b0;
  drop         = 1'b0;

  if (apb_write) begin
    unique case (apb_sbr.paddr[7:0])
      8'h08: begin // PUSH_REL
        push         = 1'b1;
        ts_push      = mtime_i[TimestampWidth-1:0] + apb_sbr.pwdata[TimestampWidth-1:0];
        ts_id        = mtime_i[TimestampWidth-1:0];
        push_payload = apb_sbr.pwdata[(PayloadWidth + 24)-1:24];
      end
      8'h0C: begin // PUSH_ABS
      end
      8'h10: begin // DROP
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
  .full_o      (full),
  .empty_o     (empty),
  .push_i      (push),
  .pop_i       (pop),
  .drop_i      (drop),
  .push_id_i   (ts_id),
  .push_data_i (ts_push),
  .payload_o   (pop_payload),
  .payload_i   (push_payload),
  .peek_data_o (ts_peek)
);

/*
pq #(
  .DEPTH (Depth),
  .TW    (TimestampWidth),
  .PW    (PayloadWidth)
)i_pq_core (
  .clk_i,
  .rst_ni,
  .push_i          (push),
  .pop_i           (pop),
  .drop_i          (drop),
  .drop_id_i       (),
  .push_id_i       (ts_id),
  .push_rdy_o      (),
  .drop_rdy_o      (),
  .pop_rdy_o       (),
  .cnt_o           (),
  .full_o          (full),
  .empty_o         (empty),
  .data_i          (ts_push),
  .data_o          (),
  .payload_o       (pop_payload),
  .payload_i       (push_payload),
  .peek_vld_o      (),
  .peek_data_o     (ts_peek),
  .overflow_o      (),
  .data_overflow_o ()
);
*/

endmodule : apb_antiq

