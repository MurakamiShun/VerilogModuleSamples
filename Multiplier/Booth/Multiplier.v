module Multiplier#(
    parameter WIDTH = 32
)(
    input wire[WIDTH-1:0] a,
    input wire[WIDTH-1:0] b,

    output wire[WIDTH*2-1:0] result
);

    // Booth Encoder
    wire[WIDTH+4:0] partial_products[WIDTH/2:0];
    wire part_prod_sign[WIDTH/2:0];

    wire[WIDTH+2:0] b_expand;
    assign b_expand = {2'b0, b, 1'b0};

    wire[WIDTH:0] multiplicand_a;
    wire[WIDTH:0] multiplicand_2a;
    wire[WIDTH:0] multiplicand_a_n;
    wire[WIDTH:0] multiplicand_2a_n;
    assign multiplicand_a  = {1'b0, a};// 001 010
    assign multiplicand_2a = {a, 1'b0};// 011
    assign multiplicand_a_n  = {1'b1, ~a};// 101 110
    assign multiplicand_2a_n = {~a, 1'b1};// 111

    genvar i;
    generate
        for(i = 0; i <= WIDTH/2; i=i+1)begin
            wire[WIDTH:0] booth_encoding;
            assign part_prod_sign[i]  = b_expand[i*2+2:i*2] == 3'b111 ? 0 : b_expand[i*2+2];
            assign booth_encoding     = b_expand[i*2+2:i*2] == 3'b001 ? multiplicand_a    :
                                        b_expand[i*2+2:i*2] == 3'b010 ? multiplicand_a    :
                                        b_expand[i*2+2:i*2] == 3'b011 ? multiplicand_2a   :
                                        b_expand[i*2+2:i*2] == 3'b100 ? multiplicand_2a_n :
                                        b_expand[i*2+2:i*2] == 3'b101 ? multiplicand_a_n  :
                                        b_expand[i*2+2:i*2] == 3'b110 ? multiplicand_a_n  :
                                        '0;
            if(i == 0)begin
                assign partial_products[i] = {1'b0, ~part_prod_sign[i], part_prod_sign[i], part_prod_sign[i], booth_encoding};
            end else begin
                assign partial_products[i] = {1'b1, ~part_prod_sign[i], booth_encoding, 1'b0, part_prod_sign[i-1]};
            end
        end
    endgenerate

    // Wallace tree
    // genvar k;
    // generate
    //     for(i = 0; i < WIDTH/2/3; i=i+1)begin


    //     end
    // endgenerate
    /* verilator lint_off UNOPTFLAT */
    wire[WIDTH*2-1:0] sum[WIDTH/2:0];
    assign sum[0] = {{(WIDTH-5){1'b0}}, partial_products[0]};
    generate
        for(i = 1; i <= WIDTH/2; i=i+1)begin
            assign sum[i] = sum[i-1] + ({{(WIDTH-5){1'b0}}, partial_products[i]} << ((i-1)*2));
        end
    endgenerate

    assign result = sum[WIDTH/2];

    
endmodule
