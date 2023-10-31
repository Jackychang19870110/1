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
// Filename: rpc2_ctrl_fifo_gray_counter.v
//
//           Gray counter
//
// Created: yise  12/27/2013  version 2.0  - initial release
//*************************************************************************

module rpc2_ctrl_fifo_gray_counter (/*AUTOARG*/
   // Outputs
   cnt, gray_cnt, next_gray_cnt, 
   // Inputs
   clk, rst_n, en
   );
   parameter WIDTH = 'd9;

   input clk;
   input rst_n;
//   input clr;
   input en;

   output [WIDTH-2:0] cnt;
   output [WIDTH-1:0] gray_cnt;
   output [WIDTH-1:0] next_gray_cnt;
   
   wire [WIDTH-1:0] next_cnt;
   wire [WIDTH-2:0] rshift_next_cnt;
   wire [WIDTH-1:0] next_gray_cnt;
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [WIDTH-1:0]      gray_cnt;
   // End of automatics
   reg [WIDTH-1:0] bin_cnt;

   assign cnt = bin_cnt[WIDTH-2:0];
   assign next_cnt = bin_cnt + en;
   assign rshift_next_cnt = (next_cnt>>1);
   assign next_gray_cnt = next_cnt ^ {1'b0, rshift_next_cnt};
         
   always @(posedge clk or negedge rst_n) begin
      if (~rst_n) begin
         bin_cnt <= {WIDTH{1'b0}};
         gray_cnt <= {WIDTH{1'b0}};
      end
//      else if (clr) begin
//       bin_cnt <= {WIDTH{1'b0}};
//       gray_cnt <= {WIDTH{1'b0}};
//      end
      else begin
         bin_cnt <= next_cnt[WIDTH-1:0];
         gray_cnt <= next_gray_cnt[WIDTH-1:0];
      end
   end
endmodule // rpc2_ctrl_fifo_gray_counter
