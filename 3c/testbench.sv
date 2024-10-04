// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module testbench;
  parameter M = 2;
  parameter N = 2;
  parameter DATA_WIDTH = 32;
  
  
  reg clk;
  reg reset;
  reg [M*N*DATA_WIDTH-1:0] operands_a;
  reg [M*N*DATA_WIDTH-1:0] operands_b;
  reg [1:0] precision_select;
  reg valid_in;
  wire [2*M*N*DATA_WIDTH-1:0] accumulator;
  wire [M*N-1:0] valids_out;
  
  pe_array #(
    .M(M),
    .N(N),
    .DATA_WIDTH(DATA_WIDTH)
  ) uut(
    .clk(clk),
    .reset(reset),
    .operands_a(operands_a),
    .operands_b(operands_b),
    .precision_select(precision_select),
    .valid_in(valid_in),
    .accumulator(accumulator),
    .valids_out(valids_out)
  );
  
  initial clk = 0;
  always #5 clk = ~clk;
  
//  task perform_mac;
//    input [31:0] a;
//    input [31:0] b;
//    input [1:0] mode;
//    begin 
//      operand_a = a;
//      operand_b = b;
//      precision_select = mode;
//      valid_in = 1;
//      #10;
//      valid_in = 0;
//      #10;
//    end
//  endtask
  
  // Start testing stimulus
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);
  	reset = 1;
    valid_in = 0;
    operands_a = 0;
    operands_b = 0;
    precision_select = 2'b00;
    #20;
    
    reset = 0;
    #10;
    
	// Provide inputs to all PEs
    valid_in = 1;
    precision_select = 2'b00;//INT8
    
    
    operands_a = {
      {24'd0, 8'd1},
      {24'd0, 8'd2},
      {24'd0, 8'd3},
      {24'd0, 8'd4}
    };
    
    operands_b = {
      {24'd0, 8'd5},
      {24'd0, 8'd6},
      {24'd0, 8'd7},
      {24'd0, 8'd8}
    };
    #10
    valid_in = 0;
    # 20
    
    
    // Now display accumulator values from all PEs
    $display("Accumulator values from all PEs:");
    for (int i = 0; i < M*N; i = i + 1) begin
      $display("PE[%0d]: %d", i, accumulator[(i+1)*2*DATA_WIDTH-1 -: 2*DATA_WIDTH]);
    end   
    $finish;
  end
endmodule
