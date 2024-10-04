// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module testbench;
  reg clk;
  reg reset;
  reg [31:0] operand_a;
  reg [31:0] operand_b;
  reg [1:0] precision_select;
  reg valid_in;
  wire [63:0] accumulator;
  wire valid_out;
  
  mac_pe_2 uut(
    .clk(clk),
    .reset(reset),
    .operand_a(operand_a),
    .operand_b(operand_b),
    .precision_select(precision_select),
    .valid_in(valid_in),
    .accumulator(accumulator),
    .valid_out(valid_out)
  );
  
  initial clk = 0;
  always #5 clk = ~clk;
  
  task perform_mac;
    input [31:0] a;
    input [31:0] b;
    input [1:0] mode;
    begin 
      operand_a = a;
      operand_b = b;
      precision_select = mode;
      valid_in = 1;
      #10;
      valid_in = 0;
      #10;
    end
  endtask
  
  // Start testing stimulus
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1);
  	reset = 1;
    valid_in = 0;
    operand_a = 0;
    operand_b = 0;
    precision_select = 2'b00;
    #20;
    
    reset = 0;
    #10;
    
    //INT8 MAC Operation
    perform_mac(8'd3, 8'd4, 2'b00);
    perform_mac(16'd5, 16'd6, 2'b01);
    perform_mac(32'd7, 32'd8, 2'b10);
    #10;
    
    $display("Final Accumulator Value: %d", accumulator);	//Expected: 98
    
    $finish;
  end
endmodule
