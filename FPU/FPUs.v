`define ROUND_TONEAREST 2'b00
`define ROUND_TOWARDZERO 2'b01
`define ROUND_DOWNWARD 2'b10
`define ROUND_UPWARD 2'b11

module F32_round(
    input wire sign,
    input wire[26:0] in_frac,
    input wire[1:0] mode,

    output wire[23:0] out_frac,
    output wire carry
);
    //wire G = in_frac[2];
    //wire R = in_frac[1];
    //wire S = in_frac[0];
    wire[24:0] norm_in_frac = {1'b0, in_frac[26:3]};

    wire[24:0] TONEAREST = norm_in_frac+(in_frac[2] & ((in_frac[3] & ~|in_frac[1:0]) | (|in_frac[1:0])));
    wire[24:0] TOWARDZERO = norm_in_frac;
    wire[24:0] DOWNWARD = norm_in_frac+(sign & |in_frac[2:0]);
    wire[24:0] UPWARD = norm_in_frac+(~sign & |in_frac[2:0]);

    wire[24:0] tmp_frac = (mode == `ROUND_TOWARDZERO) ? TOWARDZERO:
        (mode == `ROUND_DOWNWARD) ? DOWNWARD:
        (mode == `ROUND_UPWARD) ? UPWARD:
        TONEAREST;

    assign out_frac = tmp_frac[24] ? tmp_frac[24:1] : tmp_frac[23:0];
    assign carry = tmp_frac[24];

endmodule

module F32_mul(
    input wire CLK,
    input wire RST,
    input wire en,
    input wire[31:0] op1,
    input wire[31:0] op2,
    input wire[1:0] round_mode,

    output wire[31:0] result,
    output wire exception
);

    wire op1_sign = op1[31];
    wire op2_sign = op2[31];

    wire[7:0] op1_exp = op1[30:23];
    wire[7:0] op2_exp = op2[30:23];

    wire[22:0] op1_frac = op1[22:0];
    wire[22:0] op2_frac = op2[22:0];

    wire[47:0] frac_mul = {1'b1, op1_frac} * {1'b1, op2_frac}; 
    
    wire[26:0] norm_frac_mul = frac_mul[47] ? {frac_mul[47:22], |frac_mul[21:0]} : {frac_mul[46:21], |frac_mul[20:0]};
    
    wire mul_carry = frac_mul[47];

    wire result_sign = op1_sign ^ op2_sign;
    wire[23:0] round_frac;
    wire round_carry;

    F32_round round_module(
        .sign(result_sign),
        .in_frac(norm_frac_mul),
        .mode(round_mode),

        .out_frac(round_frac),
        .carry(round_carry)
    );

    wire[7:0] result_exp = (op1_exp + op2_exp - 8'd127) + (round_carry + mul_carry);

    wire is_zero = (op1_exp == 0 && (~|op1_frac) || op2_exp == 0 && (~|op2_frac));

    assign result = is_zero ? {result_sign, 8'h0, 23'h0} :
        {result_sign, result_exp, round_frac[22:0]};
endmodule

module F32_add(
    input wire[31:0] op1,
    input wire[31:0] op2,
    input wire[1:0] round_mode,

    output wire[31:0] result,
    output wire exception
);
    wire[7:0] op1_exp = op1[30:23];
    wire[7:0] op2_exp = op2[30:23];

    wire[31:0] op_big = (op1_exp > op2_exp) ? op1 : op2;
    wire[31:0] op_small = (op1_exp > op2_exp) ? op2 : op1;

    wire op_big_sign = op_big[31];
    wire op_small_sign = op_small[31];

    wire[7:0] op_big_exp = op_big[30:23];
    wire[7:0] op_small_exp = op_small[30:23];

    wire[49:0] op_big_frac = {3'b001, op_big[22:0], 24'h0};
    wire[49:0] op_small_frac = {3'b001, op_small[22:0], 24'h0} >> (op_big_exp - op_small_exp);

    wire[49:0] add_frac = (op_big_sign ? -op_big_frac : op_big_frac) + (op_small_sign ? -op_small_frac : op_small_frac);
    wire[48:0] add_abs_frac = add_frac[49] ? -add_frac : add_frac;

    wire[48:0] add_norm_frac6 = norm_shift[5] ? (add_abs_frac << 32) : add_abs_frac;
    wire[48:0] add_norm_frac5 = norm_shift[4] ? (add_norm_frac6 << 16) : add_norm_frac6;
    wire[48:0] add_norm_frac4 = norm_shift[3] ? (add_norm_frac5 << 8) : add_norm_frac5;
    wire[48:0] add_norm_frac3 = norm_shift[2] ? (add_norm_frac4 << 4) : add_norm_frac4;
    wire[48:0] add_norm_frac2 = norm_shift[1] ? (add_norm_frac3 << 2) : add_norm_frac3;
    wire[48:0] add_norm_frac1 = norm_shift[0] ? (add_norm_frac2 << 1) : add_norm_frac2;
    wire[5:0] norm_shift = ~{
        |add_abs_frac[48:17],
        |add_norm_frac6[48:33],
        |add_norm_frac5[48:41],
        |add_norm_frac4[48:45],
        |add_norm_frac3[48:47],
        add_norm_frac2[48]
    };
    wire[23:0] round_frac;

    F32_round round_module(
        .sign(add_frac[49]),
        .in_frac({add_norm_frac1[48:23], |add_norm_frac1[22:0]}),
        .mode(round_mode),

        .out_frac(round_frac),
        .carry(round_carry)
    );
    wire[7:0] result_exp = op_big_exp - norm_shift + (round_carry+1);

    assign result = (~|add_abs_frac) ? {op1[31] & op2[31], 31'h0}:
        (~|op1[30:0]) ? op2:
        (~|op2[30:0]) ? op1:
        {add_frac[49], result_exp, round_frac[22:0]};
endmodule

`define FPU_ADD 1
`define FPU_MUL 2

module FPU(
    input wire CLK,
    input wire RST,
    input wire[31:0] op1,
    input wire[31:0] op2,
    input wire[31:0] op3,
    input wire[4:0] funct,
    input wire[1:0] round_mode,

    output wire[31:0] result
);
wire[31:0] mul_result, add_result;

F32_mul f32_mul(
    .op1(op1),
    .op2(op2),
    .round_mode(round_mode),

    .result(mul_result),
    .exception()
);

F32_add f32_add(
    .op1(op1),
    .op2(op2),
    .round_mode(round_mode),

    .result(add_result),
    .exception()
);

assign result = (funct == `FPU_ADD) ? add_result : mul_result;

endmodule
