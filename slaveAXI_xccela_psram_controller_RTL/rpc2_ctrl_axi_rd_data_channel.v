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
// Filename: rpc2_ctrl_axi_rd_data_channel.v
//
//           AXI interface block of read data channel
//
// Created:  yise  01/20/2014  version 2.00  - initial release
// Modified: yise  05/15/2014  version 2.2   - added rd_active sig
//                 09/29/2014  version 2.3   - clean-up
//*************************************************************************
module rpc2_ctrl_axi_rd_data_channel (/*AUTOARG*/
   // Outputs
   AXI_RID, AXI_RDATA, AXI_RRESP, AXI_RLAST, AXI_RVALID, 
   axi2ip_data_ready, arid_fifo_rd_en, rdat_rd_en, rdat_wr_en, 
   rdat_din, rd_active, 
   // Inputs
   clk, reset_n, AXI_RREADY, ip_rd_error, ip_data_valid, 
   ip_data_last, ip_data, ip_strb, arid_id, arid_size, arid_len, 
   arid_strb, arid_fifo_empty, ip_clk, ip_reset_n, rdat_dout, 
   rdat_empty, rdat_full
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_DATA_WIDTH = 'd32;
   
   localparam RDAT_FIFO_DATA_WIDTH  = C_AXI_DATA_WIDTH+((C_AXI_DATA_WIDTH*2)/8);
   
   // Global System Signals
   input clk;
   input reset_n;
   
   // Read Data Channel Signals
   output [C_AXI_ID_WIDTH-1:0]   AXI_RID;
   output [C_AXI_DATA_WIDTH-1:0] AXI_RDATA;
   output [1:0]                  AXI_RRESP;
   output                        AXI_RLAST;
   output                        AXI_RVALID;
   input                         AXI_RREADY;

   input [1:0]                   ip_rd_error;
   input                         ip_data_valid;
   input                         ip_data_last;
   input [C_AXI_DATA_WIDTH-1:0]  ip_data;
   input [(C_AXI_DATA_WIDTH/8)-1:0] ip_strb;
   output                           axi2ip_data_ready;
   
   // from/to ARID
   input [C_AXI_ID_WIDTH-1:0]       arid_id;
   input [1:0]                      arid_size;
   input [7:0]                      arid_len;
   input [(C_AXI_DATA_WIDTH/8)-1:0] arid_strb;
   input                            arid_fifo_empty;
   output                           arid_fifo_rd_en;

   input                            ip_clk;
   input                            ip_reset_n;

   // RDAT FIFO
   output                           rdat_rd_en;
   output                           rdat_wr_en;
   output [RDAT_FIFO_DATA_WIDTH-1:0] rdat_din;
   input [RDAT_FIFO_DATA_WIDTH-1:0]  rdat_dout;
   input                             rdat_empty;
   input                             rdat_full;

   output                            rd_active;
   
   wire                              ip_data_valid;
   
   wire                              clk;
   wire                              reset_n;
   wire [RDAT_FIFO_DATA_WIDTH-1:0]   rdat_din;
   wire [RDAT_FIFO_DATA_WIDTH-1:0]   rdat_dout;
   wire                              rdat_full;
   wire                              rdat_empty;
   wire                              rdat_rd_en;
   wire                              rdat_wr_en;
   reg [(C_AXI_DATA_WIDTH/8)-1:0]    rdat_err_l_din;
   reg [(C_AXI_DATA_WIDTH/8)-1:0]    rdat_err_h_din;
   wire [(C_AXI_DATA_WIDTH/8)-1:0]   rdat_err_l_dout;
   wire [(C_AXI_DATA_WIDTH/8)-1:0]   rdat_err_h_dout;
   reg                               rdat_wr_op;
   reg                               rdat_data_valid;
   reg [C_AXI_DATA_WIDTH-1:0]        rdat_data_din;
   wire                              rdat_data_ready;

   wire                              arid_data_last;
   reg                               arid_data_valid;
   reg [7:0]                         length_counter;
   wire                              data_vr;
   reg                               rd_start;
   
   wire [(C_AXI_DATA_WIDTH/8)-1:0]   strb_rotate;
   reg [(C_AXI_DATA_WIDTH/8)-1:0]    strb;

   wire                              data_overwrite;
   reg [(C_AXI_DATA_WIDTH/8)-2:0]    rdat_data_din_valid;
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   // End of automatics
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [C_AXI_DATA_WIDTH-1:0]AXI_RDATA;
   reg [C_AXI_ID_WIDTH-1:0]AXI_RID;
   reg                  AXI_RLAST;
   reg [1:0]            AXI_RRESP;
   reg                  AXI_RVALID;
   reg                  rd_active;
   // End of automatics
   
   assign axi2ip_data_ready = ~rdat_full;
   assign data_vr = axi2ip_data_ready & ip_data_valid;
   
   //--------------------------------------------
   // Write to RDAT FIFO
   //--------------------------------------------   
   assign rdat_din = {rdat_err_h_din[(C_AXI_DATA_WIDTH/8)-1:0], rdat_err_l_din[(C_AXI_DATA_WIDTH/8)-1:0], rdat_data_din[C_AXI_DATA_WIDTH-1:0]};
   assign data_overwrite = |(rdat_data_din_valid & ip_strb[(C_AXI_DATA_WIDTH/8)-2:0]);
   assign rdat_wr_en = (rdat_wr_op & (~rdat_full)) || (data_overwrite & data_vr);
   
   // write enable to RDAT FIFO
   always @(posedge ip_clk or negedge ip_reset_n) begin
      if (~ip_reset_n)
        rdat_wr_op <= 1'b0;
      else if ((ip_strb[(C_AXI_DATA_WIDTH/8)-1] | ip_data_last) & data_vr)
        rdat_wr_op <= 1'b1;
      else if (rdat_wr_en)
        rdat_wr_op <= 1'b0;
   end
   
   genvar i;
   generate for (i = 0; i < (C_AXI_DATA_WIDTH/8); i=i+1) begin: rdat_data_din_loop
      always @(posedge ip_clk or negedge ip_reset_n) begin
         if (~ip_reset_n)
           rdat_data_din[8*i+:8] <= 8'h00;
         else if (ip_strb[i] & data_vr)
           rdat_data_din[ (8*i) +:8] <= ip_data[ (8*i) +: 8];          
         else if (rdat_wr_en)
           rdat_data_din[8*i+:8] <= 8'h00;
      end
   end
   endgenerate

   generate for (i = 0; i < (C_AXI_DATA_WIDTH/8); i=i+1) begin: rdat_err_din_loop
      always @(posedge ip_clk or negedge ip_reset_n) begin
         if (~ip_reset_n) begin
            rdat_err_l_din[i] <= 1'b0;
            rdat_err_h_din[i] <= 1'b0;
         end
         else if (ip_strb[i] & data_vr) begin
            rdat_err_l_din[i] <= ip_rd_error[0];
            rdat_err_h_din[i] <= ip_rd_error[1];
         end
         else if (rdat_wr_en) begin
            rdat_err_l_din[i] <= 1'b0;
            rdat_err_h_din[i] <= 1'b0;
         end
      end
   end
   endgenerate

   generate for (i = 0; i < ((C_AXI_DATA_WIDTH/8)-1); i=i+1) begin: rdat_data_din_valid_loop
      always @(posedge ip_clk or negedge ip_reset_n) begin
         if (~ip_reset_n)
           rdat_data_din_valid[i] <= 1'b0;
         else if ((ip_strb[(C_AXI_DATA_WIDTH/8)-1] | ip_data_last) & data_vr)
           rdat_data_din_valid[i] <= 1'b0;
         else if (ip_strb[i] & data_vr)
           rdat_data_din_valid[i] <= 1'b1;
      end
   end
   endgenerate
  
  
 
   //--------------------------------------------
   // Read from ARID
   //--------------------------------------------

   
   assign arid_fifo_rd_en = (~arid_fifo_empty) & (~rdat_empty) & ((~arid_data_valid) | arid_data_last);
//   assign arid_fifo_rd_en = (~arid_fifo_empty) & (~rdat_empty) & ((~arid_data_valid));   
   assign arid_data_last = rdat_data_valid & rdat_data_ready & (length_counter == arid_len);
  
   // arid_data_valid
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        arid_data_valid <= 1'b0;
      else if (arid_fifo_rd_en)
        arid_data_valid <= 1'b1;
      else if (arid_data_last)     
        arid_data_valid <= 1'b0;
   end

   //--------------------------------------------
   // Read from RDAT FIFO
   //--------------------------------------------
   assign strb_rotate = ({strb, strb}<<(1<<arid_size))>>((C_AXI_DATA_WIDTH/8));
   
//   assign rdat_rd_en = (~rdat_empty) & arid_data_valid & (~arid_data_last) & ((~rdat_data_valid) | (rdat_data_ready & strb[(C_AXI_DATA_WIDTH/8)-1])); 
   assign rdat_rd_en = (~rdat_empty) & arid_data_valid &  ((~rdat_data_valid) | (rdat_data_ready & strb[(C_AXI_DATA_WIDTH/8)-1]));

   
   assign rdat_data_ready = (~AXI_RVALID) | AXI_RREADY;
   
   
   // data from RDAT FIFO is valid
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        rdat_data_valid <= 1'b0;
      else if (rdat_rd_en)
        rdat_data_valid <= 1'b1;
      else if ((rdat_data_ready & strb[(C_AXI_DATA_WIDTH/8)-1]) | arid_data_last)
//      else if ((rdat_data_ready & strb[(C_AXI_DATA_WIDTH/8)-1]) | (length_counter == arid_len) )      
        rdat_data_valid <= 1'b0;
   end

   // strb
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        strb <= {(C_AXI_DATA_WIDTH/8){1'b0}};
      else if (rd_start)
        strb <= arid_strb;
      else if (rdat_data_valid & rdat_data_ready)
        strb <= strb_rotate;
   end
   
   // length_counter
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        length_counter <= 8'h00;
      else if (rd_start)
        length_counter <= 8'h00;
      else if (rdat_data_valid & rdat_data_ready)
        length_counter <= length_counter + 1'b1;
   end
   
   // rd_start
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        rd_start <= 1'b0;
      else
        rd_start <= arid_fifo_rd_en;
   end

   //--------------------------------------------
   // AXI
   //--------------------------------------------
   assign rdat_err_l_dout = rdat_dout[((C_AXI_DATA_WIDTH/8)+C_AXI_DATA_WIDTH)-1:C_AXI_DATA_WIDTH];
   assign rdat_err_h_dout = rdat_dout[RDAT_FIFO_DATA_WIDTH-1:(C_AXI_DATA_WIDTH/8)+C_AXI_DATA_WIDTH];
   
   // AXI_RDATA
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_RDATA[C_AXI_DATA_WIDTH-1:0] <= {C_AXI_DATA_WIDTH{1'b0}};
      else if (rdat_data_valid & rdat_data_ready)
        AXI_RDATA[C_AXI_DATA_WIDTH-1:0] <= rdat_dout[C_AXI_DATA_WIDTH-1:0];
   end
 
   // AXI_RVALID
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_RVALID <= 1'b0;
      else if (rdat_data_valid & rdat_data_ready)
        AXI_RVALID <= 1'b1;
      else if (AXI_RVALID & AXI_RREADY)
        AXI_RVALID <= 1'b0;
   end

   // AXI_RLAST
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_RLAST <= 1'b0;
      else if (arid_data_last)
//      else if (length_counter == arid_len)      
        AXI_RLAST <= 1'b1;
      else if (AXI_RVALID & AXI_RREADY)
        AXI_RLAST <= 1'b0;
   end
   
   // AXI_RID
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_RID <= {C_AXI_ID_WIDTH{1'b0}};
      else if (rdat_data_valid & rdat_data_ready)
        AXI_RID <= arid_id[C_AXI_ID_WIDTH-1:0];
   end
   
   // AXI_RRESP
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         AXI_RRESP[0] <= 1'b0;
         AXI_RRESP[1] <= 1'b0;
      end
      else if (rdat_data_valid & rdat_data_ready) begin
         AXI_RRESP[0] <= |(strb & rdat_err_l_dout);
         AXI_RRESP[1] <= |(strb & rdat_err_h_dout);
      end
   end

   //--------------------------------------------
   // Status
   //--------------------------------------------
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        rd_active <= 1'b0;
      else
        rd_active <= (~arid_fifo_empty) | arid_data_valid | AXI_RVALID;
   end
   
endmodule // rpc2_ctrl_axi_rd_data_channel
