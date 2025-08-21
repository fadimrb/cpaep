interface intf #(
    config_t cfg
) (
    input logic clk
);
  logic arst_n;

  /*#############################
  WHEN ADJUSTING THIS INTERFACE, ADJUST THE ENERGY ADDITIONS AT THE BOTTOM ACCORDINGLY!
  ################################*/

  // input interface
  logic [1:0] conv_kernel_mode;
  logic [1:0] conv_stride_mode;
  logic [cfg.DATA_WIDTH - 1 : 0] a_input;
  logic a_valid;
  logic a_ready;

  logic [cfg.DATA_WIDTH - 1 : 0] b_input;
  logic b_valid;
  logic b_ready;

  wire [cfg.DATA_WIDTH - 1 : 0] c_input_output;
  // logic [cfg.DATA_WIDTH - 1 : 0] c_input;
  logic c_valid;
  logic c_ready;

  // output interface
  // logic signed [cfg.DATA_WIDTH-1:0] output_data;
  logic output_valid;
  logic [$clog2(cfg.FEATURE_MAP_WIDTH)-1:0] output_x;
  logic [$clog2(cfg.FEATURE_MAP_HEIGHT)-1:0] output_y;
  logic [$clog2(cfg.OUTPUT_NB_CHANNELS)-1:0] output_ch;

  logic start;
  logic running;
  // logic [cfg.DATA_WIDTH - 1 : 0] c_input;

  //assign c_input_output = output_valid ? 'bz : c_input;

  default clocking cb @(posedge clk);
    default input #0.01 output #0.01;

    output conv_kernel_mode;
    output conv_stride_mode;
    output arst_n;
    output a_input;
    output a_valid;
    input a_ready;

    output b_input;
    output b_valid;
    input b_ready;

    inout c_input_output;
    output c_valid;
    input c_ready;

    //input output_data;
    input output_valid;
    input output_x;
    input output_y;
    input output_ch;


    output start;
    input running;
  endclocking

  modport tb(clocking cb);  // testbench's view of the interface

  //ENERGY ESTIMATION:
  always @(posedge clk) begin
    if (a_valid && a_ready) begin
      tbench_top.energy += 1 * (cfg.DATA_WIDTH);
    end
  end
  always @(posedge clk) begin
    if (b_valid && b_ready) begin
      tbench_top.energy += 1 * (cfg.DATA_WIDTH);
    end
  end
  always @(posedge clk) begin
    if (c_valid && c_ready) begin
      tbench_top.energy += 1 * (cfg.DATA_WIDTH);
    end
  end
  always @(posedge clk) begin
    if (output_valid && 1) begin  //no ready here, set to 1
      tbench_top.energy += 1 * (cfg.DATA_WIDTH);
    end
  end


endinterface
