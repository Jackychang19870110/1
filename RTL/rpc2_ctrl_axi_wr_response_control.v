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
// Filename: rpc2_ctrl_axi_wr_response_control.v
//
//           AXI interface control block of write response channel
//
// Created: yise  01/31/2014  version 2.01  - initial release
//
//*************************************************************************
module rpc2_ctrl_axi_wr_response_control (/*AUTOARG*/
   // Outputs
   awid_fifo_rd_en, bdat_rd_en, bdat_data_valid, 
   // Inputs
   clk, reset_n, awid_fifo_empty, bdat_empty, bdat_data_ready
   );
   // Global System Signals
   input clk;
   input reset_n;

   // IP
//   input [1:0]                            ip_wr_error;
//   input                          ip_wr_done;

   // AWID FIFO
   input                            awid_fifo_empty;
   output                           awid_fifo_rd_en;

   // BDAT FIFO
   output                           bdat_rd_en;
//   output                         bdat_wr_en;
//   output [1:0]                   bdat_din;
   input                            bdat_empty;

   input                            bdat_data_ready;
   output                           bdat_data_valid;
   
   wire                             clk;
   wire                             reset_n;
   wire                             bdat_rd_en;
//   wire [1:0]                             bdat_din;
   wire                             bdat_empty;
   reg                              bdat_data_valid;
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   // End of automatics
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   // End of automatics
   assign bdat_rd_en = (~awid_fifo_empty) & (~bdat_empty) & ((~bdat_data_valid)|bdat_data_ready);
   
   assign awid_fifo_rd_en = bdat_rd_en;
   
   // data valid from BDAT and AWID FIFO
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        bdat_data_valid <= 1'b0;
      else if (bdat_rd_en)
        bdat_data_valid <= 1'b1;
      else if (bdat_data_ready)
        bdat_data_valid <= 1'b0;
   end

endmodule // rpc2_ctrl_axi_wr_response_control

