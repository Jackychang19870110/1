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
// Filename: rpc2_ctrl_axi_rd_address_control.v
//
//           AXI interface control block of read address channel
//
// Created: yise  01/31/2014  version 2.01  - initial release
// Modified: yise 10/19/2015  version 2.4   - remove wdata_ready port
//
//*************************************************************************
module rpc2_ctrl_axi_rd_address_control (/*AUTOARG*/
   // Outputs
   arid_id, arid_size, arid_len, arid_strb, arid_fifo_pre_full,
   arid_fifo_empty, adr_wr_ar_valid, adr_ar_din,
   // Inputs
   clk, reset_n, AXI_ARID, AXI_ARADDR, AXI_ARLEN, AXI_ARSIZE,
   AXI_ARBURST, AXI_ARVALID, AXI_ARREADY, arid_fifo_rd_en,
   adr_wr_ar_ready, ip_data_size
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_ADDR_WIDTH = 'd32;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_LEN_WIDTH  = 'd8;
   parameter C_AR_FIFO_ADDR_BITS = 'd4;

   parameter DPRAM_MACRO = 0;        // 0=Macro is not used, 1=Macro is used
   parameter DPRAM_MACRO_TYPE = 0;   // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)

   localparam IP_LEN = (C_AXI_DATA_WIDTH=='d32) ? 'd10:
                       (C_AXI_DATA_WIDTH=='d64) ? 'd11: 'd0;
   localparam A_FIFO_DATA_WIDTH = 2+2+'d8+'d32; //size+type+len+addr
   localparam ARID_FIFO_DATA_WIDTH = C_AXI_ID_WIDTH+'d8+2+(C_AXI_DATA_WIDTH/8); //id+len+size+strb
   localparam ADDR_BITS_IN_DATA_WIDTH = (C_AXI_DATA_WIDTH=='d32) ? 2'h2:
                                        (C_AXI_DATA_WIDTH=='d64) ? 2'h3: 2'h0;
                                        
                                        
//   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2; //44: addr+len+burst
   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2+2; //46: addr+len+burst+size

   
   // Global System Signals
   input clk;
   input reset_n;

   // Read Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0] AXI_ARID;
   input [C_AXI_ADDR_WIDTH-1:0] AXI_ARADDR;
   input [C_AXI_LEN_WIDTH-1:0]  AXI_ARLEN;
   input [2:0]                  AXI_ARSIZE;
   input [1:0]                  AXI_ARBURST;
   input                        AXI_ARVALID;
   input                        AXI_ARREADY;

   // for Read Response
   input                         arid_fifo_rd_en;
   output [C_AXI_ID_WIDTH-1:0]   arid_id;
   output [1:0]                  arid_size;
   output [7:0]                  arid_len;
   output [(C_AXI_DATA_WIDTH/8)-1:0] arid_strb;
   output                            arid_fifo_pre_full;
   output                            arid_fifo_empty;

   // ADR FIFO
   input                             adr_wr_ar_ready;
   output                            adr_wr_ar_valid;
   output [PRE_ADR_DATA_WIDTH-1:0]   adr_ar_din;
   
//   input                             wdata_ready;
   input [1:0]                       ip_data_size;

   
   wire [1:0]                        rsize;
   wire [31:0]                       raddress;
   wire [7:0]                        rlen;

   reg                               ar_fifo_data_valid;
   wire                              ar_fifo_data_ready;

   wire                              ar_fifo_wr_en;
   wire [A_FIFO_DATA_WIDTH-1:0]      ar_fifo_din;
   wire                              ar_fifo_rd_en;
   reg [A_FIFO_DATA_WIDTH-1:0]       ar_fifo_dout_reg;
   wire [1:0]                        ar_fifo_dout_size;
   wire [7:0]                        ar_fifo_dout_len;
   wire [31:0]                       ar_fifo_dout_addr;
   wire [1:0]                        ar_fifo_dout_type;

   wire [1:0]                        ar_diff_size;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] r_addr_mask;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] r_aligned_addr_mask;
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] addr_mask_by_ip;
   
   wire [ADDR_BITS_IN_DATA_WIDTH-1:0] addr_in_xfer;
   wire [(C_AXI_DATA_WIDTH/8)-1:0]    strb;
   wire [(C_AXI_DATA_WIDTH/8)-1:0]    strb_mask;

   wire                               arid_fifo_wr_en;
   wire [ARID_FIFO_DATA_WIDTH-1:0]    arid_fifo_din;
   
   reg [IP_LEN-1:0]                   ar_ip_len;
   reg [IP_LEN-1:0]                   byte_r_len;

   reg                                adr_wr_ar_valid;
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [A_FIFO_DATA_WIDTH-1:0] ar_fifo_dout;   // From ar_fifo of rpc2_ctrl_ax_fifo.v, ...
   wire                 ar_fifo_empty;          // From ar_fifo of rpc2_ctrl_ax_fifo.v, ...
   wire [ARID_FIFO_DATA_WIDTH-1:0] arid_fifo_dout;// From arid_fifo of rpc2_ctrl_axid_fifo.v, ...
   // End of automatics

   
   generate
   if (C_AXI_ADDR_WIDTH=='d32) begin
      assign raddress = AXI_ARADDR[C_AXI_ADDR_WIDTH-1:0];
   end
   else begin
      assign raddress = {{(32-C_AXI_ADDR_WIDTH){1'b0}}, AXI_ARADDR[C_AXI_ADDR_WIDTH-1:0]};
   end
   endgenerate

   generate
   if (C_AXI_LEN_WIDTH=='d8) begin
      assign rlen = AXI_ARLEN[C_AXI_LEN_WIDTH-1:0]  ;
      
   end
   else begin
      assign rlen = {{(8-C_AXI_LEN_WIDTH){1'b0}}, AXI_ARLEN[C_AXI_LEN_WIDTH-1:0]};
   end
   endgenerate
   assign    rsize = (AXI_ARSIZE>ADDR_BITS_IN_DATA_WIDTH) ? ADDR_BITS_IN_DATA_WIDTH: AXI_ARSIZE[1:0];
   
   // ARID FIFO
   assign arid_fifo_wr_en = AXI_ARVALID & AXI_ARREADY;
   assign arid_fifo_din = {AXI_ARID[C_AXI_ID_WIDTH-1:0], strb[(C_AXI_DATA_WIDTH/8)-1:0], rsize[1:0], rlen[7:0]};
   assign arid_id  = arid_fifo_dout[ARID_FIFO_DATA_WIDTH-1:ARID_FIFO_DATA_WIDTH-C_AXI_ID_WIDTH];
   assign arid_strb = arid_fifo_dout[(ARID_FIFO_DATA_WIDTH-C_AXI_ID_WIDTH)-1:10];  
   assign arid_size = arid_fifo_dout[9:8];
   assign arid_len = arid_fifo_dout[7:0];
   
   // AR FIFO
   assign ar_fifo_wr_en = AXI_ARVALID & AXI_ARREADY;
   assign ar_fifo_din = {rsize[1:0], AXI_ARBURST[1:0], rlen[7:0], raddress[31:0]};
   assign ar_fifo_rd_en = (~ar_fifo_empty) & ((~ar_fifo_data_valid)|ar_fifo_data_ready);
// Don't stop the read flow when wdata is existing
//   assign ar_fifo_data_ready = ((~adr_wr_ar_valid)|adr_wr_ar_ready) & wdata_ready;
   assign ar_fifo_data_ready = ((~adr_wr_ar_valid)|adr_wr_ar_ready);
   
   assign ar_fifo_dout_size = ar_fifo_dout_reg[43:42];
   assign ar_fifo_dout_type = ar_fifo_dout_reg[41:40];
   assign ar_fifo_dout_len  = ar_fifo_dout_reg[39:32];
   assign ar_fifo_dout_addr = ar_fifo_dout_reg[31:0];
   
   // ADR FIFO
   assign adr_ar_din = {ar_fifo_dout_size[1:0], ar_fifo_dout_type[1:0], ar_ip_len[IP_LEN-1:0], ar_fifo_dout_addr[31:0]};

   assign addr_in_xfer = raddress[ADDR_BITS_IN_DATA_WIDTH-1:0] & ({ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<rsize[1:0]);
   assign strb_mask = ~({(C_AXI_DATA_WIDTH/8){1'b1}}<<(1<<rsize[1:0]));
   // When burst type is FIXED, strobe for Read Data Channel is all 1.
   assign strb = (AXI_ARBURST==2'b00) ? {(C_AXI_DATA_WIDTH/8){1'b1}}: (strb_mask<<addr_in_xfer);
   
   assign ar_diff_size = ADDR_BITS_IN_DATA_WIDTH-ar_fifo_dout_size;
   assign r_addr_mask = {ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<ar_fifo_dout_size;
   assign r_aligned_addr_mask = ~r_addr_mask;
   assign addr_mask_by_ip = ~({ADDR_BITS_IN_DATA_WIDTH{1'b1}}<<ip_data_size); 
   
   // Calculate IP length for read
   always @(*) begin
      byte_r_len = {ar_fifo_dout_len, {ADDR_BITS_IN_DATA_WIDTH{1'b1}}} >> ar_diff_size;
      if (ar_fifo_dout_type == 2'b00) // When burst type is FIXED
        ar_ip_len = {{ADDR_BITS_IN_DATA_WIDTH{1'b0}}, ar_fifo_dout_len};
      else if (ip_data_size == ar_fifo_dout_size)
        ar_ip_len = byte_r_len >> ip_data_size;
     else if (ip_data_size > ar_fifo_dout_size)
        ar_ip_len = (byte_r_len+(ar_fifo_dout_addr[ADDR_BITS_IN_DATA_WIDTH-1:0]&r_addr_mask&addr_mask_by_ip))>>ip_data_size;
      else
        ar_ip_len = (byte_r_len-(ar_fifo_dout_addr[ADDR_BITS_IN_DATA_WIDTH-1:0]&r_aligned_addr_mask))>>ip_data_size;
   end // always @ (*)

   // data valid from AR FIFO
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ar_fifo_data_valid <= 1'b0;
      else if (ar_fifo_rd_en)
        ar_fifo_data_valid <= 1'b1;
      else if (ar_fifo_data_ready)
        ar_fifo_data_valid <= 1'b0;
   end

   // register AR FIFO data
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ar_fifo_dout_reg <= {A_FIFO_DATA_WIDTH{1'b0}};
      else if (ar_fifo_data_valid & ar_fifo_data_ready)
        ar_fifo_dout_reg <= ar_fifo_dout[A_FIFO_DATA_WIDTH-1:0];
   end
   
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        adr_wr_ar_valid <= 1'b0;
      else if (ar_fifo_data_valid & ar_fifo_data_ready)
        adr_wr_ar_valid <= 1'b1;
      else if (adr_wr_ar_ready)
        adr_wr_ar_valid <= 1'b0;
   end

   //---------------------------------------------------------------------------
   // FIFO
   //---------------------------------------------------------------------------
   generate
   if (DPRAM_MACRO==0) begin
   // AR FIFO
   /* rpc2_ctrl_ax_fifo AUTO_TEMPLATE (
    .rst_n(reset_n),
    .rd_en(ar_fifo_rd_en),
    .wr_en(ar_fifo_wr_en),
    .wr_data(ar_fifo_din[A_FIFO_DATA_WIDTH-1:0]),
    .empty(ar_fifo_empty),
    .rd_data(ar_fifo_dout[A_FIFO_DATA_WIDTH-1:0]),
    );
    */
   rpc2_ctrl_ax_fifo
      #(C_AR_FIFO_ADDR_BITS,
        A_FIFO_DATA_WIDTH
        ) 
   ar_fifo (/*AUTOINST*/
            // Outputs
            .rd_data                    (ar_fifo_dout[A_FIFO_DATA_WIDTH-1:0]), // Templated
            .empty                      (ar_fifo_empty),         // Templated
            // Inputs
            .rst_n                      (reset_n),               // Templated
            .clk                        (clk),
            .rd_en                      (ar_fifo_rd_en),         // Templated
            .wr_en                      (ar_fifo_wr_en),         // Templated
            .wr_data                    (ar_fifo_din[A_FIFO_DATA_WIDTH-1:0])); // Templated

   // ARID FIFO
   /* rpc2_ctrl_axid_fifo AUTO_TEMPLATE (
    .rst_n(reset_n),
    .rd_en(arid_fifo_rd_en),
    .wr_en(arid_fifo_wr_en),
    .wr_data(arid_fifo_din[ARID_FIFO_DATA_WIDTH-1:0]),
    .pre_full(arid_fifo_pre_full),
    .empty(arid_fifo_empty),
    .rd_data(arid_fifo_dout[ARID_FIFO_DATA_WIDTH-1:0]),
    );
    */
   rpc2_ctrl_axid_fifo 
      #(C_AR_FIFO_ADDR_BITS,
        ARID_FIFO_DATA_WIDTH
        ) 
   arid_fifo (/*AUTOINST*/
              // Outputs
              .rd_data                  (arid_fifo_dout[ARID_FIFO_DATA_WIDTH-1:0]), // Templated
              .empty                    (arid_fifo_empty),       // Templated
              .pre_full                 (arid_fifo_pre_full),    // Templated
              // Inputs
              .rst_n                    (reset_n),               // Templated
              .clk                      (clk),
              .rd_en                    (arid_fifo_rd_en),       // Templated
              .wr_en                    (arid_fifo_wr_en),       // Templated
              .wr_data                  (arid_fifo_din[ARID_FIFO_DATA_WIDTH-1:0])); // Templated
   end // if (DPRAM_MACRO==0)
   else begin
   /* rpc2_ctrl_dpram_wrapper AUTO_TEMPLATE (
    .rd_rst_n(reset_n),
    .rd_clk(clk),
    .rd_en(ar_fifo_rd_en),
    .wr_rst_n(1'b0),
    .wr_clk(1'b0),
    .wr_en(ar_fifo_wr_en),
    .wr_data(ar_fifo_din[A_FIFO_DATA_WIDTH-1:0]),
    .full(),
    .pre_full(),
    .half_full(),
    .empty(ar_fifo_empty),
    .rd_data(ar_fifo_dout[A_FIFO_DATA_WIDTH-1:0]),
    );
    */
    rpc2_ctrl_dpram_wrapper
      #(1,     // 0=async_fifo_axi, 1=sync_fifo_axi
        C_AR_FIFO_ADDR_BITS,
        A_FIFO_DATA_WIDTH,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        1,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE     // 0=STD, 1=LowLeak
        ) 
   ar_fifo_wrapper (/*AUTOINST*/
                    // Outputs
                    .rd_data            (ar_fifo_dout[A_FIFO_DATA_WIDTH-1:0]), // Templated
                    .empty              (ar_fifo_empty),         // Templated
                    .full               (),                      // Templated
                    .pre_full           (),                      // Templated
                    .half_full          (),                      // Templated
                    // Inputs
                    .rd_rst_n           (reset_n),               // Templated
                    .rd_clk             (clk),                   // Templated
                    .rd_en              (ar_fifo_rd_en),         // Templated
                    .wr_rst_n           (1'b0),                  // Templated
                    .wr_clk             (1'b0),                  // Templated
                    .wr_en              (ar_fifo_wr_en),         // Templated
                    .wr_data            (ar_fifo_din[A_FIFO_DATA_WIDTH-1:0])); // Templated

   /* rpc2_ctrl_dpram_wrapper AUTO_TEMPLATE (
    .rd_rst_n(reset_n),
    .rd_clk(clk),
    .rd_en(arid_fifo_rd_en),
    .wr_rst_n(1'b0),
    .wr_clk(1'b0),
    .wr_en(arid_fifo_wr_en),
    .wr_data(arid_fifo_din[ARID_FIFO_DATA_WIDTH-1:0]),
    .full(),
    .pre_full(arid_fifo_pre_full),
    .half_full(),
    .empty(arid_fifo_empty),
    .rd_data(arid_fifo_dout[ARID_FIFO_DATA_WIDTH-1:0]),
    );
    */
    rpc2_ctrl_dpram_wrapper 
      #(1,     // 0=async_fifo_axi, 1=sync_fifo_axi
        C_AR_FIFO_ADDR_BITS,
        ARID_FIFO_DATA_WIDTH,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        3,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE     // 0=STD, 1=LowLeak
        ) 
   arid_fifo_wrapper (/*AUTOINST*/
                      // Outputs
                      .rd_data          (arid_fifo_dout[ARID_FIFO_DATA_WIDTH-1:0]), // Templated
                      .empty            (arid_fifo_empty),       // Templated
                      .full             (),                      // Templated
                      .pre_full         (arid_fifo_pre_full),    // Templated
                      .half_full        (),                      // Templated
                      // Inputs
                      .rd_rst_n         (reset_n),               // Templated
                      .rd_clk           (clk),                   // Templated
                      .rd_en            (arid_fifo_rd_en),       // Templated
                      .wr_rst_n         (1'b0),                  // Templated
                      .wr_clk           (1'b0),                  // Templated
                      .wr_en            (arid_fifo_wr_en),       // Templated
                      .wr_data          (arid_fifo_din[ARID_FIFO_DATA_WIDTH-1:0])); // Templated
   
   end // else: !if(DPRAM_MACRO==0)
   endgenerate
   
endmodule // rpc2_ctrl_axi_rd_address_control
