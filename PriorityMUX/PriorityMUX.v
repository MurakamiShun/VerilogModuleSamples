// lower is high priority

// Optimized to FPGA(LUT6 architecture)
module PriorityMUX#(
    parameter INPUTS = 4,
    parameter WIDTH = 32
)(
    input wire[INPUTS-1:0] sel,
    input wire[INPUTS-1:0][WIDTH-1:0] i_data,

    output wire[WIDTH-1:0] o_data
);

function automatic integer clog3(input integer jj);
    // integer i;
    // integer k = 1;
    // for(i = jj; i > 3; i = (i+2)/ 3)begin
    //     k = k + 1;
    // end
    // return k;
    integer i;
    integer k;
    i = jj;
    for(k = 0; k <= $clog2(jj); k=k+1)begin
        if(i == 1)begin
            i = k;
            break;
        end
        i = (i+2)/ 3;
    end
    return i;
endfunction

function automatic integer total_buff(input integer jj);
    integer i;
    integer k = 0;
    for(i = 0; i <= clog3(jj); i=i+1)begin
        k = k + 3**i;
    end
    return k;
endfunction

localparam INPUTSpadding = 3**clog3(INPUTS);
localparam TOTAL_BUFF = total_buff(INPUTS);

/* verilator lint_off UNOPTFLAT */
wire[WIDTH-1:0] tmp_data[TOTAL_BUFF-1:0];
wire tmp_sel[TOTAL_BUFF-1:0];

genvar i;
generate
    for(i = 0; i < TOTAL_BUFF; i=i+1)begin : priorily_mux_loop
        if(i < INPUTS)begin
            assign tmp_data[i] = i_data[i];
            assign tmp_sel[i]  = sel[i];
        end else if(i < INPUTSpadding) begin
            assign tmp_data[i] = 0;
            assign tmp_sel[i]  = 0;
        end else begin
            assign tmp_data[i] = tmp_sel[(i-INPUTSpadding)*3] ? tmp_data[(i-INPUTSpadding)*3] :
                                 tmp_sel[(i-INPUTSpadding)*3+1] ? tmp_data[(i-INPUTSpadding)*3+1] :
                                 tmp_data[(i-INPUTSpadding)*3+2];
            assign tmp_sel[i]  = tmp_sel[(i-INPUTSpadding)*3] | tmp_sel[(i-INPUTSpadding)*3+1] | tmp_sel[(i-INPUTSpadding)*3+2];
        end
    end
endgenerate

assign o_data = tmp_data[TOTAL_BUFF-1];

endmodule

// binary reduction

// module PriorityMUX#(
//     parameter INPUTS = 19,
//     parameter WIDTH = 32
// )(
//     input wire[INPUTS-1:0] sel,
//     input wire[INPUTS-1:0][WIDTH-1:0] i_data,

//     output wire[WIDTH-1:0] o_data
// );

// localparam INPUTSpadding = 2**$clog2(INPUTS);

// /* verilator lint_off UNOPTFLAT */
// wire[WIDTH-1:0] tmp_data[INPUTSpadding*2-2:0];
// wire tmp_sel[INPUTSpadding*2-2:0];


// genvar i;
// generate
//     for(i = 0; i < INPUTSpadding*2-1; i=i+1)begin : priorily_mux_loop
//         if(i < INPUTS)begin
//             assign tmp_data[i] = i_data[i];
//             assign tmp_sel[i]  = sel[i];
//         end else if(i < INPUTSpadding) begin
//             assign tmp_data[i] = 0;
//             assign tmp_sel[i]  = 0;
//         end else begin
//             assign tmp_data[i] = tmp_sel[(i-INPUTSpadding)*2] ? tmp_data[(i-INPUTSpadding)*2] : tmp_data[(i-INPUTSpadding)*2+1];
//             assign tmp_sel[i]  = tmp_sel[(i-INPUTSpadding)*2] | tmp_sel[(i-INPUTSpadding)*2+1];
//         end
//     end
// endgenerate

// assign o_data = tmp_data[INPUTSpadding*2-2];

// endmodule
