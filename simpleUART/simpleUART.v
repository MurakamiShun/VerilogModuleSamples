module simpleUART#(
    parameter CLK_FREQ = 50_000_000,
    parameter baudrate = 115_200,
    parameter FIFO_ADDR_WIDTH = 3
)(
    input  wire CLK,
    input  wire RST,
    input  wire RX,
    output wire TX,
    input  wire[7:0] w_data, // TX data
    input  wire w_valid,      // TX data request
    output wire w_ready,      // write available
    input  wire r_valid,     // RX read request
    output wire[7:0] r_data, // RX data
    output wire r_ready       // read available
);

localparam clk_bits = $clog2(CLK_FREQ/baudrate+1);
localparam[clk_bits-1:0] baudrate_rst_cnt = CLK_FREQ/baudrate;

reg[clk_bits-1:0] tx_baudrate_clk_cnt = 0;
reg[clk_bits-1:0] rx_baudrate_clk_cnt = 0;

localparam TX_WAIT_STAT = 2'd0;
localparam TX_START_BIT_STAT = 2'd1;
localparam TX_DATA_STAT = 2'd2;
localparam TX_STOP_BIT_STAT = 2'd3;

wire[7:0] tx_fifo_data;
reg[1:0] tx_stat = TX_WAIT_STAT;
reg[2:0] tx_shft = 0;
reg[7:0] tx_data;
reg tx_reg = 1, tx_fifo_rd_en = 0;
wire tx_fifo_full, tx_fifo_empty;
assign TX = tx_reg;
assign w_ready = ~tx_fifo_full;

localparam RX_WAIT_STAT = 2'd0;
localparam RX_START_BIT_STAT = 2'd1;
localparam RX_DATA_STAT = 2'd2;

reg[1:0] rx_stat = RX_WAIT_STAT;
reg[2:0] rx_shft = 0;
reg[7:0] rx_data;
reg rx_reg = 1, rx_buffer = 1;
wire rx_fifo_empty, rx_fifo_full;
reg rx_fifo_wr_en = 0;
assign r_ready = ~rx_fifo_empty;

simpleUART_FIFO#(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(FIFO_ADDR_WIDTH)
)tx_fifo(
    .CLK(CLK),
    .RST(RST),
    .rd_data(tx_fifo_data),
    .rd_en(tx_fifo_rd_en),
    .wr_data(w_data),
    .wr_en(~tx_fifo_full & w_valid),
    .empty(tx_fifo_empty),
    .full(tx_fifo_full)
);

simpleUART_FIFO#(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(FIFO_ADDR_WIDTH)
)rx_fifo(
    .CLK(CLK),
    .RST(RST),
    .rd_data(r_data),
    .rd_en(~rx_fifo_empty & r_valid),
    .wr_data(rx_data),
    .wr_en(rx_fifo_wr_en),
    .empty(rx_fifo_empty),
    .full(rx_fifo_full)
);

always@(posedge CLK)begin
    // TX
    if(RST)begin
        tx_fifo_rd_en <= 0;
        tx_stat <= TX_WAIT_STAT;
        tx_reg <= 1;
        tx_shft <= 0;
    end else if(tx_stat == TX_WAIT_STAT && ~tx_fifo_empty && tx_baudrate_clk_cnt == 0)begin
        tx_data <= tx_fifo_data;
        tx_fifo_rd_en <= 1;
        tx_stat <= TX_START_BIT_STAT;
    end else if(tx_stat == TX_START_BIT_STAT && tx_baudrate_clk_cnt == 0) begin
        tx_stat <= TX_DATA_STAT;
        tx_reg <= 0;
        tx_shft <= 0;
    end else if(tx_stat == TX_DATA_STAT && tx_baudrate_clk_cnt == 0)begin
        tx_stat <= TX_DATA_STAT;
        tx_reg <= tx_data[0];
        tx_data <= {1'b1, tx_data[7:1]};
        tx_shft <= tx_shft+1'b1;
        if(tx_shft == 3'd7)begin
            tx_stat <= TX_STOP_BIT_STAT;
        end
    end else if(tx_stat == TX_STOP_BIT_STAT && tx_baudrate_clk_cnt == 0)begin
        tx_stat <= TX_WAIT_STAT;
        tx_reg <= 1;
    end else begin
        tx_fifo_rd_en <= 0;
    end

    if(RST)begin
        tx_baudrate_clk_cnt <= 0;
    end else if(tx_baudrate_clk_cnt >= baudrate_rst_cnt)begin
        tx_baudrate_clk_cnt <= 0;
    end else begin
        tx_baudrate_clk_cnt <= tx_baudrate_clk_cnt+1;
    end

    // RX
    rx_buffer <= RST ? 1 : RX;
    rx_reg <= RST ? 1 : rx_buffer;

    if(RST)begin
        rx_fifo_wr_en <= 0;
        rx_stat <= RX_WAIT_STAT;
        rx_shft <= 0;
    end else if(rx_stat == RX_WAIT_STAT)begin
        rx_fifo_wr_en <= 0;
        if(~rx_fifo_full && rx_reg == 1 && rx_buffer == 0)begin
            rx_stat <= RX_START_BIT_STAT;
        end
    end else if(rx_stat == RX_START_BIT_STAT && rx_baudrate_clk_cnt == baudrate_rst_cnt/2) begin
        rx_fifo_wr_en <= 0;
        rx_stat <= RX_DATA_STAT;
        rx_shft <= 0;
    end else if(rx_stat == RX_DATA_STAT && rx_baudrate_clk_cnt == baudrate_rst_cnt/2)begin
        rx_data <= {rx_reg, rx_data[7:1]};
        rx_shft <= rx_shft + 1;
        if(rx_shft == 3'd7)begin
            rx_fifo_wr_en <= 1;
            rx_stat <= RX_WAIT_STAT;
        end else begin
            rx_fifo_wr_en <= 0;
        end
    end

    if(RST)begin
        rx_baudrate_clk_cnt <= 0;
    end else if(rx_reg != rx_buffer || rx_baudrate_clk_cnt >= baudrate_rst_cnt)begin
        rx_baudrate_clk_cnt <= 0;
    end else begin
        rx_baudrate_clk_cnt <= rx_baudrate_clk_cnt+1;
    end
end
endmodule
