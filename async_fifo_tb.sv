`timescale 1ns / 1ns
module async_fifo_tb;

localparam  DP = 8;
localparam  DW = 8;

logic               wr_clk;
logic               wr_rst_n;
logic               rd_clk;
logic               rd_rst_n;
logic               wr_en;
logic   [DW-1:0]    wr_data;
logic               wr_full;
logic               rd_en;
logic   [DW-1:0]    rd_data;
logic               rd_empty;

async_fifo #(
    .DP (DP) ,
    .DW (DW) ) u_fifo (
    .wr_clk         (wr_clk         ),
    .wr_reset_n     (wr_rst_n       ),
    .wr_en          (wr_en          ),
    .wr_data        (wr_data        ),
    .full           (wr_full        ),
    .afull          (),
    .rd_clk         (rd_clk         ),
    .rd_reset_n     (rd_rst_n       ),
    .rd_en          (rd_en          ),
    .rd_data        (rd_data        ),
    .empty          (rd_empty       ),
    .aempty         ()
);


initial forever #15ns wr_clk = ~wr_clk;
initial forever #10ns rd_clk = ~rd_clk;

initial begin
    wr_clk      = 1'b0;
    wr_rst_n    = 1'b0;
    rd_clk      = 1'b0;
    rd_rst_n    = 1'b0;
    repeat(10) @(posedge wr_clk);
    wr_rst_n   = 1'b1;
    rd_rst_n   = 1'b1;
    repeat(2**(DW+2)) @(posedge wr_clk);
    $finish;
end

always @(posedge wr_clk, negedge wr_rst_n)
    if (~wr_rst_n) begin
        wr_en <= 'b0;
        wr_data <= 'd5;
    end
    else begin
        if (~wr_full) begin
            wr_en <= 'b1;
            wr_data <= wr_data + 'd1;
        end
        else begin
            wr_en <= 'b0;
        end
    end

always @(posedge rd_clk, negedge rd_rst_n)
    if (~rd_rst_n) begin
        rd_en <= 'b0;
    end
    else begin
        if (~rd_empty) begin
            rd_en <= 'b1;
        end
        else begin
            rd_en <= 'b0;
        end
    end

initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars;
    $fsdbDumpMDA;
end

endmodule
