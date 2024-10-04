// Code your design here
`timescale 1ns/1ps

module mac_pe_3 #(
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


// START connect those processing elements in an array
// PE Array Module
module pe_array #(
    parameter M = 2,
    parameter N = 2,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire reset,
    input wire [M*N*DATA_WIDTH-1:0] operands_a, // Flattened array of operand_a
    input wire [M*N*DATA_WIDTH-1:0] operands_b, // Flattened array of operand_b
    input wire valid_in,
    input wire [1:0] precision_select,
    output wire [M*N*2*DATA_WIDTH-1:0] accumulator,
    output wire [M*N-1:0] valids_out
);
    genvar i, j;
    generate
      for (i = 0; i < M; i = i + 1) begin : ROW
        for (j = 0; j < N; j = j + 1) begin : COL
          localparam idx = i*N + j;
          localparam op_a_start = idx * DATA_WIDTH;
          localparam op_a_end = op_a_start + DATA_WIDTH - 1;
          localparam op_b_start = idx * DATA_WIDTH;
          localparam op_b_end = op_b_start + DATA_WIDTH -1;
          localparam accu_start = idx * 2 * DATA_WIDTH;
          localparam accu_end = accu_start + 2 * DATA_WIDTH -1;
          
          mac_pe_3 #(
            .DATA_WIDTH(DATA_WIDTH)
          ) pe_inst (
            .clk(clk),
            .reset(reset),
            .operand_a(operands_a[op_a_end:op_a_start]),
            .operand_b(operands_b[op_b_end:op_b_start]),
            .valid_in(valid_in),
            .precision_select(precision_select),
            .accumulator(accumulator[accu_end:accu_start]),
            .valid_out(valids_out[idx])
          );
      end
    end
  endgenerate
endmodule

