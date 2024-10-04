// Testbench
module test;

  wire [15:0] out_data;
  reg[4:0] in_data;
  reg clk,clr;
reg read_en, encoder_done;
  wire output_ready;
  wire[4:0] fill_count;

  
  // Instantiate design under test
  
  RLE_decoder u1(
    .unencoded_data(out_data),
    .encoded_data(in_data),
    .clk(clk),
    .clr(clr),
    .read_en(read_en),
    .encoder_done(encoder_done),
    .output_ready(output_ready),
    .fill_countt(fill_count)
  );

          
  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(1, test);
    
    clk = 0;
    clr = 0;
    in_data = 5'b10100;
    read_en = 1;
    encoder_done = 0;
    toggle_clk;
    in_data = 5'b00100;
    toggle_clk;
    in_data = 5'b10100;
    toggle_clk;
    in_data = 5'b00100;

    toggle_clk;
        read_en = 0;
    encoder_done = 1;
    
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    toggle_clk;
    
    

    
    

  
    
  
  end
  

  
  task toggle_clk;
    begin
      #10 clk = ~clk;
      #10 clk = ~clk;
    end
  endtask

endmodule
