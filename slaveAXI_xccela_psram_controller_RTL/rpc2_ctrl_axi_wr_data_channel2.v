
module rpc2_ctrl_axi_wr_data_channel2 (/*AUTOARG*/
   // Outputs
   AXI_WREADY, wready0_done, wready1_done, axi2ip0_data_valid, 
   axi2ip0_strb, axi2ip0_data, axi2ip1_data_valid, axi2ip1_strb, 
   axi2ip1_data, wdat0_rd_en, wdat0_wr_en, wdat0_din, wdat1_rd_en, 
   wdat1_wr_en, wdat1_din, 
   // Inputs
   axi2ip_len,
   
   clk, reset_n, AXI_WDATA, AXI_WSTRB, AXI_WLAST, AXI_WVALID, 
   AXI_WID, wready0_req, wready0_size, wready0_fixed, wready0_strb, 
   wready0_id, wready1_req, wready1_size, wready1_fixed, 
   wready1_strb, wready1_id, ip_clk, ip_reset_n, ip_data_size, 
   ip0_data_ready, ip1_data_ready, wdat0_dout, wdat0_empty, 
   wdat0_full, wdat0_pre_full, wdat1_dout, wdat1_empty, wdat1_full, 
   wdat1_pre_full
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_DATA_INTERLEAVING = 1'b1;
   
   localparam WDAT_FIFO_DATA_WIDTH = C_AXI_DATA_WIDTH+((C_AXI_DATA_WIDTH*2)/8);
   localparam IP_LEN = (C_AXI_DATA_WIDTH=='d32) ? 'd10:
                       (C_AXI_DATA_WIDTH=='d64) ? 'd11: 'd0; 
   
   // Global System Signals
   input clk;
   input reset_n;

   // Write Data Channel Signals
   input [C_AXI_DATA_WIDTH-1:0] AXI_WDATA;
   input [(C_AXI_DATA_WIDTH/8)-1:0] AXI_WSTRB;
   input                            AXI_WLAST;
   input                            AXI_WVALID;
   input [C_AXI_ID_WIDTH-1:0]       AXI_WID;
   output                           AXI_WREADY;

   // for 0
   input                            wready0_req;
   input [1:0]                      wready0_size;
   input                            wready0_fixed;
   input [(C_AXI_DATA_WIDTH/8)-1:0] wready0_strb;
   input [C_AXI_ID_WIDTH-1:0]       wready0_id;     
   output                           wready0_done;

   // for 1
   input                            wready1_req;
   input [1:0]                      wready1_size;
   input                            wready1_fixed;
   input [(C_AXI_DATA_WIDTH/8)-1:0] wready1_strb;
   input [C_AXI_ID_WIDTH-1:0]       wready1_id;     
   output                           wready1_done;

   input                            ip_clk;
   input                            ip_reset_n;
   input [1:0]                      ip_data_size;
   
   // IP 0   
   input                            ip0_data_ready;
   output                           axi2ip0_data_valid;
   output [(C_AXI_DATA_WIDTH/8)-1:0] axi2ip0_strb;
   output [C_AXI_DATA_WIDTH-1:0]     axi2ip0_data;

   // IP 1   
   input                             ip1_data_ready;
   output                            axi2ip1_data_valid;
   output [(C_AXI_DATA_WIDTH/8)-1:0] axi2ip1_strb;
   output [C_AXI_DATA_WIDTH-1:0]     axi2ip1_data;

   // WDAT FIFO 0
   output                            wdat0_rd_en;
   output                            wdat0_wr_en;
   output [WDAT_FIFO_DATA_WIDTH-1:0] wdat0_din;
   input [WDAT_FIFO_DATA_WIDTH-1:0]  wdat0_dout;
   input                             wdat0_empty;
   input                             wdat0_full;
   input                             wdat0_pre_full;
   
   // WDAT FIFO 1
   output                            wdat1_rd_en;
   output                            wdat1_wr_en;
   output [WDAT_FIFO_DATA_WIDTH-1:0] wdat1_din;
   input [WDAT_FIFO_DATA_WIDTH-1:0]  wdat1_dout;
   input                             wdat1_empty;
   input                             wdat1_full;
   input                             wdat1_pre_full;


   input  [IP_LEN-1:0]               axi2ip_len;


   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   // End of automatics

   reg                               AXI_WREADY;
   reg                               wready0_valid;
   reg                               wready1_valid;
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   // End of automatics
   

   //--------------------------------------
   // AXI
   //--------------------------------------
   generate
   if (C_AXI_DATA_INTERLEAVING==1) begin
   // VALID before READY
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_WREADY <= 1'b0;
      else if (wdat0_pre_full|wdat1_pre_full)
        AXI_WREADY <= 1'b0;
      else if (AXI_WREADY)
        AXI_WREADY <= 1'b0;
      else if (((wready0_valid&AXI_WVALID) && (wready0_id==AXI_WID)) || 
               ((wready1_valid&AXI_WVALID) && (wready1_id==AXI_WID)))
        AXI_WREADY <= 1'b1;
   end
   end
   else begin
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        AXI_WREADY <= 1'b0;
      else if (wdat0_pre_full|wdat1_pre_full)
        AXI_WREADY <= 1'b0;
      else if ((wready0_done&(~wready1_valid))|| (wready1_done&(~wready0_valid)))
        AXI_WREADY <= 1'b0;
      else if ((wready0_req|wready1_req) || (wready0_valid|wready1_valid))
        AXI_WREADY <= 1'b1;
   end
   end // if (C_AXI_DATA_INTERLEAVING==1)
   endgenerate
   
   // wready_valid
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        wready0_valid <= 1'b0;
      else if (wready0_req)
        wready0_valid <= 1'b1;
      else if (wready0_done)
        wready0_valid <= 1'b0;
   end
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        wready1_valid <= 1'b0;
      else if (wready1_req)
        wready1_valid <= 1'b1;
      else if (wready1_done)
        wready1_valid <= 1'b0;
   end
   
   /* rpc2_ctrl_axi3_wr_data_control AUTO_TEMPLATE (
    .wdat_wr_en(wdat@_wr_en),
    .wdat_rd_en(wdat@_rd_en),
    .wdat_din(wdat@_din[WDAT_FIFO_DATA_WIDTH-1:0]),
    .wready_done(wready@_done),
    .axi2ip_data_valid(axi2ip@_data_valid),
    .axi2ip_strb(axi2ip@_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
    .axi2ip_data(axi2ip@_data[C_AXI_DATA_WIDTH-1:0]),
    .wdat_empty(wdat@_empty),
    .wdat_full(wdat@_full),
    .wdat_dout(wdat@_dout[WDAT_FIFO_DATA_WIDTH-1:0]),
    .wready_req(wready@_req),
    .wready_size(wready@_size[1:0]),
    .wready_fixed(wready@_fixed),
    .wready_strb(wready@_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
    .wready_id(wready@_id),
    .ip_data_ready(ip@_data_ready),
    .AXI_WVALID(wready@_valid&AXI_WVALID),
    );
    */
   rpc2_ctrl_axi3_wr_data_control
     #(C_AXI_ID_WIDTH,
       C_AXI_DATA_WIDTH,
       WDAT_FIFO_DATA_WIDTH)
     axi_wr_data_control_0 (/*AUTOINST*/
                            // Outputs
                            .wdat_wr_en (wdat0_wr_en),           // Templated
                            .wdat_rd_en (wdat0_rd_en),           // Templated
                            .wdat_din   (wdat0_din[WDAT_FIFO_DATA_WIDTH-1:0]), // Templated
                            .wready_done(wready0_done),          // Templated
                            .axi2ip_data_valid(axi2ip0_data_valid), // Templated
                            .axi2ip_strb(axi2ip0_strb[(C_AXI_DATA_WIDTH/8)-1:0]), // Templated
                            .axi2ip_data(axi2ip0_data[C_AXI_DATA_WIDTH-1:0]), // Templated
                            // Inputs
                            .axi2ip_len (axi2ip_len),
                            
                            .clk        (clk),
                            .reset_n    (reset_n),
                            .AXI_WDATA  (AXI_WDATA[C_AXI_DATA_WIDTH-1:0]),
                            .AXI_WSTRB  (AXI_WSTRB[(C_AXI_DATA_WIDTH/8)-1:0]),
                            .AXI_WLAST  (AXI_WLAST),
                            .AXI_WVALID (wready0_valid&AXI_WVALID), // Templated
                            .AXI_WID    (AXI_WID[C_AXI_ID_WIDTH-1:0]),
                            .AXI_WREADY (AXI_WREADY),
                            .wdat_empty (wdat0_empty),           // Templated
                            .wdat_full  (wdat0_full),            // Templated
                            .wdat_dout  (wdat0_dout[WDAT_FIFO_DATA_WIDTH-1:0]), // Templated
                            .wready_req (wready0_req),           // Templated
                            .wready_size(wready0_size[1:0]),     // Templated
                            .wready_fixed(wready0_fixed),        // Templated
                            .wready_strb(wready0_strb[(C_AXI_DATA_WIDTH/8)-1:0]), // Templated
                            .wready_id  (wready0_id),            // Templated
                            .ip_clk     (ip_clk),
                            .ip_reset_n (ip_reset_n),
                            .ip_data_size(ip_data_size[1:0]),
                            .ip_data_ready(ip0_data_ready));     // Templated

   rpc2_ctrl_axi3_wr_data_control
     #(C_AXI_ID_WIDTH,
       C_AXI_DATA_WIDTH,
       WDAT_FIFO_DATA_WIDTH)
   axi_wr_data_control_1 (/*AUTOINST*/
                          // Outputs
                          .wdat_wr_en   (wdat1_wr_en),           // Templated
                          .wdat_rd_en   (wdat1_rd_en),           // Templated
                          .wdat_din     (wdat1_din[WDAT_FIFO_DATA_WIDTH-1:0]), // Templated
                          .wready_done  (wready1_done),          // Templated
                          .axi2ip_data_valid(axi2ip1_data_valid), // Templated
                          .axi2ip_strb  (axi2ip1_strb[(C_AXI_DATA_WIDTH/8)-1:0]), // Templated
                          .axi2ip_data  (axi2ip1_data[C_AXI_DATA_WIDTH-1:0]), // Templated
                          // Inputs
                          .axi2ip_len (axi2ip_len),
                          
                          .clk          (clk),
                          .reset_n      (reset_n),
                          .AXI_WDATA    (AXI_WDATA[C_AXI_DATA_WIDTH-1:0]),
                          .AXI_WSTRB    (AXI_WSTRB[(C_AXI_DATA_WIDTH/8)-1:0]),
                          .AXI_WLAST    (AXI_WLAST),
                          .AXI_WVALID   (wready1_valid&AXI_WVALID), // Templated
                          .AXI_WID      (AXI_WID[C_AXI_ID_WIDTH-1:0]),
                          .AXI_WREADY   (AXI_WREADY),
                          .wdat_empty   (wdat1_empty),           // Templated
                          .wdat_full    (wdat1_full),            // Templated
                          .wdat_dout    (wdat1_dout[WDAT_FIFO_DATA_WIDTH-1:0]), // Templated
                          .wready_req   (wready1_req),           // Templated
                          .wready_size  (wready1_size[1:0]),     // Templated
                          .wready_fixed (wready1_fixed),         // Templated
                          .wready_strb  (wready1_strb[(C_AXI_DATA_WIDTH/8)-1:0]), // Templated
                          .wready_id    (wready1_id),            // Templated
                          .ip_clk       (ip_clk),
                          .ip_reset_n   (ip_reset_n),
                          .ip_data_size (ip_data_size[1:0]),
                          .ip_data_ready(ip1_data_ready));       // Templated
   
endmodule // rpc2_ctrl_axi_wr_data_channel2

