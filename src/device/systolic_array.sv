module systolicArray #(
    WIDTH = 16
    )(
    input  logic              clk,
    input  logic              arst_n_in, //asynchronous reset, active low
    
    input  logic [WIDTH-1:0]       data_in_1, data_in_2, data_in_3,
    //data 
    /*
    input  logic  [15:0]      w1;
    input  logic  [15:0]      w2;

    input  logic  [15:0]      i1;
    input  logic  [15:0]      i2;
    input  logic  [15:0]      i3;
    input  logic  [15:0]      w00_in,w01_in,w02_in,w10_in,w11_in,w12_in,w02_in,w21_in,w22_in;
    */
    input  logic              w00_w01_w02_we,
    input  logic              w10_w11_w12_we, 
    input  logic              w20_w21_w22_we,
    input  logic              i00_i01_i02_we,
    input  logic              i10_i11_i12_we,    
    input  logic              i20_i21_i22_we,
    // input  logic              write_a,
    // input  logic              write_b,
    // input  logic              write_c,    
    // input  logic              reset_systolic,
    
    //input logic              out_en,
    output logic  [WIDTH-1:0]      final_add_out

);
// logic [15:0] w00,w01,w02,w10,w11,w12,w02,w21,w22;
// logic [15:0] w00_next,w01_next,w02_next,w10_next,w11_next,w12_next,w02_next,w21_next,w22_next;
// logic w00_we,w01_we,w02_we,w10_we,w11_we,w12_we,w02_we,w21_we,w22_we;

// logic [15:0] i_0, i_1, i_2;
// logic [15:0] i_0_next, i_1_next, i_2_next;
// logic i_0_we, i_1_we, i_2_we;

//logic [OUT_WIDTH-1:0] o1,o2,o3;

`REG(WIDTH, w00);
`REG(WIDTH, w01);
`REG(WIDTH, w02);
`REG(WIDTH, w10);
`REG(WIDTH, w11);
`REG(WIDTH, w12);
`REG(WIDTH, w20);
`REG(WIDTH, w21);
`REG(WIDTH, w22);

//`REG(16, o1_1);
//`REG(16, o1_2);
//`REG(16, o2_1);

`REG(WIDTH, i00);
`REG(WIDTH, i01);
`REG(WIDTH, i02);

`REG(WIDTH, i10);
`REG(WIDTH, i11);
`REG(WIDTH, i12);

`REG(WIDTH, i20);
`REG(WIDTH, i21);
`REG(WIDTH, i22);

// `REG(16, forin00);
// `REG(16, forin01);
// `REG(16, forin10);
// `REG(16, forin11);
// `REG(16, forin20);
// `REG(16, forin21);

