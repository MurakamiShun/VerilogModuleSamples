`include "FloatingPointConsts.svh"

module FloatingPointFMA#(
    parameter exp_width = 8,
    parameter frac_width = 23
)(
    input logic[exp_width+frac_width:0] op1,
    input logic[exp_width+frac_width:0] op2,
    input logic[exp_width+frac_width:0] op_sum,
    input logic[1:0] round_mode,

    output logic[exp_width+frac_width:0] result,
    output logic[4:0] exception
);
    localparam mul_mant_width = (frac_width+1)*2;
    localparam[exp_width:0]exp_bias = (2**(exp_width-1))-1;

    logic op1_sign, op2_sign, op_sum_sign;
    logic[exp_width-1:0] op1_exp, op2_exp, op_sum_exp;
    logic[frac_width-1:0] op1_frac, op2_frac, op_sum_frac;

    logic[mul_mant_width-1:0] mul_manti;

    logic mul_result_sign, result_sign;
    logic[exp_width:0] mul_result_exp, exp_diff, exp_diff_abs_tmp;
    logic[exp_width-1:0] exp_diff_abs;

    logic[frac_width:0] sum_manti;
    logic[mul_mant_width+1:0] sum_manti_shifted;
    logic[mul_mant_width+1:0] mul_manti_shifted;

    logic[mul_mant_width+1:0] acc_manti;
    logic[mul_mant_width+1:0] acc_manti_abs_tmp;
    logic[mul_mant_width:0] acc_manti_abs;

    logic[frac_width+3:0] acc_norm_manti;

    localparam shifter_stages = $clog2(mul_mant_width);
    logic[shifter_stages-1:0] norm_shift_amount;
    /* verilator lint_off UNOPTFLAT */
    logic[mul_mant_width:0] norm_manti[shifter_stages:0];

    logic[exp_width:0] norm_shift_ext;
    logic[exp_width:0] acc_result_exp;

    /* verilator lint_off UNOPTFLAT */
    logic[frac_width-1:0] round_frac;
    logic round_carry;

    logic[exp_width:0] result_exp;

    logic is_op1_zero, is_op2_zero, is_op_sum_zero;
    logic is_op1_nan, is_op2_nan, is_op_sum_nan;
    logic is_op1_inf, is_op2_inf, is_op_sum_inf;
    
    logic is_overflow, is_underflow, is_inexact;

    function[mul_mant_width+1:0] right_shift_with_sticky(input logic[mul_mant_width+1:0] a, input logic[exp_width-1:0]shift_amount);
        right_shift_with_sticky = (a >> shift_amount) | {{(mul_mant_width+1){1'b0}}, |(a & ~({(mul_mant_width+2){1'b1}} << shift_amount))};
    endfunction

    always_comb begin
        op1_sign = op1[exp_width+frac_width];
        op2_sign = op2[exp_width+frac_width];
        op_sum_sign = op_sum[exp_width+frac_width];

        op1_exp = op1[exp_width+frac_width-1:frac_width];
        op2_exp = op2[exp_width+frac_width-1:frac_width];
        op_sum_exp = op_sum[exp_width+frac_width-1:frac_width];

        op1_frac = op1[frac_width-1:0];
        op2_frac = op2[frac_width-1:0];
        op_sum_frac = op_sum[frac_width-1:0];

        is_op1_zero = op1_exp == {exp_width{1'b0}} && (~|op1_frac);
        is_op2_zero = op2_exp == {exp_width{1'b0}} && (~|op2_frac);
        is_op_sum_zero = op_sum_exp == {exp_width{1'b0}} && (~|op_sum_frac);
        is_op1_inf = op1_exp == {exp_width{1'b1}} && (~|op1_frac);
        is_op2_inf = op2_exp == {exp_width{1'b1}} && (~|op2_frac);
        is_op_sum_inf = op_sum_exp == {exp_width{1'b1}} && (~|op_sum_frac);
        is_op1_nan = op1_exp == {exp_width{1'b1}} && (|op1_frac);
        is_op2_nan = op2_exp == {exp_width{1'b1}} && (|op2_frac);
        is_op_sum_nan = op_sum_exp == {exp_width{1'b1}} && (|op_sum_frac);

        mul_result_sign = op1_sign ^ op2_sign;

        mul_manti = ({op1_exp != {exp_width{1'b0}}, op1_frac} * {op2_exp != {exp_width{1'b0}}, op2_frac});
        mul_result_exp = op1_exp + op2_exp + {{(exp_width){1'b0}}, mul_manti[mul_mant_width-1]} - exp_bias;
        
        sum_manti = {op_sum_exp != {exp_width{1'b0}}, op_sum_frac};
        exp_diff = mul_result_exp - op_sum_exp;
        exp_diff_abs_tmp = exp_diff[exp_width] ? -exp_diff : exp_diff;
        exp_diff_abs = exp_diff_abs_tmp[exp_width-1:0];
        
        if(exp_diff[exp_width])begin // op_sum_exp > mul_result_exp
            mul_manti_shifted = right_shift_with_sticky({2'b00, mul_manti << ~mul_manti[mul_mant_width-1]}, exp_diff_abs);
            sum_manti_shifted = {2'b00, sum_manti, {(mul_mant_width-frac_width-1){1'b0}}};
            acc_result_exp = {1'b0, op_sum_exp};
        end else begin               // op_sum_exp <= mul_result_exp
            mul_manti_shifted = {2'b00, mul_manti << ~mul_manti[mul_mant_width-1]};
            sum_manti_shifted = right_shift_with_sticky({2'b00, sum_manti, {(mul_mant_width-frac_width-1){1'b0}}}, exp_diff_abs);
            acc_result_exp = mul_result_exp;
        end
        acc_manti = (mul_result_sign ? -mul_manti_shifted : mul_manti_shifted) + (op_sum_sign ? -sum_manti_shifted : sum_manti_shifted);

        result_sign = acc_manti[mul_mant_width+1];
        acc_manti_abs_tmp = result_sign ? -acc_manti : acc_manti;
        acc_manti_abs = acc_manti_abs_tmp[mul_mant_width:0];

        norm_manti[shifter_stages] = acc_manti_abs;
    end

    for(genvar s = shifter_stages-1; s >= 0; s = s - 1) begin: barrel_shifter
        assign norm_shift_amount[s] = ~|norm_manti[s+1][mul_mant_width:mul_mant_width+1-(2**s)];
        assign norm_manti[s] = norm_shift_amount[s] ? (norm_manti[s+1] << 2**s) : norm_manti[s+1];
    end

    always_comb begin
        acc_norm_manti = {norm_manti[0][mul_mant_width:mul_mant_width-frac_width-2], |norm_manti[0][mul_mant_width-frac_width-3:0]};

        norm_shift_ext = {{(exp_width-shifter_stages+1){1'b0}}, norm_shift_amount} + {(exp_width+1){1'b1}};
    end

    FloatingPointRound#(
        .frac_width(frac_width)
    )round_module(
        .sign(result_sign),
        .in_frac(acc_norm_manti[frac_width+2:0]),
        .mode(round_mode),

        .out_frac(round_frac),
        .carry(round_carry)
    );

    always_comb begin
        result_exp = acc_result_exp - norm_shift_ext + {{(exp_width){1'b0}}, round_carry};
        
        is_overflow = result_exp > (exp_bias*2);
        is_underflow = result_exp[exp_width];
        is_inexact = |acc_norm_manti[2:0];

        if(is_op1_nan) result = op1  | {{(exp_width+1){1'b0}}, 1'b1, {(frac_width-1){1'b0}}}; // quietNaN propagation
        else if(is_op2_nan) result = op2  | {{(exp_width+1){1'b0}}, 1'b1, {(frac_width-1){1'b0}}}; // quietNaN propagation
        else if(is_op1_inf & is_op2_zero | is_op1_zero & is_op2_inf) result = {1'b1, {exp_width{1'b1}}, 1'b1, {(frac_width-1){1'b0}}}; // -nan
        else if(is_op1_zero | is_op2_zero) result = {result_sign, {exp_width{1'b0}}, {frac_width{1'b0}}}; // +-zero
        else if(is_op1_inf | is_op2_inf) result = {result_sign, {exp_width{1'b1}}, {frac_width{1'b0}}}; // +-inf
        else if(is_underflow)begin
            if(|round_frac)begin
                result = {result_sign, {exp_width{1'b0}}, round_frac}; // denormal
            end else begin
                result = {result_sign, {exp_width{1'b0}}, {frac_width{1'b0}}}; // +-zero
            end
        end
        else if(is_overflow) begin
            unique case(round_mode)
                `FP_ROUND_TOWARDZERO : result = {result_sign, {(exp_width-1){1'b1}}, 1'b0, {(frac_width){1'b1}}}; // +-MAX
                `FP_ROUND_UPWARD: result = result_sign ? {result_sign, {(exp_width-1){1'b1}}, 1'b0, {(frac_width){1'b1}}} : {1'b0, {exp_width{1'b1}}, {frac_width{1'b0}}}; // -MAX or +inf
                `FP_ROUND_DOWNWARD: result = result_sign ? {result_sign, {exp_width{1'b1}}, {frac_width{1'b0}}} : {result_sign, {(exp_width-1){1'b1}}, 1'b0, {(frac_width){1'b1}}}; // -inf or +MAX
                `FP_ROUND_TONEAREST: result = {result_sign, {exp_width{1'b1}}, {frac_width{1'b0}}}; // +-inf
            endcase
        end
        else result = {result_sign, result_exp[exp_width-1:0], round_frac};
        
        exception = ({4'b0, is_overflow} << `FP_OVERFLOW) | ({4'b0, is_underflow} << `FP_UNDERFLOW) | ({4'b0, is_inexact} << `FP_INEXACT);
    end
endmodule