
module rpc2_ctrl_axi_async_channel2 (/*AUTOARG*/
   // Outputs
   AXI_AWREADY, AXI_WREADY, AXI_BID, AXI_BRESP, AXI_BVALID,
   AXI_ARREADY, AXI_RID, AXI_RDATA, AXI_RRESP, AXI_RLAST, AXI_RVALID,
   axi2ip_valid, axi2ip_block, axi2ip_rw_n, axi2ip_address,
   
   axi2ip_size,
   
   axi2ip_burst, axi2ip_len, axi2ip0_data_valid, axi2ip0_strb,
   axi2ip0_data, axi2ip1_data_valid, axi2ip1_strb, axi2ip1_data,
   axi2ip_data_ready, rd_active, wr_active,
   // Inputs
   AXI_ACLK, AXI_ARESETN, AXI_AWID, AXI_AWADDR, AXI_AWLEN, AXI_AWSIZE,
   AXI_AWBURST, AXI_AWVALID, AXI_WDATA, AXI_WSTRB, AXI_WLAST,
   AXI_WVALID, AXI_WID, AXI_BREADY, AXI_ARID, AXI_ARADDR, AXI_ARLEN,
   AXI_ARSIZE, AXI_ARBURST, AXI_ARVALID, AXI_RREADY, ip_data_size,
   ip_ready, ip0_data_ready, ip1_data_ready, ip_data_valid,
   ip_data_last, ip_strb, ip_data, ip_rd_error, ip0_wr_done,
   ip0_wr_error, ip1_wr_done, ip1_wr_error, ip_clk, ip_reset_n,
   reg_rd_trans_alloc, reg_wr_trans_alloc
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_ADDR_WIDTH = 'd32;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_LEN_WIDTH  = 'd8;
   parameter C_AW_FIFO_ADDR_BITS  = 'd4;
   parameter C_AR_FIFO_ADDR_BITS  = 'd4;
   parameter C_WDAT_FIFO_ADDR_BITS = 'd9;
   parameter C_RDAT_FIFO_ADDR_BITS = 'd9;
   parameter C_NOWAIT_WR_DATA_DONE = 1'b0;
   parameter C_AXI_DATA_INTERLEAVING = 1'b1;
   
   parameter DPRAM_MACRO = 0;        // 0=Macro is not used, 1=Macro is used
   parameter DPRAM_MACRO_TYPE = 0;   // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)

   localparam IP_LEN = (C_AXI_DATA_WIDTH=='d32) ? 'd10:
                       (C_AXI_DATA_WIDTH=='d64) ? 'd11: 'd0; 
                       
                       
//   localparam ADR_FIFO_DATA_WIDTH = 'd46; //46: addr+len+burst+r/w+block no
   localparam ADR_FIFO_DATA_WIDTH = 'd48; //48: addr+len+burst+size+r/w+block no

   
   localparam WDAT_FIFO_DATA_WIDTH = C_AXI_DATA_WIDTH+((C_AXI_DATA_WIDTH*2)/8);
   localparam RDAT_FIFO_DATA_WIDTH = C_AXI_DATA_WIDTH+((C_AXI_DATA_WIDTH*2)/8);
   localparam OUTPUT_REGISTER = 1'b1;  // output register for synchronizer
   
   // Global System Signals
   input                             AXI_ACLK;
   input                             AXI_ARESETN;
   
   // Write Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0]        AXI_AWID;
   input [C_AXI_ADDR_WIDTH-1:0]      AXI_AWADDR;
   input [C_AXI_LEN_WIDTH-1:0]       AXI_AWLEN;
   input [2:0]                       AXI_AWSIZE;
   input [1:0]                       AXI_AWBURST;
   input                             AXI_AWVALID;
   output                            AXI_AWREADY;
   
   // Write Data Channel Signals
   input [C_AXI_DATA_WIDTH-1:0]      AXI_WDATA;
   input [(C_AXI_DATA_WIDTH/8)-1:0]  AXI_WSTRB;
   input                             AXI_WLAST;
   input                             AXI_WVALID;
   input [C_AXI_ID_WIDTH-1:0]        AXI_WID;
   output                            AXI_WREADY;
   
   // Write Response Channel Signals
   output [C_AXI_ID_WIDTH-1:0]       AXI_BID;
   output [1:0]                      AXI_BRESP;
   output                            AXI_BVALID;
   input                             AXI_BREADY;
   
   // Read Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0]        AXI_ARID;
   input [C_AXI_ADDR_WIDTH-1:0]      AXI_ARADDR;
   input [C_AXI_LEN_WIDTH-1:0]       AXI_ARLEN;
   input [2:0]                       AXI_ARSIZE;
   input [1:0]                       AXI_ARBURST;
   input                             AXI_ARVALID;
   output                            AXI_ARREADY;
   
   // Read Data Channel Signals
   output [C_AXI_ID_WIDTH-1:0]       AXI_RID;
   output [C_AXI_DATA_WIDTH-1:0]     AXI_RDATA;
   output [1:0]                      AXI_RRESP;
   output                            AXI_RLAST;
   output                            AXI_RVALID;
   input                             AXI_RREADY;

   input [1:0]                       ip_data_size;

   // AXI address
   input                             ip_ready;
   output                            axi2ip_valid;
   output                            axi2ip_block;
   output                            axi2ip_rw_n;
   output [31:0]                     axi2ip_address;
   output [1:0]                      axi2ip_burst;
   
   output [1:0]                      axi2ip_size;    
   
   output [IP_LEN-1:0]               axi2ip_len;
   
   // AXI write data 0
   input                             ip0_data_ready;
   output                            axi2ip0_data_valid;
   output [(C_AXI_DATA_WIDTH/8)-1:0] axi2ip0_strb;
   output [C_AXI_DATA_WIDTH-1:0]     axi2ip0_data;
   // AXI write data 1
   input                             ip1_data_ready;
   output                            axi2ip1_data_valid;
   output [(C_AXI_DATA_WIDTH/8)-1:0] axi2ip1_strb;
   output [C_AXI_DATA_WIDTH-1:0]     axi2ip1_data;
   
   // AXI read data
   input                             ip_data_valid;
   input                             ip_data_last;
   input [(C_AXI_DATA_WIDTH/8)-1:0]  ip_strb;
   input [C_AXI_DATA_WIDTH-1:0]      ip_data;
   input [1:0]                       ip_rd_error;
   output                            axi2ip_data_ready;
   
   // AXI write response 0
   input                             ip0_wr_done;
   input [1:0]                       ip0_wr_error;
   // AXI write response 1
   input                             ip1_wr_done;
   input [1:0]                       ip1_wr_error;
   
   input                             ip_clk;
   input                             ip_reset_n;

   output                            rd_active;
   output                            wr_active;
   input [1:0]                       reg_rd_trans_alloc;  // read transaction allocation
   input [1:0]                       reg_wr_trans_alloc;  // write transaction allocation
   
   /*AUTOINPUT*/   

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [ADR_FIFO_DATA_WIDTH-1:0] adr_din;      // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 adr_wr_en;              // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 adr_wr_ready;           // From adr_fifo_synchronizer of rpc2_ctrl_fifo_synchronizer.v
   wire                 arid_fifo_empty;        // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 arid_fifo_rd_en;        // From rpc2_ctrl_rd_data_channel of rpc2_ctrl_axi_rd_data_channel.v
   wire [C_AXI_ID_WIDTH-1:0] arid_id;           // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [7:0]           arid_len;               // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [1:0]           arid_size;              // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [(C_AXI_DATA_WIDTH/8)-1:0] arid_strb;   // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 awid0_fifo_empty;       // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 awid0_fifo_rd_en;       // From rpc2_ctrl_axi_wr_response_channel2 of rpc2_ctrl_axi_wr_response_channel2.v
   wire [C_AXI_ID_WIDTH-1:0] awid0_id;          // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 awid1_fifo_empty;       // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 awid1_fifo_rd_en;       // From rpc2_ctrl_axi_wr_response_channel2 of rpc2_ctrl_axi_wr_response_channel2.v
   wire [C_AXI_ID_WIDTH-1:0] awid1_id;          // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [1:0]           bdat0_dout;             // From bdat_fifo_wrapper_0 of rpc2_ctrl_dpram_wrapper.v
   wire                 bdat0_empty;            // From bdat_fifo_wrapper_0 of rpc2_ctrl_dpram_wrapper.v
   wire                 bdat0_rd_en;            // From rpc2_ctrl_axi_wr_response_channel2 of rpc2_ctrl_axi_wr_response_channel2.v
   wire [1:0]           bdat1_dout;             // From bdat_fifo_wrapper_1 of rpc2_ctrl_dpram_wrapper.v
   wire                 bdat1_empty;            // From bdat_fifo_wrapper_1 of rpc2_ctrl_dpram_wrapper.v
   wire                 bdat1_rd_en;            // From rpc2_ctrl_axi_wr_response_channel2 of rpc2_ctrl_axi_wr_response_channel2.v
   wire [RDAT_FIFO_DATA_WIDTH-1:0] rdat_din;    // From rpc2_ctrl_rd_data_channel of rpc2_ctrl_axi_rd_data_channel.v
   wire [RDAT_FIFO_DATA_WIDTH-1:0] rdat_dout;   // From rdat_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire                 rdat_empty;             // From rdat_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire                 rdat_full;              // From rdat_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire                 rdat_rd_en;             // From rpc2_ctrl_rd_data_channel of rpc2_ctrl_axi_rd_data_channel.v
   wire                 rdat_wr_en;             // From rpc2_ctrl_rd_data_channel of rpc2_ctrl_axi_rd_data_channel.v
   wire [WDAT_FIFO_DATA_WIDTH-1:0] wdat0_din;   // From rpc2_ctrl_axi_wr_data_channel2 of rpc2_ctrl_axi_wr_data_channel2.v
   wire [WDAT_FIFO_DATA_WIDTH-1:0] wdat0_dout;  // From wdat_fifo_wrapper_0 of rpc2_ctrl_dpram_wrapper.v
   wire                 wdat0_empty;            // From wdat_fifo_wrapper_0 of rpc2_ctrl_dpram_wrapper.v
   wire                 wdat0_full;             // From wdat_fifo_wrapper_0 of rpc2_ctrl_dpram_wrapper.v
   wire                 wdat0_pre_full;         // From wdat_fifo_wrapper_0 of rpc2_ctrl_dpram_wrapper.v
   wire                 wdat0_rd_en;            // From rpc2_ctrl_axi_wr_data_channel2 of rpc2_ctrl_axi_wr_data_channel2.v
   wire                 wdat0_wr_en;            // From rpc2_ctrl_axi_wr_data_channel2 of rpc2_ctrl_axi_wr_data_channel2.v
   wire [WDAT_FIFO_DATA_WIDTH-1:0] wdat1_din;   // From rpc2_ctrl_axi_wr_data_channel2 of rpc2_ctrl_axi_wr_data_channel2.v
   wire [WDAT_FIFO_DATA_WIDTH-1:0] wdat1_dout;  // From wdat_fifo_wrapper_1 of rpc2_ctrl_dpram_wrapper.v
   wire                 wdat1_empty;            // From wdat_fifo_wrapper_1 of rpc2_ctrl_dpram_wrapper.v
   wire                 wdat1_full;             // From wdat_fifo_wrapper_1 of rpc2_ctrl_dpram_wrapper.v
   wire                 wdat1_pre_full;         // From wdat_fifo_wrapper_1 of rpc2_ctrl_dpram_wrapper.v
   wire                 wdat1_rd_en;            // From rpc2_ctrl_axi_wr_data_channel2 of rpc2_ctrl_axi_wr_data_channel2.v
   wire                 wdat1_wr_en;            // From rpc2_ctrl_axi_wr_data_channel2 of rpc2_ctrl_axi_wr_data_channel2.v
   wire                 wready0_done;           // From rpc2_ctrl_axi_wr_data_channel2 of rpc2_ctrl_axi_wr_data_channel2.v
   wire                 wready0_fixed;          // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [C_AXI_ID_WIDTH-1:0] wready0_id;        // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 wready0_req;            // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [1:0]           wready0_size;           // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [(C_AXI_DATA_WIDTH/8)-1:0] wready0_strb;// From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 wready1_done;           // From rpc2_ctrl_axi_wr_data_channel2 of rpc2_ctrl_axi_wr_data_channel2.v
   wire                 wready1_fixed;          // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [C_AXI_ID_WIDTH-1:0] wready1_id;        // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire                 wready1_req;            // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [1:0]           wready1_size;           // From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   wire [(C_AXI_DATA_WIDTH/8)-1:0] wready1_strb;// From rpc2_ctrl_axi_address_channel2 of rpc2_ctrl_axi_address_channel2.v
   // End of automatics
   wire [ADR_FIFO_DATA_WIDTH-1:0] adr_dout;
   wire                           adr_rd_en;
   wire                           adr_rd_ready; 
   
   wire                           clk;
   wire                           reset_n;
   wire                           axi2ip_block;
   wire                           axi2ip_rw_n;
   wire [1:0]                     axi2ip_burst;
   
   wire [1:0]                     axi2ip_size;
   
   wire [IP_LEN-1:0]              axi2ip_len;
   wire [31:0]                    axi2ip_address;
   wire                           axi2ip_valid;

   assign clk = AXI_ACLK;
   assign reset_n = AXI_ARESETN;

   assign adr_rd_en = axi2ip_valid & ip_ready;
   assign axi2ip_valid = adr_rd_ready;
   
   
//   assign axi2ip_block = adr_dout[ADR_FIFO_DATA_WIDTH-1];
//   assign axi2ip_rw_n = adr_dout[34+IP_LEN]; 
   assign axi2ip_block = adr_dout[ADR_FIFO_DATA_WIDTH-1];
   assign axi2ip_rw_n = adr_dout[36+IP_LEN]; 
   assign axi2ip_size = adr_dout[(36+IP_LEN)-1:34+IP_LEN];
   
   
   assign axi2ip_burst = adr_dout[(34+IP_LEN)-1:32+IP_LEN];
   assign axi2ip_len = adr_dout[(32+IP_LEN)-1:32];
   assign axi2ip_address = adr_dout[31:0];
   
   rpc2_ctrl_axi_address_channel2
     #(C_AXI_ID_WIDTH,
       C_AXI_ADDR_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_LEN_WIDTH,
       C_AR_FIFO_ADDR_BITS,
       C_AW_FIFO_ADDR_BITS,
       C_NOWAIT_WR_DATA_DONE,
       C_AXI_DATA_INTERLEAVING,
       DPRAM_MACRO,
       DPRAM_MACRO_TYPE
       )
   rpc2_ctrl_axi_address_channel2 (/*AUTOINST*/
                                   // Outputs
                                   .AXI_AWREADY         (AXI_AWREADY),
                                   .AXI_ARREADY         (AXI_ARREADY),
                                   .wready0_req         (wready0_req),
                                   .wready0_fixed       (wready0_fixed),
                                   .wready0_size        (wready0_size[1:0]),
                                   .wready0_strb        (wready0_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                   .wready0_id          (wready0_id[C_AXI_ID_WIDTH-1:0]),
                                   .wready1_req         (wready1_req),
                                   .wready1_fixed       (wready1_fixed),
                                   .wready1_size        (wready1_size[1:0]),
                                   .wready1_strb        (wready1_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                   .wready1_id          (wready1_id[C_AXI_ID_WIDTH-1:0]),
                                   .awid0_id            (awid0_id[C_AXI_ID_WIDTH-1:0]),
                                   .awid1_id            (awid1_id[C_AXI_ID_WIDTH-1:0]),
                                   .awid0_fifo_empty    (awid0_fifo_empty),
                                   .awid1_fifo_empty    (awid1_fifo_empty),
                                   .arid_id             (arid_id[C_AXI_ID_WIDTH-1:0]),
                                   .arid_size           (arid_size[1:0]),
                                   .arid_len            (arid_len[7:0]),
                                   .arid_strb           (arid_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                   .arid_fifo_empty     (arid_fifo_empty),
                                   .adr_wr_en           (adr_wr_en),
                                   .adr_din             (adr_din[ADR_FIFO_DATA_WIDTH-1:0]),
                                   // Inputs
                                   .clk                 (clk),
                                   .reset_n             (reset_n),
                                   .AXI_AWID            (AXI_AWID[C_AXI_ID_WIDTH-1:0]),
                                   .AXI_AWADDR          (AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0]),
                                   .AXI_AWLEN           (AXI_AWLEN[C_AXI_LEN_WIDTH-1:0]),
                                   .AXI_AWSIZE          (AXI_AWSIZE[2:0]),
                                   .AXI_AWBURST         (AXI_AWBURST[1:0]),
                                   .AXI_AWVALID         (AXI_AWVALID),
                                   .AXI_ARID            (AXI_ARID[C_AXI_ID_WIDTH-1:0]),
                                   .AXI_ARADDR          (AXI_ARADDR[C_AXI_ADDR_WIDTH-1:0]),
                                   .AXI_ARLEN           (AXI_ARLEN[C_AXI_LEN_WIDTH-1:0]),
                                   .AXI_ARSIZE          (AXI_ARSIZE[2:0]),
                                   .AXI_ARBURST         (AXI_ARBURST[1:0]),
                                   .AXI_ARVALID         (AXI_ARVALID),
                                   .ip_data_size        (ip_data_size[1:0]),
                                   .wready0_done        (wready0_done),
                                   .wready1_done        (wready1_done),
                                   .awid0_fifo_rd_en    (awid0_fifo_rd_en),
                                   .awid1_fifo_rd_en    (awid1_fifo_rd_en),
                                   .arid_fifo_rd_en     (arid_fifo_rd_en),
                                   .adr_wr_ready        (adr_wr_ready),
                                   .reg_rd_trans_alloc  (reg_rd_trans_alloc[1:0]),
                                   .reg_wr_trans_alloc  (reg_wr_trans_alloc[1:0]));
   
   rpc2_ctrl_axi_wr_data_channel2
     #(C_AXI_ID_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_DATA_INTERLEAVING)
   rpc2_ctrl_axi_wr_data_channel2 (/*AUTOINST*/
                                   // Outputs
                                   .AXI_WREADY          (AXI_WREADY),
                                   .wready0_done        (wready0_done),
                                   .wready1_done        (wready1_done),
                                   .axi2ip0_data_valid  (axi2ip0_data_valid),
                                   .axi2ip0_strb        (axi2ip0_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                   .axi2ip0_data        (axi2ip0_data[C_AXI_DATA_WIDTH-1:0]),                                 
                                   .axi2ip1_data_valid  (axi2ip1_data_valid),
                                   .axi2ip1_strb        (axi2ip1_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                   .axi2ip1_data        (axi2ip1_data[C_AXI_DATA_WIDTH-1:0]),
                                   .wdat0_rd_en         (wdat0_rd_en),
                                   .wdat0_wr_en         (wdat0_wr_en),
                                   .wdat0_din           (wdat0_din[WDAT_FIFO_DATA_WIDTH-1:0]),
                                   .wdat1_rd_en         (wdat1_rd_en),
                                   .wdat1_wr_en         (wdat1_wr_en),
                                   .wdat1_din           (wdat1_din[WDAT_FIFO_DATA_WIDTH-1:0]),
                                   // Inputs
                                   .axi2ip_len          (axi2ip_len),
                                   
                                   .clk                 (clk),
                                   .reset_n             (reset_n),
                                   .AXI_WDATA           (AXI_WDATA[C_AXI_DATA_WIDTH-1:0]),
                                   .AXI_WSTRB           (AXI_WSTRB[(C_AXI_DATA_WIDTH/8)-1:0]),
                                   .AXI_WLAST           (AXI_WLAST),
                                   .AXI_WVALID          (AXI_WVALID),
                                   .AXI_WID             (AXI_WID[C_AXI_ID_WIDTH-1:0]),
                                   .wready0_req         (wready0_req),
                                   .wready0_size        (wready0_size[1:0]),
                                   .wready0_fixed       (wready0_fixed),
                                   .wready0_strb        (wready0_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                   .wready0_id          (wready0_id[C_AXI_ID_WIDTH-1:0]),
                                   .wready1_req         (wready1_req),
                                   .wready1_size        (wready1_size[1:0]),
                                   .wready1_fixed       (wready1_fixed),
                                   .wready1_strb        (wready1_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                   .wready1_id          (wready1_id[C_AXI_ID_WIDTH-1:0]),
                                   .ip_clk              (ip_clk),
                                   .ip_reset_n          (ip_reset_n),
                                   .ip_data_size        (ip_data_size[1:0]),
                                   .ip0_data_ready      (ip0_data_ready),
                                   .ip1_data_ready      (ip1_data_ready),
                                   .wdat0_dout          (wdat0_dout[WDAT_FIFO_DATA_WIDTH-1:0]),
                                   .wdat0_empty         (wdat0_empty),
                                   .wdat0_full          (wdat0_full),
                                   .wdat0_pre_full      (wdat0_pre_full),
                                   .wdat1_dout          (wdat1_dout[WDAT_FIFO_DATA_WIDTH-1:0]),
                                   .wdat1_empty         (wdat1_empty),
                                   .wdat1_full          (wdat1_full),
                                   .wdat1_pre_full      (wdat1_pre_full));
   
   rpc2_ctrl_axi_wr_response_channel2
     #(C_AXI_ID_WIDTH)
   rpc2_ctrl_axi_wr_response_channel2 (/*AUTOINST*/
                                       // Outputs
                                       .AXI_BID         (AXI_BID[C_AXI_ID_WIDTH-1:0]),
                                       .AXI_BRESP       (AXI_BRESP[1:0]),
                                       .AXI_BVALID      (AXI_BVALID),
                                       .awid0_fifo_rd_en(awid0_fifo_rd_en),
                                       .awid1_fifo_rd_en(awid1_fifo_rd_en),
                                       .bdat0_rd_en     (bdat0_rd_en),
                                       .bdat1_rd_en     (bdat1_rd_en),
                                       .wr_active       (wr_active),
                                       // Inputs
                                       .clk             (clk),
                                       .reset_n         (reset_n),
                                       .AXI_BREADY      (AXI_BREADY),
                                       .awid0_id        (awid0_id[C_AXI_ID_WIDTH-1:0]),
                                       .awid0_fifo_empty(awid0_fifo_empty),
                                       .awid1_id        (awid1_id[C_AXI_ID_WIDTH-1:0]),
                                       .awid1_fifo_empty(awid1_fifo_empty),
                                       .bdat0_dout      (bdat0_dout[1:0]),
                                       .bdat0_empty     (bdat0_empty),
                                       .bdat1_dout      (bdat1_dout[1:0]),
                                       .bdat1_empty     (bdat1_empty));

   rpc2_ctrl_axi_rd_data_channel
     #(C_AXI_ID_WIDTH,
       C_AXI_DATA_WIDTH)
   rpc2_ctrl_rd_data_channel (/*AUTOINST*/
                              // Outputs
                              .AXI_RID          (AXI_RID[C_AXI_ID_WIDTH-1:0]),
                              .AXI_RDATA        (AXI_RDATA[C_AXI_DATA_WIDTH-1:0]),
                              .AXI_RRESP        (AXI_RRESP[1:0]),
                              .AXI_RLAST        (AXI_RLAST),
                              .AXI_RVALID       (AXI_RVALID),
                              .axi2ip_data_ready(axi2ip_data_ready),
                              .arid_fifo_rd_en  (arid_fifo_rd_en),
                              .rdat_rd_en       (rdat_rd_en),
                              .rdat_wr_en       (rdat_wr_en),
                              .rdat_din         (rdat_din[RDAT_FIFO_DATA_WIDTH-1:0]),
                              .rd_active        (rd_active),
                              // Inputs
                              .clk              (clk),
                              .reset_n          (reset_n),
                              .AXI_RREADY       (AXI_RREADY),
                              .ip_rd_error      (ip_rd_error[1:0]),
                              .ip_data_valid    (ip_data_valid),
                              .ip_data_last     (ip_data_last),
                              .ip_data          (ip_data[C_AXI_DATA_WIDTH-1:0]),
                              .ip_strb          (ip_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                              .arid_id          (arid_id[C_AXI_ID_WIDTH-1:0]),
                              .arid_size        (arid_size[1:0]),
                              .arid_len         (arid_len[7:0]),
                              .arid_strb        (arid_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                              .arid_fifo_empty  (arid_fifo_empty),
                              .ip_clk           (ip_clk),
                              .ip_reset_n       (ip_reset_n),
                              .rdat_dout        (rdat_dout[RDAT_FIFO_DATA_WIDTH-1:0]),
                              .rdat_empty       (rdat_empty),
                              .rdat_full        (rdat_full));

   //----------------------------------------------------------
   // ADR FIFO
   //----------------------------------------------------------
   /* rpc2_ctrl_fifo_synchronizer AUTO_TEMPLATE (
    .rd_ready(adr_rd_ready),
    .wr_ready(adr_wr_ready),
    .rd_rst_n(ip_reset_n),
    .rd_clk(ip_clk),
    .rd_en(adr_rd_en),
    .wr_rst_n(reset_n),
    .wr_clk(clk),
    .wr_en(adr_wr_en),
    .wr_data(adr_din[ADR_FIFO_DATA_WIDTH-1:0]),
    .rd_data(adr_dout[ADR_FIFO_DATA_WIDTH-1:0]),
    );
    */
   rpc2_ctrl_fifo_synchronizer
     #(ADR_FIFO_DATA_WIDTH,
       OUTPUT_REGISTER
       )
   adr_fifo_synchronizer (/*AUTOINST*/
                          // Outputs
                          .rd_data              (adr_dout[ADR_FIFO_DATA_WIDTH-1:0]), // Templated
                          .rd_ready             (adr_rd_ready),  // Templated
                          .wr_ready             (adr_wr_ready),  // Templated
                          // Inputs
                          .rd_clk               (ip_clk),        // Templated
                          .rd_rst_n             (ip_reset_n),    // Templated
                          .rd_en                (adr_rd_en),     // Templated
                          .wr_clk               (clk),           // Templated
                          .wr_rst_n             (reset_n),       // Templated
                          .wr_en                (adr_wr_en),     // Templated
                          .wr_data              (adr_din[ADR_FIFO_DATA_WIDTH-1:0])); // Templated
      
   //---------------------------------------------------------
   // WDAT FIFO
   //---------------------------------------------------------
   /* rpc2_ctrl_dpram_wrapper AUTO_TEMPLATE (
    .rd_clk(ip_clk),
    .rd_rst_n(ip_reset_n),
    .rd_data(wdat@_dout[WDAT_FIFO_DATA_WIDTH-1:0]),
    .empty(wdat@_empty),
    .rd_en(wdat@_rd_en),
    .wr_clk(clk),
    .wr_rst_n(reset_n),
    .wr_en(wdat@_wr_en),
    .wr_data(wdat@_din[WDAT_FIFO_DATA_WIDTH-1:0]),
    .full(wdat@_full),
    .pre_full(wdat@_pre_full),
    .half_full(),
    );
    */
   rpc2_ctrl_dpram_wrapper 
      #(0,   // 0=async_fifo_axi, 1=sync_fifo_axi
        C_WDAT_FIFO_ADDR_BITS,
        WDAT_FIFO_DATA_WIDTH,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        5,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE  // 0=STD, 1=LowLeak
        ) 
   wdat_fifo_wrapper_0 (/*AUTOINST*/
                        // Outputs
                        .rd_data        (wdat0_dout[WDAT_FIFO_DATA_WIDTH-1:0]), // Templated
                        .empty          (wdat0_empty),           // Templated
                        .full           (wdat0_full),            // Templated
                        .pre_full       (wdat0_pre_full),        // Templated
                        .half_full      (),                      // Templated
                        // Inputs
                        .rd_rst_n       (ip_reset_n),            // Templated
                        .rd_clk         (ip_clk),                // Templated
                        .rd_en          (wdat0_rd_en),           // Templated
                        .wr_rst_n       (reset_n),               // Templated
                        .wr_clk         (clk),                   // Templated
                        .wr_en          (wdat0_wr_en),           // Templated
                        .wr_data        (wdat0_din[WDAT_FIFO_DATA_WIDTH-1:0])); // Templated
   rpc2_ctrl_dpram_wrapper 
      #(0,   // 0=async_fifo_axi, 1=sync_fifo_axi
        C_WDAT_FIFO_ADDR_BITS,
        WDAT_FIFO_DATA_WIDTH,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        5,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE  // 0=STD, 1=LowLeak
        ) 
   wdat_fifo_wrapper_1 (/*AUTOINST*/
                        // Outputs
                        .rd_data        (wdat1_dout[WDAT_FIFO_DATA_WIDTH-1:0]), // Templated
                        .empty          (wdat1_empty),           // Templated
                        .full           (wdat1_full),            // Templated
                        .pre_full       (wdat1_pre_full),        // Templated
                        .half_full      (),                      // Templated
                        // Inputs
                        .rd_rst_n       (ip_reset_n),            // Templated
                        .rd_clk         (ip_clk),                // Templated
                        .rd_en          (wdat1_rd_en),           // Templated
                        .wr_rst_n       (reset_n),               // Templated
                        .wr_clk         (clk),                   // Templated
                        .wr_en          (wdat1_wr_en),           // Templated
                        .wr_data        (wdat1_din[WDAT_FIFO_DATA_WIDTH-1:0])); // Templated

   //---------------------------------------------------------
   // BDAT FIFO
   //---------------------------------------------------------
   /* rpc2_ctrl_dpram_wrapper AUTO_TEMPLATE (
    .rd_clk(clk),
    .rd_rst_n(reset_n),
    .rd_data(bdat@_dout[1:0]),
    .empty(bdat@_empty),
    .rd_en(bdat@_rd_en),
    .wr_clk(ip_clk),
    .wr_rst_n(ip_reset_n),
    .wr_en(ip@_wr_done),
    .wr_data(ip@_wr_error[1:0]),
    .full(),
    .pre_full(),
    .half_full(),
    );
    */
   rpc2_ctrl_dpram_wrapper 
      #(0,     // 0=async_fifo_axi, 1=sync_fifo_axi
        C_AW_FIFO_ADDR_BITS,
        2,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        7,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE     // 0=STD, 1=LowLeak
        )
   bdat_fifo_wrapper_0 (/*AUTOINST*/
                        // Outputs
                        .rd_data        (bdat0_dout[1:0]),       // Templated
                        .empty          (bdat0_empty),           // Templated
                        .full           (),                      // Templated
                        .pre_full       (),                      // Templated
                        .half_full      (),                      // Templated
                        // Inputs
                        .rd_rst_n       (reset_n),               // Templated
                        .rd_clk         (clk),                   // Templated
                        .rd_en          (bdat0_rd_en),           // Templated
                        .wr_rst_n       (ip_reset_n),            // Templated
                        .wr_clk         (ip_clk),                // Templated
                        .wr_en          (ip0_wr_done),           // Templated
                        .wr_data        (ip0_wr_error[1:0]));    // Templated
   rpc2_ctrl_dpram_wrapper 
      #(0,     // 0=async_fifo_axi, 1=sync_fifo_axi
        C_AW_FIFO_ADDR_BITS,
        2,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        7,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE     // 0=STD, 1=LowLeak
        )
   bdat_fifo_wrapper_1 (/*AUTOINST*/
                        // Outputs
                        .rd_data        (bdat1_dout[1:0]),       // Templated
                        .empty          (bdat1_empty),           // Templated
                        .full           (),                      // Templated
                        .pre_full       (),                      // Templated
                        .half_full      (),                      // Templated
                        // Inputs
                        .rd_rst_n       (reset_n),               // Templated
                        .rd_clk         (clk),                   // Templated
                        .rd_en          (bdat1_rd_en),           // Templated
                        .wr_rst_n       (ip_reset_n),            // Templated
                        .wr_clk         (ip_clk),                // Templated
                        .wr_en          (ip1_wr_done),           // Templated
                        .wr_data        (ip1_wr_error[1:0]));    // Templated
   
   //---------------------------------------------------------
   // RDAT FIFO
   //---------------------------------------------------------
   /* rpc2_ctrl_dpram_wrapper AUTO_TEMPLATE (
    .rd_clk(clk),
    .rd_rst_n(reset_n),
    .rd_data(rdat_dout[RDAT_FIFO_DATA_WIDTH-1:0]),
    .empty(rdat_empty),
    .rd_en(rdat_rd_en),
    .wr_en(rdat_wr_en),
    .wr_data(rdat_din[RDAT_FIFO_DATA_WIDTH-1:0]),
    .full(rdat_full),
    .pre_full(),
    .half_full(),
    .wr_clk(ip_clk),
    .wr_rst_n(ip_reset_n),
    );
    */
    rpc2_ctrl_dpram_wrapper 
      #(0,     // 0=async_fifo_axi, 1=sync_fifo_axi
        C_RDAT_FIFO_ADDR_BITS,
        RDAT_FIFO_DATA_WIDTH,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        6,            // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
        DPRAM_MACRO_TYPE     // 0=STD, 1=LowLeak
        ) 
   rdat_fifo_wrapper (/*AUTOINST*/
                      // Outputs
                      .rd_data          (rdat_dout[RDAT_FIFO_DATA_WIDTH-1:0]), // Templated
                      .empty            (rdat_empty),            // Templated
                      .full             (rdat_full),             // Templated
                      .pre_full         (),                      // Templated
                      .half_full        (),                      // Templated
                      // Inputs
                      .rd_rst_n         (reset_n),               // Templated
                      .rd_clk           (clk),                   // Templated
                      .rd_en            (rdat_rd_en),            // Templated
                      .wr_rst_n         (ip_reset_n),            // Templated
                      .wr_clk           (ip_clk),                // Templated
                      .wr_en            (rdat_wr_en),            // Templated
                      .wr_data          (rdat_din[RDAT_FIFO_DATA_WIDTH-1:0])); // Templated
   
endmodule // rpc2_ctrl_axi_async_channel2
