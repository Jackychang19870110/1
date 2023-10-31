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
// Filename: rpc2_ctrl_dqin_block.v
//
//           DQ input block for RPC2 Controller
//
// Created: yise  12/27/2013  version 2.0  - initial release
//*************************************************************************

module rpc2_ctrl_dqin_block (/*AUTOARG*/
   // Outputs
   dqinfifo_empty, dqinfifo_dout, 
   // Inputs
   clk, reset_n, rds_clk, dq_in, dqinfifo_rd_en, dqinfifo_wr_en
   );
   input clk;
   input reset_n;
    
   input rds_clk;
   input [7:0] dq_in;

   input dqinfifo_rd_en;
   output dqinfifo_empty;
   output [15:0] dqinfifo_dout;

   input         dqinfifo_wr_en;
   
   
   reg [7:0] dq_in_reg;
   wire [15:0] dqinfifo_din;

   assign dqinfifo_din = {dq_in_reg[7:0], dq_in[7:0]};
   
   // DQ high data
   always @(posedge rds_clk or negedge reset_n) begin
      if (~reset_n)
        dq_in_reg <= 8'h00;
      else
        dq_in_reg <= dq_in[7:0];
   end

   /* rpc2_ctrl_dqinfifo AUTO_TEMPLATE (
    .dqinfifo_dout(dqinfifo_dout[15:0]),
    .dqinfifo_din(dqinfifo_din[15:0]),
    .rds_clk(~rds_clk),
    );
    */
   rpc2_ctrl_dqinfifo
     dqinfifo (/*AUTOINST*/
               // Outputs
               .dqinfifo_dout           (dqinfifo_dout[15:0]),   // Templated
               .dqinfifo_empty          (dqinfifo_empty),
               // Inputs
               .reset_n                 (reset_n),
               .clk                     (clk),
               .dqinfifo_rd_en          (dqinfifo_rd_en),
               .rds_clk                 (~rds_clk),              // Templated
               .dqinfifo_wr_en          (dqinfifo_wr_en),
               .dqinfifo_din            (dqinfifo_din[15:0]));   // Templated
   
endmodule // rpc2_ctrl_dqin_block

