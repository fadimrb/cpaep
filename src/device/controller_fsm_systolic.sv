module controller_fsm_systolic #(
    parameter int LOG2_OF_MEM_HEIGHT = 20,
    parameter int FEATURE_MAP_WIDTH  = 1024,
    parameter int FEATURE_MAP_HEIGHT = 1024,
    parameter int INPUT_NB_CHANNELS  = 64,
    parameter int OUTPUT_NB_CHANNELS = 64,
    parameter int IO_DATA_WIDTH = 16
) (
    input logic clk,
    input logic arst_n_in, //asynchronous reset, active low

    input  logic start,
    output logic running,

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

    //memory control interface
    output logic mem_we,
    output logic [LOG2_OF_MEM_HEIGHT-1:0] mem_write_addr,
    output logic mem_re,
    output logic [LOG2_OF_MEM_HEIGHT-1:0] mem_read_addr,

    //datapad control interface & external handshaking communication of a and b
    input  logic a_valid,
    input  logic b_valid,
    output logic b_ready,
    output logic a_ready,
    // output logic write_a,
    // output logic write_b,
    output logic mac_valid,
    output logic mac_accumulate_internal,
    output logic mac_accumulate_with_0,

    // output logic write_a_1,
    // output logic write_b_1,
    // output logic write_c_1,
    // output logic write_a_2,
    // output logic write_b_2,
    // output logic write_c_2,
  

    
    input logic c_valid,
    output logic c_ready,

    output logic output_valid,
    output logic [32-1:0] output_x,
    output logic [32-1:0] output_y,
    output logic [32-1:0] output_ch,


    // output logic reset_systolic_1,
    // output logic reset_systolic_2,
    //output logic [IO_DATA_WIDTH-1:0] out,
    // output logic c_out_en,

    output logic out_en_1, out_en_2, final_out_en,

    output logic w00_w01_w02_we_1,w10_w11_w12_we_1,w20_w21_w22_we_1,
    output logic w00_w01_w02_we_2,w10_w11_w12_we_2,w20_w21_w22_we_2,

    output logic i00_i01_i02_we_1, i10_i11_i12_we_1, i20_i21_i22_we_1,
    output logic i00_i01_i02_we_2,i10_i11_i12_we_2, i20_i21_i22_we_2
);

  logic [2:0] conv_stride;
  assign conv_stride = 1 << conv_stride_mode;
  logic [2:0] conv_kernel;
  assign conv_kernel = (conv_kernel_mode << 1) + 1;

  //loop counters (see register.sv for macro)
  // `REG(32, k_v);
  // `REG(32, k_h);
  `REG(8, x);
  `REG(8, y);
  `REG(8, ch_in);
  `REG(8, ch_out);

  logic reset_k_v, reset_k_h;
  logic reset_x, reset_y, reset_ch_in, reset_ch_out;
  // assign k_v_next = reset_k_v ? 0 : k_v + 1;
  // assign k_h_next = reset_k_h ? 0 : k_h + 1;
  assign x_next = reset_x ? 0 : x + {5'b0, conv_stride};
  assign y_next = reset_y ? 0 : y + {5'b0, conv_stride};
  assign ch_in_next = reset_ch_in ? 0 : ch_in + 1;
  assign ch_out_next = reset_ch_out ? 0 : ch_out + 1;

  logic last_k_v, last_k_h;
  logic last_x, last_y, last_ch_in, last_ch_out;
  // assign last_k_v = k_v == {5'b0, conv_kernel} - 1;
  // assign last_k_h = k_h == {5'b0, conv_kernel} - 1;
  assign last_x = x >= FEATURE_MAP_WIDTH - conv_stride;
  assign last_y = y >= FEATURE_MAP_HEIGHT - conv_stride;
  assign last_ch_in = ch_in == INPUT_NB_CHANNELS - 1;
  assign last_ch_out = ch_out == OUTPUT_NB_CHANNELS - 1;

  // assign reset_k_v = last_k_v;
  // assign reset_k_h = last_k_h;
  assign reset_x = last_x;
  assign reset_y = last_y;
  assign reset_ch_in = last_ch_in;
  assign reset_ch_out = last_ch_out;

  /*
  chosen loop order:
  for x
    for y
      for ch_in
        for ch_out     (with this order, accumulations need to be kept because ch_out is inside ch_in)
          for k_v
            for k_h
              body
  */
  // ==>

/*
  assign k_h_we = mac_valid;  //each time a mac is done, k_h_we increments (or resets to 0 if last)
  assign k_v_we = mac_valid && last_k_h;  //only if last of k_h loop
  assign ch_out_we = mac_valid && last_k_h && last_k_v;  //only if last of all enclosed loops
  assign ch_in_we  = mac_valid && last_k_h && last_k_v && last_ch_out; //only if last of all enclosed loops
  assign y_we      = mac_valid && last_k_h && last_k_v && last_ch_out && last_ch_in; //only if last of all enclosed loops
  assign x_we      = mac_valid && last_k_h && last_k_v && last_ch_out && last_ch_in && last_y; //only if last of all enclosed loops
*/

//MODIFIED
//combing k_h_we and k_v_we so that they are elaborated by one signal k_h_v_we only
//ch_in_we is driven by the output availability of second systolic array.
  // ==>
  // assign k_h_we = mac_valid;  //each time a mac is done, k_h_we increments (or resets to 0 if last)
  // assign k_v_we = mac_valid && last_k_h;  //only if last of k_h loop
  // assign ch_out_we = mac_valid && last_k_h && last_k_v;  //only if last of all enclosed loops
  // assign ch_in_we  = mac_valid && last_k_h && last_k_v && last_ch_out; //only if last of all enclosed loops
  // assign y_we      = mac_valid && last_k_h && last_k_v && last_ch_out && last_ch_in; //only if last of all enclosed loops
  // assign x_we      = mac_valid && last_k_h && last_k_v && last_ch_out && last_ch_in && last_y; //only if last of all enclosed loops


  assign y_we = mac_valid ;
  assign x_we = mac_valid && last_y; 
  assign ch_out_we = mac_valid && last_x && last_y; 





  // assign last_overall = last_k_h && last_k_v && last_ch_out && last_ch_in && last_y && last_x;
  assign last_overall = last_ch_out && last_x && last_y;


  `REG(8, prev_ch_out);
  assign prev_ch_out_next        = ch_out;
  assign prev_ch_out_we          = ch_out_we;
  //given loop order, partial sums need be saved over input channels
  //assign mem_we                  = k_v == 0 && k_h == 0;
  //assign mem_write_addr          = prev_ch_out;

  //and loaded back
  //assign mem_re                  = k_v == 0 && k_h == 0;
  // assign mem_read_addr           = ch_out;

  //assign mac_accumulate_internal = !(k_v == 0 && k_h == 0);
  //assign mac_accumulate_with_0   = ch_in == 0 && k_v == 0 && k_h == 0;

  //mark outputs
  `REG(1, output_valid_reg);
  // assign output_valid_reg_next = mac_valid && last_ch_in && last_k_v && last_k_h;
  assign output_valid_reg_next = final_out_en;
  assign output_valid_reg_we = 1;
  assign output_valid = output_valid_reg;

  // The output address (x, y, ch) is retended by these registers
  register #(
      .WIDTH(8)
  ) output_x_r (
      .clk(clk),
      .arst_n_in(arst_n_in),
      .din(x),
      .qout(output_x),
      // .we(mac_valid && last_ch_in && last_k_v && last_k_h)
      .we(mac_valid)
  );
  register #(
      .WIDTH(8)
  ) output_y_r (
      .clk(clk),
      .arst_n_in(arst_n_in),
      .din(y),
      .qout(output_y),
      // .we(mac_valid && last_ch_in && last_k_v && last_k_h)
      .we(mac_valid)
  );
  register #(
      .WIDTH(8)
  ) output_ch_r (
      .clk(clk),
      .arst_n_in(arst_n_in),
      .din(ch_out),
      .qout(output_ch),
      // .we(mac_valid && last_ch_in && last_k_v && last_k_h)
      .we(mac_valid)
  );
  //mini fsm to loop over <fetch_a, fetch_b, acc>
  logic [3:0] ctr; 
  logic [3:0] ctr_next; 
  typedef enum {
    IDLE,
    FETCH_WEIGHTS_A,
    FETCH_WEIGHTS_B,
    DUMMY_CYCLE,
    FETCH_INPUTS,
    STORE_LAST_OUTPUT,
    STATE_END
  } fsm_state_e;

  fsm_state_e current_state;
  fsm_state_e next_state;
  always @(posedge clk or negedge arst_n_in) begin
    if (arst_n_in == 0) begin
      current_state <= IDLE;
      ctr <= 0;
    end else begin
      current_state <= next_state;
      ctr <= ctr_next;
    end
  end
  // logic  w00_w01_w02_we_1, w10_w11_w12_we_1, w20_w21_w22_we_1;
  // logic  w00_w01_w02_we_2, w10_w11_w12_we_2, w20_w21_w22_we_2;

  logic [3:0] counter_computation;
  always_comb begin
    //defaults: applicable if not overwritten below
    //write_a   = 0;
    //write_b   = 0;
    mac_valid = 0;
    running   = 1;
    //a_ready   = 0;
    //b_ready   = 0;
    //c_ready =
    //final_out_en = 0;

    case (current_state)
      IDLE: begin
        running = 0;
        ctr_next = 0;
        next_state = start ? FETCH_WEIGHTS_A : IDLE;
        //write_a_1 = 0;
        // write_b_1 = 0;
        // write_c_1 = 0;
        // write_a_2 = 0;
        // write_b_2 = 0;
        // write_c_2 = 0;     
        final_out_en = 0;
        i00_i01_i02_we_1 = 0;
        i10_i11_i12_we_1 = 0;
        i20_i21_i22_we_1 = 0;
        i00_i01_i02_we_2 = 0;
        i10_i11_i12_we_2 = 0;
        i20_i21_i22_we_2 = 0;
        w00_w01_w02_we_1 = 0;
        w10_w11_w12_we_1 = 0;
        w20_w21_w22_we_1 = 0;
        w00_w01_w02_we_2 = 0;
        w10_w11_w12_we_2 = 0;
        w20_w21_w22_we_2 = 0;
          
      end

      FETCH_WEIGHTS_A: begin
        
        final_out_en = 0;
        w00_w01_w02_we_1 = 0;
        w10_w11_w12_we_1 = 0;
        w20_w21_w22_we_1 = 0;
        case(ctr)
          0:  begin 
                w00_w01_w02_we_1 = 1; 
                a_ready = 1; 
                b_ready = 1; 
                c_ready = 1; 
              end
          1:  begin 
                w10_w11_w12_we_1 = 1; 
                a_ready = 1; 
                b_ready = 1; 
                c_ready = 1; 
              end
          2:  begin 
                w20_w21_w22_we_1 = 1; 
                a_ready = 1; 
                b_ready = 1; 
                c_ready = 1; 
              end              
        endcase
        //write_a = a_valid;
        next_state = (ctr == 2) ? FETCH_WEIGHTS_B : current_state;
        ctr_next = (ctr == 2) ? 0 : ctr + 1;
      end

      FETCH_WEIGHTS_B: begin
        final_out_en = 0;
        w00_w01_w02_we_1 = 0;
        w10_w11_w12_we_1 = 0;
        w20_w21_w22_we_1 = 0;

        case(ctr)
          0:  begin 
                w00_w01_w02_we_2 = 1; 
                w10_w11_w12_we_2 = 0; 
                w20_w21_w22_we_2 = 0; 
                a_ready = 1; 
                b_ready = 1; 
                c_ready = 1;

              end
          1:  begin 
                w00_w01_w02_we_2 = 0; 
                w10_w11_w12_we_2 = 1; 
                w20_w21_w22_we_2 = 0; 
                a_ready = 1; 
                b_ready = 1; 
                c_ready = 1; 
              end
          2:  begin 
                w00_w01_w02_we_2 = 0; 
                w10_w11_w12_we_2 = 0; 
                w20_w21_w22_we_2 = 1;  
                a_ready = 1; 
                b_ready = 1; 
                c_ready = 1; 

                final_out_en = (ch_out != 0) ? 1 : 0; 

              end        

        endcase
        //write_a = a_valid;
        next_state = (ctr == 2) ? DUMMY_CYCLE : current_state;
        ctr_next = (ctr == 2) ? 0 : ctr + 1;
        a_ready = 0;
        b_ready = 0;
        c_ready = 0;          
      end
      DUMMY_CYCLE: begin
        next_state =  FETCH_INPUTS;
        final_out_en =0;
        w00_w01_w02_we_1 = 0;
        w10_w11_w12_we_1 = 0;
        w20_w21_w22_we_1 = 0;

        w00_w01_w02_we_2 = 0;
        w10_w11_w12_we_2 = 0;
        w20_w21_w22_we_2 = 0;

        i00_i01_i02_we_1 = 0;
        i10_i11_i12_we_1 = 0;
        i20_i21_i22_we_1 = 0;
        i00_i01_i02_we_2 = 0;
        i10_i11_i12_we_2 = 0;
        i20_i21_i22_we_2 = 0;
      end
      FETCH_INPUTS: begin
        //input_en <= 1;
        final_out_en=0;
        w00_w01_w02_we_2 = 0; 
        w10_w11_w12_we_2 = 0; 
        w20_w21_w22_we_2 = 0; 
        case (ctr)
        0: begin
          a_ready = 1;
          b_ready = 1;
          c_ready = 1;
          i00_i01_i02_we_1 = 1;
          i10_i11_i12_we_1 = 0;
          i20_i21_i22_we_1 = 0;
          i00_i01_i02_we_2 = 0;
          i10_i11_i12_we_2 = 0;
          i20_i21_i22_we_2 = 0;
        end
        1: begin
          a_ready = 1;
          b_ready = 1;
          c_ready = 1;
          i00_i01_i02_we_1 = 0;
          i10_i11_i12_we_1 = 1;
          i20_i21_i22_we_1 = 0;
          i00_i01_i02_we_2 = 0;
          i10_i11_i12_we_2 = 0;
          i20_i21_i22_we_2 = 0;
        end
        2: begin
          a_ready = 1;
          b_ready = 1;
          c_ready = 1;
          i00_i01_i02_we_1 = 0;
          i10_i11_i12_we_1 = 0;
          i20_i21_i22_we_1 = 1;
          i00_i01_i02_we_2 = 0;
          i10_i11_i12_we_2 = 0;
          i20_i21_i22_we_2 = 0;
        end
        3: begin
          a_ready = 1;
          b_ready = 1;
          c_ready = 1;
          i00_i01_i02_we_1 = 0;
          i10_i11_i12_we_1 = 0;
          i20_i21_i22_we_1 = 0;
          i00_i01_i02_we_2 = 1;
          i10_i11_i12_we_2 = 0;
          i20_i21_i22_we_2 = 0;
        end
        4: begin
          a_ready = 1;
          b_ready = 1;
          c_ready = 1;
          i00_i01_i02_we_1 = 0;
          i10_i11_i12_we_1 = 0;
          i20_i21_i22_we_1 = 0;
          i00_i01_i02_we_2 = 0;
          i10_i11_i12_we_2 = 1;
          i20_i21_i22_we_2 = 0;
        end
      5: begin
          a_ready = 1;
          b_ready = 1;
          c_ready = 1;          
          i00_i01_i02_we_1 = 0;
          i10_i11_i12_we_1 = 0;
          i20_i21_i22_we_1 = 0;
          i00_i01_i02_we_2 = 0;
          i10_i11_i12_we_2 = 0;
          i20_i21_i22_we_2 = 1;
      end
        6: begin
          a_ready = 0;
          b_ready = 0;
          c_ready = 0;          
          i00_i01_i02_we_1 = 0;
          i10_i11_i12_we_1 = 0;
          i20_i21_i22_we_1 = 0;
          i00_i01_i02_we_2 = 0;
          i10_i11_i12_we_2 = 0;
          i20_i21_i22_we_2 = 0; 
        end
        

        // next_state = (ctr == 2) ? FETCH_INPUTS : FETCH_WEIGHTS
        endcase
        //next_state = ((ctr == 6) && (last_y && last_x) ? STORE_LAST_OUTPUT : current_state);
        next_state = ((ctr == 6) && (last_overall)) ? STORE_LAST_OUTPUT : (((ctr == 6) && (last_y && last_x)) ? FETCH_WEIGHTS_A : current_state);

        //output_acc = (ctr == 2 && (x != 0 || y != 0)) ? final_add_out : output_acc; //At CC7. But not the first cycle
        // reset_systolic_1 = (ctr == 6 && (x != 0 || y != 0)) ? 1 : 0;
        // reset_systolic_2 = (ctr == 6 && (x != 0 || y != 0)) ? 1 : 0;
        // reset_systolic_1 <= (ctr == 4) ? 1 : 0;
        // reset_systolic_2 <= (ctr == 4) ? 1 : 0;
        ctr_next = (ctr == 6) ? 0 : ctr + 1;
        mac_valid = (ctr == 6); 
        //k_h_v_next = (ctr == 10) ? 1 : 0; 

        //out_en_1 <= (ctr == 5) ? 1 : 0;
        //out_en_2 <= (ctr == 5) ? 1 : 0;
        // out_en_2 <= ((ctr >= 1 && ctr <= 3) && current_state == FETCH_INPUTS) ? 1 : 0;
        final_out_en = ((ctr == 5) && (x!=0 || y!=0)) ? 1 : 0; 
        // final_out_en <= 0; 
        // c_out_en <= (ctr == 3 ) ? 1 : 0;

        //next_state = b_valid ? MAC : FETCH_B;
      end

      STORE_LAST_OUTPUT: begin
        i00_i01_i02_we_1 = 0;
        i10_i11_i12_we_1 = 0;
        i20_i21_i22_we_1 = 0;
        i00_i01_i02_we_2 = 0;
        i10_i11_i12_we_2 = 0;
        i20_i21_i22_we_2 = 0;
        ctr_next = (ctr == 6) ? 0 : ctr + 1;
        final_out_en = (ctr == 5); 
        next_state = (ctr == 6) ? (last_overall ? STATE_END : FETCH_WEIGHTS_A) : current_state; 
      end

      STATE_END: begin
        next_state = STATE_END;
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end



