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

    logic op1_sign, op2_sign;
    logic[exp_width-1:0] op1_exp, op2_exp, op_sum_exp;
    logic[frac_width-1:0] op1_frac, op2_frac, op_sum_frac;

    logic[mul_mant_width-1:0] mul_mant;

    localparam shifter_stages = $clog2(frac_width+2);

    logic[mul_mant_width-1:0] mul_mant_denorm_tmp;
    logic[mul_mant_width-1:0] mul_mant_denorm;
    /* verilator lint_off UNOPTFLAT */
    logic[frac_width:0] op_frac_denorm[shifter_stages:0];
    logic[exp_width:0] denormal_shift_amount;

    logic[frac_width+2:0] norm_mul_frac;

    logic result_sign;
    /* verilator lint_off UNOPTFLAT */
    logic[frac_width-1:0] round_frac;
    logic round_carry;

    logic[exp_width:0] added_exp;
    logic[exp_width:0] result_biased_exp;
    logic[exp_width:0] result_exp;
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

        is_op1_zero = op1_exp == {exp_width{1'b0}} && (~|op1_frac);
        is_op2_zero = op2_exp == {exp_width{1'b0}} && (~|op2_frac);
        is_op1_inf = op1_exp == {exp_width{1'b1}} && (~|op1_frac);
        is_op2_inf = op2_exp == {exp_width{1'b1}} && (~|op2_frac);
        is_op1_nan = op1_exp == {exp_width{1'b1}} && (|op1_frac);
        is_op2_nan = op2_exp == {exp_width{1'b1}} && (|op2_frac);

        result_sign = op1_sign ^ op2_sign;

        op_frac_denorm[shifter_stages] = {1'b0, (op1_exp == {exp_width{1'b0}}) ? op1_frac : op2_frac};
    end
    generate
        genvar s;
        for(s = shifter_stages-1; s >= 0; s = s - 1) begin: barrel_shifter
            assign denormal_shift_amount[s] = ~|op_frac_denorm[s+1][frac_width:frac_width-(2**s)+1];
            assign op_frac_denorm[s] = denormal_shift_amount[s] ? (op_frac_denorm[s+1] << 2**s) : op_frac_denorm[s+1];
        end
    endgenerate

    always_comb begin
        mul_mant = ({op1_exp != {exp_width{1'b0}}, op1_frac} * {op2_exp != {exp_width{1'b0}}, op2_frac});
        denormal_shift_amount[exp_width:shifter_stages] = {(exp_width-shifter_stages+1){1'b0}};

        if((op1_exp == {exp_width{1'b0}}) ^ (op2_exp == {exp_width{1'b0}}))begin // an input is denormal
            mul_mant_denorm_tmp = mul_mant << (denormal_shift_amount);
            if(op1_exp + op2_exp + 1 + {{(exp_width){1'b0}}, mul_mant_denorm_tmp[mul_mant_width-1]}> exp_bias + denormal_shift_amount)begin // result is normal
                mul_mant_denorm = mul_mant_denorm_tmp;
                added_exp = op1_exp + op2_exp + {{(exp_width){1'b0}}, mul_mant_denorm[mul_mant_width-1]} - denormal_shift_amount + 1;
            end else begin // result is denormal
                mul_mant_denorm = (
                    (mul_mant >> (exp_bias + (frac_width - 3) - (op1_exp + op2_exp)))
                    | {{(mul_mant_width-1){1'b0}},|(mul_mant & ~({mul_mant_width{1'b1}} << (exp_bias + (frac_width-3) - (op1_exp + op2_exp))))}
                ) << (frac_width-3);
                added_exp = 0;
            end
            unique case(mul_mant_denorm[mul_mant_width-1])
                1'b1: norm_mul_frac = {mul_mant_denorm[mul_mant_width-2:mul_mant_width-frac_width-3], |mul_mant_denorm[mul_mant_width-frac_width-4:0]};
                1'b0: norm_mul_frac = {mul_mant_denorm[mul_mant_width-3:mul_mant_width-frac_width-4], |mul_mant_denorm[mul_mant_width-frac_width-5:0]};
            endcase
        end else if((op1_exp + op2_exp + {{(exp_width){1'b0}}, mul_mant[mul_mant_width-1]}) <= exp_bias)begin // result is denormal
            added_exp = op1_exp + op2_exp;
            mul_mant_denorm = (mul_mant >> (exp_bias - added_exp)
            | {{(mul_mant_width-1){1'b0}},|(mul_mant & ~({mul_mant_width{1'b1}} << (exp_bias - added_exp)))});
            norm_mul_frac = {mul_mant_denorm[mul_mant_width-2:mul_mant_width-frac_width-3], |mul_mant_denorm[mul_mant_width-frac_width-4:0]};
        end else begin
            added_exp = op1_exp + op2_exp + {{(exp_width){1'b0}}, mul_mant[mul_mant_width-1]};
            unique case(mul_mant[mul_mant_width-1])
                1'b1: norm_mul_frac = {mul_mant[mul_mant_width-2:mul_mant_width-frac_width-3], |mul_mant[mul_mant_width-frac_width-4:0]};
                1'b0: norm_mul_frac = {mul_mant[mul_mant_width-3:mul_mant_width-frac_width-4], |mul_mant[mul_mant_width-frac_width-5:0]};
            endcase
        end
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
        result_biased_exp = added_exp + {{(exp_width){1'b0}}, round_carry};
        
        is_overflow = result_biased_exp > (exp_bias*3);
        is_underflow = exp_bias >= result_biased_exp;
        is_inexact = |norm_mul_frac[2:0];
        
        result_exp = result_biased_exp - exp_bias;

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