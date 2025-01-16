`timescale 1ns/1ps

module test_pe_output_stationary;

  parameter WEIGHT_WIDTH  = 8;
  parameter INPUT_WIDTH   = 8;
  parameter SCRATCH_WIDTH = 16;
  parameter FWD_WIDTH     = 16;

  reg                      w_clk;
  reg                      w_rst_n;
  reg                      w_ready;
  reg                      w_rw;
  reg                      w_stream;
  reg  [WEIGHT_WIDTH-1:0] w_weight;
  reg  [INPUT_WIDTH-1:0]  w_input;
  reg  [FWD_WIDTH-1:0]    w_fwd_in;

  wire [FWD_WIDTH-1:0]    w_out;
  wire [WEIGHT_WIDTH-1:0] w_wreg_out;
  wire [INPUT_WIDTH-1:0]  w_ireg_out;

  // Instantiate PE
  pe_output_stationary #(
      .WEIGHT_WIDTH (WEIGHT_WIDTH),
      .INPUT_WIDTH  (INPUT_WIDTH),
      .SCRATCH_WIDTH(SCRATCH_WIDTH),
      .FWD_WIDTH    (FWD_WIDTH)
  ) dut (
      .w_clk    (w_clk),
      .w_rst_n  (w_rst_n),
      .w_ready  (w_ready),
      .w_rw     (w_rw),
      .w_stream (w_stream),
      .w_weight (w_weight),
      .w_input  (w_input),
      .w_fwd_in (w_fwd_in),
      .w_out       (w_out),
      .w_wreg_out  (w_wreg_out),
      .w_ireg_out  (w_ireg_out)
  );

  // Clock
  initial w_clk = 1'b0;
  always #5 w_clk = ~w_clk;

  initial begin
      $dumpfile("pe_output_stationary_tb.vcd");
      $dumpvars(0, test_pe_output_stationary);

      // Init
      w_rst_n   = 1'b0;
      w_ready   = 1'b0;
      w_rw      = 1'b0;
      w_stream  = 1'b0;
      w_weight  = 8'd0;
      w_input   = 8'd0;
      w_fwd_in  = 16'd0;

      // Reset 2 cycles
      repeat(2) @(posedge w_clk);
      w_rst_n = 1'b1;
      $display("[TB] Released reset @%t", $time);

      //---------------------------
      // TEST 1: w_ready=0 => load
      //---------------------------
      $display("\n[TEST 1] w_ready=0 => load W=3,I=5 => scratch=0");
      w_ready  = 1'b0;
      w_weight = 8'd3;
      w_input  = 8'd5;
      @(posedge w_clk);
      @(posedge w_clk);

      //---------------------------
      // TEST 2: read/no-MAC
      //---------------------------
      $display("[TEST 2] read => out=old scratch=0");
      w_ready  = 1'b1;
      w_rw     = 1'b0;
      @(posedge w_clk);
      $display("  w_out=%0d (expect 0)", w_out);
      @(posedge w_clk);

      //---------------------------
      // TEST 3: Single-cycle MAC => scratch=15
      //---------------------------
      $display("[TEST 3] single-cycle MAC => scratch=15 => out=Z this cycle");
      // Pulse w_rw for 1 clock
      w_rw = 1'b1;
      @(posedge w_clk);  // triggers MAC once
      w_rw = 1'b0;
      // Next cycle => read
      @(posedge w_clk);
      $display("  w_out=%0d (expect 15)", w_out);

      //---------------------------
      // TEST 4: Data gating => W=0 => product=0 => scratch=15
      //---------------------------
      $display("\n[TEST 4] gating => W=0 => no scratch update => remain 15");
//       w_weight = 8'd0;
//       w_input  = 8'd7; // product=0
//       w_rw     = 1'b1;
//       @(posedge w_clk);
//       w_rw = 1'b0;
//       @(posedge w_clk);
//       $display("  w_out=%0d (expect 15)", w_out);

//       w_weight = 8'd0;
//       w_input  = 8'd7;   // product=0, so no scratch update
//       // single-cycle MAC:
//       w_rw = 1'b1;
//       @(posedge w_clk);  // do 1 accumulation => scratch = 15 + 0 = 15
//       w_rw = 1'b0;
//       @(posedge w_clk);  // read => out=15
//       $display(" w_out=%0d (expect 15)", w_out);
    
    // [TEST 4] Data gating => want to keep scratch at 15, so W=0 => product=0.

      // (A) First, latch the new weight=0, input=7 (no MAC yet)
      w_rw     = 1'b0;   // no accumulate
      w_weight = 8'd0;
      w_input  = 8'd7;
      @(posedge w_clk);  // after this edge, r_wreg=0, r_ireg=7

      // (B) Next cycle, do a single-cycle MAC
      w_rw = 1'b1;
      @(posedge w_clk);  // triggers accumulate with product=0
      w_rw = 1'b0;
      @(posedge w_clk);  // read the new scratch
      $display("  w_out=%0d (expect 15)", w_out);
    
    	
      //TODO: ADD TESTCASE WHEN INPUT=0 WEIGHT NON-ZERO 
      //and TESTCASE WHEN BOTH ARE 0
      //
      //---------------------------
      // TEST 5: Streaming => old Freg out, scratch=19
//       //---------------------------
//       $display("\n[TEST 5] streaming => old freg=0 => out=0, scratch=19, new freg=200");
//       w_fwd_in  = 16'd200;
//       w_weight  = 8'd2;
//       w_input   = 8'd2;
//       w_stream  = 1'b1;
//       w_rw      = 1'b1;
//       @(posedge w_clk);
//       w_rw      = 1'b0;
//       w_stream  = 1'b0;
//       // Next cycle => read
//       @(posedge w_clk);
//       $display("  w_out=%0d (expect 19)", w_out);
          // [TEST 5] streaming => expect scratch=15+4=19, out=old freg=0, then new freg=200

      // Step (A) load new W=2,I=2, stream=1, fwd_in=200, but no MAC
      w_rw     = 1'b0;       // no accumulate yet
      w_stream = 1'b1;
      w_weight = 8'd2;
      w_input  = 8'd2;
      w_fwd_in = 16'd200;
      @(posedge w_clk);      // now r_wreg=2, r_ireg=2 latched; r_freg is old
                             // out might show old scratch or old freg

      // Step (B) single-cycle MAC
      w_rw = 1'b1;           // do the MAC
      @(posedge w_clk);      // triggers scratch=15+4=19, out=old freg=0, r_freg=200
      w_rw     = 1'b0;
      w_stream = 1'b0;

      // Step (C) read the new scratch in the next cycle
      @(posedge w_clk);
      $display("[TEST 5] w_out=%0d (expect 19)", w_out);

      $display("\n[TB] Done @%t", $time);
      #20 $finish;
  end

endmodule
