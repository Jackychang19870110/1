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
// Filename: rpc2_ctrl_fifo_synchronizer.v
//
//           1-deep 2-register FIFO synchronizer
//
// Created: yise  10/20/2015  version 2.4   - initial release
//
//*************************************************************************
module rpc2_ctrl_fifo_synchronizer (/*AUTOARG*/
   // Outputs
   rd_data, rd_ready, wr_ready,
   // Inputs
   rd_clk, rd_rst_n, rd_en, wr_clk, wr_rst_n, wr_en, wr_data
   );
   parameter FIFO_DATA_WIDTH = 8;
   parameter OUTPUT_REGISTER = 0;
   
   // Read Clock Domain
   input                        rd_clk;
   input                        rd_rst_n;
   input                        rd_en;
   output [FIFO_DATA_WIDTH-1:0] rd_data;
   output                       rd_ready; // inverted "empty" flag
   // Write Clock Domain
   input                        wr_clk;
   input                        wr_rst_n;
   input                        wr_en;
   input [FIFO_DATA_WIDTH-1:0]  wr_data;
   output                       wr_ready; // inverted "full" flag
   
   wire                         wr_enable;
   wire                         rd_enable;
   
   reg                          wr_ptr;
   reg                          rd_ptr;
   reg [FIFO_DATA_WIDTH-1:0]    mem[0:1];
   reg                          wr_ptr_fx_s1;
   reg                          wr_ptr_fx_s2;
   reg                          rd_ptr_fx_s1;
   reg                          rd_ptr_fx_s2;
   wire                         wr_ready;
   reg                          rd_ready;
   reg [FIFO_DATA_WIDTH-1:0]    rd_data;
   wire                         rd_ptr_next;
   
   assign wr_enable = wr_en & wr_ready;
   assign rd_enable = rd_en & rd_ready;
   assign wr_ready = ~(wr_ptr ^ rd_ptr_fx_s2);
   assign rd_ptr_next = rd_ptr ^ rd_enable;
   
   always @(posedge wr_clk or negedge wr_rst_n) begin
      if (~wr_rst_n)
        wr_ptr <= 1'b0;
      else
        wr_ptr <= wr_ptr ^ wr_enable;
   end
   
   // sync to wr_clk
   always @(posedge wr_clk or negedge wr_rst_n) begin
      if (~wr_rst_n) begin
         rd_ptr_fx_s1 <= 1'b0;
         rd_ptr_fx_s2 <= 1'b0;
      end
      else begin
         rd_ptr_fx_s1 <= rd_ptr;
         rd_ptr_fx_s2 <= rd_ptr_fx_s1;
      end
   end
        
   always @(posedge rd_clk or negedge rd_rst_n) begin
      if (~rd_rst_n)
        rd_ptr <= 1'b0;
      else
        rd_ptr <= rd_ptr_next;
   end
   
   // sync to rd_clk
   always @(posedge rd_clk or negedge rd_rst_n) begin
      if (~rd_rst_n) begin
         wr_ptr_fx_s1 <= 1'b0;
         wr_ptr_fx_s2 <= 1'b0;
      end
      else begin
         wr_ptr_fx_s1 <= wr_ptr;
         wr_ptr_fx_s2 <= wr_ptr_fx_s1;
      end
   end
   
   // 2-register
   always @(posedge wr_clk or negedge wr_rst_n) begin
      if (~wr_rst_n) begin
         mem[0] <= {FIFO_DATA_WIDTH{1'b0}};
         mem[1] <= {FIFO_DATA_WIDTH{1'b0}};
      end
      else if (wr_enable)
        mem[wr_ptr] <= wr_data[FIFO_DATA_WIDTH-1:0];
   end

   generate
      if (OUTPUT_REGISTER == 0) begin
         always @(*) begin
            rd_data = mem[rd_ptr];
            rd_ready = rd_ptr ^ wr_ptr_fx_s2;
         end
      end
      else begin
         always @(posedge rd_clk or negedge rd_rst_n) begin
            if (~rd_rst_n)
              rd_ready <= 1'b0;
            else
              rd_ready <= rd_ptr_next ^ wr_ptr_fx_s2;
         end

         always @(posedge rd_clk or negedge rd_rst_n) begin
            if (~rd_rst_n)
              rd_data  <= {FIFO_DATA_WIDTH{1'b0}};
            else if (rd_ptr_next ^ wr_ptr_fx_s2)
              rd_data  <= mem[rd_ptr_next];
         end
      end
   endgenerate
endmodule // rpc2_ctrl_fifo_synchronizer

