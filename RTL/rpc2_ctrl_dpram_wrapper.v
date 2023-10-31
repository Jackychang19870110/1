
module rpc2_ctrl_dpram_wrapper #(
    parameter FIFO_TYPE_SYNC = 1'd0,        // 0=async_fifo_axi, 1=sync_fifo_axi
    parameter FIFO_ADDR_BITS = 32'd3,
    parameter FIFO_DATA_WIDTH = 32'd16,
    parameter DPRAM_MACRO = 1'd0,      // 0=not used, 1=used macro
    parameter DPRAM_MACRO_SIZE = 4'd0, // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
    parameter DPRAM_MACRO_TYPE = 1'd0  // 0=type-A(STD), 1=type-B(LowLeak)
)
(
    // Outputs
    rd_data, empty, full, pre_full, half_full, 
    // Inputs
    rd_rst_n, rd_clk, rd_en, wr_rst_n, wr_clk, wr_en, wr_data
);
    input   wire    rd_rst_n;
    input   wire    rd_clk;
    input   wire    rd_en;
    output  wire    [FIFO_DATA_WIDTH-1:0] rd_data;
    output  reg     empty;

    input   wire    wr_rst_n;     // only async_fifo_axi
    input   wire    wr_clk;     // only async_fifo_axi
    input   wire    wr_en;
    input   wire    [FIFO_DATA_WIDTH-1:0] wr_data;
    output  reg     full;
    output  wire    pre_full;
    output  wire    half_full;  // only sync_fifo

    wire    rd_enable;
    wire    wr_enable;
    wire    [FIFO_ADDR_BITS-1:0] rd_ptr;
    wire    [FIFO_ADDR_BITS-1:0] wr_ptr;
    wire    [FIFO_ADDR_BITS-1:0] int_rd_ptr;
    wire    [FIFO_ADDR_BITS-1:0] int_wr_ptr;
    wire    [FIFO_DATA_WIDTH-1:0] int_wr_data;

