module top_chip #(
    parameter int IO_DATA_WIDTH = 16,
    parameter int ACCUMULATION_WIDTH = 32,
    parameter int EXT_MEM_HEIGHT = 1 << 20,
    parameter int EXT_MEM_WIDTH = ACCUMULATION_WIDTH,
    parameter int FEATURE_MAP_WIDTH = 1024,
    parameter int FEATURE_MAP_HEIGHT = 1024,
    parameter int INPUT_NB_CHANNELS = 64,
    parameter int OUTPUT_NB_CHANNELS = 64
) (
    input logic clk,
    input logic arst_n_in, //asynchronous reset, active low

    //external_memory
    //read port
    output logic unsigned [$clog2(EXT_MEM_HEIGHT)-1:0] ext_mem_read_addr,
    output logic ext_mem_read_en,
    input logic [EXT_MEM_WIDTH-1:0] ext_mem_qout,

    //write port
    output logic unsigned [$clog2(EXT_MEM_HEIGHT)-1:0] ext_mem_write_addr,
    output logic [EXT_MEM_WIDTH-1:0] ext_mem_din,
    output logic ext_mem_write_en,

    // System Run-time Configuration
    input logic [1:0] conv_kernel_mode,
    // Currently support 3 sizes:
    // 0: 1x1
    // 1: 3x3
    // 2: 5x5
    input logic [1:0] conv_stride_mode,
    // Currently support 3 modes:
    // 0: step = 1
    // 1: step = 2
    // 2: step = 4

    //system data inputs and ext_mem_read_addrTH-1:0] a_input,
    input logic [IO_DATA_WIDTH-1:0] a_input,
    input logic a_valid,
    output logic a_ready,
    input logic [IO_DATA_WIDTH-1:0] b_input,
    input logic b_valid,
    output logic b_ready,

    //output
    input logic signed [IO_DATA_WIDTH-1:0] c_input,
    input logic c_valid,
    output logic c_ready,
    //output logic c_out_en,

    output logic signed [IO_DATA_WIDTH-1:0] out,
    output logic output_valid,
    output logic [$clog2(FEATURE_MAP_WIDTH)-1:0] output_x,
    output logic [$clog2(FEATURE_MAP_HEIGHT)-1:0] output_y,
    output logic [$clog2(OUTPUT_NB_CHANNELS)-1:0] output_ch,


    input  logic start,
    output logic running
);


  logic write_a_1;
  logic write_b_1;
  logic write_c_1;
  
  logic write_a_2;
  logic write_b_2;
  logic write_c_2;
 
  logic [31:0] out_1;
  logic [31:0] out_2;
  logic final_out_en;
  logic w00_w01_w02_we_1;
  logic w10_w11_w12_we_1;
  logic w20_w21_w22_we_1;
  logic w00_w01_w02_we_2;
  logic w10_w11_w12_we_2;
  logic w20_w21_w22_we_2;


  // logic [IO_DATA_WIDTH-1:0] a_1, a_2;
  // logic [IO_DATA_WIDTH-1:0] b_1, b_2;
  // logic [IO_DATA_WIDTH-1:0] c_1, c_2;
//   `REG(IO_DATA_WIDTH, a_1);
//   `REG(IO_DATA_WIDTH, b_1);
//   `REG(IO_DATA_WIDTH, c_1);

//   `REG(IO_DATA_WIDTH, a_2);
//   `REG(IO_DATA_WIDTH, b_2);
//   `REG(IO_DATA_WIDTH, c_2);

  `REG(IO_DATA_WIDTH, out_final) ;
  `REG(1, final_out_en_reg);

  assign output_valid = final_out_en_reg;
  assign final_out_en_reg_next = final_out_en;
  assign final_out_en_reg_we = 1;
  assign out_final_we = final_out_en;

  // assign out = out_final[31:16];
  //assign output_valid = c_out_en;

//   assign a_1_next = write_a_1 ? a_input : 0;
//   assign b_1_next = write_b_1 ? b_input : 0;
//   assign c_1_next = write_c_1 ? c_input : 0;

