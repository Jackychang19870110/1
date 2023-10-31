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
// Filename: rpc2_ctrl_mem_reset_block.v
//
//           Reset block for RPC2 Controller
//
// Created: yise  01/10/2014  version 2.0  - initial release
//*************************************************************************

module rpc2_ctrl_mem_reset_block (/*AUTOARG*/
   // Outputs
   reset_n, powered_up, 
   // Inputs
   clk, rsto_n, areset_n
   );
   input clk;
   input rsto_n;
   input areset_n;

   output reset_n;
   output powered_up;
   
   wire   reset_n;
   reg    reset_ff1;
   reg    reset_ff2;
   reg    rston_ff1;
   reg    rston_ff2;
   
   assign reset_n = reset_ff2;
   assign powered_up = rston_ff2;
   
   // Sync
   always @(posedge clk or negedge areset_n) begin
      if (~areset_n) begin
         reset_ff1 <= 1'b0;
         reset_ff2 <= 1'b0;
      end
      else begin
         reset_ff1 <= 1'b1;
         reset_ff2 <= reset_ff1;
      end
   end

   // Sync rst_o
   always @(posedge clk or negedge rsto_n) begin
      if (~rsto_n) begin
         rston_ff1 <= 1'b0;
         rston_ff2 <= 1'b0;
      end
      else begin
         rston_ff1 <= 1'b1;
         rston_ff2 <= rston_ff1;
      end
   end
endmodule // rpc2_ctrl_mem_reset_block

   
