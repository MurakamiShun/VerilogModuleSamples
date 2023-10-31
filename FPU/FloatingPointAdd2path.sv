`include "FloatingPointConsts.svh"

module FloatingPointAdd2path#(
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
    logic[exp_width:0] exp_diff, exp_diff_abs_tmp;
    logic[exp_width-1:0] exp_diff_abs;

    logic[exp_width+frac_width:0] op_big, op_small;
    logic op_big_sign, op_small_sign;
    logic[exp_width-1:0] op_big_exp, op_small_exp;

    logic[frac_width+1:0] op1_manti, op2_manti;
    logic[frac_width+5:0] op_big_manti, op_small_manti;

    logic[frac_width+5:0] op_small_manti_shifted;

    logic[frac_width+5:0] added_manti;
    logic[frac_width+5:0] added_manti_abs_tmp;
    logic[frac_width+4:0] added_manti_abs;
    logic[frac_width+4:0] denormed_result;

    localparam shifter_stages = $clog2(frac_width+5);
    logic[shifter_stages-1:0] norm_shift;
    /* verilator lint_off UNOPTFLAT */
    logic[frac_width+4:0] norm_manti[shifter_stages:0];

    logic[frac_width+4:0] norm_manti_merge;

    logic[frac_width-1:0] round_frac;
    logic round_carry;

    logic[exp_width:0] norm_shift_ext;
    logic[exp_width:0] result_exp;
    logic result_sign;

    logic is_op1_zero, is_op2_zero;
    logic is_op1_nan, is_op2_nan;
    logic is_op1_inf, is_op2_inf;

    logic is_overflow, is_underflow, is_inexact;

    always_comb begin
        op1_exp = op1[exp_width+frac_width-1:frac_width];
        op2_exp = op2[exp_width+frac_width-1:frac_width];

        is_op1_zero = op1_exp == {exp_width{1'b0}} && (~|op1[frac_width-1:0]);
        is_op2_zero = op2_exp == {exp_width{1'b0}} && (~|op2[frac_width-1:0]);
        is_op1_inf = op1_exp == {exp_width{1'b1}} && (~|op1[frac_width-1:0]);
        is_op2_inf = op2_exp == {exp_width{1'b1}} && (~|op2[frac_width-1:0]);
        is_op1_nan = op1_exp == {exp_width{1'b1}} && (|op1[frac_width-1:0]);
        is_op2_nan = op2_exp == {exp_width{1'b1}} && (|op2[frac_width-1:0]);

        exp_diff = op1_exp - op2_exp;

        op_big = exp_diff[exp_width] ? op2 : op1;
        op_small = exp_diff[exp_width] ? op1 : op2;

        exp_diff_abs_tmp = exp_diff[exp_width] ? -exp_diff : exp_diff;
        exp_diff_abs = exp_diff_abs_tmp[exp_width-1:0];

        op_big_sign = op_big[exp_width+frac_width];
        op_small_sign = op_small[exp_width+frac_width];

        op_big_exp = op_big[exp_width+frac_width-1:frac_width];
        op_small_exp = op_small[exp_width+frac_width-1:frac_width];

        op1_manti = (op1_exp == 0) ? {1'b0, op1[frac_width-1:0], 1'b0} : {2'b01, op1[frac_width-1:0]};
        op2_manti = (op2_exp == 0) ? {1'b0, op2[frac_width-1:0], 1'b0} : {2'b01, op2[frac_width-1:0]};

        op_big_manti = {1'b0, exp_diff[exp_width] ? op2_manti : op1_manti, 3'b000};
        op_small_manti = {1'b0, exp_diff[exp_width] ? op1_manti : op2_manti, 3'b000};

        if(exp_diff_abs == 0)begin
            op_small_manti_shifted = op_small_manti;
        end else if(exp_diff_abs == 1)begin
            op_small_manti_shifted = op_small_manti >> 1;
        end else begin
            op_small_manti_shifted = (op_small_manti >> exp_diff_abs) | {{(frac_width+5){1'b0}}, |(op_small_manti & ~({(frac_width+6){1'b1}} << exp_diff_abs))};
        end

        added_manti = op_big_manti + ((op_big_sign ^ op_small_sign) ? -op_small_manti_shifted : op_small_manti_shifted);
        
        if(exp_diff_abs == 0 || exp_diff_abs == 1)begin
            result_sign = (op_big_sign ^ added_manti[frac_width+5]);
            added_manti_abs_tmp = (added_manti[frac_width+5] ? -added_manti : added_manti); // absolute
            added_manti_abs = added_manti_abs_tmp[frac_width+4:0];
            norm_manti[shifter_stages] = added_manti_abs;
            // normalize shift
            norm_manti_merge = norm_manti[0];
            norm_shift_ext = {{(exp_width-shifter_stages+1){1'b0}}, norm_shift};
        end else begin
            result_sign = op_big_sign;
            added_manti_abs = added_manti[frac_width+4:0];

            if(added_manti[frac_width+4])begin // carry up
                norm_manti_merge = added_manti[frac_width+4:0];
                norm_shift_ext = 0;
            end else if(added_manti[frac_width+3])begin
                norm_manti_merge = {added_manti[frac_width+3:0], 1'b0};
                norm_shift_ext = 1;
            end else begin  // carry down
                norm_manti_merge = {added_manti[frac_width+2:0], 2'b00};
                norm_shift_ext = 2;
            end
        end
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
        .in_frac({norm_manti_merge[frac_width+3:2], |norm_manti_merge[1:0]}),
        .mode(round_mode),

        .out_frac(round_frac),
        .carry(round_carry)
    );

    always_comb begin
        result_exp = op_big_exp + 1 - norm_shift_ext + {{(exp_width){1'b0}}, round_carry};
        denormed_result = added_manti_abs << (op_big_exp + 1);

        is_underflow = result_exp[exp_width] | result_exp == 0;
        is_overflow = ~is_underflow & (&result_exp[exp_width-1:0]);
        is_inexact = |{norm_manti_merge[2:0]};

        if(is_op1_nan | is_op2_nan)begin
            result = (is_op1_nan ? op1 : op2) | {{(exp_width+1){1'b0}}, 1'b1, {(frac_width-1){1'b0}}}; // quietNaN propagation
        end else if(is_op1_inf | is_op2_inf)begin
            if(is_op1_inf & is_op2_inf & (op_big_sign^op_small_sign))begin
                result = {{(exp_width+1){1'b1}}, 1'b1, {(frac_width-1){1'b0}}}; // -nan
            end else begin
                result = {result_sign, {exp_width{1'b1}}, {frac_width{1'b0}}}; // +-inf
            end
        end else if(~norm_manti_merge[frac_width+4]) begin // +-zero
            unique case(round_mode)
                `FP_ROUND_DOWNWARD: result = {op_big_sign | op_small_sign, {exp_width{1'b0}}, {frac_width{1'b0}}};
                default: result = {op_big_sign & op_small_sign, {exp_width{1'b0}}, {frac_width{1'b0}}};
            endcase
        end else if(is_overflow | is_underflow)begin
            if(is_underflow)begin
                result = {result_sign, {exp_width{1'b0}}, round_carry ? denormed_result[frac_width+3:4] : denormed_result[frac_width+4:5]};
            end else begin
            unique case(round_mode)
                `FP_ROUND_TONEAREST:result = {result_sign, {exp_width{1'b1}}, {frac_width{1'b0}}}; // +-inf
                `FP_ROUND_UPWARD:  result = result_sign ? {1'b1, {(exp_width-1){1'b1}}, 1'b0, {(frac_width){1'b1}}} : {1'b0, {exp_width{1'b1}}, {frac_width{1'b0}}}; // -MAX or +inf
                `FP_ROUND_DOWNWARD: result = result_sign ? {1'b1, {exp_width{1'b1}}, {frac_width{1'b0}}} : {1'b0, {(exp_width-1){1'b1}}, 1'b0, {(frac_width){1'b1}}}; // -inf or +MAX
                `FP_ROUND_TOWARDZERO: result = {result_sign, {(exp_width-1){1'b1}}, 1'b0, {frac_width{1'b1}}}; // +-MAX
            endcase
            end
        end
        else begin
            result = {result_sign, result_exp[exp_width-1:0], round_frac};
        end

        exception = ({4'b0, is_overflow} << `FP_OVERFLOW) | ({4'b0, is_underflow} << `FP_UNDERFLOW) | ({4'b0, is_inexact} << `FP_INEXACT);
    end
endmodule