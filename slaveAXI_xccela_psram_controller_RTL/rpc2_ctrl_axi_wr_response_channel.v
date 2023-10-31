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
// Filename: rpc2_ctrl_axi_wr_response_channel.v
//
//           AXI interface block of write response channel
//
// Created: yise  01/20/2014  version 2.00  - initial release
//
//*************************************************************************
module rpc2_ctrl_axi_wr_response_channel (/*AUTOARG*/
   // Outputs
   AXI_BID, AXI_BRESP, AXI_BVALID, awid_fifo_rd_en, bdat_rd_en, 
   // Inputs
   clk, reset_n, AXI_BREADY, awid_id, awid_fifo_empty, bdat_dout, 
   bdat_empty
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   
   // Global System Signals
   input clk;
   input reset_n;

   // Write Response Channel Signals
   output [C_AXI_ID_WIDTH-1:0]      AXI_BID;
   output [1:0]                     AXI_BRESP;
   output                           AXI_BVALID;
   input                            AXI_BREADY;

//   input [1:0]                            ip_wr_error;
//   input                          ip_wr_done;

   input [C_AXI_ID_WIDTH-1:0]       awid_id;
   input                            awid_fifo_empty;
   output                           awid_fifo_rd_en;

   // BDAT FIFO
   output                           bdat_rd_en;
   input [1:0]                      bdat_dout;
   input                            bdat_empty;
//   output [1:0]                   bdat_din;
//   output                         bdat_wr_en;
   
   wire                             resp_en;
   wire                             bdat_data_ready;

//   wire                           bdat_wr_en;
//   wire [1:0]                             bdat_din;

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 bdat_data_valid;        // From axi_wr_response_control of rpc2_ctrl_axi_wr_response_control.v
   // End of automatics
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [C_AXI_ID_WIDTH-1:0]AXI_BID;
   reg [1:0]            AXI_BRESP;
   reg                  AXI_BVALID;
   // End of automatics

   assign bdat_data_ready = ((~AXI_BVALID)|AXI_BREADY);
//   assign bdat_wr_en = ip_wr_done;
//   assign bdat_din = ip_wr_error;
   
   rpc2_ctrl_axi_wr_response_control
     axi_wr_response_control (/*AUTOINST*/
                              // Outputs
                              .awid_fifo_rd_en(awid_fifo_rd_en),
                              .bdat_rd_en(bdat_rd_en),
                              .bdat_data_valid(bdat_data_valid),
                              // Inputs
                              .clk      (clk),
                              .reset_n  (reset_n),
                              .awid_fifo_empty(awid_fifo_empty),
                              .bdat_empty(bdat_empty),
                              .bdat_data_ready(bdat_data_ready));
      
   //------------------------------------------------------
   // AXI
   //------------------------------------------------------
   assign resp_en = bdat_data_ready & bdat_data_valid;

   // AXI_BVALID
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_BVALID <= 1'b0;
      else if (resp_en)
        AXI_BVALID <= 1'b1;
      else if (AXI_BREADY)
        AXI_BVALID <= 1'b0;
   end

   // AXI_BID
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_BID <= {C_AXI_ID_WIDTH{1'b0}};
      else if (resp_en)
        AXI_BID <= awid_id;
   end

   // AXI_BRESP
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_BRESP <= 2'b00;
      else if (resp_en)
        AXI_BRESP <= bdat_dout;
   end
   
endmodule // rpc2_ctrl_axi_wr_response_channel
