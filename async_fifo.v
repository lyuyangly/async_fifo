`timescale 1ns / 1ns
module async_fifo #(
    parameter   DP = 8,
    parameter   DW = 32 )(
    input               wr_clk,
    input               wr_reset_n,
    input               wr_en,
    input   [DW-1:0]    wr_data,
    output              full,
    output              afull,
    input               rd_clk,
    input               rd_reset_n,
    input               rd_en,
    output  [DW-1:0]    rd_data,
    output              empty,
    output              aempty
);

localparam  AW      = $clog2(DP);
localparam  WR_FAST = 1'b1;
localparam  RD_FAST = 1'b1;

reg     [DW-1:0]    mem[DP-1:0];
reg     [AW:0]      sync_rd_ptr_0, sync_rd_ptr_1;
wire    [AW:0]      sync_rd_ptr;
reg                 full_q;
reg     [AW:0]      wr_ptr, gray_wr_ptr;
reg     [AW:0]      gray_rd_ptr;
wire    [AW:0]      wr_ptr_inc = wr_ptr + 1'b1;
wire    [AW:0]      wr_cnt = get_cnt(wr_ptr, sync_rd_ptr);
wire                full_c  = (wr_cnt == DP) ? 1'b1 : 1'b0;
reg     [AW:0]      sync_wr_ptr_0, sync_wr_ptr_1;
wire    [AW:0]      sync_wr_ptr;
reg     [AW:0]      rd_ptr;
reg                 empty_q;
wire    [AW:0]      rd_ptr_inc = rd_ptr + 1'b1;
wire    [AW:0]      rd_cnt = get_cnt(sync_wr_ptr, rd_ptr);
wire                empty_c  = (rd_cnt == 0) ? 1'b1 : 1'b0;
reg     [DW-1:0]    rd_data_q;
wire    [DW-1:0]    rd_data_c = mem[rd_ptr[AW-1:0]];

always @(posedge wr_clk or negedge wr_reset_n)
    if (!wr_reset_n) begin
        wr_ptr <= 'd0;
        gray_wr_ptr <= 'd0;
        full_q <= 'b0;
    end
    else if (wr_en) begin
        wr_ptr <= wr_ptr_inc;
        gray_wr_ptr <= bin2gray(wr_ptr_inc);
        if (wr_cnt == (DP-'d1)) begin
            full_q <= 'b1;
        end
    end
    else begin
        if (full_q && (wr_cnt<DP)) begin
            full_q <= 'b0;
        end
    end

assign full  = (WR_FAST == 1) ? full_c : full_q;
assign afull = (wr_cnt >= DP/2 - 1) ? 1'b1 : 1'b0;

always @(posedge wr_clk)
    if (wr_en) begin
        mem[wr_ptr[AW-1:0]] <= wr_data;
    end

// read pointer synchronizer
always @(posedge wr_clk or negedge wr_reset_n)
    if (!wr_reset_n) begin
        sync_rd_ptr_0 <= 'b0;
        sync_rd_ptr_1 <= 'b0;
    end
    else begin
        sync_rd_ptr_0 <= gray_rd_ptr;
        sync_rd_ptr_1 <= sync_rd_ptr_0;
    end

assign sync_rd_ptr = gray2bin(sync_rd_ptr_1);

always @(posedge rd_clk or negedge rd_reset_n)
    if (!rd_reset_n) begin
        rd_ptr <= 'd0;
        gray_rd_ptr <= 'd0;
        empty_q <= 'b1;
    end
    else begin
        if (rd_en) begin
            rd_ptr <= rd_ptr_inc;
            gray_rd_ptr <= bin2gray(rd_ptr_inc);
            if (rd_cnt=='d1) begin
                empty_q <= 'b1;
            end
        end
        else begin
            if (empty_q && (rd_cnt!='d0)) begin
                empty_q <= 'b0;
            end
        end
    end

assign empty  = (RD_FAST == 1) ? empty_c : empty_q;
assign aempty = (rd_cnt < DP/2 - 'd3) ? 1'b1 : 1'b0;

always @(posedge rd_clk)
    rd_data_q <= rd_data_c;

assign rd_data  = (RD_FAST == 1) ? rd_data_c : rd_data_q;

// write pointer synchronizer
always @(posedge rd_clk or negedge rd_reset_n)
    if (!rd_reset_n) begin
       sync_wr_ptr_0 <= 'b0;
       sync_wr_ptr_1 <= 'b0;
    end
    else begin
       sync_wr_ptr_0 <= gray_wr_ptr;
       sync_wr_ptr_1 <= sync_wr_ptr_0;
    end

assign sync_wr_ptr = gray2bin(sync_wr_ptr_1);

function [AW:0] get_cnt;
input [AW:0] wr_ptr, rd_ptr;
begin
    if (wr_ptr >= rd_ptr) begin
        get_cnt = (wr_ptr - rd_ptr);
    end
    else begin
        get_cnt = DP*2 - (rd_ptr - wr_ptr);
    end
end
endfunction

function [AW:0] bin2gray;
input   [AW:0]  bin;

bin2gray = (bin >> 1) ^ bin;

endfunction

function [AW:0] gray2bin;
input   [AW:0]  gray;
integer         k;

for (k = 0; k <= AW; k = k + 1)
    gray2bin[k] = ^(gray >> k);

endfunction

endmodule
