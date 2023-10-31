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
// Filename: rpc2_ctrl_trans_arbiter.v
//
//           Transaction arbiter
//
// Created: yise  11/04/2015  version 2.4   - initial release
//
//*************************************************************************
module rpc2_ctrl_trans_arbiter (/*AUTOARG*/
   // Outputs
   ready0, ready1, arb_valid, arb_selector,
   // Inputs
   clk, rst_n, valid0, valid1, valid0_weight, valid1_weight,
   arb_ready
   );
   input         clk;
   input         rst_n;
   input         valid0;
   input         valid1;
   input [1:0]   valid0_weight;
   input [1:0]   valid1_weight;
   output        ready0;
   output        ready1;
   
   output        arb_valid;
   output        arb_selector;
   input         arb_ready;

   reg           mux_sel;
   reg [1:0]     v0_counter;
   reg [1:0]     v1_counter;
   
   wire          arb_selector;
   wire          arb_valid;
   wire [1:0]    ready_bit;
   wire          mux_in0;
   wire          mux_in1;
   /*AUTOWIRE*/
   
   assign arb_valid = valid0 | valid1;
   assign ready_bit = 1'b1 << arb_selector;
   assign {ready1, ready0} = ready_bit & {arb_ready, arb_ready};
   assign arb_selector = (mux_sel) ? mux_in1: mux_in0;

   assign mux_in0 = ~valid0;  // xx0 priority is higher than xx1 priority => select 0
   assign mux_in1 = valid1;   // xx1 priority is higher than xx0 priority => select 1
   
   always @(posedge clk or negedge rst_n) begin
      if (~rst_n)
        mux_sel <= 1'b0;
      else if (arb_valid & arb_ready) begin
         if ((valid0_weight == v0_counter) && (arb_selector == 1'b0))
           mux_sel <= 1'b1;
         else if ((valid1_weight == v1_counter) && (arb_selector == 1'b1))
           mux_sel <= 1'b0;
      end
   end

   // Count of transactions
   always @(posedge clk or negedge rst_n) begin
      if (~rst_n) begin
         v0_counter <= 2'b00;
         v1_counter <= 2'b00;
      end
      else if (arb_valid & arb_ready) begin
         if (arb_selector == 1'b0) begin
            v1_counter <= 2'b00;
            if (v0_counter >= valid0_weight)
              v0_counter <= 2'b00;
            else
              v0_counter <= v0_counter + 1'b1;
         end
         else begin
            v0_counter <= 2'b00;
            if (v1_counter >= valid1_weight)
              v1_counter <= 2'b00;
            else
              v1_counter <= v1_counter + 1'b1;
         end
      end
      else begin
         v0_counter <= v0_counter;
         v1_counter <= v1_counter;
      end
   end
   
endmodule // rpc2_ctrl_trans_arbiter

