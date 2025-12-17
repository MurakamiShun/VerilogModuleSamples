module PopCounter #(
    parameter int unsigned WIDTH = 32
) (
    input  var logic [WIDTH-1:0]             i_data,
    output var logic [$clog2(WIDTH + 1)-1:0] o_data
);
    function automatic logic [3-1:0] popcnt6(
        input var logic [6-1:0] d
    ) ;
        return (((d) ==? (6'b00_0000)) ? (
            3'h0
        ) : ((d) ==? (6'b11_1111)) ? (
            3'h6
        ) : ((d) ==? (6'b00_0001)) ? (
            3'h1
        ) : ((d) ==? (6'b00_0010)) ? (
            3'h1
        ) : ((d) ==? (6'b00_0100)) ? (
            3'h1
        ) : ((d) ==? (6'b00_1000)) ? (
            3'h1
        ) : ((d) ==? (6'b01_0000)) ? (
            3'h1
        ) : ((d) ==? (6'b10_0000)) ? (
            3'h1
        ) : ((d) ==? (6'b11_1110)) ? (
            3'h5
        ) : ((d) ==? (6'b11_1101)) ? (
            3'h5
        ) : ((d) ==? (6'b11_1011)) ? (
            3'h5
        ) : ((d) ==? (6'b11_0111)) ? (
            3'h5
        ) : ((d) ==? (6'b10_1111)) ? (
            3'h5
        ) : ((d) ==? (6'b01_1111)) ? (
            3'h5
        ) : ((d) ==? (6'b10_0001)) ? (
            3'h2
        ) : ((d) ==? (6'b10_0010)) ? (
            3'h2
        ) : ((d) ==? (6'b10_0100)) ? (
            3'h2
        ) : ((d) ==? (6'b10_1000)) ? (
            3'h2
        ) : ((d) ==? (6'b11_0000)) ? (
            3'h2
        ) : ((d) ==? (6'b01_0001)) ? (
            3'h2
        ) : ((d) ==? (6'b01_0010)) ? (
            3'h2
        ) : ((d) ==? (6'b01_0100)) ? (
            3'h2
        ) : ((d) ==? (6'b01_1000)) ? (
            3'h2
        ) : ((d) ==? (6'b00_1001)) ? (
            3'h2
        ) : ((d) ==? (6'b00_1010)) ? (
            3'h2
        ) : ((d) ==? (6'b00_1100)) ? (
            3'h2
        ) : ((d) ==? (6'b00_0101)) ? (
            3'h2
        ) : ((d) ==? (6'b00_0110)) ? (
            3'h2
        ) : ((d) ==? (6'b00_0011)) ? (
            3'h2
        ) : ((d) ==? (6'b10_0001)) ? (
            3'h2
        ) : ((d) ==? (6'b10_0010)) ? (
            3'h2
        ) : ((d) ==? (6'b10_0100)) ? (
            3'h2
        ) : ((d) ==? (6'b10_1000)) ? (
            3'h2
        ) : ((d) ==? (6'b11_0000)) ? (
            3'h2
        ) : ((d) ==? (6'b01_0001)) ? (
            3'h2
        ) : ((d) ==? (6'b01_0010)) ? (
            3'h2
        ) : ((d) ==? (6'b01_0100)) ? (
            3'h2
        ) : ((d) ==? (6'b01_1000)) ? (
            3'h2
        ) : ((d) ==? (6'b00_1001)) ? (
            3'h2
        ) : ((d) ==? (6'b00_1010)) ? (
            3'h2
        ) : ((d) ==? (6'b00_1100)) ? (
            3'h2
        ) : ((d) ==? (6'b00_0101)) ? (
            3'h2
        ) : ((d) ==? (6'b00_0110)) ? (
            3'h2
        ) : ((d) ==? (6'b00_0011)) ? (
            3'h2
        ) : ((d) ==? (6'b01_1110)) ? (
            3'h4
        ) : ((d) ==? (6'b01_1101)) ? (
            3'h4
        ) : ((d) ==? (6'b01_1011)) ? (
            3'h4
        ) : ((d) ==? (6'b01_0111)) ? (
            3'h4
        ) : ((d) ==? (6'b00_1111)) ? (
            3'h4
        ) : ((d) ==? (6'b10_1110)) ? (
            3'h4
        ) : ((d) ==? (6'b10_1101)) ? (
            3'h4
        ) : ((d) ==? (6'b10_1011)) ? (
            3'h4
        ) : ((d) ==? (6'b10_0111)) ? (
            3'h4
        ) : ((d) ==? (6'b11_0110)) ? (
            3'h4
        ) : ((d) ==? (6'b11_0101)) ? (
            3'h4
        ) : ((d) ==? (6'b11_0011)) ? (
            3'h4
        ) : ((d) ==? (6'b11_1010)) ? (
            3'h4
        ) : ((d) ==? (6'b11_1001)) ? (
            3'h4
        ) : ((d) ==? (6'b11_1100)) ? (
            3'h4
        ) : (
            3'h3
        ));
    endfunction

    // function popcnt4(d : input logic<4>)->logic<3>{
    //     return case d {
    //         4'b0000 : 3'h0,  4'b1111 : 3'h4,
    //         4'b0001 : 3'h1, 4'b0010 : 3'h1, 4'b0100 : 3'h1, 4'b1000 : 3'h1,
    //         4'b1110 : 3'h3, 4'b1101 : 3'h3, 4'b1011 : 3'h3, 4'b0111 : 3'h3,
    //         default : 3'h2,
    //     };
    // }

    localparam int unsigned ADDR_ELM = (WIDTH + 5) / 6;
    /* verilator lint_off ALWCOMBORDER */
    /* verilator lint_off UNOPTFLAT */
    logic [$clog2(WIDTH + 1)-1:0] adder_tree [0:ADDR_ELM * 2 - 1-1];

    for (genvar a = 0; a < (ADDR_ELM * 2 - 1); a++) begin :ADDER_TREE_LOOP
        if ((a == ADDR_ELM - 1)) begin :INITIAL
            if ((WIDTH == ADDR_ELM * 6)) begin :LAST_REMAIN
                always_comb adder_tree[a] = {{($clog2(WIDTH + 1) - 3){1'b0}}, popcnt6(i_data[WIDTH - 1:a * 6])};
            end else begin :LAST_REMAIN
                always_comb adder_tree[a] = {{($clog2(WIDTH + 1) - 3){1'b0}}, popcnt6({{ADDR_ELM * 6 - WIDTH{1'b0}}, i_data[WIDTH - 1:a * 6]})};
            end
        end else if ((a < ADDR_ELM)) begin :LAST_REMAIN
            always_comb adder_tree[a] = {{($clog2(WIDTH + 1) - 3){1'b0}}, popcnt6(i_data[a * 6 + 5:a * 6])};
        end else begin :LAST_REMAIN
            always_comb adder_tree[a] = adder_tree[(a - ADDR_ELM) * 2] + adder_tree[(a - ADDR_ELM) * 2 + 1];
        end
    end
    always_comb o_data = adder_tree[ADDR_ELM * 2 - 2];
endmodule
//# sourceMappingURL=Popcount.sv.map
