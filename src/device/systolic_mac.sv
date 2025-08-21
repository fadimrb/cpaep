module systolic_mac #(
    parameter int WIDTH = 16
)(
    input  logic              clk,
    input  logic              arst_n_in, //asynchronous reset, active low

    input logic [WIDTH-1:0] weight_in,
    input logic [WIDTH-1:0] in,
    input logic [WIDTH-1:0] par_sum_prev,
    output logic [WIDTH-1:0] par_sum
    //output logic [IN_WIDTH-1:0] for_in
);


//assign for_in = in;
logic [WIDTH-1:0] sum_result;


//logic [OUT_WIDTH-1:0] product;


`REG(16,product);
assign product_we = 1;

multiplier #(   .A_WIDTH(WIDTH),
                .B_WIDTH(WIDTH),
                .OUT_WIDTH(WIDTH),
                .OUT_SCALE(0))
    mul
    (.a(weight_in),
     .b(in),
     .out(product_next));

adder #( .A_WIDTH(WIDTH),
        .B_WIDTH(WIDTH),
        .OUT_WIDTH(WIDTH),
        .OUT_SCALE(0))
    add
    (.a(product),
        .b(par_sum_prev),
        .out(sum_result));

assign  par_sum = sum_result;

endmodule

