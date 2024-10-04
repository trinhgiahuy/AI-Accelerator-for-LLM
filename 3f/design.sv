module rle_decoder #(
  parameter DATA_WIDTH = 32,
  parameter COUNT_WIDTH = 8
)(
  input wire clk,
  input wire reset,
  input wire [DATA_WIDTH-1:0] data_in,
  input wire [COUNT_WIDTH-1:0] count_in,
  input wire valid_in,
  output reg [DATA_WIDTH-1:0] data_out,
  output reg valid_out,
  output reg ready_in
);
  reg [COUNT_WIDTH-1:0] count_reg;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      count_reg <= 0;
      valid_out <= 0;
      ready_in <= 1;
    end else begin
      if (valid_in && ready_in) begin
        if (count_in == 0) begin
          // Zero run
          data_out <= 0;
          count_reg <= 0;
          valid_out <= 1;
          ready_in <= 1;
        end else begin
          // Non-zero data
          data_out <= data_in;
          count_reg <= count_in - 1;
          valid_out <= 1;
          ready_in <= (count_in == 1);
        end
      end else if (count_reg > 0) begin
        data_out <= data_out;
        count_reg <= count_reg - 1;
        valid_out <= 1;
        ready_in <= (count_reg == 1);
      end else begin
        valid_out <= 0;
        ready_in <= 1;
      end
    end
  end
endmodule


// PE Array Module with RLE Decoder
module pe_array_with_rle #(
  parameter M = 2,
  parameter N = 2,
  parameter DATA_WIDTH = 32,
  parameter COUNT_WIDTH = 8,
  parameter RF_DEPTH = 16,
  parameter ADDR_WIDTH = 4
)(
  input wire clk,
  input wire reset,
  
  // Control Signals
  input wire [M*N-1:0] load_weights,
  input wire [M*N*DATA_WIDTH-1:0] weights_in,
  input wire valid_in,
  input wire [1:0] precision_select,

  // RLE Encoded Activation Input
  input wire [DATA_WIDTH-1:0] rle_data_in,
  input wire [COUNT_WIDTH-1:0] rle_count_in,
  input wire rle_valid_in,

  // Outputs
  output wire [M*2*DATA_WIDTH-1:0] accumulators,
  output wire [M-1:0] valids_out
);
  wire [DATA_WIDTH-1:0] activation_decoded;
  wire activation_valid;
  wire rle_ready;

  // Instantiate RLE Decoder
  rle_decoder #(
    .DATA_WIDTH(DATA_WIDTH),
    .COUNT_WIDTH(COUNT_WIDTH)
  ) rle_dec_inst (
    .clk(clk),
    .reset(reset),
    .data_in(rle_data_in),
    .count_in(rle_count_in),
    .valid_in(rle_valid_in),
    .data_out(activation_decoded),
    .valid_out(activation_valid),
    .ready_in(rle_ready)
  );

  // Pass decoded activations to PE array
  pe_array_weight_stationary #(
    .M(M),
    .N(N),
    .DATA_WIDTH(DATA_WIDTH),
    .RF_DEPTH(RF_DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) pe_array_inst (
    .clk(clk),
    .reset(reset),
    .load_weights(load_weights),
    .weights_in(weights_in),
    .valid_in(activation_valid),
    .precision_select(precision_select),
    .activations_in({N{activation_decoded}}),
    .accumulators(accumulators),
    .valids_out(valids_out)
  );
endmodule