`REG(WIDTH, parsum00);
`REG(WIDTH, parsum01);
`REG(WIDTH, parsum02);
`REG(WIDTH, parsum10);
`REG(WIDTH, parsum11);
`REG(WIDTH, parsum12);
`REG(WIDTH, parsum20);
`REG(WIDTH, parsum21);
`REG(WIDTH, parsum22);

assign w00_next = data_in_1;
assign w01_next = data_in_2;
assign w02_next = data_in_3;
assign w10_next = data_in_1;
assign w11_next = data_in_2;
assign w12_next = data_in_3;
assign w20_next = data_in_1;
assign w21_next = data_in_2;
assign w22_next = data_in_3;

assign w00_we = w00_w01_w02_we;
assign w01_we = w00_w01_w02_we;
assign w02_we = w00_w01_w02_we;
assign w10_we = w10_w11_w12_we;
assign w11_we = w10_w11_w12_we;
assign w12_we = w10_w11_w12_we;
assign w20_we = w20_w21_w22_we;
assign w21_we = w20_w21_w22_we;
assign w22_we = w20_w21_w22_we;


assign i00_next = data_in_1;
assign i01_next = data_in_2;
assign i02_next = data_in_3;
assign i10_next = data_in_1;
assign i11_next = data_in_2;
assign i12_next = data_in_3;
assign i20_next = data_in_1;
assign i21_next = data_in_2;
assign i22_next = data_in_3;

assign i00_we = i00_i01_i02_we;
assign i01_we = i00_i01_i02_we;
assign i02_we = i00_i01_i02_we;
assign i10_we = i10_i11_i12_we;
assign i11_we = i10_i11_i12_we;
assign i12_we = i10_i11_i12_we;
assign i20_we = i20_i21_i22_we;
assign i21_we = i20_i21_i22_we;
assign i22_we = i20_i21_i22_we;




//assign o1_1_next = o1;
//assign o1_2_next = o1_1;
//assign o2_1_next = o2;



//assign o1_1_we = 1;
//assign o1_2_we = 1;
//assign o2_1_we = 1;
//assign acc_we = 1;




//assign forin00_we = 1;
//assign forin11_we = 1;
// assign forin01_we = 1;
// assign forin10_we = 1;
// assign forin20_we = 1;
// assign forin21_we = 1;

// Partial sums
assign parsum00_we = 1;
assign parsum01_we = 1;
assign parsum02_we = 1;
assign parsum10_we = 1;
assign parsum11_we = 1;
assign parsum12_we = 1;
assign parsum20_we = 1;
assign parsum21_we = 1;
assign parsum22_we = 1;

systolic_mac #(
    .WIDTH(WIDTH))
    sys_mac_00(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .weight_in(w00),  
        .in(i00),           
        .par_sum_prev(32'b0),   
        .par_sum(parsum00_next)   
    );

systolic_mac #(
    .WIDTH(WIDTH))

    sys_mac_01(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .weight_in(w01),
        .in(i01),
        .par_sum_prev(32'b0),
        .par_sum(parsum01_next)
    );

systolic_mac #(
    .WIDTH(WIDTH))

    sys_mac_02(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .weight_in(w02),
        .in(i02),
        .par_sum_prev(32'b0),
        .par_sum(parsum02_next)
    );

systolic_mac #(
    .WIDTH(WIDTH))

    sys_mac_10(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .weight_in(w10),
        .in(i10),
        .par_sum_prev(parsum00),
        .par_sum(parsum10_next)
);

systolic_mac #(
    .WIDTH(WIDTH))

    sys_mac_11(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .weight_in(w11),
        .in(i11),
        .par_sum_prev(parsum01),
        .par_sum(parsum11_next)
);


systolic_mac #(
    .WIDTH(WIDTH))

    sys_mac_12(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .weight_in(w12),
        .in(i12),
        .par_sum_prev(parsum02),
        .par_sum(parsum12_next)
);

systolic_mac #(
    .WIDTH(WIDTH))

    sys_mac_20(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .weight_in(w20),
        .in(i20),
        .par_sum_prev(parsum10),
        // .par_sum(o1_1_next),
        .par_sum(parsum20_next)
);

systolic_mac #(
    .WIDTH(WIDTH))

    sys_mac_21(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .weight_in(w21),
        .in(i21),
        .par_sum_prev(parsum11),
        // .par_sum(o2_1_next),
        .par_sum(parsum21_next)
);
systolic_mac #(
    .WIDTH(WIDTH))

    sys_mac_22(
        .clk(clk),
        .arst_n_in(arst_n_in),
        .weight_in(w22),
        .in(i22),
        .par_sum_prev(parsum12),
        // .par_sum(o3 ),
        .par_sum(parsum22_next)
);

// assign o1_1_next = parsum20;
// assign o2_1_next = parsum21;

`REG(16, add_result);
`REG(16, add_intermediate);
`REG(16, add_out);

assign add_intermediate_we = 1;

logic signed [15:0] addends [0:2]; 
assign addends[0] = parsum20;
assign addends[1] = parsum21;
assign addends[2] = parsum22;

assign add_out_we = 1;
// assign addends[3] = add_result;
//logic [OUT_WIDTH-1:0] add_out;


adder #( .A_WIDTH(WIDTH),
        .B_WIDTH(WIDTH),
        .OUT_WIDTH(WIDTH),
        .OUT_SCALE(0))
    add1
    (.a(parsum20),
        .b(parsum21),
        .out(add_intermediate_next));

