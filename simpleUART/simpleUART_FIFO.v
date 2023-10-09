module simpleUART_FIFO#(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input wire CLK,
    input wire RST,
    output reg[DATA_WIDTH-1:0] rd_data,
    input wire rd_en,
    input wire[DATA_WIDTH-1:0] wr_data,
    input wire wr_en,
    output wire empty,
    output wire full
);

reg[DATA_WIDTH-1:0] storage[(2**ADDR_WIDTH)-1:0];
reg[ADDR_WIDTH:0] rd_ptr = 0, wr_ptr = 0;

assign empty = (rd_ptr == wr_ptr);
assign full = (rd_ptr[ADDR_WIDTH-1:0] == wr_ptr[ADDR_WIDTH-1:0]) & (rd_ptr[ADDR_WIDTH] != wr_ptr[ADDR_WIDTH]);

wire[ADDR_WIDTH:0] next_rd_ptr = rd_ptr + {{(ADDR_WIDTH-1){1'b0}},{1'b1}};

always@(posedge CLK)begin
    if(RST)begin
        rd_ptr <= 0;
        wr_ptr <= 0;
    end else begin
        if(rd_en)begin
            rd_ptr <= next_rd_ptr;
        end
        if(wr_en)begin
            storage[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr+1'b1;
        end
    end

    if(wr_en && empty) rd_data <= wr_data;
    else if(rd_en) rd_data <= storage[next_rd_ptr[ADDR_WIDTH-1:0]];
    else rd_data <= storage[rd_ptr[ADDR_WIDTH-1:0]];
end
endmodule
