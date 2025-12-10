// lower is high priority

module PriorityMUX#(
    parameter INPUTS = 19,
    parameter WIDTH = 32
)(
    input wire[INPUTS-1:0] sel,
    input wire[INPUTS-1:0][WIDTH-1:0] i_data,

    output wire[WIDTH-1:0] o_data
);

localparam INPUTSpadding = 2**$clog2(INPUTS);

/* verilator lint_off UNOPTFLAT */
wire[WIDTH-1:0] tmp_data[INPUTSpadding*2-2:0];
wire tmp_sel[INPUTSpadding*2-2:0];


genvar i,n;
generate
    for(i = 0; i < INPUTSpadding; i=i+1)begin : initial_loop
        if(i < INPUTS)begin
            assign tmp_data[i] = i_data[i];
            assign tmp_sel[i]  = sel[i];
        end else begin
            assign tmp_data[i] = 0;
            assign tmp_sel[i]  = 0;
        end
    end
    for(i = 0; i < INPUTSpadding-1; i=i+1)begin : n_stage_loop
        assign tmp_data[i+INPUTSpadding] = tmp_sel[i*2] ? tmp_data[i*2] : tmp_data[i*2+1];
        assign tmp_sel[i+INPUTSpadding]  = tmp_sel[i*2] | tmp_sel[i*2+1];
    end
endgenerate

assign o_data = tmp_data[INPUTSpadding*2-2];

endmodule
