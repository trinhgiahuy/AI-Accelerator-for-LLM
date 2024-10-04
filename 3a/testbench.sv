// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module testbench;
  reg clk;
  reg reset;
  reg [15:0] operand_a;
  reg [15:0] operand_b;
  reg valid_in;
  wire [31:0] accumulator;
  wire valid_out;
  
  mac_pe uut(
    .clk(clk),
    .reset(reset),
    .operand_a(operand_a),
    .operand_b(operand_b),
    .valid_in(valid_in),
    .accumulator(accumulator),
    .valid_out(valid_out)
  );
  
  // Generate clock
  initial clk = 0;
  always #5 clk = ~clk;
  
  initial begin 
    $dumpfile("dump.vcd");
    $dumpvars(1);
    reset = 1;
    valid_in = 0;
    operand_a = 0;
    operand_b = 0;
    #20
    
    reset = 0;
    #10
    
    //Do first MAC operation
    operand_a = 16'd3;
    operand_b = 16'd4;
    valid_in = 1;
    #10
    
    valid_in = 0;
    #10
    
   	//Check result
    #10
    $display("Final Accumulator Value: %d", accumulator);
    
    $finish;
  end
  endmodule
