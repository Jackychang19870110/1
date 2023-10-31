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
// Filename: rpc2_ctrl_axi_wr_response_channel2.v
//
//           AXI interface block of write response channel
//
// Created:  yise  01/31/2014  version 2.01  - initial release
// Modified: yise  05/15/2014  version 2.2   - added wr_active sig
//*************************************************************************
module rpc2_ctrl_axi_wr_response_channel2 (/*AUTOARG*/
   // Outputs
   AXI_BID, AXI_BRESP, AXI_BVALID, awid0_fifo_rd_en, 
   awid1_fifo_rd_en, bdat0_rd_en, bdat1_rd_en, wr_active, 
   // Inputs
   clk, reset_n, AXI_BREADY, awid0_id, awid0_fifo_empty, awid1_id, 
   awid1_fifo_empty, bdat0_dout, bdat0_empty, bdat1_dout, 
   bdat1_empty
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

   // for 0
//   input [1:0]                            ip0_wr_error;
//   input                          ip0_wr_done;

   input [C_AXI_ID_WIDTH-1:0]       awid0_id;
   input                            awid0_fifo_empty;
   output                           awid0_fifo_rd_en;

   // for 1
//   input [1:0]                            ip1_wr_error;
//   input                          ip1_wr_done;

   input [C_AXI_ID_WIDTH-1:0]       awid1_id;
   input                            awid1_fifo_empty;
   output                           awid1_fifo_rd_en;
   
   // BDAT FIFO
   output                           bdat0_rd_en;
//   output                         bdat0_wr_en;
//   output [1:0]                   bdat0_din;
   input [1:0]                      bdat0_dout;
   input                            bdat0_empty;

   output                           bdat1_rd_en;
//   output                         bdat1_wr_en;
//   output [1:0]                   bdat1_din;
   input [1:0]                      bdat1_dout;
   input                            bdat1_empty;

   output                           wr_active;
   
   wire                             clk;
   wire                             reset_n;
   
   wire                             bdat0_data_ready;
   wire                             bdat1_data_ready;
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 bdat0_data_valid;       // From axi_wr_response_control_0 of rpc2_ctrl_axi_wr_response_control.v
   wire                 bdat1_data_valid;       // From axi_wr_response_control_1 of rpc2_ctrl_axi_wr_response_control.v
   // End of automatics
   reg                  bdat_sel_block;
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [C_AXI_ID_WIDTH-1:0]AXI_BID;
   reg [1:0]            AXI_BRESP;
   reg                  AXI_BVALID;
   reg                  wr_active;
   // End of automatics
   wire                 bdat0_data_en;
   wire                 bdat1_data_en;

   assign bdat0_data_en = bdat0_data_valid & bdat0_data_ready;
   assign bdat1_data_en = bdat1_data_valid & bdat1_data_ready;
   
   assign bdat0_data_ready = ((~AXI_BVALID)|AXI_BREADY) & (~bdat_sel_block);
   assign bdat1_data_ready = ((~AXI_BVALID)|AXI_BREADY) & bdat_sel_block;

   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        bdat_sel_block <= 1'b0;
      else if (bdat0_rd_en & ((~bdat1_data_valid)|bdat1_data_ready))
        bdat_sel_block <= 1'b0;
      else if (bdat1_rd_en & ((~bdat0_data_valid)|bdat0_data_ready))
        bdat_sel_block <= 1'b1;
      else if (bdat0_data_en & bdat1_data_valid)
        bdat_sel_block <= 1'b1;
      else if (bdat1_data_en & bdat0_data_valid)
        bdat_sel_block <= 1'b0;
   end

   /* rpc2_ctrl_axi_wr_response_control AUTO_TEMPLATE (
    .awid_fifo_rd_en(awid@_fifo_rd_en),
    .bdat_rd_en(bdat@_rd_en),
    .bdat_wr_en(bdat@_wr_en),
    .bdat_din(bdat@_din[1:0]),
    .bdat_data_valid(bdat@_data_valid),
    .awid_fifo_empty(awid@_fifo_empty),
    .bdat_empty(bdat@_empty),
    .bdat_data_ready(bdat@_data_ready),
    );
    */
   rpc2_ctrl_axi_wr_response_control
     axi_wr_response_control_0 (/*AUTOINST*/
                                // Outputs
                                .awid_fifo_rd_en(awid0_fifo_rd_en), // Templated
                                .bdat_rd_en(bdat0_rd_en),        // Templated
                                .bdat_data_valid(bdat0_data_valid), // Templated
                                // Inputs
                                .clk    (clk),
                                .reset_n(reset_n),
                                .awid_fifo_empty(awid0_fifo_empty), // Templated
                                .bdat_empty(bdat0_empty),        // Templated
                                .bdat_data_ready(bdat0_data_ready)); // Templated
   rpc2_ctrl_axi_wr_response_control
     axi_wr_response_control_1 (/*AUTOINST*/
                                // Outputs
                                .awid_fifo_rd_en(awid1_fifo_rd_en), // Templated
                                .bdat_rd_en(bdat1_rd_en),        // Templated
                                .bdat_data_valid(bdat1_data_valid), // Templated
                                // Inputs
                                .clk    (clk),
                                .reset_n(reset_n),
                                .awid_fifo_empty(awid1_fifo_empty), // Templated
                                .bdat_empty(bdat1_empty),        // Templated
                                .bdat_data_ready(bdat1_data_ready)); // Templated
   
   //------------------------------------------------------
   // AXI
   //------------------------------------------------------   
   // AXI_BVALID
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_BVALID <= 1'b0;
      else if (bdat0_data_en | bdat1_data_en)
        AXI_BVALID <= 1'b1;
      else if (AXI_BREADY)
        AXI_BVALID <= 1'b0;
   end

   // AXI_BID
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_BID <= {C_AXI_ID_WIDTH{1'b0}};
      else if (bdat0_data_en)
        AXI_BID <= awid0_id;
      else if (bdat1_data_en)
        AXI_BID <= awid1_id;
   end

   // AXI_BRESP
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_BRESP <= 2'b00;
      else if (bdat0_data_en)
        AXI_BRESP <= bdat0_dout;
      else if (bdat1_data_en)
        AXI_BRESP <= bdat1_dout;
   end

   //--------------------------------------------
   // Status
   //--------------------------------------------
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        wr_active <= 1'b0;
      else
        wr_active <= (~awid0_fifo_empty) | (~awid1_fifo_empty) | 
                     bdat0_data_valid | bdat1_data_valid | AXI_BVALID;
   end
   
endmodule // rpc2_ctrl_axi_wr_response_channel2