// //GeMM
//  always_comb begin
//     //defaults: applicable if not overwritten below
//     write_a   = 0;
//     write_b   = 0;
//     mac_valid = 0;
//     running   = 1;
//     a_ready   = 0;
//     b_ready   = 0;
//     final_out_en = 0;

//     case (current_state)
//       IDLE: begin
//         running = 0;
//         ctr_next = 0;
//         next_state = start ? FETCH_WEIGHTS_A : IDLE;
//         write_a_1 = 0;
//         write_b_1 = 0;
//         write_c_1 = 0;
//         write_a_2 = 0;
//         write_b_2 = 0;
//         write_c_2 = 0;     
//         final_out_en = 0;
          
//       end

//       FETCH_WEIGHTS_A: begin
        
//         w00_w01_w02_we_1 = 0;
//         w10_w11_w12_we_1 = 0;
//         w20_w21_w22_we_1 = 0;
//         case(ctr)
//           0:  begin 
//                 w00_w01_w02_we_1 = 1; 
//                 a_ready = 1; 
//                 b_ready = 1; 
//                 c_ready = 1; 
//               end
//           1:  begin 
//                 w10_w11_w12_we_1 = 1; 
//                 a_ready = 1; 
//                 b_ready = 1; 
//                 c_ready = 1; 
//               end
//           2:  begin 
//                 w20_w21_w22_we_1 = 1; 
//                 a_ready = 1; 
//                 b_ready = 1; 
//                 c_ready = 1; 
//               end              
//         endcase
//         //write_a = a_valid;
//         next_state = (ctr == 2) ? FETCH_WEIGHTS_B : FETCH_WEIGHTS_A;
//         ctr_next = (ctr == 2) ? 0 : ctr + 1;
//       end

