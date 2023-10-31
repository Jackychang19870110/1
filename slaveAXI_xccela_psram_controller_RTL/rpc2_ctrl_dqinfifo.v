/**************************************************************************
* Copyright (C)2013-2014 Spansion LLC All Rights Reserved. 
*
* This source code is owned and published by: 
* Spansion LLC 915 DeGuigne Dr. Sunnyvale, CA  94088-3453 ("Spansion").
*
* BY INSTALLING OR USING THIS HYPERBUS MASTER CONTROLLER RTL SOURCE CODE, 
* YOU AGREE TO BE BOUND BY ALL THE TERMS AND CONDITIONS SET FORTH IN SPANSION 
* LICENSE AGREEMENT AND BELOW.
*
* This source code is licensed by Spansion to be adapted only 
* for use in the development of HyperBus Master Controller. Spansion is not
* responsible for misuse or illegal use of this source code.  Spansion is 
* providing this source code "AS IS" and will not be responsible for issues 
* arising from incorrect user implementation of the source code herein.  
*
* SPANSION MAKES NO WARRANTY, EXPRESS OR IMPLIED, ARISING BY LAW OR OTHERWISE, 
* REGARDING THE SOURCE CODE, ITS PERFORMANCE OR SUITABILITY FOR YOUR INTENDED 
* USE, INCLUDING, WITHOUT LIMITATION, NO IMPLIED WARRANTY OF MERCHANTABILITY, 
* FITNESS FOR A  PARTICULAR PURPOSE OR USE, OR NONINFRINGEMENT.  SPANSION WILL 
* HAVE NO LIABILITY (WHETHER IN CONTRACT, WARRANTY, TORT, NEGLIGENCE OR 
* OTHERWISE) FOR ANY DAMAGES ARISING FROM USE OR INABILITY TO USE THE SOURCE CODE, 
* INCLUDING, WITHOUT LIMITATION, ANY DIRECT, INDIRECT, INCIDENTAL, 
* SPECIAL, OR CONSEQUENTIAL DAMAGES OR LOSS OF DATA, SAVINGS OR PROFITS, 
* EVEN IF SPANSION HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.  
*
* This source code may be replicated in part or whole for the licensed use, 
* with the restriction that this Copyright notice must be included with 
* this source code, whether used in part or whole, at all times.  
*/
//*************************************************************************
// Filename: rpc2_ctrl_dqinfifo.v
//
//           Asynchronous FIFO for RPC2 Controller
//
// Created: yise  12/27/2013  version 2.0  - initial release
//*************************************************************************

module rpc2_ctrl_dqinfifo (/*AUTOARG*/
   // Outputs
   dqinfifo_dout, dqinfifo_empty, 
   // Inputs
   reset_n, clk, dqinfifo_rd_en, rds_clk, dqinfifo_wr_en, 
   dqinfifo_din
   );
  parameter FIFO_ADDR_BITS = 'd3;
  parameter FIFO_DATA_WIDTH = 'd16;

//   parameter FIFO_ADDR_BITS = 'd10;
//   parameter FIFO_DATA_WIDTH = 'd2048;
      
   input reset_n;
   
   input clk;
   input dqinfifo_rd_en;
   output [FIFO_DATA_WIDTH-1:0] dqinfifo_dout;
   output                       dqinfifo_empty;
   
   input rds_clk;
   input dqinfifo_wr_en;
   input [FIFO_DATA_WIDTH-1:0] dqinfifo_din;
   
   wire                        rd_enable;
   wire                        wr_enable;
   
   wire [FIFO_ADDR_BITS:0] rd_addr;
   wire [FIFO_ADDR_BITS:0] next_rd_addr;
   wire [FIFO_ADDR_BITS:0] wr_addr;
   wire [FIFO_ADDR_BITS:0] next_wr_addr;
   
   wire [FIFO_ADDR_BITS-1:0] rd_ptr;
   wire [FIFO_ADDR_BITS-1:0] wr_ptr;
   
   // for sync
   reg [FIFO_ADDR_BITS:0]  wr_addr_s1;
   reg [FIFO_ADDR_BITS:0]  wr_addr_s2;

   reg [FIFO_DATA_WIDTH-1:0] mem[0:(1<<FIFO_ADDR_BITS)-1];
   reg                       empty;
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [FIFO_DATA_WIDTH-1:0]dqinfifo_dout;
   // End of automatics

   assign dqinfifo_empty = empty;
   assign rd_enable = dqinfifo_rd_en && ~empty;
   assign wr_enable = dqinfifo_wr_en;

