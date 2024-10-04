// Code your design here
module PE (
  input[15:0] weight,
  input[15:0] activation,
  input clk,
  input reset,
  input[1:0] num_type,
  
  output[31:0] sum // Will be Q16.16 for FP16 input, integer for integer input
  // Should maybe add overflow flag
  
  
);
  
  reg[31:0] partial_sum = 0;
  reg[5:0] shift_amnt = 0;
  reg[31:0] new_mantissa = 0; // 32 and not 22 bits to allow for bit shifting
  assign sum = partial_sum;
  
  always @(posedge(clk) or posedge(reset)) begin
    if (reset == 1) begin
      partial_sum <= 0;
    end else begin
      case (num_type)
        2'b0: begin // 16 bit interger
          partial_sum <= partial_sum + (weight * activation);
        end
        2'b01: begin // FP16
          shift_amnt <=  weight[14:10] + activation[14:10] - 5'b01111; // no method for exponent overflow
          new_mantissa <= {1'b1,weight[9:0]} * {1'b1,activation[9:0]}; // super bottle necking critical path
          if (shift_amnt < 5'b01111) begin
            partial_sum <= partial_sum + (new_mantissa >> (5'b01111 - shift_amnt + 5'b00100));
          end else begin
            partial_sum <= partial_sum + (new_mantissa << (shift_amnt - 5'b01111 - 5'b00100));
          end
          
          
        end
        2'b10: begin // bfloat16
        end
        2'b11: begin
        end
      endcase
    end
  end
  
endmodule

module RLE_encoder (
  input [15:0] unencoded_data,
  output[4:0] encoded_data, // {num, count}
  input clk,
  input clr, // assert and deassert this signal whenever you put new data to encode
  output decoder_read,
  output done
);
  reg[3:0] count = 0; // if count == 0000, that represents 16 (we save 1 bit this way)
  reg[4:0] index = 0;
  reg prev_bit = 0;
  reg[4:0] output_reg = 0;
  reg stall_reg = 0;
  reg decoder_read_reg = 0;
  reg done_reg = 0;
  

  
  assign encoded_data = output_reg;
  assign decoder_read = decoder_read_reg;
  assign done = done_reg;
  
  always @(posedge(clk)) begin
    if (clr) begin
      prev_bit <= 0;
      count <= 0;
      index <= 0;
      stall_reg <= 0;
      output_reg <= 0;
      done_reg <= 0;
      decoder_read_reg <= 0;
    end else begin
      if (decoder_read_reg) begin
        decoder_read_reg <= 0;
      end
      if (!stall_reg && index < 17) begin
        if (index == 0) begin
          prev_bit <= unencoded_data[0];
          index <= index + 1;
          count <= count + 1;
        end else begin 
          if (unencoded_data[index] == prev_bit) begin
            count <= count + 1;
            index <= index + 1;
          end else begin
            stall_reg <= 1;
          
          end
        end
      end else if (stall_reg && index < 17) begin
        output_reg <= {prev_bit, count};
          stall_reg <= 0;
          count <= 1;
        prev_bit <= unencoded_data[index];
          index <= index + 1;
          decoder_read_reg <= 1;
        if (index == 16) begin
          done_reg <= 1;
        end
        end     
      end
    end
  
endmodule

module RLE_decoder (
  output[15:0] unencoded_data,
  input[3:0] encoded_data, // {num, count}
  input clk,
  input clr, 
  input read_en,
  input encoder_done,
  output output_ready,
  output[4:0] fill_countt
);
  
  reg [15:0] out_reg = 0;
  reg [3:0] store_index = 0;
  reg [3:0] temp_index = 0;
  reg[79:0] store = 0;
  reg[3:0] count = 1;
  reg[4:0] fill_count = 5'b10001;
  reg bit_value = 0;
  reg seg_count = 0;
  reg ready_reg = 0;
  
  assign output_ready = ready_reg;
  assign unencoded_data = out_reg;
  assign fill_countt = fill_count;
  
  always @(posedge(clk)) begin
    if (clr) begin
      out_reg <= 0;
      store_index <= 0;
      temp_index <= 0;
      store <= 0;
      count <= 1;
      fill_count <= 5'b10001;
      bit_value <= 0;
      seg_count <= 0;
      ready_reg <= 0;
      
      
    end else begin
      if (read_en) begin
        store_index <= store_index + 1;
        case (store_index)
          4'b0000: begin
            store[4:0] <= encoded_data;
          end
          4'b0001: begin
            store[9:5] <= encoded_data;
          end
          4'b0010: begin
            store[14:10] <= encoded_data;
          end
          4'b0011: begin
            store[19:15] <= encoded_data;
          end
          4'b0100: begin
            store[24:20] <= encoded_data;
          end
          4'b0101: begin
            store[29:25] <= encoded_data;
          end
          4'b0110: begin
            store[34:30] <= encoded_data;
          end
          4'b0111: begin
            store[39:35] <= encoded_data;
          end
          4'b1000: begin
            store[44:40] <= encoded_data;
          end
          4'b1001: begin
            store[49:45] <= encoded_data;
          end
          4'b1010: begin
            store[54:50] <= encoded_data;
          end
          4'b1011: begin
            store[59:55] <= encoded_data;
          end
          4'b1100: begin
            store[64:60] <= encoded_data;
          end
          4'b1101: begin
            store[69:65] <= encoded_data;
          end
          4'b1110: begin
            store[74:70] <= encoded_data;
          end
          4'b1111: begin
            store[79:75] <= encoded_data;
          end
          default: begin
            store <= 80'b0;
          end
        endcase
        
        
      end else if (encoder_done) begin
        // put serially through a 16 long flipflop chain ,and use that as teh output
        if (fill_count > 0) begin
          fill_count <= fill_count - 5'b00001;
          out_reg[15:1] <= out_reg[14:0];
          out_reg[0] <= bit_value;
          count <= count - 1;
          if (count == 1) begin
            case (seg_count)
          4'b0000: begin
            {bit_value, fill_count} <= store[4:0];
          end
          4'b0001: begin
            {bit_value, fill_count} <= store[9:5];
          end
          4'b0010: begin
            {bit_value, fill_count} <= store[14:10];
          end
          4'b0011: begin
            {bit_value, fill_count} <= store[19:15];
          end
          4'b0100: begin
            {bit_value, fill_count} <= store[24:20];
          end
          4'b0101: begin
            {bit_value, fill_count} <= store[29:25];
          end
          4'b0110: begin
            {bit_value, fill_count} <= store[34:30];
          end
          4'b0111: begin
            {bit_value, fill_count} <= store[39:35];
          end
          4'b1000: begin
            {bit_value, fill_count} <= store[44:40];
          end
          4'b1001: begin
            {bit_value, fill_count} <= store[49:45];
          end
          4'b1010: begin
            {bit_value, fill_count} <= store[54:50];
          end
          4'b1011: begin
            {bit_value, fill_count} <= store[59:55];
          end
          4'b1100: begin
            {bit_value, fill_count} <= store[64:60];
          end
          4'b1101: begin
            {bit_value, fill_count} <= store[69:65];
          end
          4'b1110: begin
            {bit_value, fill_count} <= store[74:70];
          end
          4'b1111: begin
            {bit_value, fill_count} <= store[79:75];
          end
          default: begin
            {bit_value, fill_count} <= '0;
          end
        endcase
            
            
          end else begin
            ready_reg <= 1;
            
          end
          
        end
        
        
        
      end
      
      
      
      
      
    end
  end
  

  
  
endmodule


module PE_array (
  input[7:0][15:0] weight,
  input[7:0][15:0] activation,
  input clk,
  input reset,
  input[1:0] num_type,
  input weight_w_en, // if weight stationary dataflow, make this 0 so the weight register will not be written to
  input activation_w_en,
  
  
  output[7:0][31:0] sum
);
  
  reg [7:0][15:0] weight_reg;
  reg [7:0][15:0] activation_reg;
  
  always @(posedge(clk) or posedge(reset)) begin
    if (reset) begin
      integer i;
      for (i = 0; i<8; i = i + 1) begin
        weight_reg[i] <= 0;
        activation_reg[i] <= 0;
      end
    end else begin
      if (weight_w_en) begin
        weight_reg <= weight;
      end
      if (activation_w_en) begin
        activation_reg <= activation;
      end
    end
  end
  
  genvar i;
  
  generate
    for ( i = 0; i < 8; i = i + 1) begin 
      PE u_PE (.weight(weight_reg[i]),
               .activation(activation_reg[i]),
               .clk(clk),
               .reset(reset),
               .num_type(num_type)
        
      );
    end
  endgenerate
endmodule
