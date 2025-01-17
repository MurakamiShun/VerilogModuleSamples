module Multiplier#(
    parameter LATENCY = 3,
    parameter WIDTH = 32
)(
    input logic clk,
    input logic rst_n,

    input logic[WIDTH-1:0] op1,
    input logic op1_sign,
    input logic[WIDTH-1:0] op2,
    input logic op2_sign,

    output logic[WIDTH*2-1:0] result
);


logic[(WIDTH-1)*2-1:0] delay_reg[LATENCY-2:0];
logic[WIDTH:0] sign_term[LATENCY-2:0];

logic[WIDTH-2:0] op1_upper_term;
logic[WIDTH-2:0] op2_upper_term;

always_comb begin
   op1_upper_term = {(WIDTH-1){op2_sign}} ^ ({(WIDTH-1){op2[WIDTH-1]}} & op1[WIDTH-2:0]);
   op2_upper_term = {(WIDTH-1){op1_sign}} ^ ({(WIDTH-1){op1[WIDTH-1]}} & op2[WIDTH-2:0]);
end

always_ff@(posedge clk) begin
    if(!rst_n)begin
        for(integer i = 0; i <= LATENCY-2; i = i + 1)begin
            delay_reg[i] <= '0;
            sign_term[i] <= '0;
        end
    end else begin
        delay_reg[0] <= op1[WIDTH-2:0] * op2[WIDTH-2:0];
        sign_term[0] <=
            + {1'b0, (op1_sign ^ op2_sign) ^ (op1[WIDTH-1] & op2[WIDTH-1]), op1_upper_term}
            + {1'b0, 1'b0                                                 , op2_upper_term}
            + {op1_sign | op2_sign, {(WIDTH-2){1'b0}}, op1_sign & op2_sign, op1_sign ^ op2_sign};
        for(integer i = 1; i <= LATENCY-2; i = i + 1)begin
            delay_reg[i] <= delay_reg[i-1];
            sign_term[i] <= sign_term[i-1];
        end
    end
    result <= {2'b0, delay_reg[LATENCY-2]} + {sign_term[LATENCY-2], {(WIDTH-1){1'b0}}};
end


endmodule