`ifdef DEBUG
   // for sync
   reg [FIFO_ADDR_BITS:0]  rd_addr_s1;
   reg [FIFO_ADDR_BITS:0]  rd_addr_s2;
   wire                     pre_full;
   reg                      full;
   assign pre_full = (next_wr_addr == {~rd_addr_s2[FIFO_ADDR_BITS:FIFO_ADDR_BITS-1], rd_addr_s2[FIFO_ADDR_BITS-2:0]});
`endif
   
   //-------------------------------
   // CLK
   //-------------------------------
   /* rpc2_ctrl_fifo_gray_counter AUTO_TEMPLATE (
    .cnt(rd_ptr),
    .gray_cnt(rd_addr),
    .next_gray_cnt(next_rd_addr),
    .clk(clk),
    .en(rd_enable),
    .rst_n(reset_n),
    );
    */
   rpc2_ctrl_fifo_gray_counter #(FIFO_ADDR_BITS+1) 
   rd_gray_counter (/*AUTOINST*/
                    // Outputs
                    .cnt                (rd_ptr),                // Templated
                    .gray_cnt           (rd_addr),               // Templated
                    .next_gray_cnt      (next_rd_addr),          // Templated
                    // Inputs
                    .clk                (clk),                   // Templated
                    .rst_n              (reset_n),               // Templated
                    .en                 (rd_enable));            // Templated
   
   // sync to clk
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         wr_addr_s1 <= {(FIFO_ADDR_BITS+1){1'b0}};
         wr_addr_s2 <= {(FIFO_ADDR_BITS+1){1'b0}};
      end
      else begin
         wr_addr_s1 <= wr_addr[FIFO_ADDR_BITS:0];
         wr_addr_s2 <= wr_addr_s1[FIFO_ADDR_BITS:0];
      end
   end

   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        empty <= 1'b1;
      else if (next_rd_addr == wr_addr_s2)
        empty <= 1'b1;
      else
        empty <= 1'b0;
   end
   
   //-------------------------------
   // RDS_CLK
   //-------------------------------
   /* rpc2_ctrl_fifo_gray_counter AUTO_TEMPLATE (
    .cnt(wr_ptr),
    .gray_cnt(wr_addr),
    .next_gray_cnt(next_wr_addr),
    .clk(rds_clk),
    .en(wr_enable),
    .rst_n(reset_n),
    );
    */
   rpc2_ctrl_fifo_gray_counter #(FIFO_ADDR_BITS+1) 
   wr_gray_counter (/*AUTOINST*/
                    // Outputs
                    .cnt                (wr_ptr),                // Templated
                    .gray_cnt           (wr_addr),               // Templated
                    .next_gray_cnt      (next_wr_addr),          // Templated
                    // Inputs
                    .clk                (rds_clk),               // Templated
                    .rst_n              (reset_n),               // Templated
                    .en                 (wr_enable));            // Templated

`ifdef DEBUG
   // sync to rds_clk
   always @(posedge rds_clk or negedge reset_n) begin
      if (~reset_n) begin
         rd_addr_s1 <= {(FIFO_ADDR_BITS+1){1'b0}};
         rd_addr_s2 <= {(FIFO_ADDR_BITS+1){1'b0}};
      end
      else begin
         rd_addr_s1 <= rd_addr[FIFO_ADDR_BITS:0];
         rd_addr_s2 <= rd_addr_s1[FIFO_ADDR_BITS:0];
      end
   end

   always @(posedge rds_clk or negedge reset_n) begin
      if (~reset_n)
        full <= 1'b0;
      else if (pre_full)
        full <= 1'b1;
      else
        full <= 1'b0;
   end

   always @(full)
     if (full) $display("ERROR: FIFO is full");
   
`endif
   
   //-------------------------------
   // MEM
   //-------------------------------
   always @(posedge clk) begin
      if (rd_enable)
        dqinfifo_dout <= mem[rd_ptr];
   end

   always @(posedge rds_clk) begin
      if (wr_enable)
        mem[wr_ptr] <= dqinfifo_din[FIFO_DATA_WIDTH-1:0];
   end
endmodule // rpc2_ctrl_dqinfifo

