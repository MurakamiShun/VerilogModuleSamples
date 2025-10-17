// module PrefixAdder#( // Sklansky adder
//     parameter WIDTH = 32
// )(
//     input wire[WIDTH-1:0] a,
//     input wire[WIDTH-1:0] b,
//     input wire cin,
//     input wire sub,

//     output wire[WIDTH-1:0] sum,
//     output wire cout
// );
//     localparam DEPTH = $clog2(WIDTH);
//     /* verilator lint_off UNOPTFLAT */
//     wire[WIDTH-1:0] G0[DEPTH:0];
//     /* verilator lint_off UNOPTFLAT */
//     wire[WIDTH-1:0] P0[DEPTH-1:0];

//     wire[WIDTH-1:0] bf;
//     wire c0;

//     genvar i, j, d;
//     generate
//         assign c0 = sub | cin;
//         assign bf[0] = b[0] ^ sub;
//         assign P0[0][0] = a[0] ^ bf[0];
//         assign G0[0][0] = a[0] & bf[0] | a[0] & c0 | bf[0] & c0;
//         for(i = 1; i < WIDTH; i=i+1)begin
//             assign bf[i] = b[i] ^ sub;
//             assign P0[0][i] = a[i] ^ bf[i];
//             assign G0[0][i] = a[i] & bf[i];
//         end

//         for(d = 1; d < DEPTH; d=d+1)begin
//             for(i = 0; i < WIDTH; i=i+(2<<(d-1)))begin
//                 for(j = 0; j < 1<<(d-1); j=j+1)begin
//                     assign G0[d][i+j] = G0[d-1][i+j];
//                     assign P0[d][i+j] = P0[d-1][i+j];
//                 end
//             end
//             for(i = (1<<(d-1)); i < WIDTH; i=i+(2<<(d-1)))begin
//                 for(j = 0; j < (1<<(d-1)); j=j+1)begin
//                     assign G0[d][i+j] = G0[d-1][i+j] | (G0[d-1][i-1] & P0[d-1][i+j]);
//                     assign P0[d][i+j] = P0[d-1][i+j] & P0[d-1][i-1];
//                 end
//             end
//         end

//         for(j = 0; j < WIDTH/2; j=j+1)begin
//             assign G0[DEPTH][j] = G0[DEPTH-1][j];
//         end
//         for(j = WIDTH/2; j < WIDTH; j=j+1)begin
//             assign G0[DEPTH][j] = G0[DEPTH-1][j] | (G0[DEPTH-1][WIDTH/2-1] & P0[DEPTH-1][j]);
//         end

//         assign sum[0] = P0[0][0] ^ cin;
//         for(i = 1; i < WIDTH; i=i+1)begin
//             assign sum[i] = G0[DEPTH][i-1] ^ P0[0][i];
//         end
//         assign cout = G0[DEPTH][WIDTH-1];
//     endgenerate
// endmodule

// https://web.tecnico.ulisboa.pt/~ist14359/wordpress/nfvr_pubs/dcis03.pdf
// https://ieeexplore.ieee.org/document/1292373


module PrefixAdder#( // Kogge-Stone adder
    parameter WIDTH = 16
)(
    input wire[WIDTH-1:0] a,
    input wire[WIDTH-1:0] b,
    input wire cin,
    input wire sub,

    output wire[WIDTH-1:0] sum,
    output wire cout
);
    localparam DEPTH = $clog2(WIDTH);
    /* verilator lint_off UNOPTFLAT */
    wire[WIDTH-1:0] G0[DEPTH:0];
    /* verilator lint_off UNOPTFLAT */
    wire[WIDTH-1:0] P0[DEPTH:0];

    wire[WIDTH-1:0] bf;
    wire c0;

    genvar i, j, d;
    generate
        assign c0 = sub | cin;
        assign bf[0] = b[0] ^ sub;
        assign P0[0][0] = a[0] ^ bf[0];
        assign G0[0][0] = a[0] & bf[0] | a[0] & c0 | bf[0] & c0;
        for(i = 1; i < WIDTH; i=i+1)begin
            assign bf[i] = b[i] ^ sub;
            assign P0[0][i] = a[i] ^ bf[i];
            assign G0[0][i] = a[i] & bf[i];
        end

        for(d = 1; d <= DEPTH; d=d+1)begin
            localparam prev = 1<<(d-1);
            for(i = 0; i < WIDTH; i=i+1)begin
                if(prev <= i)begin
                    assign G0[d][i] = G0[d-1][i] | (G0[d-1][i-prev] & P0[d-1][i]);
                    assign P0[d][i] = P0[d-1][i] & P0[d-1][i-prev];
                end else begin
                    assign G0[d][i] = G0[d-1][i];
                    assign P0[d][i] = P0[d-1][i];
                end
            end
        end

        assign sum[0] = P0[0][0] ^ cin;
        for(i = 1; i < WIDTH; i=i+1)begin
            assign sum[i] = G0[DEPTH][i-1] ^ P0[0][i];
        end
        assign cout = G0[DEPTH][WIDTH-1];
    endgenerate
endmodule
