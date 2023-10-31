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
// Filename: rpc2_ctrl_axi_wr_address_control.v
//
//           AXI interface control block of write address channel
//
// Created: yise  02/14/2014  version 2.01  - initial release
// Modified: yise 10/19/2015  version 2.4   - remove wdata_ready for output
//
//*************************************************************************
module rpc2_ctrl_axi_wr_address_control (/*AUTOARG*/
   // Outputs
   wready_req, wready_fixed, wready_size, wready_strb, awid_id,
   awid_fifo_pre_full, awid_fifo_empty, adr_wr_aw_valid, adr_aw_din,
   // Inputs
   clk, reset_n, AXI_AWID, AXI_AWADDR, AXI_AWLEN, AXI_AWSIZE,
   AXI_AWBURST, AXI_AWVALID, AXI_AWREADY, wready_done,
   awid_fifo_rd_en, adr_wr_aw_ready, ip_data_size
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_ADDR_WIDTH = 'd32;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_LEN_WIDTH  = 'd8;
   parameter C_AW_FIFO_ADDR_BITS = 'd4;      
   parameter C_NOWAIT_WR_DATA_DONE = 1'b0;
   
//   parameter DPRAM_MACRO = 0;        // 0=Macro is not used, 1=Macro is used
//   parameter DPRAM_MACRO_TYPE = 0;   // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)

   localparam IP_LEN = (C_AXI_DATA_WIDTH=='d32) ? 'd10:
                       (C_AXI_DATA_WIDTH=='d64) ? 'd11: 'd0;
   localparam A_FIFO_DATA_WIDTH = 2+2+'d8+'d32; //size+type+len+addr
   localparam AWID_FIFO_DATA_WIDTH = C_AXI_ID_WIDTH;
   localparam ADDR_BITS_IN_DATA_WIDTH = (C_AXI_DATA_WIDTH=='d32) ? 2'h2:
                                        (C_AXI_DATA_WIDTH=='d64) ? 2'h3: 2'h0;
//   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2; //44: addr+len+burst       32+10+2   = 44
   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2+2; //46: addr+len+burst+size  32+10+2+2 = 46
   
   // Global System Signals
   input clk;
   input reset_n;
   
   // Write Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0] AXI_AWID;
   input [C_AXI_ADDR_WIDTH-1:0] AXI_AWADDR;
   input [C_AXI_LEN_WIDTH-1:0]  AXI_AWLEN;
   input [2:0]                  AXI_AWSIZE;
   input [1:0]                  AXI_AWBURST;
   input                        AXI_AWVALID;
   input                        AXI_AWREADY;
   
   // for Write Data
   input                          wready_done;
   output                         wready_req;
//   output                         wdata_ready;
   output                         wready_fixed;
   output [1:0]                   wready_size;
   output [(C_AXI_DATA_WIDTH/8)-1:0] wready_strb;
   
   // for Write response
   input                             awid_fifo_rd_en;
   output [C_AXI_ID_WIDTH-1:0]       awid_id;
   output                            awid_fifo_pre_full;
   output                            awid_fifo_empty;
   
   // ADR FIFO
   input                             adr_wr_aw_ready;
   output                            adr_wr_aw_valid;
   output [PRE_ADR_DATA_WIDTH-1:0]   adr_aw_din;
   
   input [1:0]                       ip_data_size;

   
   wire [31:0]                       waddress;
   wire [7:0]                        wlen;
   wire [1:0]                        wsize;

   wire [(C_AXI_DATA_WIDTH/8)-1:0]   wr_strb_mask;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] wr_addr_in_xfer;

   reg [IP_LEN-1:0]                   aw_ip_len;
   reg [IP_LEN-1:0]                   byte_w_len;

   reg                                adr_wr_aw_valid;

   reg                                aw_fifo_data_valid;
   wire                               aw_fifo_data_ready;

   wire                               aw_fifo_wr_en;
   wire [A_FIFO_DATA_WIDTH-1:0]       aw_fifo_din;
   wire                               aw_fifo_rd_en;
   
   reg [A_FIFO_DATA_WIDTH-1:0]        aw_fifo_dout_reg;
   wire [1:0]                         aw_fifo_dout_size;
   wire [7:0]                         aw_fifo_dout_len;
   wire [31:0]                        aw_fifo_dout_addr;
   wire [1:0]                         aw_fifo_dout_type;

   wire [1:0]                         aw_diff_size;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] w_addr_mask;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] w_aligned_addr_mask;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] addr_mask_by_ip;

   wire                               awid_fifo_wr_en;
   wire [C_AXI_ID_WIDTH-1:0]          awid_fifo_din;
   
   reg                                wdata_ready;
   wire                               wdata_pass;
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [A_FIFO_DATA_WIDTH-1:0] aw_fifo_dout;   // From aw_fifo of rpc2_ctrl_ax_fifo.v
   wire                 aw_fifo_empty;          // From aw_fifo of rpc2_ctrl_ax_fifo.v
   wire [AWID_FIFO_DATA_WIDTH-1:0] awid_fifo_dout;// From awid_fifo of rpc2_ctrl_axid_fifo.v
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
   assign awid_fifo_wr_en = AXI_AWVALID & AXI_AWREADY;
   assign awid_fifo_din = AXI_AWID[C_AXI_ID_WIDTH-1:0];
   assign awid_id  = awid_fifo_dout[C_AXI_ID_WIDTH-1:0];
   
   // AW FIFO
   assign aw_fifo_wr_en = AXI_AWVALID & AXI_AWREADY;
   assign aw_fifo_din = {wsize[1:0], AXI_AWBURST[1:0], wlen[7:0], waddress[31:0]};
   assign aw_fifo_rd_en = (~aw_fifo_empty) & ((~aw_fifo_data_valid)|aw_fifo_data_ready) & wdata_ready;
   assign aw_fifo_data_ready = ((~adr_wr_aw_valid)|adr_wr_aw_ready) & wdata_pass;
   
   assign aw_fifo_dout_size = aw_fifo_dout_reg[43:42];
   assign aw_fifo_dout_type = aw_fifo_dout_reg[41:40];
   assign aw_fifo_dout_len  = aw_fifo_dout_reg[39:32];
   assign aw_fifo_dout_addr = aw_fifo_dout_reg[31:0];
   
   assign wr_strb_mask = ~({(C_AXI_DATA_WIDTH/8){1'b1}}<<(1<<wready_size));
   assign wr_addr_in_xfer = aw_fifo_dout[ADDR_BITS_IN_DATA_WIDTH-1:0] & ({ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<wready_size);
   
   // ADR FIFO
//   assign adr_aw_din = {aw_fifo_dout_type[1:0], aw_ip_len[IP_LEN-1:0], aw_fifo_dout_addr[31:0]}; 
   assign adr_aw_din = {aw_fifo_dout_size[1:0], aw_fifo_dout_type[1:0], aw_ip_len[IP_LEN-1:0], aw_fifo_dout_addr[31:0]}; 
   
   // Write data channel
   assign wready_req = aw_fifo_rd_en;
   assign wready_fixed = (aw_fifo_dout[41:40]==2'b00) ? 1'b1: 1'b0;  // Is burst type FIXED?
   assign wready_size  = aw_fifo_dout[43:42];
   assign wready_strb  = (wr_strb_mask<<wr_addr_in_xfer) & (wr_strb_mask<<aw_fifo_dout[ADDR_BITS_IN_DATA_WIDTH-1:0]);
   
   assign aw_diff_size = ADDR_BITS_IN_DATA_WIDTH-aw_fifo_dout_size;
   assign w_addr_mask = {ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<aw_fifo_dout_size;
   assign w_aligned_addr_mask = ~w_addr_mask;
   assign addr_mask_by_ip = ~({ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<ip_data_size);   

   // Calculate IP length for write
   always @(*) begin
      byte_w_len = {aw_fifo_dout_len, {ADDR_BITS_IN_DATA_WIDTH{1'b1}}} >> aw_diff_size;
      if (ip_data_size == aw_fifo_dout_size)
        aw_ip_len = byte_w_len >> ip_data_size;
      else if ((ip_data_size > aw_fifo_dout_size) && (aw_fifo_dout_type == 2'b00)) // When burst type is FIXED
        aw_ip_len = {{ADDR_BITS_IN_DATA_WIDTH{1'b0}}, aw_fifo_dout_len};
      else if (ip_data_size > aw_fifo_dout_size)
        aw_ip_len = (byte_w_len+(aw_fifo_dout_addr[ADDR_BITS_IN_DATA_WIDTH-1:0]&w_addr_mask&addr_mask_by_ip))>>ip_data_size;
      else
        aw_ip_len = (byte_w_len-(aw_fifo_dout_addr[ADDR_BITS_IN_DATA_WIDTH-1:0]&w_aligned_addr_mask))>>ip_data_size;
   end
   
   // data valid from AW FIFO
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        aw_fifo_data_valid <= 1'b0;
      else if (aw_fifo_rd_en)
        aw_fifo_data_valid <= 1'b1;
      else if (aw_fifo_data_ready)
        aw_fifo_data_valid <= 1'b0;
   end

   
   // register AW FIFO data
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        aw_fifo_dout_reg <= {A_FIFO_DATA_WIDTH{1'b0}};
      else if (aw_fifo_data_valid & aw_fifo_data_ready)
        aw_fifo_dout_reg <= aw_fifo_dout[A_FIFO_DATA_WIDTH-1:0];
   end

   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        adr_wr_aw_valid <= 1'b0;
      else if (aw_fifo_data_valid & aw_fifo_data_ready)
        adr_wr_aw_valid <= 1'b1;
      else if (adr_wr_aw_ready)
        adr_wr_aw_valid <= 1'b0;
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
   /* rpc2_ctrl_ax_fifo AUTO_TEMPLATE (
    .rst_n(reset_n),
    .rd_en(aw_fifo_rd_en),
    .wr_en(aw_fifo_wr_en),
    .wr_data(aw_fifo_din[A_FIFO_DATA_WIDTH-1:0]),
    .empty(aw_fifo_empty),
    .rd_data(aw_fifo_dout[A_FIFO_DATA_WIDTH-1:0]),
    );
    */
   rpc2_ctrl_ax_fifo
      #(C_AW_FIFO_ADDR_BITS,
        A_FIFO_DATA_WIDTH
        ) 
   aw_fifo (/*AUTOINST*/
            // Outputs
            .rd_data                    (aw_fifo_dout[A_FIFO_DATA_WIDTH-1:0]), // Templated
            .empty                      (aw_fifo_empty),         // Templated
            // Inputs
            .rst_n                      (reset_n),               // Templated
            .clk                        (clk),
            .rd_en                      (aw_fifo_rd_en),         // Templated
            .wr_en                      (aw_fifo_wr_en),         // Templated
            .wr_data                    (aw_fifo_din[A_FIFO_DATA_WIDTH-1:0])); // Templated
                      

   // AWID FIFO
   /* rpc2_ctrl_axid_fifo AUTO_TEMPLATE (
    .rst_n(reset_n),
    .rd_en(awid_fifo_rd_en),
    .wr_en(awid_fifo_wr_en),
    .wr_data(awid_fifo_din[AWID_FIFO_DATA_WIDTH-1:0]),
    .pre_full(awid_fifo_pre_full),
    .empty(awid_fifo_empty),
    .rd_data(awid_fifo_dout[AWID_FIFO_DATA_WIDTH-1:0]),
    );
    */
   rpc2_ctrl_axid_fifo
      #(C_AW_FIFO_ADDR_BITS,
        AWID_FIFO_DATA_WIDTH
        )
   awid_fifo (/*AUTOINST*/
              // Outputs
              .rd_data                  (awid_fifo_dout[AWID_FIFO_DATA_WIDTH-1:0]), // Templated
              .empty                    (awid_fifo_empty),       // Templated
              .pre_full                 (awid_fifo_pre_full),    // Templated
              // Inputs
              .rst_n                    (reset_n),               // Templated
              .clk                      (clk),
              .rd_en                    (awid_fifo_rd_en),       // Templated
              .wr_en                    (awid_fifo_wr_en),       // Templated
              .wr_data                  (awid_fifo_din[AWID_FIFO_DATA_WIDTH-1:0])); // Templated
   
endmodule // rpc2_ctrl_axi_wr_address_control

