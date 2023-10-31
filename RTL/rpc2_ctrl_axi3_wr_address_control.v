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
// Filename: rpc2_ctrl_axi3_wr_address_control.v
//
//           AXI3 interface control block of write address channel with
//           write data interleaving
//
// Created:  yise  02/14/2014  version 2.01  - initial release
// Modified: yise  10/19/2015  version 2.4   - added arbiter
//
//*************************************************************************
module rpc2_ctrl_axi3_wr_address_control (/*AUTOARG*/
   // Outputs
   wready_req, wready_fixed, wready_size, wready_strb, wready_id,
   awid_id, awid_fifo_pre_full, awid_fifo_empty, aw_data_valid,
   aw_fifo_dout,
   // Inputs
   clk, reset_n, id_en, AXI_AWID, AXI_AWADDR, AXI_AWLEN, AXI_AWSIZE,
   AXI_AWBURST, AXI_AWVALID, AXI_AWREADY, wready_done,
   awid_fifo_rd_en, aw_data_ready
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

   localparam A_FIFO_DATA_WIDTH = 2+2+'d8+'d32; //size+type+len+addr
   localparam AWID_FIFO_DATA_WIDTH = C_AXI_ID_WIDTH;
   localparam WID_FIFO_DATA_WIDTH  = C_AXI_ID_WIDTH;
   localparam ADDR_BITS_IN_DATA_WIDTH = (C_AXI_DATA_WIDTH=='d32) ? 2'h2:
                                        (C_AXI_DATA_WIDTH=='d64) ? 2'h3: 2'h0;

   // Global System Signals
   input                             clk;
   input                             reset_n;

   input                             id_en;
   
   // Write Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0]        AXI_AWID;
   input [C_AXI_ADDR_WIDTH-1:0]      AXI_AWADDR;
   input [C_AXI_LEN_WIDTH-1:0]       AXI_AWLEN;
   input [2:0]                       AXI_AWSIZE;
   input [1:0]                       AXI_AWBURST;
   input                             AXI_AWVALID;
   input                             AXI_AWREADY;
   
   // for Write Data
   input                             wready_done;
   output                            wready_req;
   output                            wready_fixed;
   output [1:0]                      wready_size;
   output [(C_AXI_DATA_WIDTH/8)-1:0] wready_strb;
   output [C_AXI_ID_WIDTH-1:0]       wready_id;
   
   // for Write response
   input                             awid_fifo_rd_en;
   output [C_AXI_ID_WIDTH-1:0]       awid_id;
   output                            awid_fifo_pre_full;
   output                            awid_fifo_empty;
   
   output                            aw_data_valid;
   output [A_FIFO_DATA_WIDTH-1:0]    aw_fifo_dout;
   input                             aw_data_ready;
   
   
   wire [31:0]                       waddress;
   wire [7:0]                        wlen;
   wire [1:0]                        wsize;
   
   wire [(C_AXI_DATA_WIDTH/8)-1:0]   wr_strb_mask;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] wr_addr_in_xfer;
   
   reg                                aw_fifo_data_valid;
   wire                               aw_fifo_data_ready;

   wire                               aw_fifo_wr_en;
   wire [A_FIFO_DATA_WIDTH-1:0]       aw_fifo_din;
   wire                               aw_fifo_rd_en;
   wire                               awid_fifo_wr_en;
   wire [C_AXI_ID_WIDTH-1:0]          awid_fifo_din;

   wire                               wid_fifo_wr_en;
   wire [WID_FIFO_DATA_WIDTH-1:0]     wid_fifo_din;
   wire                               wid_fifo_rd_en;
   
   reg                                wdata_ready;
   wire                               wdata_pass;
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 aw_fifo_empty;          // From aw_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire [AWID_FIFO_DATA_WIDTH-1:0] awid_fifo_dout;// From awid_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire [WID_FIFO_DATA_WIDTH-1:0] wid_fifo_dout;// From wid_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire                 wid_fifo_empty;         // From wid_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   // End of automatics
   
   assign wdata_pass = wdata_ready | C_NOWAIT_WR_DATA_DONE;

   generate
   if (C_AXI_ADDR_WIDTH=='d32) begin
      assign waddress = AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0];
   end
   else begin
      assign waddress = {{(32-C_AXI_ADDR_WIDTH){1'b0}}, AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0]};
   end
   endgenerate

   generate
   if (C_AXI_LEN_WIDTH=='d8) begin
      assign wlen = AXI_AWLEN[C_AXI_LEN_WIDTH-1:0];
   end
   else begin
      assign wlen = {{(8-C_AXI_LEN_WIDTH){1'b0}}, AXI_AWLEN[C_AXI_LEN_WIDTH-1:0]};
   end
   endgenerate
   assign    wsize = (AXI_AWSIZE>ADDR_BITS_IN_DATA_WIDTH) ? ADDR_BITS_IN_DATA_WIDTH: AXI_AWSIZE[1:0];
 
   // AWID FIFO
   assign awid_fifo_wr_en = AXI_AWVALID & AXI_AWREADY & id_en;
   assign awid_fifo_din = AXI_AWID[C_AXI_ID_WIDTH-1:0];
   assign awid_id  = awid_fifo_dout[C_AXI_ID_WIDTH-1:0];

   // WID FIFO
   assign wid_fifo_wr_en = aw_fifo_wr_en;
   assign wid_fifo_rd_en = aw_fifo_rd_en;
   generate
   if (C_AXI_DATA_INTERLEAVING==1)
     assign wid_fifo_din = AXI_AWID[WID_FIFO_DATA_WIDTH-1:0];
   else
     assign wid_fifo_din = {WID_FIFO_DATA_WIDTH{1'b0}};
   endgenerate
   
   // AW FIFO
   assign aw_fifo_wr_en = AXI_AWVALID & AXI_AWREADY & id_en;
   assign aw_fifo_din = {wsize[1:0], AXI_AWBURST[1:0], wlen[7:0], waddress[31:ADDR_BITS_IN_DATA_WIDTH],
                         (AXI_AWBURST==2'b00) ?
                         waddress[ADDR_BITS_IN_DATA_WIDTH-1:0]&({ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<wsize):
                         waddress[ADDR_BITS_IN_DATA_WIDTH-1:0]};
   assign aw_fifo_rd_en = ((~aw_fifo_empty) & (~wid_fifo_empty)) & ((~aw_fifo_data_valid)|aw_fifo_data_ready) & wdata_ready;

   assign aw_fifo_data_ready = aw_data_ready;
   assign aw_data_valid = aw_fifo_data_valid & wdata_pass;
   
   assign wr_strb_mask = ~({(C_AXI_DATA_WIDTH/8){1'b1}}<<(1<<wready_size));
   assign wr_addr_in_xfer = aw_fifo_dout[ADDR_BITS_IN_DATA_WIDTH-1:0] & ({ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<wready_size);
      
   // Write data channel
   assign wready_req = aw_fifo_rd_en;
   assign wready_fixed = (aw_fifo_dout[41:40]==2'b00) ? 1'b1: 1'b0;  // Is burst type FIXED?
   assign wready_size  = aw_fifo_dout[43:42];
   assign wready_strb  = (wr_strb_mask<<wr_addr_in_xfer) & (wr_strb_mask<<aw_fifo_dout[ADDR_BITS_IN_DATA_WIDTH-1:0]);
   assign wready_id    = wid_fifo_dout[WID_FIFO_DATA_WIDTH-1:0];
   
   // data valid from AW FIFO
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        aw_fifo_data_valid <= 1'b0;
      else if (aw_fifo_rd_en)
        aw_fifo_data_valid <= 1'b1;
      else if (aw_data_valid & aw_data_ready)
        aw_fifo_data_valid <= 1'b0;
   end
   
   // wdata_ready
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        wdata_ready <= 1'b1;
      else if (wready_req)
        wdata_ready <= 1'b0;
      else if (wready_done)
        wdata_ready <= 1'b1;
   end

   //---------------------------------------------------------------------------
   // FIFO
   //---------------------------------------------------------------------------
   // AW FIFO
   /* rpc2_ctrl_dpram_wrapper AUTO_TEMPLATE (
    .rd_rst_n(reset_n),
    .rd_clk(clk),
    .rd_en(aw_fifo_rd_en),
    .wr_rst_n(1'b0),
    .wr_clk(1'b0),
    .wr_en(aw_fifo_wr_en),
    .wr_data(aw_fifo_din[A_FIFO_DATA_WIDTH-1:0]),
    .full(),
    .pre_full(),
    .half_full(),
    .empty(aw_fifo_empty),
    .rd_data(aw_fifo_dout[A_FIFO_DATA_WIDTH-1:0]),
    );
    */
    rpc2_ctrl_dpram_wrapper 
      #(1,     // 0=async_fifo_axi, 1=sync_fifo_axi
        C_AW_FIFO_ADDR_BITS,
        A_FIFO_DATA_WIDTH,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        0,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE     // 0=STD, 1=LowLeak
        ) 
   aw_fifo_wrapper (/*AUTOINST*/
                    // Outputs
                    .rd_data            (aw_fifo_dout[A_FIFO_DATA_WIDTH-1:0]), // Templated
                    .empty              (aw_fifo_empty),         // Templated
                    .full               (),                      // Templated
                    .pre_full           (),                      // Templated
                    .half_full          (),                      // Templated
                    // Inputs
                    .rd_rst_n           (reset_n),               // Templated
                    .rd_clk             (clk),                   // Templated
                    .rd_en              (aw_fifo_rd_en),         // Templated
                    .wr_rst_n           (1'b0),                  // Templated
                    .wr_clk             (1'b0),                  // Templated
                    .wr_en              (aw_fifo_wr_en),         // Templated
                    .wr_data            (aw_fifo_din[A_FIFO_DATA_WIDTH-1:0])); // Templated
                      
   // WID FIFO
   /* rpc2_ctrl_dpram_wrapper AUTO_TEMPLATE (
    .rd_rst_n(reset_n),
    .rd_clk(clk),
    .rd_en(wid_fifo_rd_en),
    .wr_rst_n(1'b0),
    .wr_clk(1'b0),
    .wr_en(wid_fifo_wr_en),
    .wr_data(wid_fifo_din[WID_FIFO_DATA_WIDTH-1:0]),
    .full(),
    .pre_full(),
    .half_full(),
    .empty(wid_fifo_empty),
    .rd_data(wid_fifo_dout[WID_FIFO_DATA_WIDTH-1:0]),
    );
    */
   rpc2_ctrl_dpram_wrapper 
      #(1,     // 0=async_fifo_axi, 1=sync_fifo_axi
        C_AW_FIFO_ADDR_BITS,
        WID_FIFO_DATA_WIDTH,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        4,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE     // 0=STD, 1=LowLeak
        )
   wid_fifo_wrapper (/*AUTOINST*/
                     // Outputs
                     .rd_data           (wid_fifo_dout[WID_FIFO_DATA_WIDTH-1:0]), // Templated
                     .empty             (wid_fifo_empty),        // Templated
                     .full              (),                      // Templated
                     .pre_full          (),                      // Templated
                     .half_full         (),                      // Templated
                     // Inputs
                     .rd_rst_n          (reset_n),               // Templated
                     .rd_clk            (clk),                   // Templated
                     .rd_en             (wid_fifo_rd_en),        // Templated
                     .wr_rst_n          (1'b0),                  // Templated
                     .wr_clk            (1'b0),                  // Templated
                     .wr_en             (wid_fifo_wr_en),        // Templated
                     .wr_data           (wid_fifo_din[WID_FIFO_DATA_WIDTH-1:0])); // Templated


   // AWID FIFO
   /* rpc2_ctrl_dpram_wrapper AUTO_TEMPLATE (
    .rd_rst_n(reset_n),
    .rd_clk(clk),
    .rd_en(awid_fifo_rd_en),
    .wr_rst_n(1'b0),
    .wr_clk(1'b0),
    .wr_en(awid_fifo_wr_en),
    .wr_data(awid_fifo_din[AWID_FIFO_DATA_WIDTH-1:0]),
    .full(),
    .pre_full(awid_fifo_pre_full),
    .half_full(),
    .empty(awid_fifo_empty),
    .rd_data(awid_fifo_dout[AWID_FIFO_DATA_WIDTH-1:0]),
    );
    */
   rpc2_ctrl_dpram_wrapper 
      #(1,     // 0=async_fifo_axi, 1=sync_fifo_axi
        C_AW_FIFO_ADDR_BITS,
        AWID_FIFO_DATA_WIDTH,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        2,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE     // 0=STD, 1=LowLeak
        )
   awid_fifo_wrapper (/*AUTOINST*/
                      // Outputs
                      .rd_data          (awid_fifo_dout[AWID_FIFO_DATA_WIDTH-1:0]), // Templated
                      .empty            (awid_fifo_empty),       // Templated
                      .full             (),                      // Templated
                      .pre_full         (awid_fifo_pre_full),    // Templated
                      .half_full        (),                      // Templated
                      // Inputs
                      .rd_rst_n         (reset_n),               // Templated
                      .rd_clk           (clk),                   // Templated
                      .rd_en            (awid_fifo_rd_en),       // Templated
                      .wr_rst_n         (1'b0),                  // Templated
                      .wr_clk           (1'b0),                  // Templated
                      .wr_en            (awid_fifo_wr_en),       // Templated
                      .wr_data          (awid_fifo_din[AWID_FIFO_DATA_WIDTH-1:0])); // Templated
   
endmodule // rpc2_ctrl_axi3_wr_address_control

