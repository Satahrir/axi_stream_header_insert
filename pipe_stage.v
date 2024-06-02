`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/01 21:46:41
// Design Name: 
// Module Name: pipe_stage
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pipe_stage#(
    parameter DATA_WD = 32
)(
    input                   clk,
    input                   rst_n,

    input       [DATA_WD-1:0]   din,
    output reg  [DATA_WD-1:0]   dout,

    input                   pre_valid,
    output                  cur_ready,

    output reg              cur_valid,
    input                   nxt_ready
    );

    assign cur_ready = ~cur_valid | nxt_ready;  // 本级就绪

always @(posedge clk) begin
    if(~rst_n)
        dout <= 0;
    else if (pre_valid && cur_ready)    // 上级有效且本级就绪
        dout <= din;
    else
        dout <= dout;
end

always @(posedge clk) begin
    if(~rst_n)
        cur_valid <= 0;
    else if(cur_ready)
        cur_valid <= pre_valid;
    else
        cur_valid <= cur_valid;
end


endmodule
