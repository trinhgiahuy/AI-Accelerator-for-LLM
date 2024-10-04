// Code your design here
`timescale 1ns/1ps

module mac_pe #(
  parameter DATA_WIDTH = 16
)(
  input wire clk,
  input wire reset,
  input wire [DATA_WIDTH-1:0] operand_a,
  input wire [DATA_WIDTH-1:0] operand_b,
  input wire valid_in,
  output reg [2*DATA_WIDTH-1:0] accumulator,
  output reg valid_out
);
  
  always @(posedge clk or posedge reset) begin
    if (reset) begin 
    	accumulator <= 32'd0;
      	valid_out <= 1'b0;
    end else if (valid_in) begin 
    	accumulator <= accumulator + operand_a * operand_b;
      	valid_out <= 1'b1;
    end else begin
      	valid_out <= 1'b0;
    end
  end
           
    
endmodule