//   assign a_2_next = write_a_2 ? a_input : 0;
//   assign b_2_next = write_b_2 ? b_input : 0;
//   assign c_2_next = write_c_2 ? c_input : 0;

  // assign a_1 = write_a_1 | w00_w01_w02_we_1 | w10_w11_w12_we_1 | w20_w21_w22_we_1 ? a_input : 0;
  // assign b_1 = write_b_1 | w00_w01_w02_we_1 | w10_w11_w12_we_1 | w20_w21_w22_we_1 ? b_input : 0;
  // assign c_1 = write_c_1 | w00_w01_w02_we_1 | w10_w11_w12_we_1 | w20_w21_w22_we_1 ? c_input : 0;

  // assign a_2 = write_a_2 | w00_w01_w02_we_2 | w10_w11_w12_we_2 | w20_w21_w22_we_2 ? a_input : 0;
  // assign b_2 =  write_b_2 | w00_w01_w02_we_2 | w10_w11_w12_we_2 | w20_w21_w22_we_2 ? b_input : 0;
  // assign c_2 = write_c_2 | w00_w01_w02_we_2 | w10_w11_w12_we_2 | w20_w21_w22_we_2  ? c_input : 0;

  // logic reset_systolic_1, reset_systolic_2;

//   assign a_1_we   = 1;
//   assign b_1_we   = 1;
//   assign c_1_we   = 1;

//   assign a_2_we   = 1;
//   assign b_2_we   = 1;
//   assign c_2_we   = 1;
 

  // logic mac_valid;
  // logic mac_accumulate_internal;
  // logic mac_accumulate_with_0;

  // logic out_en_1;
  // logic out_en_2;
  


  // `REG(IO_DATA_WIDTH, out_1_reg);
  
  //  assign out_1_reg_we = out_en_1;
  // assign out_1_reg_next = out_1;

  controller_fsm_systolic #(
      .LOG2_OF_MEM_HEIGHT($clog2(EXT_MEM_HEIGHT)),
      .FEATURE_MAP_WIDTH (FEATURE_MAP_WIDTH),
      .FEATURE_MAP_HEIGHT(FEATURE_MAP_HEIGHT),
      .INPUT_NB_CHANNELS (INPUT_NB_CHANNELS),
      .OUTPUT_NB_CHANNELS(OUTPUT_NB_CHANNELS),
      .IO_DATA_WIDTH(IO_DATA_WIDTH)
  ) controller (
      .clk(clk),
      .arst_n_in(arst_n_in),
      .start(start),
      .running(running),
      .conv_kernel_mode(conv_kernel_mode),
      .conv_stride_mode(conv_stride_mode),

      .mem_we(ext_mem_write_en),
      .mem_write_addr(ext_mem_write_addr),
      .mem_re(ext_mem_read_en),
      .mem_read_addr(ext_mem_read_addr),

      .a_valid(a_valid),
      .a_ready(a_ready),
      .b_valid(b_valid),
      .b_ready(b_ready),
      // .write_a(write_a),
      // .write_b(write_b),
      .mac_valid(mac_valid),
      .mac_accumulate_internal(mac_accumulate_internal),
      .mac_accumulate_with_0(mac_accumulate_with_0),
      .w00_w01_w02_we_1(w00_w01_w02_we_1),
      .w10_w11_w12_we_1(w10_w11_w12_we_1),
      .w20_w21_w22_we_1(w20_w21_w22_we_1),

      .w00_w01_w02_we_2(w00_w01_w02_we_2),
      .w10_w11_w12_we_2(w10_w11_w12_we_2),
      .w20_w21_w22_we_2(w20_w21_w22_we_2),

      .i00_i01_i02_we_1(i00_i01_i02_we_1),
      .i10_i11_i12_we_1(i10_i11_i12_we_1),    
      .i20_i21_i22_we_1(i20_i21_i22_we_1),
      .i00_i01_i02_we_2(i00_i01_i02_we_2),
      .i10_i11_i12_we_2(i10_i11_i12_we_2),    
      .i20_i21_i22_we_2(i20_i21_i22_we_2),

      // .write_a_1(write_a_1),
      // .write_b_1(write_b_1),
      // .write_c_1(write_c_1),
      // .write_a_2(write_a_2),
      // .write_b_2(write_b_2),
      // .write_c_2(write_c_2),

      .c_valid(c_valid),
      .c_ready(c_ready),
      //.c_out_en(c_out_en),

      .out_en_1(out_en_1),
      .out_en_2(out_en_2),
      .final_out_en(final_out_en),

      .output_x(output_x),
      .output_y(output_y),
      .output_ch(output_ch)

      // .reset_systolic_1(reset_systolic_1),
      // .reset_systolic_2(reset_systolic_2)
  );

  // Assign partial sum 0 to avoid reading uninitialized memory
  logic signed [ACCUMULATION_WIDTH-1:0] mac_partial_sum;
  assign mac_partial_sum = mac_accumulate_with_0 ? 0 : ext_mem_qout;

  // Intermediate Buffer is always buffered by external memory (output memory)
  logic signed [ACCUMULATION_WIDTH-1:0] mac_out;
  assign ext_mem_din = mac_out;

