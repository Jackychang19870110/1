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
// Filename: rpc2_ctrl_axi_address_channel.v
//
//           AXI interface block of address channel
//
// Created: yise  01/31/2014  version 2.01  - initial release
// Modified: yise 10/19/2015  version 2.4   - remove wdata_ready
//
//*************************************************************************

module rpc2_ctrl_axi_address_channel (/*AUTOARG*/
   // Outputs
   AXI_AWREADY, AXI_ARREADY, axi2ip_valid, wready_req, wready_fixed,
   wready_size, wready_strb, awid_id, awid_fifo_empty, arid_id,
   arid_size, arid_len, arid_strb, arid_fifo_empty, adr_rd_en,
   adr_wr_en, adr_din,
   // Inputs
   clk, reset_n, AXI_AWID, AXI_AWADDR, AXI_AWLEN, AXI_AWSIZE,
   AXI_AWBURST, AXI_AWVALID, AXI_ARID, AXI_ARADDR, AXI_ARLEN,
   AXI_ARSIZE, AXI_ARBURST, AXI_ARVALID, ip_ready, ip_data_size,
   wready_done, awid_fifo_rd_en, arid_fifo_rd_en, adr_full, adr_empty,
   ip_clk, ip_reset_n
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_ADDR_WIDTH = 'd32;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_LEN_WIDTH  = 'd8;
   parameter C_AR_FIFO_ADDR_BITS  = 'd4;
   parameter C_AW_FIFO_ADDR_BITS  = 'd4;  
   parameter C_NOWAIT_WR_DATA_DONE = 1'b0;

//   parameter DPRAM_MACRO = 0;        // 0=Macro is not used, 1=Macro is used
//   parameter DPRAM_MACRO_TYPE = 0;   // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)

   localparam IP_LEN = (C_AXI_DATA_WIDTH=='d32) ? 'd10:
                       (C_AXI_DATA_WIDTH=='d64) ? 'd11: 'd0;
//   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2; //44: addr+len+burst
//   localparam ADR_FIFO_DATA_WIDTH = PRE_ADR_DATA_WIDTH+1; //45: addr+len+burst+r/w
   
   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2+2; //46: addr+len+burst+size  32+10+2+2 = 46  
   localparam ADR_FIFO_DATA_WIDTH = PRE_ADR_DATA_WIDTH+1; //47: addr+len+burst+size+r/w
   
   // Global System Signals
   input                        clk;
   input                        reset_n;

   // Write Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0]   AXI_AWID;
   input [C_AXI_ADDR_WIDTH-1:0] AXI_AWADDR;
   input [C_AXI_LEN_WIDTH-1:0]  AXI_AWLEN;
   input [2:0]                  AXI_AWSIZE;
   input [1:0]                  AXI_AWBURST;
   input                        AXI_AWVALID;
   output                       AXI_AWREADY;

   // Read Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0] AXI_ARID;
   input [C_AXI_ADDR_WIDTH-1:0] AXI_ARADDR;
   input [C_AXI_LEN_WIDTH-1:0]  AXI_ARLEN;
   input [2:0]                  AXI_ARSIZE;
   input [1:0]                  AXI_ARBURST;
   input                        AXI_ARVALID;
   output                       AXI_ARREADY;

   // for IP
   input                        ip_ready;
   output                       axi2ip_valid;
//   output                     axi2ip_rw_n;
//   output [1:0]               axi2ip_burst;
//   output [1:0]               axi2ip_size;
//   output [IP_LEN-1:0]                axi2ip_len;
//   output [31:0]              axi2ip_address;
   
   input [1:0]                   ip_data_size;
   
   // for Write Data
   output                        wready_req;
   output                        wready_fixed;
   output [1:0]                  wready_size;
   output [(C_AXI_DATA_WIDTH/8)-1:0] wready_strb;
   
   input                         wready_done;

   // for Write Response
   input                         awid_fifo_rd_en;
   output [C_AXI_ID_WIDTH-1:0]   awid_id;
   output                        awid_fifo_empty;
   
   // for Read Response
   input                         arid_fifo_rd_en;
   output [C_AXI_ID_WIDTH-1:0]   arid_id;
   output [1:0]                  arid_size;
   output [7:0]                  arid_len;
   output [(C_AXI_DATA_WIDTH/8)-1:0] arid_strb;
   output                            arid_fifo_empty;

   // ADR FIFO
   output                            adr_rd_en;
   output                            adr_wr_en;
   output [ADR_FIFO_DATA_WIDTH-1:0]  adr_din;
//   input [ADR_FIFO_DATA_WIDTH-1:0]   adr_dout;
   input                             adr_full;
   input                             adr_empty;
   
   input                             ip_clk;
   input                             ip_reset_n;
   

//   wire                            aw_fifo_wr_en;
//   wire                            ar_fifo_wr_en;
//   wire                            aw_fifo_rd_en;
//   wire                            ar_fifo_rd_en;
   wire                              adr_wr_en_aw;
   wire                              adr_wr_en_ar;
   wire                              adr_wr_en;
   wire                              adr_wr_aw_ready;
   wire                              adr_wr_ar_ready;
   
   wire [ADR_FIFO_DATA_WIDTH-1:0]    adr_din;
//   wire [ADR_FIFO_DATA_WIDTH-1:0]    adr_dout;
   wire                              adr_rd_en;

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [PRE_ADR_DATA_WIDTH-1:0] adr_ar_din;    // From axi_rd_address_control of rpc2_ctrl_axi_rd_address_control.v
   wire [PRE_ADR_DATA_WIDTH-1:0] adr_aw_din;    // From axi_wr_address_control of rpc2_ctrl_axi_wr_address_control.v
   wire                 adr_wr_ar_valid;        // From axi_rd_address_control of rpc2_ctrl_axi_rd_address_control.v
   wire                 adr_wr_aw_valid;        // From axi_wr_address_control of rpc2_ctrl_axi_wr_address_control.v
   wire                 arid_fifo_pre_full;     // From axi_rd_address_control of rpc2_ctrl_axi_rd_address_control.v
   wire                 awid_fifo_pre_full;     // From axi_wr_address_control of rpc2_ctrl_axi_wr_address_control.v
   // End of automatics
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg                  AXI_ARREADY;
   reg                  AXI_AWREADY;
   reg                  axi2ip_valid;
   // End of automatics
   
   assign adr_wr_aw_ready = ~adr_full;
   assign adr_wr_en_aw = adr_wr_aw_valid & adr_wr_aw_ready;
   
   assign adr_wr_ar_ready = (~adr_full) & ~adr_wr_aw_valid;  // write priority is higher than read
   assign adr_wr_en_ar = adr_wr_ar_valid & adr_wr_ar_ready;
   
   assign adr_wr_en = adr_wr_en_aw | adr_wr_en_ar;
   assign adr_din = (adr_wr_en_aw) ? {1'b0, adr_aw_din}: {1'b1, adr_ar_din};


   rpc2_ctrl_axi_wr_address_control
     #(C_AXI_ID_WIDTH,
       C_AXI_ADDR_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_LEN_WIDTH,
       C_AW_FIFO_ADDR_BITS,
       C_NOWAIT_WR_DATA_DONE)
     axi_wr_address_control (/*AUTOINST*/
                             // Outputs
                             .wready_req        (wready_req),
                             .wready_fixed      (wready_fixed),
                             .wready_size       (wready_size[1:0]),
                             .wready_strb       (wready_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                             .awid_id           (awid_id[C_AXI_ID_WIDTH-1:0]),
                             .awid_fifo_pre_full(awid_fifo_pre_full),
                             .awid_fifo_empty   (awid_fifo_empty),
                             .adr_wr_aw_valid   (adr_wr_aw_valid),
                             .adr_aw_din        (adr_aw_din[PRE_ADR_DATA_WIDTH-1:0]),
                             // Inputs
                             .clk               (clk),
                             .reset_n           (reset_n),
                             .AXI_AWID          (AXI_AWID[C_AXI_ID_WIDTH-1:0]),
                             .AXI_AWADDR        (AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0]),
                             .AXI_AWLEN         (AXI_AWLEN[C_AXI_LEN_WIDTH-1:0]),
                             .AXI_AWSIZE        (AXI_AWSIZE[2:0]),
                             .AXI_AWBURST       (AXI_AWBURST[1:0]),
                             .AXI_AWVALID       (AXI_AWVALID),
                             .AXI_AWREADY       (AXI_AWREADY),
                             .wready_done       (wready_done),
                             .awid_fifo_rd_en   (awid_fifo_rd_en),
                             .adr_wr_aw_ready   (adr_wr_aw_ready),
                             .ip_data_size      (ip_data_size[1:0]));
   
   rpc2_ctrl_axi_rd_address_control
     #(C_AXI_ID_WIDTH,
       C_AXI_ADDR_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_LEN_WIDTH,
       C_AR_FIFO_ADDR_BITS)
     axi_rd_address_control (/*AUTOINST*/
                             // Outputs
                             .arid_id           (arid_id[C_AXI_ID_WIDTH-1:0]),
                             .arid_size         (arid_size[1:0]),
                             .arid_len          (arid_len[7:0]),
                             .arid_strb         (arid_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                             .arid_fifo_pre_full(arid_fifo_pre_full),
                             .arid_fifo_empty   (arid_fifo_empty),
                             .adr_wr_ar_valid   (adr_wr_ar_valid),
                             .adr_ar_din        (adr_ar_din[PRE_ADR_DATA_WIDTH-1:0]),
                             // Inputs
                             .clk               (clk),
                             .reset_n           (reset_n),
                             .AXI_ARID          (AXI_ARID[C_AXI_ID_WIDTH-1:0]),
                             .AXI_ARADDR        (AXI_ARADDR[C_AXI_ADDR_WIDTH-1:0]),
                             .AXI_ARLEN         (AXI_ARLEN[C_AXI_LEN_WIDTH-1:0]),
                             .AXI_ARSIZE        (AXI_ARSIZE[2:0]),
                             .AXI_ARBURST       (AXI_ARBURST[1:0]),
                             .AXI_ARVALID       (AXI_ARVALID),
                             .AXI_ARREADY       (AXI_ARREADY),
                             .arid_fifo_rd_en   (arid_fifo_rd_en),
                             .adr_wr_ar_ready   (adr_wr_ar_ready),
                             .ip_data_size      (ip_data_size[1:0]));
   
   //----------------------------------------------------------
   // AXI
   //----------------------------------------------------------
   // AXI_AWREADY
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_AWREADY <= 1'b0;
      else if (awid_fifo_pre_full)
        AXI_AWREADY <= 1'b0;
      else
        AXI_AWREADY <= 1'b1;
   end
        
   // AXI_ARREADY
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_ARREADY <= 1'b0;
      else if (arid_fifo_pre_full)
        AXI_ARREADY <= 1'b0;
      else
        AXI_ARREADY <= 1'b1;
   end
   
   //----------------------------------------------------------
   // IP
   //----------------------------------------------------------
   assign adr_rd_en = (~adr_empty) && (ip_ready | ~axi2ip_valid);


//   assign axi2ip_rw_n = adr_dout[36+IP_LEN]; 
//   assign axi2ip_size = adr_dout[(36+IP_LEN)-1:34+IP_LEN];
   
//   assign axi2ip_burst = adr_dout[(34+IP_LEN)-1:32+IP_LEN];
//   assign axi2ip_len   = adr_dout[(32+IP_LEN)-1:32];
//   assign axi2ip_address = adr_dout[31:0];
   
   // axi2ip_valid
   always @(posedge ip_clk or negedge ip_reset_n) begin
      if (~ip_reset_n)
        axi2ip_valid <= 1'b0;
      else if (adr_rd_en)
        axi2ip_valid <= 1'b1;
      else if (axi2ip_valid & ip_ready)
        axi2ip_valid <= 1'b0;
   end

endmodule // rpc2_ctrl_axi_address_channel
