module LeadingZerosCounter#(
    parameter in_width = 32 // assert(in_width >= 4)
)(
    input wire[in_width-1:0] Di,
    output wire[$clog2(2**$clog2(in_width)+1)-1:0] Do
);

localparam in_width_exp2 = 2**$clog2(in_width);
localparam out_width = $clog2(in_width_exp2+1);
wire[in_width_exp2-1:0] Di_reverse;
wire[in_width_exp2/2-1:0] Di_nor;
wire[in_width_exp2/4-1:0] Di_nor_and;

    for(genvar i = 0; i < in_width_exp2; i = i+1)begin
        assign Di_reverse[i] = (in_width-1 >= i) ? Di[in_width-1-i] : 1;
    end
    for(genvar i = 0; i < in_width_exp2/2; i = i+1)begin
        assign Di_nor[i] = ~(Di_reverse[i*2] | Di_reverse[i*2+1]);
    end
    for(genvar i = 0; i < in_width_exp2/4; i = i+1)begin
        assign Di_nor_and[i] = Di_nor[i*2] & Di_nor[i*2+1];
    end

// in_width_exp2
assign Do[out_width-1] = &Di_nor_and[in_width_exp2/4-1:0];

for(genvar i = 2; i < out_width-1; i = i + 1)begin
    wire[in_width_exp2/(2**(i+1))-1:0] result_bit_n;
    localparam pow2 = 2**(i-1);
    localparam pow2_width = 2**(i-2);
    for(genvar k = 0; k < in_width_exp2/(2**(i+1)); k = k + 1)begin
        assign result_bit_n[k] = &Di_nor_and[k * pow2 + pow2_width - 1:0] & ~&Di_nor_and[k * pow2 + pow2_width*2-1:k * pow2 + pow2_width];
    end
    assign Do[i] = |result_bit_n[in_width_exp2/(2**(i+1))-1:0];
end

// 2
wire[in_width_exp2/4-1:0] result_bit1;
assign result_bit1[0] = Di_nor[0] & ~Di_nor[1];
for(genvar i = 1; i < in_width_exp2/4; i = i + 1)begin
    assign result_bit1[i] = (Di_nor[i*2] & &Di_nor_and[i-1:0])  & ~&Di_nor[i*2+1];
end
assign Do[1] = |result_bit1[in_width_exp2/4-1:0];

// 1
wire[in_width_exp2/2-1:0] result_bit0;
assign result_bit0[0] = ~Di_reverse[0] & Di_reverse[1];
assign result_bit0[1] = (Di_nor[0] & ~Di_reverse[2]) & Di_reverse[3];
for(genvar i = 2; i < in_width_exp2/2; i = i + 1)begin
    if(i%2 == 0) assign result_bit0[i] = (              &Di_nor_and[i/2-1:0] & ~Di_reverse[i*2]) & Di_reverse[i*2+1];
    else         assign result_bit0[i] = (Di_nor[i-1] & &Di_nor_and[i/2-1:0] & ~Di_reverse[i*2]) & Di_reverse[i*2+1];
end
assign Do[0] = |result_bit0[in_width_exp2/2-1:0];

endmodule