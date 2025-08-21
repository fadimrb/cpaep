class Driver #(
    config_t cfg
);

  virtual intf #(cfg) intf_i;

  mailbox #(Transaction_Feature #(cfg)) gen2drv_feature;
  mailbox #(Transaction_Kernel #(cfg)) gen2drv_kernel;

  function new(virtual intf #(cfg) i, mailbox#(Transaction_Feature#(cfg)) g2d_feature,
               mailbox#(Transaction_Kernel#(cfg)) g2d_kernel);
    intf_i = i;
    gen2drv_feature = g2d_feature;
    gen2drv_kernel = g2d_kernel;
  endfunction : new

  task reset;
    $display("[DRV] ----- Reset Started -----");
    //asynchronous start of reset
    intf_i.cb.start <= 0;
    intf_i.cb.conv_kernel_mode <= 0;
    intf_i.cb.conv_stride_mode <= 0;
    intf_i.cb.a_valid <= 0;
    intf_i.cb.b_valid <= 0;
    intf_i.cb.c_valid <= 0;
    intf_i.cb.arst_n <= 0;
    repeat (2) @(intf_i.cb);
    intf_i.cb.arst_n <= 1;  //synchronous release of reset
    repeat (2) @(intf_i.cb);
    $display("[DRV] -----  Reset Ended  -----");
  endtask


  task run();
    // Get a transaction with kernel from the Generator
    // Kernel remains same throughput the verification
    Transaction_Kernel #(cfg) tract_kernel;
    gen2drv_kernel.get(tract_kernel);

    $display("[DRV] -----  Start execution -----");
     

    forever begin
      time starttime;
      // Get a transaction with feature from the Generator
      Transaction_Feature #(cfg) tract_feature;
      gen2drv_feature.get(tract_feature);
      $display("[DRV] Programming configuration bits");
      intf_i.cb.conv_kernel_mode <= (cfg.KERNEL_SIZE - 1) / 2;
      intf_i.cb.conv_stride_mode <= $clog2(cfg.CONV_STEP);

      $display("[DRV] Giving start signal");
      intf_i.cb.start <= 1;
      starttime = $time();
      // intf_i.cb.a_valid <= 1;
      // intf_i.cb.b_valid <= 1;
      // intf_i.cb.c_valid <= 1;
      @(intf_i.cb);

      intf_i.cb.start <= 0;
      for (int outch = 0; outch < cfg.OUTPUT_NB_CHANNELS; outch++) begin
        for (int inch_w = 0; inch_w < cfg.INPUT_NB_CHANNELS; inch_w++) begin
          for (int cycle_count_w = 0; cycle_count_w < 3; cycle_count_w = cycle_count_w + 1) begin 
            intf_i.cb.a_valid <= 1;
            intf_i.cb.b_valid <= 1;
            intf_i.cb.c_valid <= 1;
            // $display("[DRV][WEIGHTS] cycle count loop first line");
            //assert (!$isunknown(tract_kernel.kernel[cycle_count_w][0][inch_w][outch]));
            intf_i.cb.a_input <= tract_kernel.kernel[cycle_count_w][0][inch_w][outch];
            intf_i.cb.b_input <= tract_kernel.kernel[cycle_count_w][1][inch_w][outch];
            intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : tract_kernel.kernel[cycle_count_w][2][inch_w][outch];
            // intf_i.cb.c_input_output <= intf_i.c_valid ? 1 : 'bz;//tract_kernel.kernel[cycle_count_w][2][inch_w][outch];

            @(intf_i.cb);

            // @(intf_i.cb iff intf_i.cb.a_ready);
            //   intf_i.cb.a_valid <= 0;
            // @(intf_i.cb iff intf_i.cb.b_ready);
            //   intf_i.cb.b_valid <= 0;
            // @(intf_i.cb iff intf_i.cb.c_ready);
            //   intf_i.cb.c_valid <= 0;
            // $display("[DRV][WEIGHTS] cycle count loop last line");

          end
        end
        //DUMMY CYCLE
        intf_i.cb.a_valid <= 0;
        intf_i.cb.b_valid <= 0;
        intf_i.cb.c_valid <= 0;
        intf_i.cb.a_input <= 0;
        intf_i.cb.b_input <= 0;
        intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 0;
        
        @(intf_i.cb);
        for (int x = 0; x < cfg.FEATURE_MAP_WIDTH; x = x + cfg.CONV_STEP) begin
          for (int y = 0; y < cfg.FEATURE_MAP_HEIGHT; y = y + cfg.CONV_STEP) begin
            //for (int inch = 0; inch < cfg.INPUT_NB_CHANNELS; inch++) begin
              for (int cycle_count = 0; cycle_count < 7; cycle_count = cycle_count + 1) begin 
                //$display("[DRV][Inputs] cycle count loop first line");
                intf_i.cb.a_valid <= (cycle_count == 6) ? 0 :1;
                intf_i.cb.b_valid <= (cycle_count == 6) ? 0 :1;
                intf_i.cb.c_valid <= (cycle_count == 6) ? 0 :1;

                case(cycle_count)
                  0: begin 
                    
                    intf_i.cb.a_input <= (x-1 < 0 || y-1 < 0) ? 0 : tract_feature.inputs[y-1][x-1][0];  //00
                    intf_i.cb.b_input <= (y-1 < 0) ? 0 : tract_feature.inputs[y-1][x][0];  //01
                    intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH || y-1 < 0) ? 0 : tract_feature.inputs[y-1][x+1][0]; //02
                  end 

                  1: begin 
                    intf_i.cb.a_input <= (x-1 < 0) ? 0 : tract_feature.inputs[y][x-1][0]; //10
                    intf_i.cb.b_input <= tract_feature.inputs[y][x][0]; //11
                    intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH) ? 0 : tract_feature.inputs[y][x+1][0];  //12
                  end 

                  2: begin 
                    intf_i.cb.a_input <= (x-1 < 0 || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 :  tract_feature.inputs[y+1][x-1][0];  //20
                    intf_i.cb.b_input <= (y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x][0]; //11
                    intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x+1][0]; //02
                  end

                  3: begin 

                    intf_i.cb.a_input <= (x-1 < 0 || y-1 < 0) ? 0 : tract_feature.inputs[y-1][x-1][1];  //00
                    intf_i.cb.b_input <= (y-1 < 0) ? 0 : tract_feature.inputs[y-1][x][1];  //01
                    intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH || y-1 < 0) ? 0 : tract_feature.inputs[y-1][x+1][1]; //02
                  end 

                  4: begin 
                    intf_i.cb.a_input <= (x-1 < 0) ? 0 : tract_feature.inputs[y][x-1][1]; //10
                    intf_i.cb.b_input <= tract_feature.inputs[y][x][1]; //11
                    intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH) ? 0 : tract_feature.inputs[y][x+1][1];  //12
                  end 

                  5: begin 
                    intf_i.cb.a_input <= (x-1 < 0 || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x-1][1];  //20
                    intf_i.cb.b_input <= (y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x][1]; //11
                    intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x+1][1]; //02
                  end
                  6: begin 
                    intf_i.cb.a_input <= 0;
                    intf_i.cb.b_input <=  0;
                    intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 0;
                  end
                endcase
                //  $display("Storing inputs for x = %d; y = %d", x, y);
                //  $display("Sent inputs on cycle %d: A = %d ; B = %d ; C = %d", cycle_count, intf_i.cb.a_input, intf_i.cb.b_input, intf_i.cb.c_input_output);

  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH) ? 0 : tract_feature.inputs[y][x+1][inch];  //12
                // @(intf_i.cb iff intf_i.cb.a_ready);
                //   intf_i.cb.a_valid <= 0;
                // @(intf_i.cb iff intf_i.cb.b_ready);
                //   intf_i.cb.b_valid <= 0;
                // //@(intf_i.cb iff intf_i.cb.c_ready);
                // @(intf_i.cb iff !intf_i.cb.c_ready);
                //   intf_i.cb.c_valid <= 0;
                @(intf_i.cb);

                //$display("[DRV][Inputs] cycle count loop last line");

              end
              // intf_i.cb.a_input <= 0;//(x-1 < 0 || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x-1][inch];  //20
              // intf_i.cb.b_input <= 0;//tract_feature.inputs[y][x][inch]; //11
              // intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 0;//(x+1 >= cfg.FEATURE_MAP_WIDTH || y-1 < 0) ? 0 : tract_feature.inputs[y-1][x+1][inch]; //02
   
              // @(intf_i.cb);

            end
          //end 
        end 
        // for(int stall_count = 0; stall_count <= 3; stall_count++) begin 
        //   intf_i.cb.a_valid <= 0;
        //   intf_i.cb.b_valid <= 0;
        //   intf_i.cb.c_valid <= 0;
        //   intf_i.cb.a_input <= 0;
        //   intf_i.cb.b_input <=  0;
        //   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 0;
          // $display("Stall count %d", stall_count);
        //end
      end
      @(intf_i.cb);



  // task run();
  //   // Get a transaction with kernel from the Generator
  //   // Kernel remains same throughput the verification
  //   Transaction_Kernel #(cfg) tract_kernel;
  //   gen2drv_kernel.get(tract_kernel);

  //   $display("[DRV] -----  Start execution -----");
     

  //   forever begin
  //     time starttime;
  //     // Get a transaction with feature from the Generator
  //     Transaction_Feature #(cfg) tract_feature;
  //     gen2drv_feature.get(tract_feature);
  //     $display("[DRV] Programming configuration bits");
  //     intf_i.cb.conv_kernel_mode <= (cfg.KERNEL_SIZE - 1) / 2;
  //     intf_i.cb.conv_stride_mode <= $clog2(cfg.CONV_STEP);

  //     $display("[DRV] Giving start signal");
  //     intf_i.cb.start <= 1;
  //     starttime = $time();
  //     // intf_i.cb.a_valid <= 1;
  //     // intf_i.cb.b_valid <= 1;
  //     // intf_i.cb.c_valid <= 1;
  //     @(intf_i.cb);

  //     intf_i.cb.start <= 0;
  //     for (int outch = 0; outch < cfg.OUTPUT_NB_CHANNELS; outch++) begin
  //       for (int inch_w = 0; inch_w < cfg.INPUT_NB_CHANNELS; inch_w++) begin
  //         for (int cycle_count_w = 0; cycle_count_w < 3; cycle_count_w = cycle_count_w + 1) begin 
  //           intf_i.cb.a_valid <= 1;
  //           intf_i.cb.b_valid <= 1;
  //           intf_i.cb.c_valid <= 1;
  //           // $display("[DRV][WEIGHTS] cycle count loop first line");
  //           //assert (!$isunknown(tract_kernel.kernel[cycle_count_w][0][inch_w][outch]));
  //           intf_i.cb.a_input <= 1;//tract_kernel.kernel[cycle_count_w][0][inch_w][outch];
  //           intf_i.cb.b_input <= 2;//tract_kernel.kernel[cycle_count_w][1][inch_w][outch];
  //           intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 3;//tract_kernel.kernel[cycle_count_w][2][inch_w][outch];
  //           // intf_i.cb.c_input_output <= intf_i.c_valid ? 1 : 'bz;//tract_kernel.kernel[cycle_count_w][2][inch_w][outch];

  //           @(intf_i.cb);

  //           // @(intf_i.cb iff intf_i.cb.a_ready);
  //           //   intf_i.cb.a_valid <= 0;
  //           // @(intf_i.cb iff intf_i.cb.b_ready);
  //           //   intf_i.cb.b_valid <= 0;
  //           // @(intf_i.cb iff intf_i.cb.c_ready);
  //           //   intf_i.cb.c_valid <= 0;
  //           // $display("[DRV][WEIGHTS] cycle count loop last line");

  //         end
  //       end
  //       for (int x = 0; x < cfg.FEATURE_MAP_WIDTH; x = x + cfg.CONV_STEP) begin
  //         for (int y = 0; y < cfg.FEATURE_MAP_HEIGHT; y = y + cfg.CONV_STEP) begin
  //           //for (int inch = 0; inch < cfg.INPUT_NB_CHANNELS; inch++) begin
  //             for (int cycle_count = 0; cycle_count < 7; cycle_count = cycle_count + 1) begin 
  //               //$display("[DRV][Inputs] cycle count loop first line");
  //               intf_i.cb.a_valid <= (cycle_count == 3) ? 0 :1;
  //               intf_i.cb.b_valid <= (cycle_count == 3) ? 0 :1;
  //               intf_i.cb.c_valid <= (cycle_count == 3) ? 0 :1;

  //               case(cycle_count)
  //                 0: begin 
                    
  //                   intf_i.cb.a_input <= (x-1 < 0 || y-1 < 0) ? 0 : 1;//tract_feature.inputs[y-1][x-1][0];  //00
  //                   intf_i.cb.b_input <= (y-1 < 0) ? 0 : 2;//tract_feature.inputs[y-1][x][0];  //01
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH || y-1 < 0) ? 0 : 3;//tract_feature.inputs[y-1][x+1][0]; //02
  //                 end 

  //                 1: begin 
  //                   intf_i.cb.a_input <= (x-1 < 0) ? 0 : 4;//tract_feature.inputs[y][x-1][0]; //10
  //                   intf_i.cb.b_input <= 5;//tract_feature.inputs[y][x][0]; //11
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH) ? 0 : 6;//tract_feature.inputs[y][x+1][0];  //12
  //                 end 

  //                 2: begin 
  //                   intf_i.cb.a_input <= (x-1 < 0 || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : 7;// tract_feature.inputs[y+1][x-1][0];  //20
  //                   intf_i.cb.b_input <= (y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : 8;//tract_feature.inputs[y+1][x][0]; //11
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : 9;//tract_feature.inputs[y+1][x+1][0]; //02
  //                 end
  //                 3: begin 
  //                   intf_i.cb.a_input <= 0;
  //                   intf_i.cb.b_input <=  0;
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 0;
  //                 end
  //                 4: begin 

  //                   intf_i.cb.a_input <= (x-1 < 0 || y-1 < 0) ? 0 : 1;//tract_feature.inputs[y-1][x-1][1];  //00
  //                   intf_i.cb.b_input <= (y-1 < 0) ? 0 : 2;//tract_feature.inputs[y-1][x][1];  //01
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 3;//(x+1 >= cfg.FEATURE_MAP_WIDTH || y-1 < 0) ? 0 : tract_feature.inputs[y-1][x+1][1]; //02
  //                 end 

  //                 5: begin 
  //                   intf_i.cb.a_input <= (x-1 < 0) ? 0 : 4;//tract_feature.inputs[y][x-1][1]; //10
  //                   intf_i.cb.b_input <= 5;//tract_feature.inputs[y][x][1]; //11
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH) ? 0 : 6;//tract_feature.inputs[y][x+1][1];  //12
  //                 end 

  //                 6: begin 
  //                   intf_i.cb.a_input <= (x-1 < 0 || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : 7;//tract_feature.inputs[y+1][x-1][1];  //20
  //                   intf_i.cb.b_input <= (y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : 8;//tract_feature.inputs[y+1][x][1]; //11
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : 9;//tract_feature.inputs[y+1][x+1][1]; //02
  //                 end
  //               endcase
  //               //  $display("Storing inputs for x = %d; y = %d", x, y);
  //               //  $display("Sent inputs on cycle %d: A = %d ; B = %d ; C = %d", cycle_count, intf_i.cb.a_input, intf_i.cb.b_input, intf_i.cb.c_input_output);

  // //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH) ? 0 : tract_feature.inputs[y][x+1][inch];  //12
  //               // @(intf_i.cb iff intf_i.cb.a_ready);
  //               //   intf_i.cb.a_valid <= 0;
  //               // @(intf_i.cb iff intf_i.cb.b_ready);
  //               //   intf_i.cb.b_valid <= 0;
  //               // //@(intf_i.cb iff intf_i.cb.c_ready);
  //               // @(intf_i.cb iff !intf_i.cb.c_ready);
  //               //   intf_i.cb.c_valid <= 0;
  //               @(intf_i.cb);

  //               //$display("[DRV][Inputs] cycle count loop last line");

  //             end
  //             // intf_i.cb.a_input <= 0;//(x-1 < 0 || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x-1][inch];  //20
  //             // intf_i.cb.b_input <= 0;//tract_feature.inputs[y][x][inch]; //11
  //             // intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 0;//(x+1 >= cfg.FEATURE_MAP_WIDTH || y-1 < 0) ? 0 : tract_feature.inputs[y-1][x+1][inch]; //02
   
  //             // @(intf_i.cb);

  //           end
  //         //end 
  //       end 
  //       for(int stall_count = 0; stall_count <= 3; stall_count++) begin 
  //         intf_i.cb.a_valid <= 0;
  //         intf_i.cb.b_valid <= 0;
  //         intf_i.cb.c_valid <= 0;
  //         intf_i.cb.a_input <= 0;
  //         intf_i.cb.b_input <=  0;
  //         intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 0;
  //         // $display("Stall count %d", stall_count);
  //         @(intf_i.cb);
  //       end
  //     end


      // GEMM


  // task run();
  //   // Get a transaction with kernel from the Generator
  //   // Kernel remains same throughput the verification
  //   Transaction_Kernel #(cfg) tract_kernel;
  //   gen2drv_kernel.get(tract_kernel);

  //   $display("[DRV] -----  Start execution -----");
     

  //   forever begin
  //     time starttime;
  //     // Get a transaction with feature from the Generator
  //     Transaction_Feature #(cfg) tract_feature;
  //     gen2drv_feature.get(tract_feature);
  //     $display("[DRV] Programming configuration bits");
  //     intf_i.cb.conv_kernel_mode <= (cfg.KERNEL_SIZE - 1) / 2;
  //     intf_i.cb.conv_stride_mode <= $clog2(cfg.CONV_STEP);

  //     $display("[DRV] Giving start signal");
  //     intf_i.cb.start <= 1;
  //     starttime = $time();
  //     // intf_i.cb.a_valid <= 1;
  //     // intf_i.cb.b_valid <= 1;
  //     // intf_i.cb.c_valid <= 1;
  //     @(intf_i.cb);

  //     intf_i.cb.start <= 0;
  //     for (int outch = 0; outch < cfg.OUTPUT_NB_CHANNELS; outch++) begin
  //       for (int inch_w = 0; inch_w < cfg.INPUT_NB_CHANNELS; inch_w++) begin
  //         for (int cycle_count_w = 0; cycle_count_w < 3; cycle_count_w = cycle_count_w + 1) begin 
  //           intf_i.cb.a_valid <= 1;
  //           intf_i.cb.b_valid <= 1;
  //           intf_i.cb.c_valid <= 1;
  //           // $display("[DRV][WEIGHTS] cycle count loop first line");
  //           //assert (!$isunknown(tract_kernel.kernel[cycle_count_w][0][inch_w][outch]));
  //           intf_i.cb.a_input <= tract_kernel.kernel[cycle_count_w][0][inch_w][outch];
  //           intf_i.cb.b_input <= tract_kernel.kernel[cycle_count_w][1][inch_w][outch];
  //           // intf_i.cb.c_input_output <= intf_i.c_valid ? 1 : 'bz;//tract_kernel.kernel[cycle_count_w][2][inch_w][outch];
  //           intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : tract_kernel.kernel[cycle_count_w][2][inch_w][outch];
            
  //           @(intf_i.cb);

  //           // @(intf_i.cb iff intf_i.cb.a_ready);
  //           //   intf_i.cb.a_valid <= 0;
  //           // @(intf_i.cb iff intf_i.cb.b_ready);
  //           //   intf_i.cb.b_valid <= 0;
  //           // @(intf_i.cb iff intf_i.cb.c_ready);
  //           //   intf_i.cb.c_valid <= 0;
  //           // $display("[DRV][WEIGHTS] cycle count loop last line");

  //         end
  //       end
  //       for (int x = 0; x < cfg.FEATURE_MAP_WIDTH; x = x + cfg.CONV_STEP) begin
  //         for (int y = 0; y < cfg.FEATURE_MAP_HEIGHT; y = y + cfg.CONV_STEP) begin
  //           for (int inch = 0; inch < cfg.INPUT_NB_CHANNELS; inch++) begin
  //             for (int cycle_count = 0; cycle_count < 5; cycle_count = cycle_count + 1) begin 
  //               //$display("[DRV][Inputs] cycle count loop first line");

  //               intf_i.cb.a_valid <= 1;
  //               intf_i.cb.b_valid <= 1;
  //               intf_i.cb.c_valid <= 1;

  //               case(cycle_count)
  //                 0: begin 

  //                   intf_i.cb.a_input <= (x-1 < 0 || y-1 < 0) ? 0 : tract_feature.inputs[y-1][x-1][inch];  //00
  //                   intf_i.cb.b_input <= 0;
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : 0;
  //                 end 

  //                 1: begin 
  //                   intf_i.cb.a_input <= (x-1 < 0) ? 0 : tract_feature.inputs[y][x-1][inch]; //10
  //                   intf_i.cb.b_input <= (y-1 < 0) ? 0 : tract_feature.inputs[y-1][x][inch];  //01
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH && y-1 < 0) ? 0 :tract_feature.inputs[y-1][x+1][inch];

  //                 end 

  //                 2: begin 
  //                   intf_i.cb.a_input <= (x-1 < 0 || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x-1][inch];  //20
  //                   intf_i.cb.b_input <= tract_feature.inputs[y][x][inch]; //11
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH || y-1 < 0) ? 0 : tract_feature.inputs[y-1][x+1][inch]; //02
  //                 end 

  //                 3: begin 
  //                   intf_i.cb.a_input <= 0;
  //                   intf_i.cb.b_input <= (y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x][inch];  //21
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH) ? 0 : tract_feature.inputs[y][x+1][inch];  //12
  //                 end 

  //                 4: begin  
  //                   intf_i.cb.a_input <= 0;
  //                   intf_i.cb.b_input <= 0;
  //                   intf_i.cb.c_input_output <= intf_i.output_valid ? 'bz : (x+1 >= cfg.FEATURE_MAP_WIDTH || y+1 >= cfg.FEATURE_MAP_HEIGHT) ? 0 : tract_feature.inputs[y+1][x+1][inch]; //22
  //                 end 
  //               endcase
  //               // @(intf_i.cb iff intf_i.cb.a_ready);
  //               //   intf_i.cb.a_valid <= 0;
  //               // @(intf_i.cb iff intf_i.cb.b_ready);
  //               //   intf_i.cb.b_valid <= 0;
  //               // //@(intf_i.cb iff intf_i.cb.c_ready);
  //               // @(intf_i.cb iff !intf_i.cb.c_ready);
  //               //   intf_i.cb.c_valid <= 0;
  //               @(intf_i.cb);

  //               //$display("[DRV][Inputs] cycle count loop last line");

  //             end
  //           end
  //         end 
  //       end 
  //     end
  
      // OLD LOOP (COMMENT THIS OUT BEFORE RUNNING)

      //outch needs to be the outermost
      // $display("[DRV] ----- Driving a new input feature map -----");
      // for (int x = 0; x < cfg.FEATURE_MAP_WIDTH; x = x + cfg.CONV_STEP) begin
      //   $display("[DRV] %.2f %% of the input is transferred",
      //            ((x) * 100.0) / cfg.FEATURE_MAP_WIDTH);
      //   for (int y = 0; y < cfg.FEATURE_MAP_HEIGHT; y = y + cfg.CONV_STEP) begin
      //     for (int inch = 0; inch < cfg.INPUT_NB_CHANNELS; inch++) begin
      //       for (int outch = 0; outch < cfg.OUTPUT_NB_CHANNELS; outch++) begin
      //         for (int ky = 0; ky < cfg.KERNEL_SIZE; ky++) begin
      //           for (int kx = 0; kx < cfg.KERNEL_SIZE; kx++) begin

      //             //drive a (one word from feature)
      //             intf_i.cb.a_valid <= 1;
      //             if( x+kx-cfg.KERNEL_SIZE/2 >= 0 && x+kx-cfg.KERNEL_SIZE/2 < cfg.FEATURE_MAP_WIDTH
      //               &&y+ky-cfg.KERNEL_SIZE/2 >= 0 && y+ky-cfg.KERNEL_SIZE/2 < cfg.FEATURE_MAP_HEIGHT) begin
      //               assert (!$isunknown(
      //                   tract_feature.inputs[y+ky-cfg.KERNEL_SIZE/2][x+kx-cfg.KERNEL_SIZE/2][inch]
      //               ));

      //               //for loop 1 to 5.
      //               //i00, i01, i10 etc etc
      //               //then we need to remove kx and ky
      //               //we also assign b input here and comment the b input below
      //               //we also assign c input here by modifying the out so to make it inout
      //               intf_i.cb.a_input <= tract_feature.inputs[y+ky-cfg.KERNEL_SIZE/2 ][x+kx-cfg.KERNEL_SIZE/2][inch];
      //             end 
                  
      //             else begin
      //               intf_i.cb.a_input <= 0;  // zero padding for boundary cases
      //             end
      //             @(intf_i.cb iff intf_i.cb.a_ready);
      //             intf_i.cb.a_valid <= 0;

      //             //drive a (one word from kernel)
      //             intf_i.cb.b_valid <= 1;
      //             assert (!$isunknown(tract_kernel.kernel[ky][kx][inch][outch]));
      //             intf_i.cb.b_input <= tract_kernel.kernel[ky][kx][inch][outch];
      //             @(intf_i.cb iff intf_i.cb.b_ready);
      //             intf_i.cb.b_valid <= 0;
      //           end
      //         end
      //       end
      //     end
      //   end
      // end


      $display("\n\n------------------\nLATENCY: input processed in %t\n------------------\n",
               $time() - starttime);

      $display("------------------\nENERGY:  %0d\n------------------\n", tbench_top.energy);

      $display("------------------\nENERGYxLATENCY PRODUCT (/1e9):  %0d\n------------------\n",
               (longint'(tbench_top.energy) * ($time() - starttime)) / 1e9);

      tbench_top.energy = 0;

      $display("\n------------------\nAREA (breakdown see start): %0d\n------------------\n",
               tbench_top.area);

    end
  endtask : run
endclass : Driver