//    // Timing delay for simulation
//    assign #500 rd_enable = rd_en && (~empty);
//    assign #500 wr_enable = wr_en && (~full);
//    assign #500 rd_ptr = int_rd_ptr;
//    assign #500 wr_ptr = int_wr_ptr;
//    assign #500 int_wr_data = wr_data;

    // Timing delay for simulation
    assign rd_enable = rd_en && (~empty);
    assign wr_enable = wr_en && (~full);
    assign rd_ptr = int_rd_ptr;
    assign wr_ptr = int_wr_ptr;
    assign int_wr_data = wr_data;
    
    
    generate
    if(FIFO_TYPE_SYNC == 0) begin
        wire    [FIFO_ADDR_BITS:0] rd_addr;
        wire    [FIFO_ADDR_BITS:0] next_rd_addr;
        wire    [FIFO_ADDR_BITS:0] wr_addr;
        wire    [FIFO_ADDR_BITS:0] next_wr_addr;
        // for sync
        reg     [FIFO_ADDR_BITS:0] rd_addr_s1;
        reg     [FIFO_ADDR_BITS:0] rd_addr_s2;
        reg     [FIFO_ADDR_BITS:0] wr_addr_s1;
        reg     [FIFO_ADDR_BITS:0] wr_addr_s2;

        assign pre_full = (next_wr_addr == {(~rd_addr_s2[FIFO_ADDR_BITS:FIFO_ADDR_BITS-1]), rd_addr_s2[FIFO_ADDR_BITS-2:0]});
        assign half_full = 1'b0;

        //-------------------------------
        // RD_CLK
        //-------------------------------
        rpc2_ctrl_fifo_gray_counter #(FIFO_ADDR_BITS+1) 
        rd_gray_counter (/*AUTOINST*/
            // Outputs
            .cnt (int_rd_ptr),
            .gray_cnt (rd_addr),
            .next_gray_cnt (next_rd_addr),
            // Inputs
            .clk (rd_clk),
            .rst_n (rd_rst_n),
            .en (rd_enable));
        // sync to rd_clk
        always @(posedge rd_clk or negedge rd_rst_n) begin
            if (~rd_rst_n) begin
                wr_addr_s1 <= {(FIFO_ADDR_BITS+1){1'b0}};
                wr_addr_s2 <= {(FIFO_ADDR_BITS+1){1'b0}};
            end // if rd_rst_n
            else begin
                wr_addr_s1 <= wr_addr[FIFO_ADDR_BITS:0];
                wr_addr_s2 <= wr_addr_s1[FIFO_ADDR_BITS:0];
            end // else rd_rst_n
        end
        // generate empty flag
        always @(posedge rd_clk or negedge rd_rst_n) begin
            if (~rd_rst_n)
                empty <= 1'b1;
            else if (next_rd_addr == wr_addr_s2)
                empty <= 1'b1;
            else
                empty <= 1'b0;
        end

        //-------------------------------
        // WR_CLK
        //-------------------------------
        rpc2_ctrl_fifo_gray_counter #(FIFO_ADDR_BITS+1) 
        wr_gray_counter (/*AUTOINST*/
            // Outputs
            .cnt (int_wr_ptr),
            .gray_cnt (wr_addr),
            .next_gray_cnt (next_wr_addr),
            // Inputs
            .clk (wr_clk),
            .rst_n (wr_rst_n),
            .en (wr_enable));
        // sync to wr_clk
        always @(posedge wr_clk or negedge wr_rst_n) begin
            if (~wr_rst_n) begin
                rd_addr_s1 <= {(FIFO_ADDR_BITS+1){1'b0}};
                rd_addr_s2 <= {(FIFO_ADDR_BITS+1){1'b0}};
            end // if wr_rst_n
            else begin
                rd_addr_s1 <= rd_addr[FIFO_ADDR_BITS:0];
                rd_addr_s2 <= rd_addr_s1[FIFO_ADDR_BITS:0];
            end // else wr_rst_n
        end
        // generate full flag
        always @(posedge wr_clk or negedge wr_rst_n) begin
            if (~wr_rst_n)
                full <= 1'b0;
            else if (pre_full)
                full <= 1'b1;
            else
                full <= 1'b0;
        end

        // A port = input / B port = output FIFO using DPRAM
        rpc2_ctrl_dpram_generator #(
            .FIFO_ADDR_BITS(FIFO_ADDR_BITS),
            .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
            .DPRAM_MACRO(DPRAM_MACRO),              // 0=not used, 1=used macro
            .DPRAM_MACRO_SIZE(DPRAM_MACRO_SIZE),    // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX
            .DPRAM_MACRO_TYPE(DPRAM_MACRO_TYPE)     // 0=STD, 1=LowLeak
        ) dpram (
            // Outputs
            .b_odata(rd_data),                  // B port output data
            // Inputs
            .clka(wr_clk),                      // A port clock
            .clkb(rd_clk),                      // B port clock
            .ceia_n(!wr_enable),                // A port chip enable (negative)
            .cejb_n(!rd_enable),                // B port chip enable (negative)
            .ia(wr_ptr),                        // A port address
            .jb(rd_ptr),                        // B port address
            .i_idata(int_wr_data)               // A port input data
        );
    end // if FIFO_TYPE_SYNC == 0
    else if(FIFO_TYPE_SYNC == 1) begin
        reg     [FIFO_ADDR_BITS:0] rd_addr;
        reg     [FIFO_ADDR_BITS:0] wr_addr;
        wire    [FIFO_ADDR_BITS:0] num;
        reg     int_half_full;

        assign half_full = int_half_full;
        assign num = wr_addr - rd_addr;
        assign pre_full = ((num == (1<<FIFO_ADDR_BITS)) && (~rd_en)) || ((num == ((1<<FIFO_ADDR_BITS)-1)) && wr_en && (~rd_en));
        if (FIFO_ADDR_BITS != 0) begin
            assign int_rd_ptr = rd_addr[FIFO_ADDR_BITS-1:0];
            assign int_wr_ptr = wr_addr[FIFO_ADDR_BITS-1:0];
        end // if FIFO_ADDR_BITS != 0
        else begin
            assign int_rd_ptr = 1'b0;
            assign int_wr_ptr = 1'b0;
        end // else FIFO_ADDR_BITS != 0

        // read address
        always @(posedge rd_clk or negedge rd_rst_n) begin
            if (~rd_rst_n)
                rd_addr <= {(FIFO_ADDR_BITS+1){1'b0}};
            else if (rd_enable)
                rd_addr <= rd_addr + 1'b1;
        end

        // write address
        always @(posedge rd_clk or negedge rd_rst_n) begin
            if (~rd_rst_n)
                wr_addr <= {(FIFO_ADDR_BITS+1){1'b0}};
            else if (wr_enable)
                wr_addr <= wr_addr + 1'b1;
        end

        // empty
        always @(posedge rd_clk or negedge rd_rst_n) begin
            if (~rd_rst_n)
                empty <= 1'b1;
            else if (((num == 0) && (~wr_en)) || ((num == 1) && rd_en && (~wr_en)))
                empty <= 1'b1;
            else
                empty <= 1'b0;
        end

        // full
        always @(posedge rd_clk or negedge rd_rst_n) begin
            if (~rd_rst_n)
                full <= 1'b0;
            else if (pre_full)
                full <= 1'b1;
            else
                full <= 1'b0;
        end

        // half full
        always @(posedge rd_clk or negedge rd_rst_n) begin
            if (~rd_rst_n)
                int_half_full <= 1'b0;
            else if (num > (1<<(FIFO_ADDR_BITS-1)))
                int_half_full <= 1'b1;
            else
                int_half_full <= 1'b0;
        end

        // A port = input / B port = output FIFO using DPRAM
        rpc2_ctrl_dpram_generator #(
            .FIFO_ADDR_BITS(FIFO_ADDR_BITS),
            .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
            .DPRAM_MACRO(DPRAM_MACRO),              // 0=not used, 1=used macro
            .DPRAM_MACRO_SIZE(DPRAM_MACRO_SIZE),    // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX
            .DPRAM_MACRO_TYPE(DPRAM_MACRO_TYPE)     // 0=STD, 1=LowLeak
        ) dpram (
            // Outputs
            .b_odata(rd_data),                  // B port output data
            // Inputs
            .clka(rd_clk),                      // A port clock
            .clkb(rd_clk),                      // B port clock
            .ceia_n(!wr_enable),                // A port chip enable (negative)
            .cejb_n(!rd_enable),                // B port chip enable (negative)
            .ia(wr_ptr),                        // A port address
            .jb(rd_ptr),                        // B port address
            .i_idata(int_wr_data)               // A port input data
        );
    end // else if FIFO_TYPE_SYNC == 1
    endgenerate
endmodule // rpc2_ctrl_dpram_wrapper
