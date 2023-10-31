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
// Filename: rpc2_ctrl_axi_wr_address_control2.v
//
//           AXI interface control block of write address channel
//
// Created: yise  11/02/2015  version 2.4   - initial release
//
//*************************************************************************
module rpc2_ctrl_axi_wr_address_control2 (/*AUTOARG*/
   // Outputs
   wready0_req, wready0_fixed, wready0_size, wready0_strb, wready0_id,
   wready1_req, wready1_fixed, wready1_size, wready1_strb, wready1_id,
   awid0_id, awid1_id, awid0_fifo_empty, awid1_fifo_empty,
   awid0_fifo_pre_full, awid1_fifo_pre_full, adr_aw_valid, adr_aw_din,
   adr_aw_block,
   // Inputs
   clk, reset_n, AXI_AWID, AXI_AWADDR, AXI_AWLEN, AXI_AWSIZE,
   AXI_AWBURST, AXI_AWVALID, AXI_AWREADY, wready0_done, wready1_done,
   awid0_fifo_rd_en, awid1_fifo_rd_en, adr_aw_ready, ip_data_size
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_ADDR_WIDTH = 'd32;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_LEN_WIDTH  = 'd8;
   parameter C_AW_FIFO_ADDR_BITS = 'd4;      
   parameter C_NOWAIT_WR_DATA_DONE = 1'b0;
   parameter C_AXI_DATA_INTERLEAVING = 1;

   parameter DPRAM_MACRO = 0;        // 0=Macro is not used, 1=Macro is used
   parameter DPRAM_MACRO_TYPE = 0;   // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)

   localparam IP_LEN = (C_AXI_DATA_WIDTH=='d32) ? 'd10:
                       (C_AXI_DATA_WIDTH=='d64) ? 'd11: 'd0;
   localparam A_FIFO_DATA_WIDTH = 2+2+'d8+'d32;            //size+type+len+addr
   localparam AWR_FIFO_DATA_WIDTH = A_FIFO_DATA_WIDTH+1; //size+type+len+addr+block
   localparam ADDR_BITS_IN_DATA_WIDTH = (C_AXI_DATA_WIDTH=='d32) ? 2'h2:
                                        (C_AXI_DATA_WIDTH=='d64) ? 2'h3: 2'h0;
//   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2; //44: addr+len+burst
   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2+2; //46: addr+len+burst+size
   // Global System Signals
   input                             clk;
   input                             reset_n;
   
   // Write Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0]        AXI_AWID;
   input [C_AXI_ADDR_WIDTH-1:0]      AXI_AWADDR;
   input [C_AXI_LEN_WIDTH-1:0]       AXI_AWLEN;
   input [2:0]                       AXI_AWSIZE;
   input [1:0]                       AXI_AWBURST;
   input                             AXI_AWVALID;
   input                             AXI_AWREADY;

   // for Write Data 0
   output                            wready0_req;
   output                            wready0_fixed;
   output [1:0]                      wready0_size;
   output [(C_AXI_DATA_WIDTH/8)-1:0] wready0_strb;
   output [C_AXI_ID_WIDTH-1:0]       wready0_id;
   input                             wready0_done;

   // for Write Data 1
   output                            wready1_req;
   output                            wready1_fixed;
   output [1:0]                      wready1_size;
   output [(C_AXI_DATA_WIDTH/8)-1:0] wready1_strb;
   output [C_AXI_ID_WIDTH-1:0]       wready1_id;
   input                             wready1_done;

   // for Write Response
   input                             awid0_fifo_rd_en;
   input                             awid1_fifo_rd_en;
   output [C_AXI_ID_WIDTH-1:0]       awid0_id;
   output [C_AXI_ID_WIDTH-1:0]       awid1_id;
   output                            awid0_fifo_empty;
   output                            awid1_fifo_empty;
   output                            awid0_fifo_pre_full;
   output                            awid1_fifo_pre_full;
   
   // ADR FIFO
   input                             adr_aw_ready;
   output                            adr_aw_valid;
   output [PRE_ADR_DATA_WIDTH-1:0]   adr_aw_din;
   output                            adr_aw_block;
   
   input [1:0]                       ip_data_size;


   wire                              id0_en;
   wire                              id1_en;
   
   wire                              id_match;
   reg                               interleave_block;
   reg [C_AXI_ID_WIDTH-1:0]          reserved_id;
      
   reg [IP_LEN-1:0]                   aw_ip_len;
   reg [IP_LEN-1:0]                   byte_w_len;

   wire [1:0]                         aw_diff_size;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] w_addr_mask;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] w_aligned_addr_mask;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] addr_mask_by_ip;


   /*AUTOWIRE*/
   reg                                adr_aw_valid;
   wire                               adr_aw_block;
   
   reg                                aw_sel_block;
   wire                               aw0_data_ready;
   wire                               aw1_data_ready;
   wire                               aw0_data_valid;
   wire                               aw1_data_valid;
   
   wire [A_FIFO_DATA_WIDTH-1:0]       aw0_fifo_dout;
   wire [A_FIFO_DATA_WIDTH-1:0]       aw1_fifo_dout;

   wire                               request0_start;
   wire                               request1_start;
   
   wire [1:0]                         aw_sel_data_size;
   wire [7:0]                         aw_sel_data_len;
   wire [31:0]                        aw_sel_data_addr;
   wire [1:0]                         aw_sel_data_type;
   wire                               awr_fifo_wr_en;
   wire                               awr_fifo_rd_en;
   wire                               awr_fifo_empty;
   wire                               awr_fifo_full;
   wire [AWR_FIFO_DATA_WIDTH-1:0]     awr_fifo_din;
   wire [AWR_FIFO_DATA_WIDTH-1:0]     awr_fifo_dout;
   
   generate
   if (C_AXI_DATA_INTERLEAVING==1) begin
   assign id_match = (reserved_id==AXI_AWID) ? 1'b1: 1'b0;
   assign id0_en = (id_match) ? ~interleave_block: interleave_block;
   assign id1_en = (id_match) ? interleave_block: ~interleave_block;
   
   // select the block 0 or 1
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        interleave_block <= 1'b0;
      else if (AXI_AWVALID & AXI_AWREADY & ~id_match)
        interleave_block <= ~interleave_block;
   end

   // reserved AWID
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        reserved_id <= {C_AXI_ID_WIDTH{1'b0}};
      else if (AXI_AWVALID & AXI_AWREADY)
        reserved_id <= AXI_AWID;
   end
   end
   else begin
   assign id0_en = 1'b1;
   assign id1_en = 1'b0;
   end 
   endgenerate
   
   assign aw0_data_ready = (~aw_sel_block) & (~awr_fifo_full);
   assign aw1_data_ready = aw_sel_block & (~awr_fifo_full);
   
   assign request0_start = (C_NOWAIT_WR_DATA_DONE) ? wready0_req: wready0_done;
   assign request1_start = (C_NOWAIT_WR_DATA_DONE) ? wready1_req: wready1_done;
      
   //---------------------------------------------------------------------------
   // AW0 FIFO -|
   //           +- AWR FIFO - IP len calculation
   // AW1 FIFO -|
   //---------------------------------------------------------------------------
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        aw_sel_block <= 1'b0;
      else if ((request0_start && ((~aw1_data_valid) | aw1_data_ready)) ||
               ((aw1_data_valid & aw1_data_ready) && aw0_data_valid))
        aw_sel_block <= 1'b0;
      else if ((request1_start && ((~aw0_data_valid) | aw0_data_ready)) ||
               ((aw0_data_valid & aw0_data_ready) && aw1_data_valid))
        aw_sel_block <= 1'b1;
   end

   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        adr_aw_valid <= 1'b0;
      else if (awr_fifo_rd_en)
        adr_aw_valid <= 1'b1;
      else if (adr_aw_valid & adr_aw_ready)
        adr_aw_valid <= 1'b0;
   end
   
   // ADR FIFO
   assign adr_aw_din = {aw_sel_data_size[1:0], aw_sel_data_type[1:0], aw_ip_len[IP_LEN-1:0], aw_sel_data_addr[31:0]};
   assign adr_aw_block = awr_fifo_dout[AWR_FIFO_DATA_WIDTH-1];
   
   assign aw_sel_data_size = awr_fifo_dout[43:42];
   assign aw_sel_data_type = awr_fifo_dout[41:40];
   assign aw_sel_data_len  = awr_fifo_dout[39:32];
   assign aw_sel_data_addr = awr_fifo_dout[31:0];
   
   assign aw_diff_size = ADDR_BITS_IN_DATA_WIDTH-aw_sel_data_size;
   assign w_addr_mask = {ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<aw_sel_data_size;
   assign w_aligned_addr_mask = ~w_addr_mask;
   assign addr_mask_by_ip = ~({ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<ip_data_size);

   // Calculate IP length for write
   always @(*) begin
      byte_w_len = {aw_sel_data_len, {ADDR_BITS_IN_DATA_WIDTH{1'b1}}} >> aw_diff_size;
      if (ip_data_size == aw_sel_data_size)
        aw_ip_len = byte_w_len >> ip_data_size;
      else if ((ip_data_size > aw_sel_data_size) && (aw_sel_data_type == 2'b00)) // When burst type is FIXED
        aw_ip_len = {{ADDR_BITS_IN_DATA_WIDTH{1'b0}}, aw_sel_data_len};
      else if (ip_data_size > aw_sel_data_size)
        aw_ip_len = (byte_w_len+(aw_sel_data_addr[ADDR_BITS_IN_DATA_WIDTH-1:0]&w_addr_mask&addr_mask_by_ip))>>ip_data_size;
      else
        aw_ip_len = (byte_w_len-(aw_sel_data_addr[ADDR_BITS_IN_DATA_WIDTH-1:0]&w_aligned_addr_mask))>>ip_data_size;
   end

   //---------------------------------------------------------------------------
   // Instantiates
   //---------------------------------------------------------------------------
   /* rpc2_ctrl_axi3_wr_address_control AUTO_TEMPLATE (
    .aw_fifo_empty(aw@_fifo_empty),
    .wready_req(wready@_req),
    .wready_fixed(wready@_fixed),
    .wready_size(wready@_size),
    .wready_strb(wready@_strb),
    .wready_id(wready@_id),
    .awid_id(awid@_id),
    .awid_fifo_pre_full(awid@_fifo_pre_full),
    .awid_fifo_empty(awid@_fifo_empty),
    .aw_data_valid(aw@_data_valid),
    .aw_fifo_dout(aw@_fifo_dout),
    .id_en(id@_en),
    .wready_done(wready@_done),
    .awid_fifo_rd_en(awid@_fifo_rd_en),
    .aw_data_ready(aw@_data_ready),
    );
    */
   rpc2_ctrl_axi3_wr_address_control
     #(C_AXI_ID_WIDTH,
       C_AXI_ADDR_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_LEN_WIDTH,
       C_AW_FIFO_ADDR_BITS,
       C_NOWAIT_WR_DATA_DONE,
       C_AXI_DATA_INTERLEAVING,
       DPRAM_MACRO,
       DPRAM_MACRO_TYPE
       )
   axi_wr_address_control_0 (/*AUTOINST*/
                             // Outputs
                             .wready_req        (wready0_req),   // Templated
                             .wready_fixed      (wready0_fixed), // Templated
                             .wready_size       (wready0_size),  // Templated
                             .wready_strb       (wready0_strb),  // Templated
                             .wready_id         (wready0_id),    // Templated
                             .awid_id           (awid0_id),      // Templated
                             .awid_fifo_pre_full(awid0_fifo_pre_full), // Templated
                             .awid_fifo_empty   (awid0_fifo_empty), // Templated
                             .aw_data_valid     (aw0_data_valid), // Templated
                             .aw_fifo_dout      (aw0_fifo_dout), // Templated
                             // Inputs
                             .clk               (clk),
                             .reset_n           (reset_n),
                             .id_en             (id0_en),        // Templated
                             .AXI_AWID          (AXI_AWID[C_AXI_ID_WIDTH-1:0]),
                             .AXI_AWADDR        (AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0]),
                             .AXI_AWLEN         (AXI_AWLEN[C_AXI_LEN_WIDTH-1:0]),
                             .AXI_AWSIZE        (AXI_AWSIZE[2:0]),
                             .AXI_AWBURST       (AXI_AWBURST[1:0]),
                             .AXI_AWVALID       (AXI_AWVALID),
                             .AXI_AWREADY       (AXI_AWREADY),
                             .wready_done       (wready0_done),  // Templated
                             .awid_fifo_rd_en   (awid0_fifo_rd_en), // Templated
                             .aw_data_ready     (aw0_data_ready)); // Templated

   rpc2_ctrl_axi3_wr_address_control
     #(C_AXI_ID_WIDTH,
       C_AXI_ADDR_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_LEN_WIDTH,
       C_AW_FIFO_ADDR_BITS,
       C_NOWAIT_WR_DATA_DONE,
       C_AXI_DATA_INTERLEAVING,
       DPRAM_MACRO,
       DPRAM_MACRO_TYPE
       )
   axi_wr_address_control_1 (/*AUTOINST*/
                             // Outputs
                             .wready_req        (wready1_req),   // Templated
                             .wready_fixed      (wready1_fixed), // Templated
                             .wready_size       (wready1_size),  // Templated
                             .wready_strb       (wready1_strb),  // Templated
                             .wready_id         (wready1_id),    // Templated
                             .awid_id           (awid1_id),      // Templated
                             .awid_fifo_pre_full(awid1_fifo_pre_full), // Templated
                             .awid_fifo_empty   (awid1_fifo_empty), // Templated
                             .aw_data_valid     (aw1_data_valid), // Templated
                             .aw_fifo_dout      (aw1_fifo_dout), // Templated
                             // Inputs
                             .clk               (clk),
                             .reset_n           (reset_n),
                             .id_en             (id1_en),        // Templated
                             .AXI_AWID          (AXI_AWID[C_AXI_ID_WIDTH-1:0]),
                             .AXI_AWADDR        (AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0]),
                             .AXI_AWLEN         (AXI_AWLEN[C_AXI_LEN_WIDTH-1:0]),
                             .AXI_AWSIZE        (AXI_AWSIZE[2:0]),
                             .AXI_AWBURST       (AXI_AWBURST[1:0]),
                             .AXI_AWVALID       (AXI_AWVALID),
                             .AXI_AWREADY       (AXI_AWREADY),
                             .wready_done       (wready1_done),  // Templated
                             .awid_fifo_rd_en   (awid1_fifo_rd_en), // Templated
                             .aw_data_ready     (aw1_data_ready)); // Templated

   //---------------------------------------------------------------------------
   // AWR_FIFO
   //---------------------------------------------------------------------------
   assign awr_fifo_wr_en = (~awr_fifo_full) & (aw0_data_valid | aw1_data_valid);
   assign awr_fifo_din = (aw_sel_block) ? {1'b1, aw1_fifo_dout[A_FIFO_DATA_WIDTH-1:0]}: {1'b0, aw0_fifo_dout[A_FIFO_DATA_WIDTH-1:0]};
   assign awr_fifo_rd_en = ((~adr_aw_valid) | adr_aw_ready) & (~awr_fifo_empty);
   
   /* rpc2_ctrl_dpram_wrapper AUTO_TEMPLATE (
    .rd_data(awr_fifo_dout[AWR_FIFO_DATA_WIDTH-1:0]),
    .empty(awr_fifo_empty),
    .full(awr_fifo_full),
    .pre_full(),
    .half_full(),
    .rd_rst_n(reset_n),
    .rd_clk(clk),
    .rd_en(awr_fifo_rd_en),
    .wr_rst_n(1'b0),
    .wr_clk(1'b0),
    .wr_en(awr_fifo_wr_en),
    .wr_data(awr_fifo_din[AWR_FIFO_DATA_WIDTH-1:0]),
    );
    */
   rpc2_ctrl_dpram_wrapper
     #(1,
       C_AW_FIFO_ADDR_BITS,
       AWR_FIFO_DATA_WIDTH,
       DPRAM_MACRO,
       'd10,
       DPRAM_MACRO_TYPE
       )
   awr_fifo (/*AUTOINST*/
             // Outputs
             .rd_data                   (awr_fifo_dout[AWR_FIFO_DATA_WIDTH-1:0]), // Templated
             .empty                     (awr_fifo_empty),        // Templated
             .full                      (awr_fifo_full),         // Templated
             .pre_full                  (),                      // Templated
             .half_full                 (),                      // Templated
             // Inputs
             .rd_rst_n                  (reset_n),               // Templated
             .rd_clk                    (clk),                   // Templated
             .rd_en                     (awr_fifo_rd_en),        // Templated
             .wr_rst_n                  (1'b0),                  // Templated
             .wr_clk                    (1'b0),                  // Templated
             .wr_en                     (awr_fifo_wr_en),        // Templated
             .wr_data                   (awr_fifo_din[AWR_FIFO_DATA_WIDTH-1:0])); // Templated
       
endmodule // rpc2_ctrl_axi_wr_address_control2


