`include "FloatingPointConsts.svh"

module FloatingPointMul#(
    parameter exp_width = 8,
    parameter frac_width = 23
)(
    input logic[exp_width+frac_width:0] op1,
    input logic[exp_width+frac_width:0] op2,
    input logic[1:0] round_mode,

    output logic[exp_width+frac_width:0] result,
    output logic[4:0] exception
);
    localparam mul_mant_width = (frac_width+1)*2;
    localparam exp_bias = (exp_width+1)'(2**(exp_width-1)-1);

    logic op1_sign, op2_sign;
    logic[exp_width-1:0] op1_exp, op2_exp;
    logic[frac_width-1:0] op1_frac, op2_frac;

    logic[mul_mant_width-1:0] mul_mant;
    logic[frac_width+2:0] norm_mul_frac;
    logic mul_carry;

    logic result_sign;
    /* verilator lint_off UNOPTFLAT */
    logic[frac_width-1:0] round_frac;
    logic round_carry;

    logic[exp_width:0] result_biased_exp;
    logic[exp_width-1:0] result_exp;
    logic is_op1_zero, is_op2_zero;
    logic is_op1_nan, is_op2_nan;
    logic is_op1_inf, is_op2_inf;
    
    logic is_overflow, is_underflow, is_inexact;

    always_comb begin
        op1_sign = op1[exp_width+frac_width];
        op2_sign = op2[exp_width+frac_width];

        op1_exp = op1[exp_width+frac_width-1:frac_width];
        op2_exp = op2[exp_width+frac_width-1:frac_width];

        op1_frac = op1[frac_width-1:0];
        op2_frac = op2[frac_width-1:0];

        is_op1_zero = op1_exp == {exp_width{1'b0}} && (~|op1_frac); // regard denormal number as zero
        is_op2_zero = op2_exp == {exp_width{1'b0}} && (~|op2_frac); // regard denormal number as zero
        is_op1_inf = op1_exp == {exp_width{1'b1}} && (~|op1_frac);
        is_op2_inf = op2_exp == {exp_width{1'b1}} && (~|op2_frac);
        is_op1_nan = op1_exp == {exp_width{1'b1}} && (|op1_frac);
        is_op2_nan = op2_exp == {exp_width{1'b1}} && (|op2_frac);

        result_sign = op1_sign ^ op2_sign;
        mul_mant = {op1_exp != {exp_width{1'b0}}, op1_frac} * {op2_exp != {exp_width{1'b0}}, op2_frac};

        unique case(mul_mant[mul_mant_width-1])
            1'b1: norm_mul_frac = {mul_mant[mul_mant_width-2:mul_mant_width-frac_width-3], |mul_mant[mul_mant_width-frac_width-4:0]};
            1'b0: norm_mul_frac = {mul_mant[mul_mant_width-3:mul_mant_width-frac_width-4], |mul_mant[mul_mant_width-frac_width-5:0]};
        endcase

        mul_carry = mul_mant[mul_mant_width-1];
    end

    FloatingPointRound#(
        .frac_width(frac_width)
    )round_module(
        .sign(result_sign),
        .in_frac(norm_mul_frac),
        .mode(round_mode),

        .out_frac(round_frac),
        .carry(round_carry)
    );

    always_comb begin
        result_biased_exp = op1_exp + op2_exp + (exp_width+1)'(unsigned'(round_carry + mul_carry));
        
        is_overflow = result_biased_exp > (exp_bias*3);
        is_underflow = exp_bias > result_biased_exp;
        is_inexact = |norm_mul_frac[2:0];
        
        result_exp = exp_width'(result_biased_exp - exp_bias);

        if(is_op1_nan) result = op1; // NAN propagation
        else if(is_op2_nan) result = op2; // NAN propagation
        else if(is_op1_inf & is_op2_zero | is_op1_zero & is_op2_inf) result = {1'b1, {exp_width{1'b1}}, 1'b1, {(frac_width-1){1'b0}}}; // -nan
        else if(is_op1_zero | is_op2_zero | is_underflow) result = {result_sign, {exp_width{1'b0}}, {frac_width{1'b0}}}; // +-zero
        else if(is_op1_inf | is_op2_inf | is_overflow) result = {result_sign, {exp_width{1'b1}}, {frac_width{1'b0}}}; // +-inf
        else result = {result_sign, result_exp, round_frac};
        
        exception = (5'(is_overflow) << `FP_OVERFLOW) | (5'(is_underflow) << `FP_UNDERFLOW) | (5'(is_inexact) << `FP_INEXACT);
    end
endmodule