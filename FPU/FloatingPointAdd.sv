`include "FloatingPointConsts.svh"

module FloatingPointAdd#(
    parameter exp_width = 8,
    parameter frac_width = 23
)(
    input logic[exp_width+frac_width:0] op1,
    input logic[exp_width+frac_width:0] op2,
    input logic[1:0] round_mode,

    output logic[31:0] result,
    output logic[4:0] exception
);
    logic[exp_width-1:0] op1_exp, op2_exp;

    logic[exp_width+frac_width:0] op_big, op_small;
    logic op_big_sign, op_small_sign;
    logic[exp_width-1:0] op_big_exp, op_small_exp;

    logic[frac_width+5:0] op_big_manti, op_small_manti;

    logic[frac_width+5:0] added_manti;

    localparam shifter_stages = $clog2(frac_width+5);
    logic[shifter_stages-1:0] norm_shift;
    /* verilator lint_off UNOPTFLAT */
    logic[frac_width+4:0] norm_manti[shifter_stages:0];

    logic[frac_width-1:0] round_frac;
    logic round_carry;

    logic[exp_width:0] result_exp;
    logic result_sign;

    logic is_overflow, is_underflow, is_inexact;

    always_comb begin
        op1_exp = op1[exp_width+frac_width-1:frac_width];
        op2_exp = op2[exp_width+frac_width-1:frac_width];

        op_big = (op1_exp > op2_exp) ? op1 : op2;
        op_small = (op1_exp > op2_exp) ? op2 : op1;

        op_big_sign = op_big[exp_width+frac_width];
        op_small_sign = op_small[exp_width+frac_width];

        op_big_exp = op_big[exp_width+frac_width-1:frac_width];
        op_small_exp = op_small[exp_width+frac_width-1:frac_width];

        op_big_manti = {3'b001, op_big[frac_width-1:0], 3'b000};
        op_small_manti = {3'b001, op_small[frac_width-1:0], 3'b000} >> (op_big_exp - op_small_exp);

        added_manti = (op_big_sign ? -op_big_manti : op_big_manti) + (op_small_sign ? -op_small_manti : op_small_manti);
        result_sign = added_manti[frac_width+5];
        
        norm_manti[shifter_stages] = (frac_width+5)'(result_sign ? -added_manti : added_manti); // absolute
    end

    for(genvar s = shifter_stages-1; s >= 0; s = s - 1) begin: barrel_shifter
        assign norm_shift[s] = |norm_manti[s+1][frac_width+4:frac_width+5-(2**s)];
        assign norm_manti[s] = norm_shift[s] ? (norm_manti[s+1] << 2**s) : norm_manti[s+1];
    end
    
    FloatingPointRound#(
        .frac_width(frac_width)
    )round_module(
        .sign(result_sign),
        .in_frac({norm_manti[0][frac_width+3:2], |norm_manti[0][1:0]}),
        .mode(round_mode),

        .out_frac(round_frac),
        .carry(round_carry)
    );

    always_comb begin
        result_exp = op_big_exp - exp_width'(norm_shift) + exp_width'(unsigned'(round_carry+1'b1));

        is_overflow = result_exp[exp_width];
        is_underflow = result_exp[exp_width];
        is_inexact = |{norm_manti[0][2:0]};

        result = {result_sign, result_exp[exp_width-1:0], round_frac};

        exception = (5'(is_overflow) << `FP_OVERFLOW) | (5'(is_underflow) << `FP_UNDERFLOW) | (5'(is_inexact) << `FP_INEXACT);
    end
endmodule