//       FETCH_WEIGHTS_B: begin
//         w00_w01_w02_we_1 = 0;
//         w10_w11_w12_we_1 = 0;
//         w20_w21_w22_we_1 = 0;

//         case(ctr)
//           0:  begin 
//                 w00_w01_w02_we_2 = 1; 
//                 w10_w11_w12_we_2 = 0; 
//                 w20_w21_w22_we_2 = 0; 
//                 a_ready = 1; 
//                 b_ready = 1; 
//                 c_ready = 1;
//               end
//           1:  begin 
//                 w00_w01_w02_we_2 = 0; 
//                 w10_w11_w12_we_2 = 1; 
//                 w20_w21_w22_we_2 = 0; 
//                 a_ready = 1; 
//                 b_ready = 1; 
//                 c_ready = 1; 
//               end
//           2:  begin 
//                 w00_w01_w02_we_2 = 0; 
//                 w10_w11_w12_we_2 = 0; 
//                 w20_w21_w22_we_2 = 1;  
//                 a_ready = 1; 
//                 b_ready = 1; 
//                 c_ready = 1; 
//               end        
//         endcase
//         //write_a = a_valid;
//         next_state = (ctr == 2) ? FETCH_INPUTS : FETCH_WEIGHTS_B;
//         ctr_next = (ctr == 2) ? 0 : ctr + 1;
//       end

