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
// Filename: rpc2_ctrl_axi_channel.v
//
//           AXI interface block for register channel
//
// Created: yise  01/20/2014  version 2.00  - initial release
//
//*************************************************************************
module rpc2_ctrl_axi_channel (/*AUTOARG*/
   // Outputs
   AXI_AWREADY, AXI_WREADY, AXI_BID, AXI_BRESP, AXI_BVALID, 
   AXI_ARREADY, AXI_RID, AXI_RDATA, AXI_RRESP, AXI_RLAST, AXI_RVALID, 
   axi2ip_valid, axi2ip_rw_n, axi2ip_address, axi2ip_burst,
   axi2ip_size,  
   axi2ip_len, axi2ip_data_valid, axi2ip_strb, axi2ip_data, 
   axi2ip_data_ready, 
   // Inputs
   AXI_ACLK, AXI_ARESETN, AXI_AWID, AXI_AWADDR, AXI_AWLEN, 
   AXI_AWSIZE, AXI_AWBURST, AXI_AWVALID, AXI_WDATA, AXI_WSTRB, 
   AXI_WLAST, AXI_WVALID, AXI_BREADY, AXI_ARID, AXI_ARADDR, 
   AXI_ARLEN, AXI_ARSIZE, AXI_ARBURST, AXI_ARVALID, AXI_RREADY, 
   ip_data_size, ip_ready, ip_data_ready, ip_data_valid, 
   ip_data_last, ip_strb, ip_data, ip_rd_error, ip_wr_done, 
   ip_wr_error
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_ADDR_WIDTH = 'd32;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_LEN_WIDTH  = 'd8;
   parameter C_ADR_FIFO_ADDR_BITS = 'd4;
   parameter C_AW_FIFO_ADDR_BITS  = 'd4;
   parameter C_AR_FIFO_ADDR_BITS  = 'd4;
   parameter C_WDAT_FIFO_ADDR_BITS = 'd9;
   parameter C_RDAT_FIFO_ADDR_BITS = 'd9;
   parameter C_NOWAIT_WR_DATA_DONE = 1'b0;

//   parameter DPRAM_MACRO = 0;        // 0=Macro is not used, 1=Macro is used
//   parameter DPRAM_MACRO_TYPE = 0;   // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)

   localparam IP_LEN = (C_AXI_DATA_WIDTH=='d32) ? 'd10:
                       (C_AXI_DATA_WIDTH=='d64) ? 'd11: 'd0; 
                       
                       
//   localparam ADR_FIFO_DATA_WIDTH = 'd45; //45: addr+len+burst+r/w
   localparam ADR_FIFO_DATA_WIDTH = 'd47; //47: addr+len+burst+size+r/w   
   
   localparam RDAT_FIFO_DATA_WIDTH = C_AXI_DATA_WIDTH+((C_AXI_DATA_WIDTH*2)/8);
   localparam WDAT_FIFO_DATA_WIDTH = C_AXI_DATA_WIDTH+((C_AXI_DATA_WIDTH*2)/8);
   
   // Global System Signals
   input AXI_ACLK;
   input AXI_ARESETN;

   // Write Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0] AXI_AWID;
   input [C_AXI_ADDR_WIDTH-1:0] AXI_AWADDR;
   input [C_AXI_LEN_WIDTH-1:0]  AXI_AWLEN;
   input [2:0]                  AXI_AWSIZE;
   input [1:0]                  AXI_AWBURST;
   input                        AXI_AWVALID;
   output                       AXI_AWREADY;
   
   // Write Data Channel Signals
   input [C_AXI_DATA_WIDTH-1:0] AXI_WDATA;
   input [(C_AXI_DATA_WIDTH/8)-1:0] AXI_WSTRB;
   input                            AXI_WLAST;
   input                            AXI_WVALID;
   output                           AXI_WREADY;
   
   // Write Response Channel Signals
   output [C_AXI_ID_WIDTH-1:0]      AXI_BID;
   output [1:0]                     AXI_BRESP;
   output                           AXI_BVALID;
   input                            AXI_BREADY;

   // Read Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0]       AXI_ARID;
   input [C_AXI_ADDR_WIDTH-1:0]     AXI_ARADDR;
   input [C_AXI_LEN_WIDTH-1:0]      AXI_ARLEN;
   input [2:0]                      AXI_ARSIZE;
   input [1:0]                      AXI_ARBURST;
   input                            AXI_ARVALID;
   output                           AXI_ARREADY;
   
   // Read Data Channel Signals
   output [C_AXI_ID_WIDTH-1:0]      AXI_RID;
   output [C_AXI_DATA_WIDTH-1:0]    AXI_RDATA;
   output [1:0]                     AXI_RRESP;
   output                           AXI_RLAST;
   output                           AXI_RVALID;
   input                            AXI_RREADY;
   
   input [1:0]                      ip_data_size;

   // AXI address
   input                            ip_ready;
   output                           axi2ip_valid;
   output                           axi2ip_rw_n;
   output [31:0]                    axi2ip_address;
   
   output [1:0]                     axi2ip_size;
      
   output [1:0]                     axi2ip_burst;
   output [IP_LEN-1:0]              axi2ip_len;
   
   // AXI write data
   input                            ip_data_ready;
   output                           axi2ip_data_valid;
   output [(C_AXI_DATA_WIDTH/8)-1:0] axi2ip_strb;
   output [C_AXI_DATA_WIDTH-1:0]     axi2ip_data;
   
   // AXI read data
   input                             ip_data_valid;
   input                             ip_data_last;
   input [(C_AXI_DATA_WIDTH/8)-1:0]  ip_strb;
   input [C_AXI_DATA_WIDTH-1:0]      ip_data;
   input [1:0]                       ip_rd_error;
   output                            axi2ip_data_ready;
   
   // AXI write response
   input                             ip_wr_done;
   input [1:0]                       ip_wr_error;
   
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   // End of automatics
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [ADR_FIFO_DATA_WIDTH-1:0]adr_din;       // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire                 adr_empty;              // From adr_fifo of rpc2_ctrl_sync_fifo.v
   wire                 adr_full;               // From adr_fifo of rpc2_ctrl_sync_fifo.v
   wire                 adr_rd_en;              // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire                 adr_wr_en;              // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire                 arid_fifo_empty;        // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire                 arid_fifo_rd_en;        // From axi_rd_data_channel of rpc2_ctrl_axi_rd_data_channel.v
   wire [C_AXI_ID_WIDTH-1:0]arid_id;            // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire [7:0]           arid_len;               // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire [1:0]           arid_size;              // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire [(C_AXI_DATA_WIDTH/8)-1:0]arid_strb;    // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire                 awid_fifo_empty;        // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire                 awid_fifo_rd_en;        // From axi_wr_response_channel of rpc2_ctrl_axi_wr_response_channel.v
   wire [C_AXI_ID_WIDTH-1:0]awid_id;            // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire [1:0]           bdat_dout;              // From bdat_fifo of rpc2_ctrl_ax_fifo.v
   wire                 bdat_empty;             // From bdat_fifo of rpc2_ctrl_ax_fifo.v
   wire                 bdat_rd_en;             // From axi_wr_response_channel of rpc2_ctrl_axi_wr_response_channel.v
   wire [RDAT_FIFO_DATA_WIDTH-1:0]rdat_din;     // From axi_rd_data_channel of rpc2_ctrl_axi_rd_data_channel.v
   wire [RDAT_FIFO_DATA_WIDTH-1:0]rdat_dout;    // From rdat_fifo of rpc2_ctrl_sync_fifo.v
   wire                 rdat_empty;             // From rdat_fifo of rpc2_ctrl_sync_fifo.v
   wire                 rdat_full;              // From rdat_fifo of rpc2_ctrl_sync_fifo.v
   wire                 rdat_rd_en;             // From axi_rd_data_channel of rpc2_ctrl_axi_rd_data_channel.v
   wire                 rdat_wr_en;             // From axi_rd_data_channel of rpc2_ctrl_axi_rd_data_channel.v
   wire [WDAT_FIFO_DATA_WIDTH-1:0]wdat_din;     // From axi_wr_data_channel of rpc2_ctrl_axi_wr_data_channel.v
   wire [WDAT_FIFO_DATA_WIDTH-1:0]wdat_dout;    // From wdat_fifo of rpc2_ctrl_sync_fifo_axi.v
   wire                 wdat_empty;             // From wdat_fifo of rpc2_ctrl_sync_fifo_axi.v
   wire                 wdat_full;              // From wdat_fifo of rpc2_ctrl_sync_fifo_axi.v
   wire                 wdat_pre_full;          // From wdat_fifo of rpc2_ctrl_sync_fifo_axi.v
   wire                 wdat_rd_en;             // From axi_wr_data_channel of rpc2_ctrl_axi_wr_data_channel.v
   wire                 wdat_wr_en;             // From axi_wr_data_channel of rpc2_ctrl_axi_wr_data_channel.v
   wire                 wready_done;            // From axi_wr_data_channel of rpc2_ctrl_axi_wr_data_channel.v
   wire                 wready_fixed;           // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire                 wready_req;             // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire [1:0]           wready_size;            // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   wire [(C_AXI_DATA_WIDTH/8)-1:0]wready_strb;  // From axi_address_channel of rpc2_ctrl_axi_address_channel.v
   // End of automatics
   wire [ADR_FIFO_DATA_WIDTH-1:0] adr_dout;
   wire                           rd_active;
   
   wire                           clk;
   wire                           ip_clk;
   wire                           reset_n;
   wire                           ip_reset_n;
   
   assign clk    = AXI_ACLK;
   assign ip_clk = AXI_ACLK;
   assign reset_n    = AXI_ARESETN;
   assign ip_reset_n = AXI_ARESETN;

//   assign axi2ip_rw_n  = adr_dout[34+IP_LEN];
   assign axi2ip_rw_n = adr_dout[36+IP_LEN]; 
   assign axi2ip_size = adr_dout[(36+IP_LEN)-1:34+IP_LEN];
   
   
   assign axi2ip_burst = adr_dout[(34+IP_LEN)-1:32+IP_LEN];
   assign axi2ip_len   = adr_dout[(32+IP_LEN)-1:32];
   assign axi2ip_address = adr_dout[31:0];
   
   rpc2_ctrl_axi_address_channel
     #(C_AXI_ID_WIDTH,
       C_AXI_ADDR_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_LEN_WIDTH,
       C_AR_FIFO_ADDR_BITS,
       C_AW_FIFO_ADDR_BITS,
       C_NOWAIT_WR_DATA_DONE
       )
   axi_address_channel (/*AUTOINST*/
                        // Outputs
                        .AXI_AWREADY    (AXI_AWREADY),
                        .AXI_ARREADY    (AXI_ARREADY),
                        .axi2ip_valid   (axi2ip_valid),
                        .wready_req     (wready_req),
                        .wready_fixed   (wready_fixed),
                        .wready_size    (wready_size[1:0]),
                        .wready_strb    (wready_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                        .awid_id        (awid_id[C_AXI_ID_WIDTH-1:0]),
                        .awid_fifo_empty(awid_fifo_empty),
                        .arid_id        (arid_id[C_AXI_ID_WIDTH-1:0]),
                        .arid_size      (arid_size[1:0]),
                        .arid_len       (arid_len[7:0]),
                        .arid_strb      (arid_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                        .arid_fifo_empty(arid_fifo_empty),
                        .adr_rd_en      (adr_rd_en),
                        .adr_wr_en      (adr_wr_en),
                        .adr_din        (adr_din[ADR_FIFO_DATA_WIDTH-1:0]),
                        // Inputs
                        .clk            (clk),
                        .reset_n        (reset_n),
                        .AXI_AWID       (AXI_AWID[C_AXI_ID_WIDTH-1:0]),
                        .AXI_AWADDR     (AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0]),
                        .AXI_AWLEN      (AXI_AWLEN[C_AXI_LEN_WIDTH-1:0]),
                        .AXI_AWSIZE     (AXI_AWSIZE[2:0]),
                        .AXI_AWBURST    (AXI_AWBURST[1:0]),
                        .AXI_AWVALID    (AXI_AWVALID),
                        .AXI_ARID       (AXI_ARID[C_AXI_ID_WIDTH-1:0]),
                        .AXI_ARADDR     (AXI_ARADDR[C_AXI_ADDR_WIDTH-1:0]),
                        .AXI_ARLEN      (AXI_ARLEN[C_AXI_LEN_WIDTH-1:0]),
                        .AXI_ARSIZE     (AXI_ARSIZE[2:0]),
                        .AXI_ARBURST    (AXI_ARBURST[1:0]),
                        .AXI_ARVALID    (AXI_ARVALID),
                        .ip_ready       (ip_ready),
                        .ip_data_size   (ip_data_size[1:0]),
                        .wready_done    (wready_done),
                        .awid_fifo_rd_en(awid_fifo_rd_en),
                        .arid_fifo_rd_en(arid_fifo_rd_en),
                        .adr_full       (adr_full),
                        .adr_empty      (adr_empty),
                        .ip_clk         (ip_clk),
                        .ip_reset_n     (ip_reset_n));

   rpc2_ctrl_axi_wr_data_channel
//     #(C_AXI_ID_WIDTH,
     #(C_AXI_DATA_WIDTH)
   axi_wr_data_channel (/*AUTOINST*/
                        // Outputs
                        .AXI_WREADY     (AXI_WREADY),
                        .wready_done    (wready_done),
                        .axi2ip_data_valid(axi2ip_data_valid),
                        .axi2ip_strb    (axi2ip_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                        .axi2ip_data    (axi2ip_data[C_AXI_DATA_WIDTH-1:0]),
                        .wdat_rd_en     (wdat_rd_en),
                        .wdat_wr_en     (wdat_wr_en),
                        .wdat_din       (wdat_din[WDAT_FIFO_DATA_WIDTH-1:0]),
                        // Inputs
                        .clk            (clk),
                        .reset_n        (reset_n),
                        .AXI_WDATA      (AXI_WDATA[C_AXI_DATA_WIDTH-1:0]),
                        .AXI_WSTRB      (AXI_WSTRB[(C_AXI_DATA_WIDTH/8)-1:0]),
                        .AXI_WLAST      (AXI_WLAST),
                        .AXI_WVALID     (AXI_WVALID),
                        .wready_req     (wready_req),
                        .wready_size    (wready_size[1:0]),
                        .wready_fixed   (wready_fixed),
                        .wready_strb    (wready_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                        .ip_clk         (ip_clk),
                        .ip_reset_n     (ip_reset_n),
                        .ip_data_ready  (ip_data_ready),
                        .ip_data_size   (ip_data_size[1:0]),
                        .wdat_dout      (wdat_dout[WDAT_FIFO_DATA_WIDTH-1:0]),
                        .wdat_empty     (wdat_empty),
                        .wdat_full      (wdat_full),
                        .wdat_pre_full  (wdat_pre_full));

   rpc2_ctrl_axi_wr_response_channel
     #(C_AXI_ID_WIDTH)
   axi_wr_response_channel (/*AUTOINST*/
                            // Outputs
                            .AXI_BID    (AXI_BID[C_AXI_ID_WIDTH-1:0]),
                            .AXI_BRESP  (AXI_BRESP[1:0]),
                            .AXI_BVALID (AXI_BVALID),
                            .awid_fifo_rd_en(awid_fifo_rd_en),
                            .bdat_rd_en (bdat_rd_en),
                            // Inputs
                            .clk        (clk),
                            .reset_n    (reset_n),
                            .AXI_BREADY (AXI_BREADY),
                            .awid_id    (awid_id[C_AXI_ID_WIDTH-1:0]),
                            .awid_fifo_empty(awid_fifo_empty),
                            .bdat_dout  (bdat_dout[1:0]),
                            .bdat_empty (bdat_empty));

   rpc2_ctrl_axi_rd_data_channel
     #(C_AXI_ID_WIDTH,
       C_AXI_DATA_WIDTH)
   axi_rd_data_channel (/*AUTOINST*/
                        // Outputs
                        .AXI_RID        (AXI_RID[C_AXI_ID_WIDTH-1:0]),
                        .AXI_RDATA      (AXI_RDATA[C_AXI_DATA_WIDTH-1:0]),
                        .AXI_RRESP      (AXI_RRESP[1:0]),
                        .AXI_RLAST      (AXI_RLAST),
                        .AXI_RVALID     (AXI_RVALID),
                        .axi2ip_data_ready(axi2ip_data_ready),
                        .arid_fifo_rd_en(arid_fifo_rd_en),
                        .rdat_rd_en     (rdat_rd_en),
                        .rdat_wr_en     (rdat_wr_en),
                        .rdat_din       (rdat_din[RDAT_FIFO_DATA_WIDTH-1:0]),
                        .rd_active      (rd_active),
                        // Inputs
                        .clk            (clk),
                        .reset_n        (reset_n),
                        .AXI_RREADY     (AXI_RREADY),
                        .ip_rd_error    (ip_rd_error[1:0]),
                        .ip_data_valid  (ip_data_valid),
                        .ip_data_last   (ip_data_last),
                        .ip_data        (ip_data[C_AXI_DATA_WIDTH-1:0]),
                        .ip_strb        (ip_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                        .arid_id        (arid_id[C_AXI_ID_WIDTH-1:0]),
                        .arid_size      (arid_size[1:0]),
                        .arid_len       (arid_len[7:0]),
                        .arid_strb      (arid_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                        .arid_fifo_empty(arid_fifo_empty),
                        .ip_clk         (ip_clk),
                        .ip_reset_n     (ip_reset_n),
                        .rdat_dout      (rdat_dout[RDAT_FIFO_DATA_WIDTH-1:0]),
                        .rdat_empty     (rdat_empty),
                        .rdat_full      (rdat_full));

   //----------------------------------------------------------
   // ADR FIFO
   //----------------------------------------------------------
   /* rpc2_ctrl_sync_fifo AUTO_TEMPLATE (
    .rst_n(reset_n),
    .rd_data(adr_dout[ADR_FIFO_DATA_WIDTH-1:0]),
    .empty(adr_empty),
    .rd_en(adr_rd_en),
    .wr_en(adr_wr_en),
    .wr_data(adr_din[ADR_FIFO_DATA_WIDTH-1:0]),
    .full(adr_full),
    );
    */
   rpc2_ctrl_sync_fifo
     #(C_ADR_FIFO_ADDR_BITS, //FIFO_ADDR_BITS
       ADR_FIFO_DATA_WIDTH //FIFO_DATA_WIDTH
       )
   adr_fifo (/*AUTOINST*/
             // Outputs
             .rd_data                   (adr_dout[ADR_FIFO_DATA_WIDTH-1:0]), // Templated
             .empty                     (adr_empty),             // Templated
             .full                      (adr_full),              // Templated
             // Inputs
             .rst_n                     (reset_n),               // Templated
             .clk                       (clk),
             .rd_en                     (adr_rd_en),             // Templated
             .wr_en                     (adr_wr_en),             // Templated
             .wr_data                   (adr_din[ADR_FIFO_DATA_WIDTH-1:0])); // Templated

   //--------------------------------------------
   // RDAT FIFO
   //--------------------------------------------
   /* rpc2_ctrl_sync_fifo AUTO_TEMPLATE (
    .rd_data(rdat_dout[RDAT_FIFO_DATA_WIDTH-1:0]),
    .empty(rdat_empty),
    .rst_n(reset_n),
    .rd_en(rdat_rd_en),
    .wr_en(rdat_wr_en),
    .wr_data(rdat_din[RDAT_FIFO_DATA_WIDTH-1:0]),
    .full(rdat_full),
    );
    */
   rpc2_ctrl_sync_fifo 
     #(C_RDAT_FIFO_ADDR_BITS, //FIFO_ADDR_BITS
       RDAT_FIFO_DATA_WIDTH //FIFO_DATA_WIDTH
       )
   rdat_fifo (/*AUTOINST*/
              // Outputs
              .rd_data                  (rdat_dout[RDAT_FIFO_DATA_WIDTH-1:0]), // Templated
              .empty                    (rdat_empty),            // Templated
              .full                     (rdat_full),             // Templated
              // Inputs
              .rst_n                    (reset_n),               // Templated
              .clk                      (clk),
              .rd_en                    (rdat_rd_en),            // Templated
              .wr_en                    (rdat_wr_en),            // Templated
              .wr_data                  (rdat_din[RDAT_FIFO_DATA_WIDTH-1:0])); // Templated

   //--------------------------------------
   // WDAT FIFO
   //--------------------------------------
   /* rpc2_ctrl_sync_fifo_axi AUTO_TEMPLATE (
    .rst_n(reset_n),
    .rd_data(wdat_dout[WDAT_FIFO_DATA_WIDTH-1:0]),
    .empty(wdat_empty),
    .rd_en(wdat_rd_en),
    .wr_en(wdat_wr_en),
    .wr_data(wdat_din[WDAT_FIFO_DATA_WIDTH-1:0]),
    .full(wdat_full),
    .pre_full(wdat_pre_full),
    );
    */
   rpc2_ctrl_sync_fifo_axi 
     #(C_WDAT_FIFO_ADDR_BITS, //FIFO_ADDR_BITS
       WDAT_FIFO_DATA_WIDTH //FIFO_DATA_WIDTH
       )
   wdat_fifo (/*AUTOINST*/
              // Outputs
              .rd_data                  (wdat_dout[WDAT_FIFO_DATA_WIDTH-1:0]), // Templated
              .empty                    (wdat_empty),            // Templated
              .full                     (wdat_full),             // Templated
              .pre_full                 (wdat_pre_full),         // Templated
              // Inputs
              .rst_n                    (reset_n),               // Templated
              .clk                      (clk),
              .rd_en                    (wdat_rd_en),            // Templated
              .wr_en                    (wdat_wr_en),            // Templated
              .wr_data                  (wdat_din[WDAT_FIFO_DATA_WIDTH-1:0])); // Templated

   //------------------------------------------------------
   // BDAT FIFO
   //------------------------------------------------------
   /* rpc2_ctrl_ax_fifo AUTO_TEMPLATE (
    .rst_n(reset_n),
    .rd_data(bdat_dout[1:0]),
    .empty(bdat_empty),
    .rd_en(bdat_rd_en),
    .wr_en(ip_wr_done),
    .wr_data(ip_wr_error[1:0]),
    );
    */
   rpc2_ctrl_ax_fifo 
     #(C_AW_FIFO_ADDR_BITS, //FIFO_ADDR_BITS
       2 //FIFO_DATA_WIDTH
       )
   bdat_fifo (/*AUTOINST*/
              // Outputs
              .rd_data                  (bdat_dout[1:0]),        // Templated
              .empty                    (bdat_empty),            // Templated
              // Inputs
              .rst_n                    (reset_n),               // Templated
              .clk                      (clk),
              .rd_en                    (bdat_rd_en),            // Templated
              .wr_en                    (ip_wr_done),            // Templated
              .wr_data                  (ip_wr_error[1:0]));     // Templated
   
endmodule // rpc2_ctrl_axi_channel