adder #( .A_WIDTH(WIDTH),
        .B_WIDTH(WIDTH),
        .OUT_WIDTH(WIDTH),
        .OUT_SCALE(0))
    add2
    (.a(add_intermediate),
        .b(parsum22),
        .out(add_out_next));

/*
adder_tree #(

  .ADDEND_WIDTH(IN_WIDTH),               // width of the addends
  .OUT_SCALE(0),                   // by how many bits to downscale the output
  .OUT_WIDTH(IN_WIDTH),                  // the width of the output
  .NB_ADDENDS(3),                   // the number of addends to be summed
  .NB_LEVELS_IN_PIPELINE_STAGE(1)  // after every this amount of levels of the adder tree, pipeline registers are added
  ) adder_tree_1
  (
  .clk(clk), 
  .arst_n_in(arst_n_in), // both of these can be left open if NB_LEVELS_IN_PIPELINE_STAGE > ceil(log2(NB_ADDENDS)), as then there is no pipelining
  .addends(addends),
  .out(add_out)
);
*/

// assign add_result_next = reset_systolic ? 0 : add_out;
//assign add_result_we = (out_en | reset_systolic);

// assign final_add_out = add_result >>> 3;
assign final_add_out = add_out;


endmodule



// // OLD GEMM SYSTOLIC
// module systolicArray #(
//     IN_WIDTH = 16,
//     OUT_WIDTH = 32
// )(
//     input  logic              clk,
//     input  logic              arst_n_in, //asynchronous reset, active low
    
//     input  logic [IN_WIDTH-1:0]       data_in_1, data_in_2, data_in_3,
//     //data 
//     /*
//     input  logic  [15:0]      w1;
//     input  logic  [15:0]      w2;

//     input  logic  [15:0]      i1;
//     input  logic  [15:0]      i2;
//     input  logic  [15:0]      i3;
//     input  logic  [15:0]      w00_in,w01_in,w02_in,w10_in,w11_in,w12_in,w02_in,w21_in,w22_in;
//     */
//     input  logic              w00_w01_w02_we,
//     input  logic              w10_w11_w12_we, 
//     input  logic              w20_w21_w22_we,
//     input  logic              write_a,
//     input  logic              write_b,
//     input  logic              write_c,    
//     input  logic              reset_systolic,
    
//     input logic              out_en,
//     output logic  [OUT_WIDTH-1:0]      final_add_out

// );
// // logic [15:0] w00,w01,w02,w10,w11,w12,w02,w21,w22;
// // logic [15:0] w00_next,w01_next,w02_next,w10_next,w11_next,w12_next,w02_next,w21_next,w22_next;
// // logic w00_we,w01_we,w02_we,w10_we,w11_we,w12_we,w02_we,w21_we,w22_we;

// // logic [15:0] i_0, i_1, i_2;
// // logic [15:0] i_0_next, i_1_next, i_2_next;
// // logic i_0_we, i_1_we, i_2_we;

// logic [OUT_WIDTH-1:0] o1,o2,o3;

// `REG(16, w00);
// `REG(16, w01);
// `REG(16, w02);
// `REG(16, w10);
// `REG(16, w11);
// `REG(16, w12);
// `REG(16, w20);
// `REG(16, w21);
// `REG(16, w22);

// `REG(32, o1_1);
// `REG(32, o1_2);
// `REG(32, o2_1);

// `REG(16, i_0);
// `REG(16, i_1);
// `REG(16, i_2);

// `REG(16, forin00);
// `REG(16, forin01);
// `REG(16, forin10);
// `REG(16, forin11);
// `REG(16, forin20);
// `REG(16, forin21);

// `REG(32, parsum00);
// `REG(32, parsum01);
// `REG(32, parsum02);
// `REG(32, parsum10);
// `REG(32, parsum11);
// `REG(32, parsum12);
// `REG(32, parsum20);
// `REG(32, parsum21);
// `REG(32, parsum22);

