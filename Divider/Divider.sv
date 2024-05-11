module Divider#(
    parameter width = 32
)(
    input logic clk,
    input logic rst_n,
    input logic en,
    input logic[width-1:0] op_dividend, // result * divisor + rem = dividend 
    input logic[width-1:0] op_divisor,

    output logic busy,
    output logic done,
    output logic[width-1:0] result,
    output logic[width-1:0] rem
);

logic[width-1:0] dividend;
logic[width-1:0] divisor;

logic[width-1:0] tentative_sub;
always_comb begin
    tentative_sub = rem - divisor;
end

logic[$clog2(width+1):0] cnt;

always_ff@(posedge clk)begin
    if(!rst_n)begin
        done <= 0;
        result <= '0;
        rem <= '0;
        cnt <= 0;
    end else if(en)begin
        done <= 0;
        result <= '0;
        cnt <= 1;
        divisor <= op_divisor;
        dividend <= {op_dividend[width-2:0], 1'b0};
        rem <= {{(width-1){1'b0}}, op_dividend[width-1]};
    end else if(cnt != 0)begin
        dividend <= {dividend[width-2:0], 1'b0};
        if(cnt == width)begin
            done <= 1;
            cnt <= 0;
            if(rem >= divisor)begin
                result <= {result[width-2:0], 1'b1};
                rem <= tentative_sub;
            end else begin
                result <= {result[width-2:0], 1'b0};
                rem <= rem;
            end
        end else begin
            done <= 0;
            cnt <= cnt + 1;
            if(rem >= divisor)begin
                result <= {result[width-2:0], 1'b1};
                rem <= {tentative_sub[width-2:0], dividend[width-1]};
            end else begin
                result <= {result[width-2:0], 1'b0};
                rem <= {rem[width-2:0], dividend[width-1]};
            end
        end
    end else begin
        done <= 0;
    end
end

always_comb begin
    busy = en || (cnt != 0);
end

endmodule