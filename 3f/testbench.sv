// testbench.sv
`timescale 1ns/1ps

module testbench;
  parameter M = 2;
  parameter N = 2;
  parameter DATA_WIDTH = 32;
  parameter COUNT_WIDTH = 8;

  reg clk;
  reg reset;
  reg [M*N-1:0] load_weights;
  reg [M*N*DATA_WIDTH-1:0] weights_in;
  reg valid_in;
  reg [1:0] precision_select;
  reg [DATA_WIDTH-1:0] rle_data_in;
  reg [COUNT_WIDTH-1:0] rle_count_in;
  reg rle_valid_in;
  wire [M*2*DATA_WIDTH-1:0] accumulators;
  wire [M-1:0] valids_out;

  // Instantiate the PE array with RLE decoder
  pe_array_with_rle #(
    .M(M),
    .N(N),
    .DATA_WIDTH(DATA_WIDTH),
    .COUNT_WIDTH(COUNT_WIDTH)
  ) uut (
    .clk(clk),
    .reset(reset),
    .load_weights(load_weights),
    .weights_in(weights_in),
    .valid_in(valid_in),
    .precision_select(precision_select),
    .rle_data_in(rle_data_in),
    .rle_count_in(rle_count_in),
    .rle_valid_in(rle_valid_in),
    .accumulators(accumulators),
    .valids_out(valids_out)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 10ns clock period

  // Test stimulus
  integer i;
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);

    // Initialize signals
    reset = 1;
    valid_in = 0;
    rle_valid_in = 0;
    load_weights = 0;
    weights_in = 0;
    precision_select = 2'b00;
    #20;

    reset = 0;
    #10;

    // Load weights into PEs
    load_weights = 4'b1111; // Load all weights
    weights_in = {
      {24'd0, 8'd1}, // PE[1][1] weight
      {24'd0, 8'd2}, // PE[1][0] weight
      {24'd0, 8'd3}, // PE[0][1] weight
      {24'd0, 8'd4}  // PE[0][0] weight
    };
    #10;
    load_weights = 0; // Disable weight loading

    // Provide RLE encoded activations
    precision_select = 2'b00; // INT8

    // First RLE data: Zero run
    rle_data_in = {DATA_WIDTH{1'b0}};
    rle_count_in = 8'd2; // Skip 2 zeros
    rle_valid_in = 1;
    #10;

    // Second RLE data: Non-zero activation
    rle_data_in = {24'd0, 8'd5}; // Activation value 5
    rle_count_in = 8'd1; // Repeat once
    #10;

    rle_valid_in = 0;
    #50;

    // Display accumulator values from all PEs
    $display("Accumulator values from all PEs:");
    for (i = 0; i < M; i = i + 1) begin
      $display("Row %0d Accumulator: %d", i, accumulators[(i+1)*2*DATA_WIDTH-1 -: 2*DATA_WIDTH]);
    end

    $finish;
  end
endmodule