//       FETCH_INPUTS: begin
//         //input_en <= 1;
//         w00_w01_w02_we_2 = 0; 
//         w10_w11_w12_we_2 = 0; 
//         w20_w21_w22_we_2 = 0; 
//         case (ctr)
//         0: begin
//           a_ready = 1;
//           b_ready = 0;
//           c_ready = 0;
//           write_a_1 = a_valid; //i00
//           write_b_1 = 0;
//           write_c_1 = 0;
//           write_a_2 = 0;
//           write_b_2 = 0;
//           write_c_2 = 0;
//         end
//         1: begin
//           a_ready = 1;
//           b_ready = 1;
//           c_ready = 0;
//           write_a_1 = a_valid; //i10
//           write_b_1 = b_valid; //i01
//           write_c_1 = 0;          
//           write_a_2 = 0;
//           write_b_2 = 0;
//           write_c_2 = 0;
//         end
//         2: begin
//           a_ready = 1;
//           b_ready = 1;
//           c_ready = 1;
//           write_a_1 = a_valid; //i20
//           write_b_1 = b_valid; //i11
//           write_c_1 = c_valid; //i02
//           write_a_2 = 0;
//           write_b_2 = 0;
//           write_c_2 = 0;
//         end
//         3: begin
//           a_ready = 0;
//           b_ready = 1;
//           c_ready = 1;
//           write_a_1 = 0;
//           write_b_1 = b_valid; //i12  
//           write_c_1 = c_valid; //i21
//           write_a_2 = 0;
//           write_b_2 = 0;
//           write_c_2 = 0;
//         end
//         4: begin
//           a_ready = 0;
//           b_ready = 0;
//           c_ready = 1;
//           write_a_1 = 0;
//           write_b_1 = 0;
//           write_c_1 = c_valid; //i22
//           write_a_2 = 0;
//           write_b_2 = 0;
//           write_c_2 = 0;
//         end
//         5: begin
//           a_ready = 1;
//           b_ready = 0;
//           c_ready = 0;          
//           write_a_2 = a_valid; //i00
//           write_b_2 = 0;
//           write_c_2 = 0;
//           write_a_1 = 0;
//           write_b_1 = 0;
//           write_c_1 = 0;
//         end
//         6: begin
//           a_ready = 1;
//           b_ready = 1;
//           c_ready = 0;          
//           write_a_2 = a_valid; //i10
//           write_b_2 = b_valid; //i01
//           write_c_2 = 0;          
//           write_a_1 = 0;
//           write_b_1 = 0;
//           write_c_1 = 0;
//         end
//         7: begin
//           a_ready = 1;
//           b_ready = 1;
//           c_ready = 1;          
//           write_a_2 = a_valid; //i200          
//           write_b_2 = b_valid; //i11
//           write_c_2 = c_valid; //i02
//           write_a_1 = 0;
//           write_b_1 = 0;
//           write_c_1 = 0;
//         end
//         8: begin
//           a_ready = 0;
//           b_ready = 0;
//           c_ready = 1;          
//           write_a_2 = 0;
//           write_b_2 = b_valid; //i12  
//           write_c_2 = c_valid; //i21
//           write_a_1 = 0;
//           write_b_1 = 0;
//           write_c_1 = 0;

