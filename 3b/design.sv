// Code your design here
`timescale 1ns/1ps

module mac_pe_2 #(
  parameter DATA_WIDTH = 32
)(
  input wire clk,
  input wire reset,
  input wire [DATA_WIDTH-1:0] operand_a,
  input wire [DATA_WIDTH-1:0] operand_b,
  input wire valid_in,
  input wire [1:0] precision_select,	// 2'b00: INT8, 2'b01: INT16, 2'b10: INT32, 
  output reg [2*DATA_WIDTH-1:0] accumulator,
  output reg valid_out
);
  reg [DATA_WIDTH-1:0] op_a, op_b;
  
  always @(*) begin
    case (precision_select)
      2'b00: begin
        op_a = {{24{operand_a[7]}}, operand_a[7:0]};
        op_b = {{24{operand_b[7]}}, operand_b[7:0]};                        
      end
      2'b01: begin
        op_a = {{16{operand_a[15]}}, operand_a[15:0]};
        op_b = {{16{operand_b[15]}}, operand_b[15:0]};     
      end
      2'b10: begin
		op_a = operand_a;
        op_b = operand_b;
      end
      default: begin
        op_a = operand_a;
        op_b = operand_b;
      end
    endcase
  end
  
  always @(posedge clk or posedge reset) begin
    if (reset) begin 
    	accumulator <= 64'd0;
      	valid_out <= 1'b0;
    end else if (valid_in) begin 
    	accumulator <= accumulator + operand_a * operand_b;
      	valid_out <= 1'b1;
    end else begin
      	valid_out <= 1'b0;
    end
  end
          
endmodule
           
