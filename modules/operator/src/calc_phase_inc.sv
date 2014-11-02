/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: calc_phase_inc.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 13 Oct 2014
#
#   DESCRIPTION:
#   Prepare the phase increment for the NCO (calc multiplier and vibrato)
#
#   CHANGE HISTORY:
#   13 Oct 2014    Greg Taylor
#       Initial version
#
#   SVN Identification
#   $Id$
#******************************************************************************/
`timescale 1ns / 1ps
`default_nettype none  // disable implicit net type declarations

import opl3_pkg::*;

module calc_phase_inc (
    input wire clk,
	input wire sample_clk_en,
    input wire [REG_FNUM_WIDTH-1:0] fnum,
    input wire [REG_MULT_WIDTH-1:0] mult,
    input wire [REG_BLOCK_WIDTH-1:0] block,
    input wire vib,
    input wire dvb,
    input wire [ENV_WIDTH-1:0] env,
    output logic [PHASE_ACC_WIDTH-1:0] phase_inc = 0
);
    localparam VIBRATO_INDEX_WIDTH = 13;
    
    logic [PHASE_ACC_WIDTH-1:0] phase_inc_p0 = 0;
    logic [PHASE_ACC_WIDTH-1:0] pre_mult = 0;
    logic [PHASE_ACC_WIDTH-1:0] post_mult = 0;
    
    logic [VIBRATO_INDEX_WIDTH-1:0] vibrato_index = 0;
    logic [REG_FNUM_WIDTH-1:0] delta0 = 0;
    logic [REG_FNUM_WIDTH-1:0] delta1 = 0;
    logic [REG_FNUM_WIDTH-1:0] delta2 = 0;
    logic [REG_FNUM_WIDTH-1:0] delta3 = 0;
    
    always_ff @(posedge clk)
        pre_mult <= fnum << block; // might be - 1 here;
    
	always_ff @(posedge clk)
		unique case (mult)
		'h0: post_mult <= pre_mult >> 1;
        'h1: post_mult <= pre_mult;
        'h2: post_mult <= pre_mult*2;
        'h3: post_mult <= pre_mult*3;
        'h4: post_mult <= pre_mult*4;
        'h5: post_mult <= pre_mult*5;
        'h6: post_mult <= pre_mult*6;
        'h7: post_mult <= pre_mult*7;
        'h8: post_mult <= pre_mult*8;
        'h9: post_mult <= pre_mult*9;
        'hA: post_mult <= pre_mult*10;
        'hB: post_mult <= pre_mult*10;
        'hC: post_mult <= pre_mult*12;
        'hD: post_mult <= pre_mult*12;
        'hE: post_mult <= pre_mult*15;
        'hF: post_mult <= pre_mult*15;
        endcase
    
    /*
     * Pipeline output of multipliers a bit just for good form
     */
    always_ff @(posedge clk)
        phase_inc_p0 <= post_mult;
    
    always_ff @(posedge clk)
        if (vib)
            phase_inc <= phase_inc_p0 + delta3;
        else
            phase_inc <= phase_inc_p0;
        
    /*
     * LFO for vibrato, 6.06884765625Hz (Sample Freq/2**13)
     */        
    always_ff @(posedge clk)
        if (sample_clk_en)
            vibrato_index <= vibrato_index + 1;
        
    always_comb delta0 = fnum >> 7;
    always_comb delta1 = ((vibrato_index >> 10) & 3) == 3 ? delta0 >> 1 : delta0;
    always_comb delta2 = !dvb ? delta1 >> 1 : delta1;
    
    always_ff @(posedge clk)
        delta3 <= ((vibrato_index >> 10) & 4) != 0 ? ~delta2 : delta2;
endmodule
`default_nettype wire  // re-enable implicit net type declarations