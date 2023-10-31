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
// Filename: rpc2_ctrl_sync_to_regclk.v
//
//           Sync to Register clock
//
// Created : yise    05/15/2014  version 2.2  - initial release
//*************************************************************************

module rpc2_ctrl_sync_to_regclk (/*AUTOARG*/
   // Outputs
   mem_rd_active, mem_wr_active, mem_wr_rsto_status, 
   mem_wr_slv_status, mem_wr_dec_status, mem_rd_stall_status, 
   mem_rd_rsto_status, mem_rd_slv_status, mem_rd_dec_status, 
   // Inputs
   AXIr_ACLK, AXIr_ARESETN, rd_active, wr_active, wr_rsto_status, 
   wr_slv_status, wr_dec_status, rd_stall_status, rd_rsto_status, 
   rd_slv_status, rd_dec_status
   );
   input AXIr_ACLK;
   input AXIr_ARESETN;

   input rd_active;
   input wr_active;
   input wr_rsto_status;
   input wr_slv_status;
   input wr_dec_status;
   input rd_stall_status;
   input rd_rsto_status;
   input rd_slv_status;
   input rd_dec_status;
   
   output mem_rd_active;
   output mem_wr_active;
   output mem_wr_rsto_status;
   output mem_wr_slv_status;
   output mem_wr_dec_status;
   output mem_rd_stall_status;
   output mem_rd_rsto_status;
   output mem_rd_slv_status;
   output mem_rd_dec_status;
   
   reg    mem_rd_active_ff1;
   reg    mem_wr_active_ff1;
   reg    mem_wr_rsto_status_ff1;
   reg    mem_wr_slv_status_ff1;
   reg    mem_wr_dec_status_ff1;
   reg    mem_rd_stall_status_ff1;
   reg    mem_rd_rsto_status_ff1;
   reg    mem_rd_slv_status_ff1;
   reg    mem_rd_dec_status_ff1;
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg                  mem_rd_active;
   reg                  mem_rd_dec_status;
   reg                  mem_rd_rsto_status;
   reg                  mem_rd_slv_status;
   reg                  mem_rd_stall_status;
   reg                  mem_wr_active;
   reg                  mem_wr_dec_status;
   reg                  mem_wr_rsto_status;
   reg                  mem_wr_slv_status;
   // End of automatics

   always @(posedge AXIr_ACLK or negedge AXIr_ARESETN) begin
      if (~AXIr_ARESETN) begin
         mem_rd_active_ff1 <= 1'b0;
         mem_rd_active     <= 1'b0;
         mem_wr_active_ff1 <= 1'b0;
         mem_wr_active     <= 1'b0;
         mem_wr_rsto_status     <= 1'b0;
         mem_wr_rsto_status_ff1 <= 1'b0;
         mem_wr_slv_status      <= 1'b0;
         mem_wr_slv_status_ff1  <= 1'b0;
         mem_wr_dec_status      <= 1'b0;
         mem_wr_dec_status_ff1  <= 1'b0;
         mem_rd_stall_status    <= 1'b0;
         mem_rd_stall_status_ff1<= 1'b0;
         mem_rd_rsto_status     <= 1'b0;
         mem_rd_rsto_status_ff1 <= 1'b0;
         mem_rd_slv_status      <= 1'b0;
         mem_rd_slv_status_ff1  <= 1'b0;
         mem_rd_dec_status      <= 1'b0;
         mem_rd_dec_status_ff1  <= 1'b0;
      end
      else begin
         mem_rd_active_ff1 <= rd_active;
         mem_rd_active     <= mem_rd_active_ff1;
         mem_wr_active_ff1 <= wr_active;
         mem_wr_active     <= mem_wr_active_ff1;
         mem_wr_rsto_status_ff1 <= wr_rsto_status;
         mem_wr_rsto_status     <= mem_wr_rsto_status_ff1;
         mem_wr_slv_status_ff1  <= wr_slv_status;
         mem_wr_slv_status      <= mem_wr_slv_status_ff1;
         mem_wr_dec_status_ff1  <= wr_dec_status;
         mem_wr_dec_status      <= mem_wr_dec_status_ff1;
         mem_rd_stall_status_ff1<= rd_stall_status;
         mem_rd_stall_status    <= mem_rd_stall_status_ff1;
         mem_rd_rsto_status_ff1 <= rd_rsto_status;
         mem_rd_rsto_status     <= mem_rd_rsto_status_ff1;
         mem_rd_slv_status_ff1  <= rd_slv_status;
         mem_rd_slv_status      <= mem_rd_slv_status_ff1;
         mem_rd_dec_status_ff1  <= rd_dec_status;
         mem_rd_dec_status      <= mem_rd_dec_status_ff1;
      end
   end
         
endmodule
   
