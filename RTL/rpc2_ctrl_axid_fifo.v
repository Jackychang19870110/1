
module rpc2_ctrl_axid_fifo (/*AUTOARG*/
   // Outputs
   rd_data, empty, pre_full, 
   // Inputs
   rst_n, clk, rd_en, wr_en, wr_data
   );
   parameter FIFO_ADDR_BITS  = 'd9;
   parameter FIFO_DATA_WIDTH = 'd16;

   input rst_n;
   input clk;

   input rd_en;
   output [FIFO_DATA_WIDTH-1:0] rd_data;
   output                       empty;

   input                        wr_en;
   input [FIFO_DATA_WIDTH-1:0]  wr_data;
//   output                     full;
   output                       pre_full;
   
   reg [FIFO_ADDR_BITS:0]       rd_addr;
   reg [FIFO_ADDR_BITS:0]       wr_addr;
   reg [FIFO_DATA_WIDTH-1:0]    mem[0:(1<<FIFO_ADDR_BITS)-1];

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg                  empty;
   reg [FIFO_DATA_WIDTH-1:0]rd_data;
   // End of automatics
   reg                      full;
   wire                     pre_full;
   wire [FIFO_ADDR_BITS:0] num;
   wire                    pre_empty;
   wire rd_enable = rd_en && ~empty;
   wire wr_enable = wr_en && ~full;
   
   generate
   if (FIFO_ADDR_BITS != 0) begin
   wire [FIFO_ADDR_BITS-1:0] rd_ptr;
   wire [FIFO_ADDR_BITS-1:0] wr_ptr;
   assign                    rd_ptr = rd_addr[FIFO_ADDR_BITS-1:0];
   assign                    wr_ptr = wr_addr[FIFO_ADDR_BITS-1:0];
   // mem
   always @(posedge clk) begin
      if (rd_enable)
        rd_data <= mem[rd_ptr];
   end
   
   always @(posedge clk) begin
      if (wr_enable)
        mem[wr_ptr] <= wr_data[FIFO_DATA_WIDTH-1:0];
   end
   end
   else begin
   // mem
   always @(posedge clk or negedge rst_n) begin
      if (~rst_n)
        rd_data <= {FIFO_DATA_WIDTH{1'b0}};
      else if (rd_enable)
        rd_data <= mem[0];
   end
   
   always @(posedge clk or negedge rst_n) begin
      if (~rst_n)
        mem[0] <= {FIFO_DATA_WIDTH{1'b0}};
      else if (wr_enable)
        mem[0] <= wr_data[FIFO_DATA_WIDTH-1:0];
   end
   end
   endgenerate
   
   assign num = wr_addr - rd_addr;
   assign pre_empty = ((num == 0) && (~wr_en)) ||
                      ((num == 1) && rd_en && (~wr_en));
   assign pre_full = ((num == (1<<FIFO_ADDR_BITS)) && (~rd_en)) || 
                     ((num == ((1<<FIFO_ADDR_BITS)-1)) && wr_en && (~rd_en));
   
   // read address
   always @(posedge clk or negedge rst_n) begin
      if (~rst_n)
        rd_addr <= {(FIFO_ADDR_BITS+1){1'b0}};
      else if (rd_enable)
        rd_addr <= rd_addr + 1'b1;
   end

   // write address
   always @(posedge clk or negedge rst_n) begin
      if (~rst_n)
        wr_addr <= {(FIFO_ADDR_BITS+1){1'b0}};
      else if (wr_enable)
        wr_addr <= wr_addr + 1'b1;
   end

   // empty
   always @(posedge clk or negedge rst_n) begin
      if (~rst_n)
        empty <= 1'b1;
      else if (pre_empty)
        empty <= 1'b1;
      else
        empty <= 1'b0;
   end

   // full
   always @(posedge clk or negedge rst_n) begin
      if (~rst_n)
        full <= 1'b0;
      else if (pre_full)
        full <= 1'b1;
      else
        full <= 1'b0;
   end
 
endmodule // rpc2_ctrl_axid_fifo

