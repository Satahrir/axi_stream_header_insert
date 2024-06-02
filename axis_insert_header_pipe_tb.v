module axis_insert_header_pipe_tb(

    );

    // Parameters
    localparam  DATA_WD = 32;
    localparam  DATA_BYTE_WD = DATA_WD/8;
    localparam  BYTE_CNT_WD = $clog2(DATA_BYTE_WD);
  
    //Ports
    reg  clk = 0;
    reg  rst_n= 0;
    wire valid_in;
    wire [DATA_WD-1:0] data_in;
    wire [DATA_BYTE_WD-1:0] keep_in;
    wire  last_in;
    wire  ready_in;
    wire  valid_out;
    wire [DATA_WD-1:0] data_out;
    wire [DATA_BYTE_WD-1:0] keep_out;
    wire  last_out;
    reg  ready_out = 0;
    wire  valid_insert;
    wire [DATA_WD-1:0] data_insert;
    wire [DATA_BYTE_WD-1:0] keep_insert;
    wire [BYTE_CNT_WD-1:0] byte_insert_cnt = 2;
    wire  ready_insert;
  
    axi_stream_insert_header_pipe # (
      .DATA_WD(32),
      .DATA_BYTE_WD(4),
      .BYTE_CNT_WD(2)
    )
    axi_stream_insert_header_pipe_inst (
      .clk(clk),
      .rst_n(rst_n),
      .valid_in(valid_in),
      .data_in(data_in),
      .keep_in(keep_in),
      .last_in(last_in),
      .ready_in(ready_in),
      
      .valid_out(valid_out),
      .data_out(data_out),
      .keep_out(keep_out),
      .last_out(last_out),
      .ready_out(ready_out),

      .valid_insert(valid_insert),
      .data_insert(data_insert),
      .keep_insert(keep_insert),
      .byte_insert_cnt(byte_insert_cnt),
      .ready_insert(ready_insert)
    );
  
  always #5  clk = ! clk ;

    wire M_AXIS_TLAST;

  m_axis_src # (
    .C_M_AXIS_TDATA_WIDTH(32),
    .C_M_START_COUNT(2),
    .NUMBER_OF_OUTPUT_WORDS(2)
  )
  header_insert (
    .M_AXIS_ACLK(clk),
    .M_AXIS_ARESETN(rst_n),
    .M_AXIS_TVALID(valid_insert),
    .M_AXIS_TDATA(data_insert),
    .M_AXIS_TSTRB(keep_insert),
    .M_AXIS_TLAST(M_AXIS_TLAST),
    .M_AXIS_TREADY(ready_insert)
  );

  m_axis_src # (
    .C_M_AXIS_TDATA_WIDTH(32),
    .C_M_START_COUNT(2),
    .NUMBER_OF_OUTPUT_WORDS(8)
  )
  data_in_1 (
    .M_AXIS_ACLK(clk),
    .M_AXIS_ARESETN(rst_n),
    .M_AXIS_TVALID(valid_in),
    .M_AXIS_TDATA(data_in),
    .M_AXIS_TSTRB(keep_in),
    .M_AXIS_TLAST(last_in),
    .M_AXIS_TREADY(ready_in)
  );

initial begin
    #100 rst_n = 1;
    #15 ready_out = 0;
    
    #90 ready_out = 1;
    // #10 ready_out = 0;
    // #40 ready_out = 1;
    // #20 ready_out = 0;
    // #30 ready_out = 1;
    // #80 ready_out = 0;
    // #90 ready_out = 1;
    // #10 ready_out = 0;
    // #40 ready_out = 1;
    // #20 ready_out = 0;
    // #30 ready_out = 1;
    // #80 ready_out = 0;
    // #90 ready_out = 1;
    // #10 ready_out = 0;
    // #40 ready_out = 1;
    // #20 ready_out = 0;
    // #30 ready_out = 1;
    // #80 ready_out = 0;

end
endmodule