//         end
//         9: begin
//           a_ready = 0;
//           b_ready = 0;
//           c_ready = 1;          
//           write_a_2 = 0;
//           write_b_2 = 0;
//           write_c_2 = c_valid; //i22
//           write_a_1 = 0;
//           write_b_1 = 0;
//           write_c_1 = 0;

//         end

//         // next_state = (ctr == 2) ? FETCH_INPUTS : FETCH_WEIGHTS
//         endcase
//         next_state = (ctr == 9) && (last_y && last_x) ? FETCH_WEIGHTS_A : FETCH_INPUTS;
//         next_state = ((ctr == 9) && last_overall ) ? STATE_END : FETCH_INPUTS;
//         //output_acc = (ctr == 2 && (x != 0 || y != 0)) ? final_add_out : output_acc; //At CC7. But not the first cycle
//         reset_systolic_1 = (ctr == 4 && (x != 0 || y != 0)) ? 1 : 0;
//         reset_systolic_2 = (ctr == 4 && (x != 0 || y != 0)) ? 1 : 0;
//         // reset_systolic_1 <= (ctr == 4) ? 1 : 0;
//         // reset_systolic_2 <= (ctr == 4) ? 1 : 0;
//         ctr_next <= (ctr == 9) ? 0 : ctr + 1;
//         mac_valid <= (ctr == 9); 
//         //k_h_v_next = (ctr == 10) ? 1 : 0; 

//         out_en_1 <= (ctr >= 6 && ctr <= 8) ? 1 : 0;
//         out_en_2 <= ((ctr >= 1 && ctr <= 3) && (x != 0 || y != 0)) ? 1 : 0;
//         // out_en_2 <= ((ctr >= 1 && ctr <= 3) && current_state == FETCH_INPUTS) ? 1 : 0;
//         final_out_en <= (ctr == 4 && (x != 0 || y != 0)) ? 1 : 0; 
//         // final_out_en <= 0; 
//         // c_out_en <= (ctr == 3 ) ? 1 : 0;

//         //next_state = b_valid ? MAC : FETCH_B;
//       end
//       STATE_END: begin
//         next_state = STATE_END;
//       end
//       default: begin
//         next_state = IDLE;
//       end
//     endcase
//   end  
endmodule