// assign w00_next = data_in_1;
// assign w01_next = data_in_2;
// assign w02_next = data_in_3;
// assign w10_next = data_in_1;
// assign w11_next = data_in_2;
// assign w12_next = data_in_3;
// assign w20_next = data_in_1;
// assign w21_next = data_in_2;
// assign w22_next = data_in_3;

// assign w00_we = w00_w01_w02_we;
// assign w01_we = w00_w01_w02_we;
// assign w02_we = w00_w01_w02_we;
// assign w10_we = w10_w11_w12_we;
// assign w11_we = w10_w11_w12_we;
// assign w12_we = w10_w11_w12_we;
// assign w20_we = w20_w21_w22_we;
// assign w21_we = w20_w21_w22_we;
// assign w22_we = w20_w21_w22_we;


// assign i_0_next = data_in_1;
// assign i_1_next =  data_in_2;
// assign i_2_next =  data_in_3;

// assign i_0_we = 1;
// assign i_1_we = 1;
// assign i_2_we = 1;



// //assign o1_1_next = o1;
// assign o1_2_next = o1_1;
// //assign o2_1_next = o2;



// assign o1_1_we = 1;
// assign o1_2_we = 1;
// assign o2_1_we = 1;
// assign acc_we = 1;




// assign forin00_we = 1;
// assign forin11_we = 1;
// assign forin01_we = 1;
// assign forin10_we = 1;
// assign forin20_we = 1;
// assign forin21_we = 1;

// // Partial sums
// assign parsum00_we = 1;
// assign parsum01_we = 1;
// assign parsum02_we = 1;
// assign parsum10_we = 1;
// assign parsum11_we = 1;
// assign parsum12_we = 1;
// assign parsum20_we = 1;
// assign parsum21_we = 1;
// assign parsum22_we = 1;

// systolic_mac #(
//     .IN_WIDTH(IN_WIDTH),  //16
//     .OUT_WIDTH(OUT_WIDTH))  //32
//     sys_mac_00(
//         // WE STOPPED HERE
//         .clk(clk),
//         .arst_n_in(arst_n_in),
//         .weight_in(w00),   //16
//         .in(i_0),           //16
//         .par_sum_prev(32'b0),   //32
//         .par_sum(parsum00_next),     //32
//         .for_in(forin00_next)   //16
//     );

// systolic_mac #(
//     .IN_WIDTH(IN_WIDTH),
//     .OUT_WIDTH(OUT_WIDTH))
//     sys_mac_01(
//         // WE STOPPED HERE
//         .clk(clk),
//         .arst_n_in(arst_n_in),
//         .weight_in(w01),
//         .in(forin00),
//         .par_sum_prev(32'b0),
//         .par_sum(parsum01_next),
//         .for_in(forin01_next)
//     );

// systolic_mac #(
//     .IN_WIDTH(IN_WIDTH),
//     .OUT_WIDTH(OUT_WIDTH))
//     sys_mac_02(
//         // WE STOPPED HERE
//         .clk(clk),
//         .arst_n_in(arst_n_in),
//         .weight_in(w02),
//         .in(forin01),
//         .par_sum_prev(32'b0),
//         .par_sum(parsum02_next),
//         .for_in(forin02_next)
//     );

// systolic_mac #(
//     .IN_WIDTH(IN_WIDTH),
//     .OUT_WIDTH(OUT_WIDTH))
//     sys_mac_10(
//         .clk(clk),
//         .arst_n_in(arst_n_in),
//         .weight_in(w10),
//         .in(i_1),
//         .par_sum_prev(parsum00),
//         .par_sum(parsum10_next),
//         .for_in(forin10_next)
// );

// systolic_mac #(
//     .IN_WIDTH(IN_WIDTH),
//     .OUT_WIDTH(OUT_WIDTH))
//     sys_mac_11(
//         .clk(clk),
//         .arst_n_in(arst_n_in),
//         .weight_in(w11),
//         .in(forin10),
//         .par_sum_prev(parsum01),
//         .par_sum(parsum11_next),
//         .for_in(forin11_next)
// );


