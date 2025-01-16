// Code your design here
/*
 * Copyright (c) 2025 WAT.ai Chip Team
 * Author: Huy Trinh
 * SPDX-License-Identifier: Apache-2.0
 * 
 * Implements a two-stage, output-stationary Processing Element (PE) for 
 * AI MAC operations. Follows the “A2” design rules, including:
 *  - 16-bit partial-sum scratchpad (S)
 *  - 8-bit weight/input registers (Wreg/Ireg)
 *  - 16-bit forward register (Freg) for passing a prior output downstream
 *  - Data gating (skip multiply if weight=0 or input=0)
 *  - Function-table and waveform behavior described in the MVP spec
 *
 *   Symbolic signals:
 *     w_clk        : Clock
 *     w_rst_n      : Active-low reset
 *     w_ready      : 1 => PE is active/enabled this cycle; 0 => prepare for new load
 *     w_rw         : 1 => “MAC/update” cycle, 0 => “no MAC” cycle
 *     w_stream     : 1 => forward prior output (Freg) to the global buffer
 *     w_weight     : 8-bit incoming weight
 *     w_input      : 8-bit incoming activation
 *     w_fwd_in     : 16-bit forward input (to load into Freg if streaming)
 *
 *     w_out        : 16-bit output from the PE
 *     w_wreg_out   : 8-bit output for the next PE’s weight chain
 *     w_ireg_out   : 8-bit output for the next PE’s input chain
 *
 *   Behavior (matching the function table):
 *   1) w_ready=0:
 *      - scratch <= 0
 *      - wreg    <= w_weight
 *      - ireg    <= w_input
 *      - freg    <= 0
 *      - out     <= Z (high impedance or “don’t care”)
 *
 *   2) w_ready=1, w_rw=0, w_stream=0:
 *      - scratch <= scratch(t-1)
 *      - wreg    <= w_weight
 *      - ireg    <= w_input
 *      - freg    <= freg(t-1)
 *      - out     <= scratch(t-1)
 *
 *   3) w_ready=1, w_rw=0, w_stream=1:
 *      - scratch <= scratch(t-1)
 *      - wreg    <= w_weight
 *      - ireg    <= w_input
 *      - freg    <= freg(t-1)
 *      - out     <= freg(t-1)
 *
 *   4) w_ready=1, w_rw=1, w_stream=0:
 *      - scratch <= scratch(t-1) + (w_weight * w_input)   [with data gating if either=0]
 *      - wreg    <= w_weight
 *      - ireg    <= w_input
 *      - freg    <= freg(t-1)
 *      - out     <= Z
 *
 *   5) w_ready=1, w_rw=1, w_stream=1:
 *      - scratch <= scratch(t-1) + (w_weight * w_input)   [with data gating]
 *      - wreg    <= w_weight
 *      - ireg    <= w_input
 *      - freg    <= w_fwd_in
 *      - out     <= freg(t-1)
 */

`timescale 1ns/1ps

module pe_output_stationary #(
    parameter WEIGHT_WIDTH  = 8,
    parameter INPUT_WIDTH   = 8,
    parameter SCRATCH_WIDTH = 16,
    parameter FWD_WIDTH     = 16
)(
    input  wire                   w_clk,
    input  wire                   w_rst_n,
    input  wire                   w_ready, 
    input  wire                   w_rw,
    input  wire                   w_stream,
    input  wire [WEIGHT_WIDTH-1:0] w_weight,
    input  wire [INPUT_WIDTH-1:0]  w_input,
    input  wire [FWD_WIDTH-1:0]    w_fwd_in,

    output wire [FWD_WIDTH-1:0]    w_out,
    output wire [WEIGHT_WIDTH-1:0] w_wreg_out,
    output wire [INPUT_WIDTH-1:0]  w_ireg_out
);

    reg [SCRATCH_WIDTH-1:0] r_scratch;
    reg [WEIGHT_WIDTH-1:0]  r_wreg;
    reg [INPUT_WIDTH-1:0]   r_ireg;
    reg [FWD_WIDTH-1:0]     r_freg;
    reg [FWD_WIDTH-1:0]     r_out;

    // Gated multiplier
    wire [SCRATCH_WIDTH-1:0] w_product = 
        ((w_weight == 0) || (w_input == 0)) ? 0 : (w_weight * w_input);

    always @(posedge w_clk or negedge w_rst_n) begin
        if (!w_rst_n) begin
            r_scratch <= 0;
            r_wreg    <= 0;
            r_ireg    <= 0;
            r_freg    <= 0;
            r_out     <= 0;
        end else begin
            // Defaults
            reg [SCRATCH_WIDTH-1:0] nxt_scratch = r_scratch;
            reg [WEIGHT_WIDTH-1:0]  nxt_wreg    = r_wreg;
            reg [INPUT_WIDTH-1:0]   nxt_ireg    = r_ireg;
            reg [FWD_WIDTH-1:0]     nxt_freg    = r_freg;
            reg [FWD_WIDTH-1:0]     nxt_out     = {FWD_WIDTH{1'bz}};

            if (!w_ready) begin
                // Load mode
                nxt_scratch = 0;
                nxt_wreg    = w_weight;
                nxt_ireg    = w_input;
                nxt_freg    = 0;
                nxt_out     = {FWD_WIDTH{1'bz}};
            end else if (w_ready && !w_rw) begin
                // read/no-MAC
                nxt_wreg    = w_weight;
                nxt_ireg    = w_input;
                nxt_scratch = r_scratch;
                nxt_freg    = r_freg;
                if (!w_stream)
                    nxt_out = r_scratch;
                else
                    nxt_out = r_freg;
            end else if (w_ready && w_rw) begin
                // MAC
                nxt_scratch = r_scratch + w_product;
                nxt_wreg    = w_weight;
                nxt_ireg    = w_input;
                if (!w_stream) begin
                    nxt_out  = {FWD_WIDTH{1'bz}};
                    nxt_freg = r_freg;
                end else begin
                    nxt_out  = r_freg;
                    nxt_freg = w_fwd_in;
                end
            end

            // Update
            r_scratch <= nxt_scratch;
            r_wreg    <= nxt_wreg;
            r_ireg    <= nxt_ireg;
            r_freg    <= nxt_freg;
            r_out     <= nxt_out;
        end
    end

    assign w_out       = r_out;
    assign w_wreg_out  = r_wreg;
    assign w_ireg_out  = r_ireg;

endmodule
