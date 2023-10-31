
module rpc2_ctrl_axi_address_channel2 (/*AUTOARG*/
   // Outputs
   AXI_AWREADY, AXI_ARREADY, wready0_req, wready0_fixed, wready0_size,
   wready0_strb, wready0_id, wready1_req, wready1_fixed, wready1_size,
   wready1_strb, wready1_id, awid0_id, awid1_id, awid0_fifo_empty,
   awid1_fifo_empty, arid_id, arid_size, arid_len, arid_strb,
   arid_fifo_empty, adr_wr_en, adr_din,
   // Inputs
   clk, reset_n, AXI_AWID, AXI_AWADDR, AXI_AWLEN, AXI_AWSIZE,
   AXI_AWBURST, AXI_AWVALID, AXI_ARID, AXI_ARADDR, AXI_ARLEN,
   AXI_ARSIZE, AXI_ARBURST, AXI_ARVALID, ip_data_size, wready0_done,
   wready1_done, awid0_fifo_rd_en, awid1_fifo_rd_en, arid_fifo_rd_en,
   adr_wr_ready, reg_rd_trans_alloc, reg_wr_trans_alloc
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_ADDR_WIDTH = 'd32;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_LEN_WIDTH  = 'd8;
   parameter C_AR_FIFO_ADDR_BITS  = 'd4;
   parameter C_AW_FIFO_ADDR_BITS  = 'd4;  
   parameter C_NOWAIT_WR_DATA_DONE = 1'b0;
   parameter C_AXI_DATA_INTERLEAVING = 1'b1;

   parameter DPRAM_MACRO = 0;        // 0=Macro is not used, 1=Macro is used
   parameter DPRAM_MACRO_TYPE = 0;   // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)
      
   localparam IP_LEN = (C_AXI_DATA_WIDTH=='d32) ? 'd10:
                       (C_AXI_DATA_WIDTH=='d64) ? 'd11: 'd0;

//   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2; //44: addr+len+burst
//   localparam ADR_FIFO_DATA_WIDTH = PRE_ADR_DATA_WIDTH+1+1; //46: addr+len+burst+r/w+block no


   localparam PRE_ADR_DATA_WIDTH = 'd32+IP_LEN+2+2; //46: addr+len+burst+size  32+10+2+2 = 46  
   localparam ADR_FIFO_DATA_WIDTH = PRE_ADR_DATA_WIDTH+1+1; //48: addr+len+burst+size+r/w+block no

   
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
   output                            AXI_AWREADY;
   
   // Read Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0]        AXI_ARID;
   input [C_AXI_ADDR_WIDTH-1:0]      AXI_ARADDR;
   input [C_AXI_LEN_WIDTH-1:0]       AXI_ARLEN;
   input [2:0]                       AXI_ARSIZE;
   input [1:0]                       AXI_ARBURST;
   input                             AXI_ARVALID;
   output                            AXI_ARREADY;
   
   // IP
   input [1:0]                       ip_data_size;
   
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
   
   // for Read Response
   input                             arid_fifo_rd_en;
   output [C_AXI_ID_WIDTH-1:0]       arid_id;
   output [1:0]                      arid_size;
   output [7:0]                      arid_len;
   output [(C_AXI_DATA_WIDTH/8)-1:0] arid_strb;
   output                            arid_fifo_empty;
      
   // ADR FIFO
   output                            adr_wr_en;
   output [ADR_FIFO_DATA_WIDTH-1:0]  adr_din;
   input                             adr_wr_ready;

   input [1:0]                       reg_rd_trans_alloc;  // read transaction allocation
   input [1:0]                       reg_wr_trans_alloc;  // write transaction allocation
   
   wire [ADR_FIFO_DATA_WIDTH-1:0]    adr_din;
   wire [PRE_ADR_DATA_WIDTH-1:0]     adr_ar_din;
   wire [PRE_ADR_DATA_WIDTH-1:0]     adr_aw_din;
   wire                              adr_wr_ar_ready;
   wire                              adr_aw_ready;
   wire                              adr_wr_ar_valid;
   wire                              adr_aw_valid;
   wire                              adr_aw_block;
      
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 arb_selector;           // From trans_arbiter of rpc2_ctrl_trans_arbiter.v
   wire                 arb_valid;              // From trans_arbiter of rpc2_ctrl_trans_arbiter.v
   wire                 arid_fifo_pre_full;     // From axi_rd_address_control of rpc2_ctrl_axi_rd_address_control.v
   wire                 awid0_fifo_pre_full;    // From axi_wr_address_control of rpc2_ctrl_axi_wr_address_control2.v
   wire                 awid1_fifo_pre_full;    // From axi_wr_address_control of rpc2_ctrl_axi_wr_address_control2.v
   // End of automatics
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg                  AXI_ARREADY;
   reg                  AXI_AWREADY;
   // End of automatics
      
   assign adr_wr_en = arb_valid & adr_wr_ready;
   assign adr_din = (arb_selector) ? {adr_aw_block, 1'b0, adr_aw_din}: {1'b0, 1'b1, adr_ar_din};
   
   
   /* rpc2_ctrl_axi_wr_address_control2 AUTO_TEMPLATE (
    );
    */
   rpc2_ctrl_axi_wr_address_control2
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
     axi_wr_address_control (/*AUTOINST*/
                             // Outputs
                             .wready0_req       (wready0_req),
                             .wready0_fixed     (wready0_fixed),
                             .wready0_size      (wready0_size[1:0]),
                             .wready0_strb      (wready0_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                             .wready0_id        (wready0_id[C_AXI_ID_WIDTH-1:0]),
                             .wready1_req       (wready1_req),
                             .wready1_fixed     (wready1_fixed),
                             .wready1_size      (wready1_size[1:0]),
                             .wready1_strb      (wready1_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                             .wready1_id        (wready1_id[C_AXI_ID_WIDTH-1:0]),
                             .awid0_id          (awid0_id[C_AXI_ID_WIDTH-1:0]),
                             .awid1_id          (awid1_id[C_AXI_ID_WIDTH-1:0]),
                             .awid0_fifo_empty  (awid0_fifo_empty),
                             .awid1_fifo_empty  (awid1_fifo_empty),
                             .awid0_fifo_pre_full(awid0_fifo_pre_full),
                             .awid1_fifo_pre_full(awid1_fifo_pre_full),
                             .adr_aw_valid      (adr_aw_valid),
                             .adr_aw_din        (adr_aw_din[PRE_ADR_DATA_WIDTH-1:0]),
                             .adr_aw_block      (adr_aw_block),
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
                             .wready0_done      (wready0_done),
                             .wready1_done      (wready1_done),
                             .awid0_fifo_rd_en  (awid0_fifo_rd_en),
                             .awid1_fifo_rd_en  (awid1_fifo_rd_en),
                             .adr_aw_ready      (adr_aw_ready),
                             .ip_data_size      (ip_data_size[1:0]));

   /* rpc2_ctrl_axi_rd_address_control AUTO_TEMPLATE (
    );
    */
   rpc2_ctrl_axi_rd_address_control
     #(C_AXI_ID_WIDTH,
       C_AXI_ADDR_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_LEN_WIDTH,
       C_AR_FIFO_ADDR_BITS,
       DPRAM_MACRO,
       DPRAM_MACRO_TYPE
       )
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

   // 0: Read, 1: Write
   /* rpc2_ctrl_trans_arbiter AUTO_TEMPLATE (
    .ready0(adr_wr_ar_ready),
    .ready1(adr_aw_ready),
    .rst_n(reset_n),
    .valid0(adr_wr_ar_valid),
    .valid1(adr_aw_valid),
    .valid0_weight(reg_rd_trans_alloc),
    .valid1_weight(reg_wr_trans_alloc),
    .arb_ready(adr_wr_ready),
    );
    */
   rpc2_ctrl_trans_arbiter
     trans_arbiter (/*AUTOINST*/
                    // Outputs
                    .ready0             (adr_wr_ar_ready),       // Templated
                    .ready1             (adr_aw_ready),          // Templated
                    .arb_valid          (arb_valid),
                    .arb_selector       (arb_selector),
                    // Inputs
                    .clk                (clk),
                    .rst_n              (reset_n),               // Templated
                    .valid0             (adr_wr_ar_valid),       // Templated
                    .valid1             (adr_aw_valid),          // Templated
                    .valid0_weight      (reg_rd_trans_alloc),    // Templated
                    .valid1_weight      (reg_wr_trans_alloc),    // Templated
                    .arb_ready          (adr_wr_ready));                 // Templated
   
   //----------------------------------------------------------
   // AXI
   //----------------------------------------------------------
   // AXI_AWREADY
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_AWREADY <= 1'b0;
      else if (awid0_fifo_pre_full|awid1_fifo_pre_full)
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
   
endmodule // rpc2_ctrl_axi_address_channel2