// systolic_mac #(
//     .IN_WIDTH(IN_WIDTH),
//     .OUT_WIDTH(OUT_WIDTH))
//     sys_mac_12(
//         .clk(clk),
//         .arst_n_in(arst_n_in),
//         .weight_in(w12),
//         .in(forin11),
//         .par_sum_prev(parsum02),
//         .par_sum(parsum12_next),
//         .for_in()
// );

// systolic_mac #(
//     .IN_WIDTH(IN_WIDTH),
//     .OUT_WIDTH(OUT_WIDTH))
//     sys_mac_20(
//         .clk(clk),
//         .arst_n_in(arst_n_in),
//         .weight_in(w20),
//         .in(i_2),
//         .par_sum_prev(parsum10),
//         // .par_sum(o1_1_next),
//         .par_sum(parsum20_next),
//         .for_in(forin20_next)
// );

// systolic_mac #(
//     .IN_WIDTH(IN_WIDTH),
//     .OUT_WIDTH(OUT_WIDTH))
//     sys_mac_21(
//         .clk(clk),
//         .arst_n_in(arst_n_in),
//         .weight_in(w21),
//         .in(forin20),
//         .par_sum_prev(parsum11),
//         // .par_sum(o2_1_next),
//         .par_sum(parsum21_next),
//         .for_in(forin21_next)
// );
// systolic_mac #(
//     .IN_WIDTH(IN_WIDTH),
//     .OUT_WIDTH(OUT_WIDTH))
//     sys_mac_22(
//         .clk(clk),
//         .arst_n_in(arst_n_in),
//         .weight_in(w22),
//         .in(forin21),
//         .par_sum_prev(parsum12),
//         // .par_sum(o3 ),
//         .par_sum(parsum22_next),
//         .for_in()
// );

// assign o1_1_next = parsum20;
// assign o2_1_next = parsum21;

// `REG(35, add_result);

// logic signed [31:0] addends [0:3]; 
// assign addends[0] = o1_2;
// assign addends[1] = o2_1;
// assign addends[2] = parsum22;
// assign addends[3] = add_result;
// logic [OUT_WIDTH-1:0] add_out;

// // adder_tree #(
// //   /*automatically generates an adder tree, possibly pipelined, to add more than two numbers together*/

// //   .ADDEND_WIDTH(OUT_WIDTH),               // width of the addends
// //   .OUT_SCALE(3),                   // by how many bits to downscale the output
// //   .OUT_WIDTH(OUT_WIDTH),                  // the width of the output
// //   .NB_ADDENDS(4),                   // the number of addends to be summed
// //   .NB_LEVELS_IN_PIPELINE_STAGE(0)  // after every this amount of levels of the adder tree, pipeline registers are added
// //   ) adder_tree_1
// //   (
// //   .clk(clk), 
// //   .arst_n_in(arst_n_in), // both of these can be left open if NB_LEVELS_IN_PIPELINE_STAGE > ceil(log2(NB_ADDENDS)), as then there is no pipelining
// //   .addends(addends),
// //   .out(add_out)
// // );

// adder_tree #(
//   /*automatically generates an adder tree, possibly pipelined, to add more than two numbers together*/

//   .ADDEND_WIDTH(OUT_WIDTH),               // width of the addends
//   .OUT_SCALE(0),                   // by how many bits to downscale the output
//   .OUT_WIDTH(OUT_WIDTH),                  // the width of the output
//   .NB_ADDENDS(4),                   // the number of addends to be summed
//   .NB_LEVELS_IN_PIPELINE_STAGE(0)  // after every this amount of levels of the adder tree, pipeline registers are added
//   ) adder_tree_1
//   (
//   .clk(clk), 
//   .arst_n_in(arst_n_in), // both of these can be left open if NB_LEVELS_IN_PIPELINE_STAGE > ceil(log2(NB_ADDENDS)), as then there is no pipelining
//   .addends(addends),
//   .out(add_out)
// );


// assign add_result_next = reset_systolic ? 0 : add_out;
// assign add_result_we = (out_en | reset_systolic);

// // assign final_add_out = add_result >>> 3;
// assign final_add_out = add_result;


// endmodule