logic [31:0] addends[0:3];
logic [31:0] add_out;





// check the output 17 bits
 adder #(
  .A_WIDTH(32),
  .B_WIDTH(32),
  // .OUT_SCALE(1),
  .OUT_SCALE(0),
  .OUT_WIDTH(32)
  ) adder_1
  (
  .a(out_1),
  .b(out_2),
  .out(out_final_next)
  );


systolicArray #(
    .WIDTH(IO_DATA_WIDTH)
    ) systolicArray_1(
    .clk(clk),
    .arst_n_in(arst_n_in),
    .data_in_1(a_input),
    .data_in_2(b_input),
    .data_in_3(c_input),
    // .data_in_1(a_1),
    // .data_in_2(b_1),
    // .data_in_3(c_1),
    .w00_w01_w02_we(w00_w01_w02_we_1),
    .w10_w11_w12_we(w10_w11_w12_we_1),
    .w20_w21_w22_we(w20_w21_w22_we_1),
    .i00_i01_i02_we(i00_i01_i02_we_1),
    .i10_i11_i12_we(i10_i11_i12_we_1),    
    .i20_i21_i22_we(i20_i21_i22_we_1),
    // .write_a(write_a_1),
    // .write_b(write_b_1),    
    // .write_c(write_c_1),        
    // .reset_systolic(reset_systolic_1),
    //.out_en(out_en_1),
    .final_add_out(out_1)
  
    /*.i00_we(i_00_we),
    .i01_i10_we(i01_i10_we),
    .i20_i11_i02we(i20_i11_i02_we),
    .i21_i12_we(i21_i12_we),
    .i22_we(i22_we),*/
    //data 
    /*
    input  logic  [15:0]      w1;
    input  logic  [15:0]      w2;

    input  logic  [15:0]      i1;
    input  logic  [15:0]      i2;
    input  logic  [15:0]      i3;
    input  logic  [15:0]      w00_in,w01_in,w02_in,w10_in,w11_in,w12_in,w02_in,w21_in,w22_in;
    input  logic              w00_w01_w02_we, w10_w11_w12_we, w20_w21_w22_we;
    */
);



systolicArray #(
    .WIDTH(IO_DATA_WIDTH)) 
    systolicArray_2(
    .clk(clk),
    .arst_n_in(arst_n_in),
    .data_in_1(a_input),
    .data_in_2(b_input),
    .data_in_3(c_input),
    // .data_in_1(a_1),
    // .data_in_2(b_1),
    // .data_in_3(c_1),
    .w00_w01_w02_we(w00_w01_w02_we_2),
    .w10_w11_w12_we(w10_w11_w12_we_2),
    .w20_w21_w22_we(w20_w21_w22_we_2),
    .i00_i01_i02_we(i00_i01_i02_we_2),
    .i10_i11_i12_we(i10_i11_i12_we_2),    
    .i20_i21_i22_we(i20_i21_i22_we_2),
    // .write_a(write_a_2),
    // .write_b(write_b_2),    
    // .write_c(write_c_2),    
    // .reset_systolic(reset_systolic_2),
    //.out_en(out_en_2),
    .final_add_out(out_2)

    /*.i00_we(i_00_we),
    .i01_i10_we(i01_i10_we),
    .i20_i11_i02we(i20_i11_i02_we),
    .i21_i12_we(i21_i12_we),
    .i22_we(i22_we),*/
    //data 
    /*
    input  logic  [15:0]      w1;
    input  logic  [15:0]      w2;

    input  logic  [15:0]      i1;
    input  logic  [15:0]      i2;
    input  logic  [15:0]      i3;
    input  logic  [15:0]      w00_in,w01_in,w02_in,w10_in,w11_in,w12_in,w02_in,w21_in,w22_in;
    input  logic              w00_w01_w02_we, w10_w11_w12_we, w20_w21_w22_we;
    */
);

/*
      FETCH: begin
        a_ready = 1;
        b_ready = 1;
        write_a = a_valid;
        write_b = b_valid;
        next_state = b_valid ? MAC : FETCH;
       end
      MAC: begin
        mac_valid = 1;
        next_state = last_overall ? IDLE : FETCH;
*/

assign out = out_final[15:0];


endmodule
