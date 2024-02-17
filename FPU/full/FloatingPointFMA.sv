`include "FloatingPointConsts.svh"

module FloatingPointFMA#(
    parameter exp_width = 8,
    parameter frac_width = 23
)(
    input logic[exp_width+frac_width:0] op1,
    input logic[exp_width+frac_width:0] op2,
    input logic[exp_width+frac_width:0] op_acc,
    input logic[1:0] round_mode,

    output logic[exp_width+frac_width:0] result,
    output logic[4:0] exception
);
    localparam exp_bias = (2**(exp_width-1))-1;

    logic op1_sign, op2_sign, op_acc_sign;
    logic[exp_width-1:0] op1_exp, op2_exp, op_acc_exp;
    logic[frac_width-1:0] op1_frac, op2_frac, op_acc_frac;

    logic is_op1_zero, is_op2_zero, is_op_acc_zero;
    logic is_op1_nan, is_op2_nan, is_op_acc_nan;
    logic is_op1_inf, is_op2_inf, is_op_acc_inf;


    always_comb begin
        op1_sign = op1[exp_width+frac_width];
        op2_sign = op2[exp_width+frac_width];
        op_acc_sign = op_acc[exp_width+frac_width];

        op1_exp = op1[exp_width+frac_width-1:frac_width];
        op2_exp = op2[exp_width+frac_width-1:frac_width];
        op_acc_exp = op_acc[exp_width+frac_width-1:frac_width];

        op1_frac = op1[frac_width-1:0];
        op2_frac = op2[frac_width-1:0];
        op_acc_frac = op_acc[frac_width-1:0];

        is_op1_zero = op1_exp == 0 && (~|op1_frac);
        is_op2_zero = op2_exp == 0 && (~|op2_frac);
        is_op_acc_zero = op_acc_exp == 0 && (~|op_acc_frac);
        is_op1_inf = op1_exp == {exp_width{1'b1}} && (~|op1_frac);
        is_op2_inf = op2_exp == {exp_width{1'b1}} && (~|op2_frac);
        is_op_acc_inf = op_acc_exp == {exp_width{1'b1}} && (~|op_acc_frac);
        is_op1_nan = op1_exp == {exp_width{1'b1}} && (|op1_frac);
        is_op2_nan = op2_exp == {exp_width{1'b1}} && (|op2_frac);
        is_op_acc_nan = op_acc_exp == {exp_width{1'b1}} && (|op_acc_frac);
    end

    localparam mul_mant_width = (frac_width+1)*2;
    
    logic[frac_width:0] op1_manti, op2_manti;

    logic[mul_mant_width-1:0] mul_manti;
    logic mul_result_sign;
    logic[exp_width+1:0] mul_result_exp;

    always_comb begin
        mul_result_sign = op1_sign ^ op2_sign;
        
        op1_manti = (op1_exp == 0) ? {op1_frac, 1'b0} : {1'b1, op1_frac};
        op2_manti = (op2_exp == 0) ? {op2_frac, 1'b0} : {1'b1, op2_frac};

        mul_manti = op1_manti * op2_manti;

        mul_result_exp = {1'b0, {1'b0, op1_exp} + {1'b0, op2_exp}} - exp_bias;
    end

    logic[frac_width:0] op_acc_manti;

    logic[exp_width+1:0] exp_diff_abs_tmp;
    logic[exp_width:0] exp_diff_abs;
    
    
    logic[mul_mant_width+1:0] mul_manti_ext, op_acc_manti_ext;
    logic[mul_mant_width+1:0] big_manti, small_manti, acc_manti;
    logic big_sign;

    logic[exp_width+1:0] acc_result_exp;

    logic[mul_mant_width+1:0] acc_manti_abs_tmp;
    logic[mul_mant_width:0] acc_manti_abs;

    logic result_sign;
    logic is_mul_exp_big;

    localparam shifter_stages = $clog2(mul_mant_width+2);
    /* verilator lint_off UNOPTFLAT */
    logic[mul_mant_width+1:0] right_shift_with_sticky_acc[shifter_stages:0];
    logic[exp_width:0] shift_amount;
    generate
        genvar i;
        for(i = 0; i < shifter_stages; i = i+1)begin
            assign right_shift_with_sticky_acc[i] = !shift_amount[i] ? right_shift_with_sticky_acc[i+1]:
                   {right_shift_with_sticky_acc[i+1][mul_mant_width+1:1] >> (2**i), |right_shift_with_sticky_acc[i+1][2**i:0]};
        end
    endgenerate

    always_comb begin
        op_acc_manti = (op_acc_exp == 0) ? {op_acc_frac, 1'b0} : {1'b1, op_acc_frac};
        mul_manti_ext = {2'b00, mul_manti};
        op_acc_manti_ext = {3'b000, op_acc_manti, {(mul_mant_width-frac_width-2){1'b0}}};

        is_mul_exp_big = $signed({2'b00, op_acc_exp}) < $signed(mul_result_exp);
        exp_diff_abs_tmp = is_mul_exp_big ? (mul_result_exp - {2'b00, op_acc_exp}) : ({2'b00, op_acc_exp} - mul_result_exp);
        exp_diff_abs = exp_diff_abs_tmp[exp_width:0];

        big_manti = is_mul_exp_big ? mul_manti_ext : op_acc_manti_ext;
        right_shift_with_sticky_acc[shifter_stages] = is_mul_exp_big ? op_acc_manti_ext : mul_manti_ext;
        shift_amount = exp_diff_abs;
        small_manti = |shift_amount[exp_width:shifter_stages-1] ? {{(mul_mant_width+1){1'b0}}, |right_shift_with_sticky_acc[shifter_stages]} : right_shift_with_sticky_acc[0];
        big_sign = is_mul_exp_big ? mul_result_sign : op_acc_sign;
        acc_result_exp = is_mul_exp_big ? mul_result_exp : {2'b00, op_acc_exp};

        acc_manti = big_manti + (mul_result_sign ^ op_acc_sign ? -small_manti : small_manti);

        result_sign = big_sign ^ ($signed(acc_manti) < 0);
        acc_manti_abs_tmp = ($signed(acc_manti) < 0) ? -acc_manti : acc_manti;
        acc_manti_abs = acc_manti_abs_tmp[mul_mant_width:0];
    end

    localparam lzc_bits = $clog2(2**$clog2(mul_mant_width+1)+1);
    logic[lzc_bits-1:0] norm_shift_amount;

    LeadingZerosCounter#(
        .in_width(mul_mant_width+1)
    )lzc(
        .Di(acc_manti_abs),
        .Do(norm_shift_amount)
    );

    logic[frac_width+3:0] acc_norm_manti;
    logic[exp_width+1:0] norm_shift_ext;

    logic[mul_mant_width:0] norm_manti;

    always_comb begin
        norm_shift_ext = {{(exp_width-lzc_bits+2){1'b0}}, norm_shift_amount};
        if(acc_result_exp + 2 <= norm_shift_ext)begin // denormal
            norm_manti = acc_manti_abs << (acc_result_exp + 1);
        end else begin
            norm_manti = acc_manti_abs << norm_shift_ext;
        end

        acc_norm_manti = {norm_manti[mul_mant_width:mul_mant_width-frac_width-2], |norm_manti[mul_mant_width-frac_width-3:0]};
    end

    /* verilator lint_off UNOPTFLAT */
    logic[frac_width-1:0] round_frac;
    logic round_carry;

    logic[exp_width+1:0] result_exp;

    FloatingPointRound#(
        .frac_width(frac_width)
    )round_module(
        .sign(result_sign),
        .in_frac(acc_norm_manti[frac_width+2:0]),
        .mode(round_mode),

        .out_frac(round_frac),
        .carry(round_carry)
    );

    logic is_overflow, is_underflow, is_inexact;

    always_comb begin
        result_exp = acc_result_exp + 2 - norm_shift_ext + {{(exp_width+1){1'b0}}, round_carry};
        
        is_overflow = result_exp[exp_width] | &result_exp[exp_width-1:0];
        is_underflow = !(|acc_norm_manti[frac_width+3:frac_width+2]) & !round_carry;
        is_inexact = |acc_norm_manti[2:0];

        if(is_op_acc_nan) result = op_acc | {{(exp_width+1){1'b0}}, 1'b1, {(frac_width-1){1'b0}}}; // quietNaN propagation
        else if(is_op1_nan | is_op2_nan) result = (is_op1_nan ? op1 : op2) | {{(exp_width+1){1'b0}}, 1'b1, {(frac_width-1){1'b0}}}; // quietNaN propagation
        else if(is_op1_inf & is_op2_zero | is_op1_zero & is_op2_inf) result = {1'b1, {exp_width{1'b1}}, 1'b1, {(frac_width-1){1'b0}}}; // -nan
        else if(is_op1_inf | is_op2_inf | is_op_acc_inf) result = {result_sign, {exp_width{1'b1}}, {frac_width{1'b0}}}; // +-inf
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
                `FP_ROUND_UPWARD: result = result_sign ? {1'b1, {(exp_width-1){1'b1}}, 1'b0, {(frac_width){1'b1}}} : {1'b0, {exp_width{1'b1}}, {frac_width{1'b0}}}; // -MAX or +inf
                `FP_ROUND_DOWNWARD: result = result_sign ? {1'b1, {exp_width{1'b1}}, {frac_width{1'b0}}} : {1'b0, {(exp_width-1){1'b1}}, 1'b0, {(frac_width){1'b1}}}; // -inf or +MAX
                `FP_ROUND_TONEAREST: result = {result_sign, {exp_width{1'b1}}, {frac_width{1'b0}}}; // +-inf
            endcase
        end
        else result = {result_sign, result_exp[exp_width-1:0], round_frac};
        
        exception = ({4'b0, is_overflow} << `FP_OVERFLOW) | ({4'b0, is_underflow} << `FP_UNDERFLOW) | ({4'b0, is_inexact} << `FP_INEXACT);
    end
endmodule