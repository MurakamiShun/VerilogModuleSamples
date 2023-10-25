`include "FloatingPointConsts.svh"

module FloatingPointAdd#(
    parameter exp_width = 8,
    parameter frac_width = 23
)(
    input logic[exp_width+frac_width:0] op1,
    input logic[exp_width+frac_width:0] op2,
    input logic[1:0] round_mode,

    output logic[exp_width+frac_width:0] result,
    output logic[4:0] exception
);
    logic[exp_width-1:0] op1_exp, op2_exp;

    logic[exp_width+frac_width:0] op_big, op_small;
    logic op_big_sign, op_small_sign;
    logic[exp_width-1:0] op_big_exp, op_small_exp;

    logic[frac_width+5:0] op_big_manti, op_small_manti;
    logic[frac_width+5:0] op_small_manti_shifted;
    logic[exp_width-1:0] exp_diff;

    logic[frac_width+5:0] added_manti;
    logic[frac_width+5:0] added_manti_abs;

    localparam shifter_stages = $clog2(frac_width+5);
    logic[shifter_stages-1:0] norm_shift;
    /* verilator lint_off UNOPTFLAT */
    logic[frac_width+4:0] norm_manti[shifter_stages:0];

    logic[frac_width-1:0] round_frac;
    logic round_carry;

    logic[exp_width:0] norm_shift_ext;
    logic[exp_width:0] result_exp_before_norm_shift;
    logic[exp_width:0] result_exp;
    logic result_sign;

    logic is_op_big_zero, is_op_small_zero;
    logic is_op_big_nan, is_op_small_nan;
    logic is_op_big_inf, is_op_small_inf;

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

        exp_diff = op_big_exp - op_small_exp;

        op_big_manti = {2'b00, op_big_exp != {exp_width{1'b0}}, op_big[frac_width-1:0], 3'b000} << (op_big_exp == {exp_width{1'b0}});
        op_small_manti = {2'b00, op_small_exp != {exp_width{1'b0}}, op_small[frac_width-1:0], 3'b000} << (op_small_exp == {exp_width{1'b0}});

        op_small_manti_shifted = (op_small_manti >> exp_diff) | {{(frac_width+5){1'b0}}, |(op_small_manti & ~({(frac_width+6){1'b1}} << exp_diff))};

        is_op_big_zero = op_big_exp == {exp_width{1'b0}} && (~|op_big[frac_width-1:0]);
        is_op_small_zero = op_small_exp == {exp_width{1'b0}} && (~|op_small[frac_width-1:0]);
        is_op_big_inf = op_big_exp == {exp_width{1'b1}} && (~|op_big[frac_width-1:0]);
        is_op_small_inf = op_small_exp == {exp_width{1'b1}} && (~|op_small[frac_width-1:0]);
        is_op_big_nan = op_big_exp == {exp_width{1'b1}} && (|op_big[frac_width-1:0]);
        is_op_small_nan = op_small_exp == {exp_width{1'b1}} && (|op_small[frac_width-1:0]);

        added_manti = (op_big_sign ? -op_big_manti : op_big_manti) + (op_small_sign ? -op_small_manti_shifted : op_small_manti_shifted);
        result_sign = added_manti[frac_width+5];
        
        added_manti_abs = (result_sign ? -added_manti : added_manti); // absolute
        norm_manti[shifter_stages] = added_manti_abs[frac_width+4:0];
    end

    generate
    genvar s;
    for(s = shifter_stages-1; s >= 0; s = s - 1) begin: barrel_shifter
        assign norm_shift[s] = ~|norm_manti[s+1][frac_width+4:frac_width+5-(2**s)];
        assign norm_manti[s] = norm_shift[s] ? (norm_manti[s+1] << 2**s) : norm_manti[s+1];
    end
    endgenerate
    
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
        norm_shift_ext = {{(exp_width-shifter_stages+1){1'b0}}, norm_shift};
        result_exp_before_norm_shift = op_big_exp + {{(exp_width-2){1'b0}}, (round_carry+2'b01)};
        result_exp = result_exp_before_norm_shift - norm_shift_ext;

        is_underflow = result_exp_before_norm_shift < norm_shift_ext;
        is_overflow = ~is_underflow & result_exp[exp_width];
        is_inexact = |{norm_manti[0][2:0]};

        if(is_op_big_nan) result = op_big | {{(exp_width+1){1'b0}}, 1'b1, {(frac_width-1){1'b0}}}; // quietNaN propagation
        else if(is_op_small_nan) result = op_small  | {{(exp_width+1){1'b0}}, 1'b1, {(frac_width-1){1'b0}}}; // quietNaN propagation
        else if(is_op_big_inf & is_op_small_inf & (op_big_sign^op_small_sign))begin
            result = {{(exp_width+1){1'b1}}, 1'b1, {(frac_width-1){1'b0}}}; // -nan
        end
        else if(is_op_big_inf | is_op_small_inf | is_overflow) result = {result_sign, {exp_width{1'b1}}, {frac_width{1'b0}}}; // +-inf
        else if(~|added_manti) begin // +-zero
            unique case(round_mode)
                `FP_ROUND_DOWNWARD: result = {op_big_sign | op_small_sign, {exp_width{1'b0}}, {frac_width{1'b0}}};
                default: result = {op_big_sign & op_small_sign, {exp_width{1'b0}}, {frac_width{1'b0}}};
            endcase
        end
        else result = {result_sign, result_exp[exp_width-1:0], round_frac};

        exception = ({4'b0, is_overflow} << `FP_OVERFLOW) | ({4'b0, is_underflow} << `FP_UNDERFLOW) | ({4'b0, is_inexact} << `FP_INEXACT);
    end
endmodule