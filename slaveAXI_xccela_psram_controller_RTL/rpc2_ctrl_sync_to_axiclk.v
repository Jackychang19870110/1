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
// Filename: rpc2_ctrl_sync_to_axiclk.v
//
//           Sync to AXI clock from Regsiter clock
//
// Created: yise  10/30/2015  version 2.4   - initial release
//
//*************************************************************************
module rpc2_ctrl_sync_to_axiclk (/*AUTOARG*/
   // Outputs
   reg_rd_trans_alloc, reg_wr_trans_alloc,
   // Inputs
   AXIm_ACLK, AXIm_ARESETN, tar_reg_rta, tar_reg_wta
   );
   input             AXIm_ACLK;
   input             AXIm_ARESETN;

   input  [1:0]      tar_reg_rta;
   input  [1:0]      tar_reg_wta;

   output [1:0]      reg_rd_trans_alloc;
   output [1:0]      reg_wr_trans_alloc;

   reg [1:0]         reg_rd_trans_alloc;
   reg [1:0]         reg_rd_trans_alloc_ff1;
   reg [1:0]         reg_wr_trans_alloc;
   reg [1:0]         reg_wr_trans_alloc_ff1;
   
   always @(posedge AXIm_ACLK or negedge AXIm_ARESETN) begin
      if (~AXIm_ARESETN) begin
         reg_rd_trans_alloc     <= 2'b00;
         reg_rd_trans_alloc_ff1 <= 2'b00;
         reg_wr_trans_alloc     <= 2'b00;
         reg_wr_trans_alloc_ff1 <= 2'b00;
      end
      else begin
         reg_rd_trans_alloc     <= reg_rd_trans_alloc_ff1;
         reg_rd_trans_alloc_ff1 <= tar_reg_rta;
         reg_wr_trans_alloc     <= reg_wr_trans_alloc_ff1;
         reg_wr_trans_alloc_ff1 <= tar_reg_wta;
      end
   end
endmodule // rpc2_ctrl_sync_to_axiclk
