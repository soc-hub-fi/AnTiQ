module apb_antiq #(
  parameter int unsigned Depth      = 8,
  parameter int unsigned IrqWidth   = 8,
  parameter bit          BtmArbTree = 1'b1
)(
  input  logic                clk_i,
  input  logic                rst_ni,
  input  logic         [63:0] mtime_i,
  output logic [IrqWidth-1:0] irqs_o,
  output logic                irq_full_o,
  output logic                irq_nfull_o,
  APB.Slave                   apb_sbr
);

initial begin
  ap_depth: assert(Depth != 0);
end

localparam int unsigned TimestampWidth = 24;
localparam int unsigned PayloadWidth   = $clog2(IrqWidth);
localparam int unsigned IdxWidth       = $clog2(Depth);
localparam logic[7:0] DepthMinusOne = Depth-1;

localparam int unsigned StatusAddr  = 8'h0;
localparam int unsigned LastIdxAddr = 8'h4;
localparam int unsigned TopIdxAddr  = 8'h8;
localparam int unsigned BtmIdxAddr  = 8'hC;
localparam int unsigned PDCtrlAddr  = 8'h10;
localparam int unsigned PRelLoAddr  = 8'h14;
localparam int unsigned PRelHiAddr  = 8'h18;
localparam int unsigned PAbsLoAddr  = 8'h1C;
localparam int unsigned PAbsHiAddr  = 8'h20;
localparam int unsigned DPayloadAddr = 8'h24;
localparam int unsigned DDispatchLoAddr = 8'h28;
localparam int unsigned DDispatchHiAddr = 8'h2C;

logic               [31:0] reg_status_q, reg_status_d;
logic       [IdxWidth-1:0] reg_last_q, reg_last_d;
logic [TimestampWidth-1:0] ts_peek, ts_push;
logic               [63:0] ts_reg_d, ts_reg_q;
logic       [IdxWidth-1:0] ptr_drop_d, ptr_drop_q, ptr_top, ptr_last, ptr_btm;
logic   [PayloadWidth-1:0] pop_payload, push_payload_d, push_payload_q;
logic                      full, empty;
logic                      push, pop, drop;
logic                      drop_q;
logic                      apb_write, apb_read;
logic [TimestampWidth-1:0] drop_ts_d, drop_ts_q;
logic               [63:0] drop_ts_apb;
logic [PayloadWidth-1:0]   drop_payload_d, drop_payload_q;

assign apb_write      = apb_sbr.psel & apb_sbr.penable &  apb_sbr.pwrite;
assign apb_read       = apb_sbr.psel & apb_sbr.penable & ~apb_sbr.pwrite;
assign apb_sbr.pready = apb_sbr.psel & apb_sbr.penable;

logic [7:0] status_top;
assign reg_top_d    = PayloadWidth'(ptr_top);
assign reg_status_d = {DepthMinusOne, 8'h0, 7'h0, empty, 7'h0, full};

assign pop = (ts_peek <= mtime_i[TimestampWidth-1:0]) & ~empty;

assign drop_ts_apb = 64'(drop_ts_q);

assign irq_full_o  =  full & ~reg_status_q[0];
assign irq_nfull_o = ~full &  reg_status_q[0];

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
      StatusAddr:  apb_sbr.prdata = reg_status_q;
      LastIdxAddr: apb_sbr.prdata = 32'(reg_last_q);
      TopIdxAddr:  apb_sbr.prdata = 32'(ptr_top);
      BtmIdxAddr:  apb_sbr.prdata = 32'(ptr_btm);
      DDispatchLoAddr: apb_sbr.prdata = 32'(drop_ts_apb[31:0]);
      DDispatchHiAddr: apb_sbr.prdata = 32'(drop_ts_apb[63:32]);
      DPayloadAddr: apb_sbr.prdata = 32'(drop_payload_q);
      default:;
    endcase
  end

end

always_comb begin : write_logic

  reg_last_d     = reg_last_q;
  ts_reg_d       = ts_reg_q;
  push_payload_d = push_payload_q;
  ptr_drop_d     = ptr_drop_q;
  push           = 1'b0;
  drop           = 1'b0;

  if (apb_write) begin
    unique case (apb_sbr.paddr[7:0])
      PDCtrlAddr: begin
        ptr_drop_d     = IrqWidth'(apb_sbr.pwdata[31:24]);
        push_payload_d = IrqWidth'(apb_sbr.pwdata[23:16]);
        drop           = apb_sbr.pwdata[8];
        push           = apb_sbr.pwdata[0];
        reg_last_d     = ptr_last;
      end
      PRelLoAddr: ts_reg_d[31:0]  = apb_sbr.pwdata + mtime_i[31:0];
      PRelHiAddr: ts_reg_d[63:32] = apb_sbr.pwdata + mtime_i[63:32];
      PAbsLoAddr: ts_reg_d[31:0]  = apb_sbr.pwdata;
      PAbsHiAddr: ts_reg_d[63:32] = apb_sbr.pwdata;
      default:;
    endcase
  end

end

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (~rst_ni) begin
    ts_reg_q       <= 64'h0;
    reg_status_q   <= 32'h0;
    reg_last_q     <= 32'h0;
    drop_q         <= 1'h0;
    ptr_drop_q     <= PayloadWidth'('h0);
    push_payload_q <= PayloadWidth'('h0);
    drop_ts_q      <= TimestampWidth'('h0);
    drop_payload_q <= PayloadWidth'('h0);
  end else begin
    ts_reg_q       <= ts_reg_d;
    reg_status_q   <= reg_status_d;
    reg_last_q     <= reg_last_d;
    drop_q         <= drop;
    ptr_drop_q     <= ptr_drop_d;
    push_payload_q <= push_payload_d;
    if (drop) begin
      drop_ts_q      <= drop_ts_d;
      drop_payload_q <= drop_payload_d;
    end
  end
end

assign ts_push = ts_reg_q[TimestampWidth-1:0];

priority_queue #(
  .Depth        (Depth),
  .TimeWidth    (TimestampWidth),
  .PayloadWidth (PayloadWidth),
  .BtmArbTree   (BtmArbTree)
) i_pq (
  .clk_i,
  .rst_ni,
  .full_o          (full),
  .empty_o         (empty),
  .push_i          (push),
  .pop_i           (pop),
  .drop_i          (drop_q),
  .free_ptr_o      (ptr_last),
  .top_ptr_o       (ptr_top),
  .btm_ptr_o       (ptr_btm),
  .drop_ptr_i      (ptr_drop_q),
  .push_dispatch_i (ts_push),
  .payload_o       (pop_payload),
  .payload_i       (push_payload_q),
  .peek_data_o     (ts_peek),
  .drop_ts_o       (drop_ts_d),
  .drop_payload_o  (drop_payload_d)
);

endmodule : apb_antiq

