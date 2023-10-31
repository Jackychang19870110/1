
module rpc2_ctrl_axi3_wr_data_control (/*AUTOARG*/
   // Outputs
   wdat_wr_en, wdat_rd_en, wdat_din, wready_done, axi2ip_data_valid, 
   axi2ip_strb, axi2ip_data, 
   // Inputs
   axi2ip_len,
   clk, reset_n, AXI_WDATA, AXI_WSTRB, AXI_WLAST, AXI_WVALID, 
   AXI_WID, AXI_WREADY, wdat_empty, wdat_full, wdat_dout, wready_req, 
   wready_size, wready_fixed, wready_strb, wready_id, ip_clk, 
   ip_reset_n, ip_data_size, ip_data_ready
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter WDAT_FIFO_DATA_WIDTH = C_AXI_DATA_WIDTH+((C_AXI_DATA_WIDTH*2)/8);

   localparam ADDR_BITS_IN_DATA_WIDTH = (C_AXI_DATA_WIDTH=='d32) ? 2'h2:
                                        (C_AXI_DATA_WIDTH=='d64) ? 2'h3: 2'h0;

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
   input                            AXI_WREADY;

   // WDAT FIFO
   input                            wdat_empty;
   input                            wdat_full;
   input [WDAT_FIFO_DATA_WIDTH-1:0]  wdat_dout;
   output                            wdat_wr_en;
   output                            wdat_rd_en;
   output [WDAT_FIFO_DATA_WIDTH-1:0] wdat_din;

   // Address Channel
   input                             wready_req;
   input [1:0]                       wready_size;
   input                             wready_fixed;
   input [(C_AXI_DATA_WIDTH/8)-1:0]  wready_strb;
   input [C_AXI_ID_WIDTH-1:0]        wready_id;
   output                            wready_done;

   // for IP
   input                             ip_clk;
   input                             ip_reset_n;
   input [1:0]                       ip_data_size;
   input                             ip_data_ready;
   output                            axi2ip_data_valid;
   output [(C_AXI_DATA_WIDTH/8)-1:0] axi2ip_strb;
   output [C_AXI_DATA_WIDTH-1:0]     axi2ip_data;

   input  [IP_LEN-1:0]               axi2ip_len;

   
   reg [C_AXI_DATA_WIDTH-1:0]        wdat_data_din;
   reg [(C_AXI_DATA_WIDTH/8)-1:0]    wdat_strb_din;
   reg [(C_AXI_DATA_WIDTH/8)-1:0]    wdat_valid_din;
   
   reg                               wdat_wr_op;
   
   reg [(C_AXI_DATA_WIDTH/8)-1:0]    strb;
   wire [(C_AXI_DATA_WIDTH/8)-1:0]   next_strb;
//   wire [((C_AXI_DATA_WIDTH*2)/8)-1:0] strb_rotate;
   wire [(C_AXI_DATA_WIDTH/8)-1:0]   strb_rotate;
   
   wire                              data_en;
   reg [(C_AXI_DATA_WIDTH/8)-1:0]    ip_data_mask;
   reg [ADDR_BITS_IN_DATA_WIDTH-1:0] xfer_in_unit;
   reg                               in_xfer;

   wire [C_AXI_DATA_WIDTH-1:0]       wdat_data_dout;
   wire [(C_AXI_DATA_WIDTH/8)-1:0]   wdat_strb_dout;
   wire [(C_AXI_DATA_WIDTH/8)-1:0]   wdat_valid_dout;

   wire                              w_en;
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [C_AXI_DATA_WIDTH-1:0]axi2ip_data;
   reg                  axi2ip_data_valid;
   reg [(C_AXI_DATA_WIDTH/8)-1:0]axi2ip_strb;
   
   reg [3:0]                  valid_data_counter;
   // End of automatics

   //------------------------------------------------
   // WRITE
   //------------------------------------------------
   assign w_en = AXI_WVALID & AXI_WREADY & (AXI_WID==wready_id);
   assign wready_done = AXI_WLAST & w_en;
   
   assign wdat_din = {wdat_valid_din, wdat_strb_din, wdat_data_din};
   assign wdat_wr_en = wdat_wr_op & ~wdat_full;

//   assign strb_rotate = {strb, strb} << (1<<wready_size);
   assign strb_rotate = ({strb, strb}<<(1<<wready_size))>>(C_AXI_DATA_WIDTH/8);
   assign next_strb = ((~|strb) || wready_fixed) ? 
//                      wready_strb: strb_rotate[((C_AXI_DATA_WIDTH*2)/8)-1:(C_AXI_DATA_WIDTH/8)];
                        wready_strb: strb_rotate;
   
   // wdat_wr_op
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        wdat_wr_op <= 1'b0;
      else if (w_en & (wready_fixed | next_strb[(C_AXI_DATA_WIDTH/8)-1] | AXI_WLAST))
        wdat_wr_op <= 1'b1;
      else if (wdat_wr_en)
        wdat_wr_op <= 1'b0;
   end

   // strobe
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        strb <= {(C_AXI_DATA_WIDTH/8){1'b0}};
      else if (wready_req)
        strb <= {(C_AXI_DATA_WIDTH/8){1'b0}};
      else if (w_en)
        strb <= next_strb | AXI_WSTRB | {(C_AXI_DATA_WIDTH/8){wready_size[1]}}; // fixed write strobe issue
   end
   
   genvar i;

   // wdat_data_din
   generate for (i = 0; i < (C_AXI_DATA_WIDTH/8); i=i+1) begin: wdat_data_din_loop
      always @(posedge clk or negedge reset_n) begin
         if (~reset_n)
           wdat_data_din[i*8+:8] <= 8'h00;
         else if (w_en & AXI_WSTRB[i])
           wdat_data_din[i*8+:8] <= AXI_WDATA[i*8+:8];
         else if (wdat_wr_en)
           wdat_data_din[i*8+:8] <= 8'h00;
      end
   end
   endgenerate

   // wdat_strb_din
   generate for (i = 0; i < (C_AXI_DATA_WIDTH/8); i=i+1) begin: wdat_strb_din_loop
      always @(posedge clk or negedge reset_n) begin
         if (~reset_n)
           wdat_strb_din[i] <= 1'b0;
         else if (w_en & AXI_WSTRB[i])
           wdat_strb_din[i] <= 1'b1;
         else if (wdat_wr_en)
           wdat_strb_din[i] <= 1'b0;
      end
   end
   endgenerate

   // wdat_valid_din
   generate for (i = 0; i < (C_AXI_DATA_WIDTH/8); i=i+1) begin: wdat_valid_din_loop
      always @(posedge clk or negedge reset_n) begin
         if (~reset_n)
           wdat_valid_din[i] <= 1'b0;
         else if (w_en & (next_strb[i] | AXI_WSTRB[i]))
           wdat_valid_din[i] <= 1'b1;
         else if (wdat_wr_en)
           wdat_valid_din[i] <= 1'b0;
      end
   end
   endgenerate

   //------------------------------------------------
   // READ
   //------------------------------------------------
   assign data_en = (axi2ip_data_valid&ip_data_ready) | ~axi2ip_data_valid; 
//   assign data_en = (axi2ip_data_valid&ip_data_ready) | ( (valid_data_counter >= 4'h1) & (valid_data_counter <= axi2ip_len) ) ? 1'b1 :  ( |  (~axi2ip_data_valid)  ); 

   
   assign wdat_rd_en = (~wdat_empty) && (((xfer_in_unit==0)&&data_en) || ~in_xfer);
   assign wdat_data_dout = wdat_dout[C_AXI_DATA_WIDTH-1:0];
   assign wdat_strb_dout = wdat_dout[(((C_AXI_DATA_WIDTH/8)+C_AXI_DATA_WIDTH)-1):C_AXI_DATA_WIDTH];
   assign wdat_valid_dout = wdat_dout[WDAT_FIFO_DATA_WIDTH-1:WDAT_FIFO_DATA_WIDTH-(C_AXI_DATA_WIDTH/8)];
 
   
   // ip_data_mask
   always @(posedge ip_clk or negedge ip_reset_n) begin
      if (~ip_reset_n)
        ip_data_mask <= {(C_AXI_DATA_WIDTH/8){1'b0}};
      else if (wdat_rd_en)
        ip_data_mask <= ~({(C_AXI_DATA_WIDTH/8){1'b1}}<<(1<<ip_data_size));
//        ip_data_mask <= ~(  {  (32/8){1'b1}  }   <<    (   1<<ip_data_size  )   );
        
      else if (data_en)
        ip_data_mask <= ip_data_mask << (1<<ip_data_size);
        
   end

   // xfer_in_unit
   always @(posedge ip_clk or negedge ip_reset_n) begin
      if (~ip_reset_n)
        xfer_in_unit <= {ADDR_BITS_IN_DATA_WIDTH{1'b0}};
      else if (wdat_rd_en)
        xfer_in_unit <= {ADDR_BITS_IN_DATA_WIDTH{1'b1}}>>ip_data_size;
      else if (data_en && |xfer_in_unit)
        xfer_in_unit <= xfer_in_unit - 1'b1;
   end

   // in transfer
   always @(posedge ip_clk or negedge ip_reset_n) begin
      if (~ip_reset_n)
        in_xfer <= 1'b0;
      else if (wdat_rd_en)
        in_xfer <= 1'b1;
      else if ((xfer_in_unit==0) && data_en)
        in_xfer <= 1'b0;
   end

   //
   always @(posedge ip_clk or negedge ip_reset_n) begin
      if (~ip_reset_n)
        axi2ip_strb <= {(C_AXI_DATA_WIDTH/8){1'b0}};
      else if (data_en)
        axi2ip_strb <= wdat_strb_dout & ip_data_mask;
   end
        
   //
   always @(posedge ip_clk or negedge ip_reset_n) begin
      if (~ip_reset_n)
        axi2ip_data_valid <= 1'b0;      
      else if (data_en)
        axi2ip_data_valid <= (|(wdat_valid_dout & ip_data_mask));        
   end

   // valid_data_counter
   always @(posedge ip_clk or negedge ip_reset_n) begin
      if (~ip_reset_n)
//        valid_data_counter <= {MEM_LEN{1'b0}};
        valid_data_counter <= 4'h0;
//      else if (axi2ip_data_valid&ip_data_ready )   
      else if (data_en & axi2ip_data_valid)         
        valid_data_counter <= valid_data_counter + 1'b1;        
      else   
        valid_data_counter <= 4'h0;       
         
   end
   
   
   
   
   //
   always @(posedge ip_clk or negedge ip_reset_n) begin
      if (~ip_reset_n)
        axi2ip_data <= {C_AXI_DATA_WIDTH{1'b0}};
      else if (data_en)
        axi2ip_data <= wdat_data_dout;
   end
   
endmodule // rpc2_ctrl_axi3_wr_data_control

