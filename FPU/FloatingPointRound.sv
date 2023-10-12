`include "FloatingPointConsts.svh"

module FloatingPointRound#(
    parameter frac_width = 23
)(
    input logic sign,
    input logic[frac_width+2:0] in_frac, // without hidden bit
    input logic[1:0] mode,

    output logic[frac_width-1:0] out_frac, // without hidden bit
    output logic carry
);
    //wire G = in_frac[2];
    //wire R = in_frac[1];
    //wire S = in_frac[0];
    logic[frac_width+1:0] tmp_frac;
    logic round_up;

    always_comb begin
        unique case(mode)
            `FP_ROUND_TONEAREST: round_up = (in_frac[2] & (in_frac[3] | (|in_frac[1:0])));
            `FP_ROUND_TOWARDZERO:round_up = 1'b0;
            `FP_ROUND_DOWNWARD:  round_up = (sign & |in_frac[2:0]);
            `FP_ROUND_UPWARD:    round_up = (~sign & |in_frac[2:0]);
        endcase
        tmp_frac = {2'b01, in_frac[frac_width+2:3]} + {{(frac_width+1){1'b0}}, round_up};
        out_frac = tmp_frac[frac_width+1] ? tmp_frac[frac_width:1] : tmp_frac[frac_width-1:0];
        carry = tmp_frac[frac_width+1];
    end
endmodule