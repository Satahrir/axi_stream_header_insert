`timescale 1ns / 1ps
module axi_stream_insert_header_pipe #(
    parameter   DATA_WD = 32,
    parameter   DATA_BYTE_WD = DATA_WD/8,
    parameter   BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
)
(
        input                       clk,
        input                       rst_n,
        // AXI Stream input original data
        input                       valid_in,
        input   [DATA_WD-1:0]       data_in,
        input   [DATA_BYTE_WD-1:0]  keep_in,  
        input                       last_in,
        output reg                  ready_in,
        // AXI Stream output with header inserted
        output                      valid_out,
        output  [DATA_WD-1:0]       data_out,
        output  [DATA_BYTE_WD-1:0]  keep_out,                      
        output                      last_out,
        input                       ready_out,
        // Header
        input                       valid_insert,
        input   [DATA_WD-1:0]       data_insert,
        input   [DATA_BYTE_WD-1:0]  keep_insert,
        input   [BYTE_CNT_WD-1:0]   byte_insert_cnt,
        output reg                  ready_insert
    );

    // 第一级
    wire [DATA_WD-1:0] data_s1_s2;
    wire [DATA_BYTE_WD-1:0] keep_s1_s2;
    wire last_s1_s2;
    wire valid_o_s1;
    wire rdy_s1_o;    // 本级有效(s1 to outside)
    
    // 第二级
    wire [DATA_WD-1:0] data_s2_s3;
    wire [DATA_BYTE_WD-1:0] keep_s2_s3;
    wire last_s2_s3;
    wire valid_o_s2;
    wire rdy_s2_s1;    // 本级有效(s2 to s1)
    
    // 第三级
    wire [DATA_WD-1:0] data_s3_o;
    wire [DATA_BYTE_WD-1:0] keep_s3_o;
    wire last_s3_o;
    wire valid_o_s3;
    wire rdy_s3_s2;    // 本级有效(s3 to s2)
    reg rdy_nxt;
// Data stream pipeline
pipe_stage #(
    .DATA_WD(DATA_WD + DATA_BYTE_WD + 1)
)data_st1(
    .clk                               (clk                       ),
    .rst_n                             (rst_n                     ),
    .din                               ({data_in, keep_in, last_in}),
    .dout                              ({data_s1_s2,keep_s1_s2,last_s1_s2}   ),
    .pre_valid                         (valid_in                  ),
    .cur_ready                         (rdy_s1_o                  ),

    .cur_valid                         (valid_o_s1                ),
    .nxt_ready                         (rdy_s2_s1                 ) 
);

pipe_stage #(
    .DATA_WD(DATA_WD + DATA_BYTE_WD+1)
)data_st2(
    .clk                               (clk                       ),
    .rst_n                             (rst_n                     ),
    .din                               ({data_s1_s2, keep_s1_s2,last_s1_s2}  ),
    .dout                              ({data_s2_s3, keep_s2_s3,last_s2_s3}  ),
    .pre_valid                         (valid_o_s1                ),
    .cur_ready                         (rdy_s2_s1                 ),
    .cur_valid                         (valid_o_s2                ),
    .nxt_ready                         (rdy_s3_s2                 )
);

pipe_stage #(
    .DATA_WD(DATA_WD + DATA_BYTE_WD+1)
)data_st3(
    .clk                               (clk                       ),
    .rst_n                             (rst_n                     ),
    .din                               ({data_s2_s3, keep_s2_s3,last_s2_s3}  ),
    .dout                              ({data_s3_o, keep_s3_o,last_s3_o}    ),
    .pre_valid                         (valid_o_s2                ),
    .cur_ready                         (rdy_s3_s2                 ),
    .cur_valid                         (valid_o_s3                ),
    .nxt_ready                         (rdy_nxt                 )
);
// Header insert pipeline
    // 第一级
    wire [DATA_WD-1:0] head_s1_s2;
    wire [DATA_BYTE_WD-1:0] hkeep_s1_s2;
    wire hvalid_o_s1;
    wire hrdy_s1_o;    // 本级有效(s1 to outside)

    // 第二级
    wire [DATA_WD-1:0] head_s2_s3;
    wire [DATA_BYTE_WD-1:0] hkeep_s2_s3;
    wire hvalid_o_s2;
    wire hrdy_s2_s1;    // 本级有效(s2 to s1)
    reg hrdy_nxt;

    reg [7:0] cnt_insert;
    reg [7:0] cnt_in;
    reg [7:0] cnt_out;
pipe_stage #(
    .DATA_WD(DATA_WD + DATA_BYTE_WD)
)head_st1(
    .clk                               (clk                       ),
    .rst_n                             (rst_n                     ),
    .din                               ({data_insert, keep_insert}),
    .dout                              ({head_s1_s2, hkeep_s1_s2} ),               
    .pre_valid                         (valid_insert              ),
    .cur_ready                         (hrdy_s1_o                 ),
    .cur_valid                         (hvalid_o_s1               ),
    .nxt_ready                         (hrdy_s2_s1                ) 
);
pipe_stage #(
    .DATA_WD(DATA_WD + DATA_BYTE_WD)
) head_st2(
    .clk                               (clk                       ),
    .rst_n                             (rst_n                     ),
    .din                               ({head_s1_s2, hkeep_s1_s2} ),
    .dout                              ({head_s2_s3, hkeep_s2_s3} ),
    .pre_valid                         (hvalid_o_s1               ),
    .cur_ready                         (hrdy_s2_s1                ),
    .cur_valid                         (hvalid_o_s2               ),
    .nxt_ready                         (hrdy_nxt                  )
);

always @(posedge clk) begin
    if(~rst_n)
        cnt_out <= 0;
    else if (valid_out & ready_out)
        cnt_out <= cnt_out + 1;
end
always @(posedge clk ) begin
    if(~rst_n)
        cnt_insert <= 0;
    else if (valid_insert & ready_insert)
        cnt_insert <= cnt_insert + 1;
end
always @(posedge clk ) begin
    if(~rst_n)
        cnt_in <= 0;
    else if (valid_in & ready_in)
        cnt_in <= cnt_in + 1;
end
always @(*) begin
    if (cnt_insert < 2-1)
        hrdy_nxt = 1;
    else if(cnt_out <= byte_insert_cnt)
        hrdy_nxt = ready_out;
    else
        hrdy_nxt = 0;
end
always @(*) begin
    if (cnt_in < 3-1)
        rdy_nxt = 1;
    else if(cnt_out <= byte_insert_cnt)
        rdy_nxt = 0;
    else
        rdy_nxt = ready_out;
end

always @(*) begin
    if(~rst_n) begin
        // ready_in   <= 0;
        ready_insert = 0;
    end
    else if (cnt_insert < 2) begin
        ready_insert = 1;
    end
    else if (cnt_out < byte_insert_cnt) begin
        // ready_in <= cnt_out < 3 ? hrdy_s1_o : 0;
        ready_insert = hrdy_s1_o;
    end
    else begin
        // ready_in <= rdy_s1_o;
        ready_insert = 0;
    end
end
    // reg [7:0] cnt_in;
always @(*) begin
    if(~rst_n) begin
        ready_in <= 0;
    end
    else if (cnt_in < 3) begin
        ready_in <= 1;
    end
    else if (cnt_out < byte_insert_cnt) begin
        ready_in <= 0;
    end
    else
        ready_in <= rdy_s1_o;
end

// assign ready_in = rdy_s1_o;
assign data_out = (cnt_out <= byte_insert_cnt) ? head_s2_s3 : data_s3_o;
assign keep_out = (cnt_out <= byte_insert_cnt) ? hkeep_s2_s3 : keep_s3_o;
assign last_out = (cnt_out <= byte_insert_cnt) ? 0 : last_s3_o & valid_o_s3;
assign valid_out = (cnt_out <= byte_insert_cnt) ? hvalid_o_s2 : valid_o_s3;
endmodule