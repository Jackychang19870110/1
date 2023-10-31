

module rpc2_ctrl_ip (
`ifdef CK2
   ck2_en,
`endif
   /*AUTOARG*/
   // Outputs
   AXIm_AWREADY, AXIm_WREADY, AXIm_BID, AXIm_BRESP, AXIm_BVALID,
   AXIm_ARREADY, AXIm_RID, AXIm_RDATA, AXIm_RRESP, AXIm_RLAST,
   AXIm_RVALID, AXIr_AWREADY, AXIr_WREADY, AXIr_BID, AXIr_BRESP,
   AXIr_BVALID, AXIr_ARREADY, AXIr_RID, AXIr_RDATA, AXIr_RRESP,
   AXIr_RLAST, AXIr_RVALID, reset_n, cs0n_en, cs1n_en, csn_d, ck_en,
   dq_io_tri, dq_out_en, dq_out0, dq_out1, wds_en, wds0, wds1,
   rwds_io_tri, hwreset_n, wp_n, IENOn, GPO,
   // Inputs
   AXIm_ACLK, AXIm_ARESETN, AXIm_AWID, AXIm_AWADDR, AXIm_AWLEN,
   AXIm_AWSIZE, AXIm_AWBURST, AXIm_AWVALID, AXIm_WDATA, AXIm_WSTRB,
   AXIm_WID, AXIm_WLAST, AXIm_WVALID, AXIm_BREADY, AXIm_ARID,
   AXIm_ARADDR, AXIm_ARLEN, AXIm_ARSIZE, AXIm_ARBURST, AXIm_ARVALID,
   AXIm_RREADY, AXIr_ACLK, AXIr_ARESETN, AXIr_AWID, AXIr_AWADDR,
   AXIr_AWLEN, AXIr_AWSIZE, AXIr_AWBURST, AXIr_AWVALID, AXIr_WDATA,
   AXIr_WSTRB, AXIr_WLAST, AXIr_WVALID, AXIr_BREADY, AXIr_ARID,
   AXIr_ARADDR, AXIr_ARLEN, AXIr_ARSIZE, AXIr_ARBURST, AXIr_ARVALID,
   AXIr_RREADY, clk, rds_clk, dq_in, rwds_in, int_n, rsto_n,
//// new for roshan controller////////////
   xl_ck,xl_ce,xl_dqs,xl_dq,clk90
//// new for roshan controller////////////   
   );
   
//// new for roshan controller////////////   

          
   output         xl_ck;
   output         xl_ce;
   inout          xl_dqs;   
   inout  [7:0]   xl_dq;

   input clk90;    
//// new for roshan controller////////////
//   wire           xl_ck,
//   wire           xl_ce,
//   wire           xl_dqs,   
//   wire  [7:0]    xl_dq,
//
//   wire           clk90; 
   
   
   
   
   
   parameter C_AXI_MEM_ID_WIDTH   = 'd4;
   parameter C_AXI_MEM_ADDR_WIDTH = 'd32;
   parameter C_AXI_MEM_DATA_WIDTH = 'd32;
   parameter C_AXI_MEM_LEN_WIDTH  = 'd4;
   parameter C_AXI_MEM_DATA_INTERLEAVING = 1'b1;
   parameter C_MEM_AW_FIFO_ADDR_BITS  = 'd4;
   parameter C_MEM_AR_FIFO_ADDR_BITS  = 'd4;
   parameter C_MEM_WDAT_FIFO_ADDR_BITS = 'd7;
   parameter C_MEM_RDAT_FIFO_ADDR_BITS = 'd7;

   parameter C_AXI_REG_ID_WIDTH   = 'd4;
   parameter C_AXI_REG_ADDR_WIDTH = 'd32;
   parameter C_AXI_REG_DATA_WIDTH = 'd32;
   parameter C_AXI_REG_LEN_WIDTH  = 'd4;
   parameter C_AXI_REG_BASEADDR = 32'h00000000;
   parameter C_AXI_REG_HIGHADDR = 32'h0000004F;
   
   parameter C_RX_FIFO_ADDR_BITS = 'd8;
   parameter DPRAM_MACRO = 0;       // 0=Macro is not used, 1=Macro is used
   parameter DPRAM_MACRO_TYPE = 0;  // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)

   parameter   integer INIT_CLOCK_HZ = 200_000000;
   parameter   INIT_DRIVE_STRENGTH = 50;
       
   // Global System Signals for MEM
   input                                AXIm_ACLK;
   input                                AXIm_ARESETN;
   
   // Write Address Channel Signals for MEM
   input [C_AXI_MEM_ID_WIDTH-1:0]       AXIm_AWID;
   input [C_AXI_MEM_ADDR_WIDTH-1:0]     AXIm_AWADDR;
   input [C_AXI_MEM_LEN_WIDTH-1:0]      AXIm_AWLEN;
   input [2:0]                          AXIm_AWSIZE;
   input [1:0]                          AXIm_AWBURST;
   input                                AXIm_AWVALID;
   output                               AXIm_AWREADY;
   
   // Write Data Channel Signals for MEM
   input [C_AXI_MEM_DATA_WIDTH-1:0]     AXIm_WDATA;
   input [(C_AXI_MEM_DATA_WIDTH/8)-1:0] AXIm_WSTRB;
   input [C_AXI_MEM_ID_WIDTH-1:0]       AXIm_WID;
   input                                AXIm_WLAST;
   input                                AXIm_WVALID;
   output                               AXIm_WREADY;
   
   // Write Response Channel Signals for MEM
   output [C_AXI_MEM_ID_WIDTH-1:0]      AXIm_BID;
   output [1:0]                         AXIm_BRESP;
   output                               AXIm_BVALID;
   input                                AXIm_BREADY;

   // Read Address Channel Signals for MEM
   input [C_AXI_MEM_ID_WIDTH-1:0]       AXIm_ARID;
   input [C_AXI_MEM_ADDR_WIDTH-1:0]     AXIm_ARADDR;
   input [C_AXI_MEM_LEN_WIDTH-1:0]      AXIm_ARLEN;
   input [2:0]                          AXIm_ARSIZE;
   input [1:0]                          AXIm_ARBURST;
   input                                AXIm_ARVALID;
   output                               AXIm_ARREADY;
   
   // Read Data Channel Signals for MEM
   output [C_AXI_MEM_ID_WIDTH-1:0]      AXIm_RID;
   output [C_AXI_MEM_DATA_WIDTH-1:0]    AXIm_RDATA;
   output [1:0]                         AXIm_RRESP;
   output                               AXIm_RLAST;
   output                               AXIm_RVALID;
   input                                AXIm_RREADY;
   
   // Global System Signals for REG
   input                                AXIr_ACLK;
   input                                AXIr_ARESETN;

   // Write Address Channel Signals for REG
   input [C_AXI_REG_ID_WIDTH-1:0]       AXIr_AWID;
   input [C_AXI_REG_ADDR_WIDTH-1:0]     AXIr_AWADDR;
   input [C_AXI_REG_LEN_WIDTH-1:0]      AXIr_AWLEN;
   input [2:0]                          AXIr_AWSIZE;
   input [1:0]                          AXIr_AWBURST;
   input                                AXIr_AWVALID;
   output                               AXIr_AWREADY;
   
   // Write Data Channel Signals for REG
   input [C_AXI_REG_DATA_WIDTH-1:0]     AXIr_WDATA;
   input [(C_AXI_REG_DATA_WIDTH/8)-1:0] AXIr_WSTRB;
   input                                AXIr_WLAST;
   input                                AXIr_WVALID;
   output                               AXIr_WREADY;
   
   // Write Response Channel Signals for REG
   output [C_AXI_REG_ID_WIDTH-1:0]      AXIr_BID;
   output [1:0]                         AXIr_BRESP;
   output                               AXIr_BVALID;
   input                                AXIr_BREADY;
   
   // Read Address Channel Signals for REG
   input [C_AXI_REG_ID_WIDTH-1:0]       AXIr_ARID;
   input [C_AXI_REG_ADDR_WIDTH-1:0]     AXIr_ARADDR;
   input [C_AXI_REG_LEN_WIDTH-1:0]      AXIr_ARLEN;
   input [2:0]                          AXIr_ARSIZE;
   input [1:0]                          AXIr_ARBURST;
   input                                AXIr_ARVALID;
   output                               AXIr_ARREADY;
   
   // Read Data Channel Signals for REG
   output [C_AXI_REG_ID_WIDTH-1:0]      AXIr_RID;
   output [C_AXI_REG_DATA_WIDTH-1:0]    AXIr_RDATA;
   output [1:0]                         AXIr_RRESP;
   output                               AXIr_RLAST;
   output                               AXIr_RVALID;
   input                                AXIr_RREADY; 
   
   // RPC IO
   output                               reset_n;   
   input                                clk;
   input                                rds_clk;
   input [7:0]                          dq_in;
   input                                rwds_in;
   output                               cs0n_en;
   output                               cs1n_en;
   output                               csn_d;
   output                               ck_en;
   output                               dq_io_tri;
   output                               dq_out_en;
   output [7:0]                         dq_out0;
   output [7:0]                         dq_out1;
   output                               wds_en;
   output                               wds0;
   output                               wds1;
   output                               rwds_io_tri;
`ifdef CK2
   output                               ck2_en;
`endif
   output                               hwreset_n;
   output                               wp_n;
   input                                int_n;
   input                                rsto_n;
   
   output                               IENOn;
   output [1:0]                         GPO;

   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 lbr_reg_loopback;       // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [7:0]           mbr0_reg_a;             // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [7:0]           mbr1_reg_a;             // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr0_reg_acs;           // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr0_reg_crt;           // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   
   wire                 mcr0_reg_devtype;       // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr0_reg_gb_rst;       // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr0_reg_mem_init;
   
   wire                 mcr0_reg_men;           // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [8:0]           mcr0_reg_mlen;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr0_reg_tcmo;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [1:0]           mcr0_reg_wrapsize;      // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr1_reg_acs;           // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr1_reg_crt;           // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr1_reg_devtype;       // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr1_reg_men;           // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [8:0]           mcr1_reg_mlen;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mcr1_reg_tcmo;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [1:0]           mcr1_reg_wrapsize;      // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 mem_rd_active;          // From rpc2_ctrl_sync_to_regclk of rpc2_ctrl_sync_to_regclk.v
   wire                 mem_rd_dec_status;      // From rpc2_ctrl_sync_to_regclk of rpc2_ctrl_sync_to_regclk.v
   wire                 mem_rd_rsto_status;     // From rpc2_ctrl_sync_to_regclk of rpc2_ctrl_sync_to_regclk.v
   wire                 mem_rd_slv_status;      // From rpc2_ctrl_sync_to_regclk of rpc2_ctrl_sync_to_regclk.v
   wire                 mem_rd_stall_status;    // From rpc2_ctrl_sync_to_regclk of rpc2_ctrl_sync_to_regclk.v
   wire                 mem_wr_active;          // From rpc2_ctrl_sync_to_regclk of rpc2_ctrl_sync_to_regclk.v
   wire                 mem_wr_dec_status;      // From rpc2_ctrl_sync_to_regclk of rpc2_ctrl_sync_to_regclk.v
   wire                 mem_wr_rsto_status;     // From rpc2_ctrl_sync_to_regclk of rpc2_ctrl_sync_to_regclk.v
   wire                 mem_wr_slv_status;      // From rpc2_ctrl_sync_to_regclk of rpc2_ctrl_sync_to_regclk.v
   wire [3:0]           mtr0_reg_ltcy;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr0_reg_rcsh;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr0_reg_rcshi;         // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr0_reg_rcss;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr0_reg_wcsh;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr0_reg_wcshi;         // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr0_reg_wcss;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr1_reg_ltcy;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr1_reg_rcsh;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr1_reg_rcshi;         // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr1_reg_rcss;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr1_reg_wcsh;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr1_reg_wcshi;         // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire [3:0]           mtr1_reg_wcss;          // From rpc2_ctrl_reg of rpc2_ctrl_reg.v
   wire                 rd_active;              // From rpc2_ctrl_mem of rpc2_ctrl_mem.v
   wire                 rd_dec_status;          // From rpc2_ctrl_mem of rpc2_ctrl_mem.v
   wire                 rd_rsto_status;         // From rpc2_ctrl_mem of rpc2_ctrl_mem.v
   wire                 rd_slv_status;          // From rpc2_ctrl_mem of rpc2_ctrl_mem.v
   wire                 rd_stall_status;        // From rpc2_ctrl_mem of rpc2_ctrl_mem.v
   wire                 reg_crt0;               // From rpc2_ctrl_sync_to_memclk of rpc2_ctrl_sync_to_memclk.v
   wire                 reg_crt1;               // From rpc2_ctrl_sync_to_memclk of rpc2_ctrl_sync_to_memclk.v
   wire                 reg_lbr;                // From rpc2_ctrl_sync_to_memclk of rpc2_ctrl_sync_to_memclk.v
   wire                 reg_max_len_en0;        // From rpc2_ctrl_sync_to_memclk of rpc2_ctrl_sync_to_memclk.v
   wire                 reg_max_len_en1;        // From rpc2_ctrl_sync_to_memclk of rpc2_ctrl_sync_to_memclk.v
   wire [8:0]           reg_max_length0;        // From rpc2_ctrl_sync_to_memclk of rpc2_ctrl_sync_to_memclk.v
   wire [8:0]           reg_max_length1;        // From rpc2_ctrl_sync_to_memclk of rpc2_ctrl_sync_to_memclk.v
   wire [1:0]           reg_rd_trans_alloc;     // From rpc2_ctrl_sync_to_axiclk of rpc2_ctrl_sync_to_axiclk.v
   wire [1:0]           reg_wr_trans_alloc;     // From rpc2_ctrl_sync_to_axiclk of rpc2_ctrl_sync_to_axiclk.v
   wire                 wr_active;              // From rpc2_ctrl_mem of rpc2_ctrl_mem.v
   wire                 wr_dec_status;          // From rpc2_ctrl_mem of rpc2_ctrl_mem.v
   wire                 wr_rsto_status;         // From rpc2_ctrl_mem of rpc2_ctrl_mem.v
   wire                 wr_slv_status;          // From rpc2_ctrl_mem of rpc2_ctrl_mem.v
   // End of automatics

   /*AUTOINPUT*/
   /*AUTOOUTPUT*/
   wire                 reg_acs0;  // asymmetric cache support
   wire                 reg_acs1;


   wire                 reg_dt0;   // device type
   wire                 reg_gb_rst;   // global reset 
   wire                 reg_mem_init;   
   
   wire                 reg_dt1;
   wire [7:0]           reg_mbr0;  // memory base register address[31:24]
   wire [7:0]           reg_mbr1;
   wire                 reg_tco0;  // tc option
   wire                 reg_tco1;
   wire [1:0]           reg_wrap_size0; // wrap size
   wire [1:0]           reg_wrap_size1;

   wire [3:0]           reg_latency0;
   wire [3:0]           reg_latency1;
   wire [3:0]           reg_rd_cshi0;
   wire [3:0]           reg_rd_cshi1;
   wire [3:0]           reg_rd_css0;
   wire [3:0]           reg_rd_css1;
   wire [3:0]           reg_rd_csh0;
   wire [3:0]           reg_rd_csh1;
   wire [3:0]           reg_wr_cshi0;
   wire [3:0]           reg_wr_cshi1;
   wire [3:0]           reg_wr_css0;
   wire [3:0]           reg_wr_css1;
   wire [3:0]           reg_wr_csh0;
   wire [3:0]           reg_wr_csh1;
   wire [1:0]           tar_reg_rta;
   wire [1:0]           tar_reg_wta;
   
   assign hwreset_n = AXIm_ARESETN;  
   
   //------------------------------------------------------------------
   // Memory 
   //------------------------------------------------------------------
   /* rpc2_ctrl_mem AUTO_TEMPLATE (
    .AXI_AWREADY(AXIm_AWREADY),
    .AXI_WREADY(AXIm_WREADY),
    .AXI_BID(AXIm_BID[C_AXI_MEM_ID_WIDTH-1:0]),
    .AXI_BRESP(AXIm_BRESP[1:0]),
    .AXI_BVALID(AXIm_BVALID),
    .AXI_ARREADY(AXIm_ARREADY),
    .AXI_RID(AXIm_RID[C_AXI_MEM_ID_WIDTH-1:0]),
    .AXI_RDATA(AXIm_RDATA[C_AXI_MEM_DATA_WIDTH-1:0]),
    .AXI_RRESP(AXIm_RRESP[1:0]),
    .AXI_RLAST(AXIm_RLAST),
    .AXI_RVALID(AXIm_RVALID),
    .AXI_ACLK(AXIm_ACLK),
    .AXI_ARESETN(AXIm_ARESETN),
    .AXI_AWID(AXIm_AWID[C_AXI_MEM_ID_WIDTH-1:0]),
    .AXI_AWADDR(AXIm_AWADDR[C_AXI_MEM_ADDR_WIDTH-1:0]),
    .AXI_AWLEN(AXIm_AWLEN[C_AXI_MEM_LEN_WIDTH-1:0]),
    .AXI_AWSIZE(AXIm_AWSIZE[2:0]),
    .AXI_AWBURST(AXIm_AWBURST[1:0]),
    .AXI_AWVALID(AXIm_AWVALID),
    .AXI_WDATA(AXIm_WDATA[C_AXI_MEM_DATA_WIDTH-1:0]),
    .AXI_WSTRB(AXIm_WSTRB[(C_AXI_MEM_DATA_WIDTH/8)-1:0]),
    .AXI_WLAST(AXIm_WLAST),
    .AXI_WVALID(AXIm_WVALID),
    .AXI_WID(AXIm_WID),
    .AXI_BREADY(AXIm_BREADY),
    .AXI_ARID(AXIm_ARID[C_AXI_MEM_ID_WIDTH-1:0]),
    .AXI_ARADDR(AXIm_ARADDR[C_AXI_MEM_ADDR_WIDTH-1:0]),
    .AXI_ARLEN(AXIm_ARLEN[C_AXI_MEM_LEN_WIDTH-1:0]),
    .AXI_ARSIZE(AXIm_ARSIZE[2:0]),
    .AXI_ARBURST(AXIm_ARBURST[1:0]),
    .AXI_ARVALID(AXIm_ARVALID),
    .AXI_RREADY(AXIm_RREADY),
    .reg_rd_max_len_en0(reg_max_len_en0),
    .reg_rd_max_len_en1(reg_max_len_en1),
    .reg_rd_max_length0(reg_max_length0[8:0]),
    .reg_rd_max_length1(reg_max_length1[8:0]),
    .reg_wr_max_len_en0(reg_max_len_en0),
    .reg_wr_max_len_en1(reg_max_len_en1),
    .reg_wr_max_length0(reg_max_length0[8:0]),
    .reg_wr_max_length1(reg_max_length1[8:0]),
    );
    */
   rpc2_ctrl_mem
     #(C_AXI_MEM_ID_WIDTH,
       C_AXI_MEM_ADDR_WIDTH,
       C_AXI_MEM_DATA_WIDTH,
       C_AXI_MEM_LEN_WIDTH,
       C_MEM_AW_FIFO_ADDR_BITS,
       C_MEM_AR_FIFO_ADDR_BITS,
       C_MEM_WDAT_FIFO_ADDR_BITS,
       C_MEM_RDAT_FIFO_ADDR_BITS,
       C_RX_FIFO_ADDR_BITS,
       C_AXI_MEM_DATA_INTERLEAVING,
       DPRAM_MACRO,
       DPRAM_MACRO_TYPE,
       INIT_CLOCK_HZ,
       INIT_DRIVE_STRENGTH       
       )
   rpc2_ctrl_mem (
                  `ifdef CK2
                  .ck2_en               (ck2_en),
                  `endif
                  /*AUTOINST*/
                  // Outputs
                  .AXI_AWREADY          (AXIm_AWREADY),          // Templated
                  .AXI_WREADY           (AXIm_WREADY),           // Templated
                  .AXI_BID              (AXIm_BID[C_AXI_MEM_ID_WIDTH-1:0]), // Templated
                  .AXI_BRESP            (AXIm_BRESP[1:0]),       // Templated
                  .AXI_BVALID           (AXIm_BVALID),           // Templated
                  .AXI_ARREADY          (AXIm_ARREADY),          // Templated
                  .AXI_RID              (AXIm_RID[C_AXI_MEM_ID_WIDTH-1:0]), // Templated
                  .AXI_RDATA            (AXIm_RDATA[C_AXI_MEM_DATA_WIDTH-1:0]), // Templated
                  .AXI_RRESP            (AXIm_RRESP[1:0]),       // Templated
                  .AXI_RLAST            (AXIm_RLAST),            // Templated
                  .AXI_RVALID           (AXIm_RVALID),           // Templated
                  .reset_n              (reset_n),
                  .cs0n_en              (cs0n_en),
                  .cs1n_en              (cs1n_en),
                  .csn_d                (csn_d),
                  .ck_en                (ck_en),
                  .dq_io_tri            (dq_io_tri),
                  .dq_out_en            (dq_out_en),
                  .dq_out0              (dq_out0[7:0]),
                  .dq_out1              (dq_out1[7:0]),
                  .wds_en               (wds_en),
                  .wds0                 (wds0),
                  .wds1                 (wds1),
                  .rwds_io_tri          (rwds_io_tri),
                  .rd_active            (rd_active),
                  .wr_active            (wr_active),
                  .wr_rsto_status       (wr_rsto_status),
                  .wr_slv_status        (wr_slv_status),
                  .wr_dec_status        (wr_dec_status),
                  .rd_stall_status      (rd_stall_status),
                  .rd_rsto_status       (rd_rsto_status),
                  .rd_slv_status        (rd_slv_status),
                  .rd_dec_status        (rd_dec_status),
                  // Inputs
                  .AXI_ACLK             (AXIm_ACLK),             // Templated
                  .AXI_ARESETN          (AXIm_ARESETN),          // Templated
                  .AXI_AWID             (AXIm_AWID[C_AXI_MEM_ID_WIDTH-1:0]), // Templated
                  .AXI_AWADDR           (AXIm_AWADDR[C_AXI_MEM_ADDR_WIDTH-1:0]), // Templated
                  .AXI_AWLEN            (AXIm_AWLEN[C_AXI_MEM_LEN_WIDTH-1:0]), // Templated
                  .AXI_AWSIZE           (AXIm_AWSIZE[2:0]),      // Templated
                  .AXI_AWBURST          (AXIm_AWBURST[1:0]),     // Templated
                  .AXI_AWVALID          (AXIm_AWVALID),          // Templated
                  .AXI_WDATA            (AXIm_WDATA[C_AXI_MEM_DATA_WIDTH-1:0]), // Templated
                  .AXI_WSTRB            (AXIm_WSTRB[(C_AXI_MEM_DATA_WIDTH/8)-1:0]), // Templated
                  .AXI_WLAST            (AXIm_WLAST),            // Templated
                  .AXI_WVALID           (AXIm_WVALID),           // Templated
                  .AXI_WID              (AXIm_WID),              // Templated
                  .AXI_BREADY           (AXIm_BREADY),           // Templated
                  .AXI_ARID             (AXIm_ARID[C_AXI_MEM_ID_WIDTH-1:0]), // Templated
                  .AXI_ARADDR           (AXIm_ARADDR[C_AXI_MEM_ADDR_WIDTH-1:0]), // Templated
                  .AXI_ARLEN            (AXIm_ARLEN[C_AXI_MEM_LEN_WIDTH-1:0]), // Templated
                  .AXI_ARSIZE           (AXIm_ARSIZE[2:0]),      // Templated
                  .AXI_ARBURST          (AXIm_ARBURST[1:0]),     // Templated
                  .AXI_ARVALID          (AXIm_ARVALID),          // Templated
                  .AXI_RREADY           (AXIm_RREADY),           // Templated
                  .clk                  (clk),
                  .rds_clk              (rds_clk),
                  .dq_in                (dq_in[7:0]),
                  .rsto_n               (rsto_n),
                  .rwds_in              (rwds_in),
                  .reg_wrap_size0       (reg_wrap_size0[1:0]),
                  .reg_wrap_size1       (reg_wrap_size1[1:0]),
                  .reg_acs0             (reg_acs0),
                  .reg_acs1             (reg_acs1),
                  .reg_mbr0             (reg_mbr0[7:0]),
                  .reg_mbr1             (reg_mbr1[7:0]),
                  .reg_tco0             (reg_tco0),
                  .reg_tco1             (reg_tco1),
                  
                  .reg_dt0              (reg_dt0),
                  .reg_gb_rst           (reg_gb_rst),
                  .reg_mem_init         (reg_mem_init),
                 
                  
                  .reg_dt1              (reg_dt1),
                  .reg_crt0             (reg_crt0),
                  .reg_crt1             (reg_crt1),
                  .reg_lbr              (reg_lbr),
                  .reg_latency0         (reg_latency0[3:0]),
                  .reg_latency1         (reg_latency1[3:0]),
                  .reg_rd_cshi0         (reg_rd_cshi0[3:0]),
                  .reg_rd_cshi1         (reg_rd_cshi1[3:0]),
                  .reg_rd_css0          (reg_rd_css0[3:0]),
                  .reg_rd_css1          (reg_rd_css1[3:0]),
                  .reg_rd_csh0          (reg_rd_csh0[3:0]),
                  .reg_rd_csh1          (reg_rd_csh1[3:0]),
                  .reg_wr_cshi0         (reg_wr_cshi0[3:0]),
                  .reg_wr_cshi1         (reg_wr_cshi1[3:0]),
                  .reg_wr_css0          (reg_wr_css0[3:0]),
                  .reg_wr_css1          (reg_wr_css1[3:0]),
                  .reg_wr_csh0          (reg_wr_csh0[3:0]),
                  .reg_wr_csh1          (reg_wr_csh1[3:0]),
                  .reg_rd_max_len_en0   (reg_max_len_en0),       // Templated
                  .reg_rd_max_len_en1   (reg_max_len_en1),       // Templated
                  .reg_rd_max_length0   (reg_max_length0[8:0]),  // Templated
                  .reg_rd_max_length1   (reg_max_length1[8:0]),  // Templated
                  .reg_wr_max_len_en0   (reg_max_len_en0),       // Templated
                  .reg_wr_max_len_en1   (reg_max_len_en1),       // Templated
                  .reg_wr_max_length0   (reg_max_length0[8:0]),  // Templated
                  .reg_wr_max_length1   (reg_max_length1[8:0]),  // Templated
                  .reg_rd_trans_alloc   (reg_rd_trans_alloc[1:0]),
                  .reg_wr_trans_alloc   (reg_wr_trans_alloc[1:0]),
                  
//// new for roshan controller////////////                         
                        .xl_ck          (xl_ck),
                        .xl_ce          (xl_ce),
                        .xl_dqs         (xl_dqs),
                        .xl_dq          (xl_dq),
                        .clk90         (clk90)  
//// new for roshan controller////////////                   
                  
                  
                  );
   
   //------------------------------------------------------------------
   // Register 
   //------------------------------------------------------------------
   /* rpc2_ctrl_reg AUTO_TEMPLATE (
    .AXI_AWREADY(AXIr_AWREADY),
    .AXI_WREADY(AXIr_WREADY),
    .AXI_BID(AXIr_BID[C_AXI_REG_ID_WIDTH-1:0]),
    .AXI_BRESP(AXIr_BRESP[1:0]),
    .AXI_BVALID(AXIr_BVALID),
    .AXI_ARREADY(AXIr_ARREADY),
    .AXI_RID(AXIr_RID[C_AXI_REG_ID_WIDTH-1:0]),
    .AXI_RDATA(AXIr_RDATA[C_AXI_REG_DATA_WIDTH-1:0]),
    .AXI_RRESP(AXIr_RRESP[1:0]),
    .AXI_RLAST(AXIr_RLAST),
    .AXI_RVALID(AXIr_RVALID),
    .AXI_ACLK(AXIr_ACLK),
    .AXI_ARESETN(AXIr_ARESETN),
    .AXI_AWID(AXIr_AWID[C_AXI_REG_ID_WIDTH-1:0]),
    .AXI_AWADDR(AXIr_AWADDR[C_AXI_REG_ADDR_WIDTH-1:0]),
    .AXI_AWLEN(AXIr_AWLEN[C_AXI_REG_LEN_WIDTH-1:0]),
    .AXI_AWSIZE(AXIr_AWSIZE[2:0]),
    .AXI_AWBURST(AXIr_AWBURST[1:0]),
    .AXI_AWVALID(AXIr_AWVALID),
    .AXI_WDATA(AXIr_WDATA[C_AXI_REG_DATA_WIDTH-1:0]),
    .AXI_WSTRB(AXIr_WSTRB[(C_AXI_REG_DATA_WIDTH/8)-1:0]),
    .AXI_WLAST(AXIr_WLAST),
    .AXI_WVALID(AXIr_WVALID),
    .AXI_BREADY(AXIr_BREADY),
    .AXI_ARID(AXIr_ARID[C_AXI_REG_ID_WIDTH-1:0]),
    .AXI_ARADDR(AXIr_ARADDR[C_AXI_REG_ADDR_WIDTH-1:0]),
    .AXI_ARLEN(AXIr_ARLEN[C_AXI_REG_LEN_WIDTH-1:0]),
    .AXI_ARSIZE(AXIr_ARSIZE[2:0]),
    .AXI_ARBURST(AXIr_ARBURST[1:0]),
    .AXI_ARVALID(AXIr_ARVALID),
    .AXI_RREADY(AXIr_RREADY),
    );
    */
   rpc2_ctrl_reg
     #(C_AXI_REG_ID_WIDTH,
       C_AXI_REG_ADDR_WIDTH,
       C_AXI_REG_DATA_WIDTH,
       C_AXI_REG_LEN_WIDTH,
       C_AXI_REG_BASEADDR,
       C_AXI_REG_HIGHADDR)
     rpc2_ctrl_reg (/*AUTOINST*/
                    // Outputs
                    .AXI_AWREADY        (AXIr_AWREADY),          // Templated
                    .AXI_WREADY         (AXIr_WREADY),           // Templated
                    .AXI_BID            (AXIr_BID[C_AXI_REG_ID_WIDTH-1:0]), // Templated
                    .AXI_BRESP          (AXIr_BRESP[1:0]),       // Templated
                    .AXI_BVALID         (AXIr_BVALID),           // Templated
                    .AXI_ARREADY        (AXIr_ARREADY),          // Templated
                    .AXI_RID            (AXIr_RID[C_AXI_REG_ID_WIDTH-1:0]), // Templated
                    .AXI_RDATA          (AXIr_RDATA[C_AXI_REG_DATA_WIDTH-1:0]), // Templated
                    .AXI_RRESP          (AXIr_RRESP[1:0]),       // Templated
                    .AXI_RLAST          (AXIr_RLAST),            // Templated
                    .AXI_RVALID         (AXIr_RVALID),           // Templated
                    .mcr0_reg_wrapsize  (mcr0_reg_wrapsize[1:0]),
                    .mcr1_reg_wrapsize  (mcr1_reg_wrapsize[1:0]),
                    .mcr0_reg_acs       (mcr0_reg_acs),
                    .mcr1_reg_acs       (mcr1_reg_acs),
                    .mbr0_reg_a         (mbr0_reg_a[7:0]),
                    .mbr1_reg_a         (mbr1_reg_a[7:0]),
                    .mcr0_reg_tcmo      (mcr0_reg_tcmo),
                    .mcr1_reg_tcmo      (mcr1_reg_tcmo),
                    
                    .mcr0_reg_devtype   (mcr0_reg_devtype),
                    .mcr0_reg_gb_rst   (mcr0_reg_gb_rst),
                    .mcr0_reg_mem_init   (mcr0_reg_mem_init),
                    
                    
                    .mcr1_reg_devtype   (mcr1_reg_devtype),
                    .mcr0_reg_crt       (mcr0_reg_crt),
                    .mcr1_reg_crt       (mcr1_reg_crt),
                    .mtr0_reg_rcshi     (mtr0_reg_rcshi[3:0]),
                    .mtr1_reg_rcshi     (mtr1_reg_rcshi[3:0]),
                    .mtr0_reg_wcshi     (mtr0_reg_wcshi[3:0]),
                    .mtr1_reg_wcshi     (mtr1_reg_wcshi[3:0]),
                    .mtr0_reg_rcss      (mtr0_reg_rcss[3:0]),
                    .mtr1_reg_rcss      (mtr1_reg_rcss[3:0]),
                    .mtr0_reg_wcss      (mtr0_reg_wcss[3:0]),
                    .mtr1_reg_wcss      (mtr1_reg_wcss[3:0]),
                    .mtr0_reg_rcsh      (mtr0_reg_rcsh[3:0]),
                    .mtr1_reg_rcsh      (mtr1_reg_rcsh[3:0]),
                    .mtr0_reg_wcsh      (mtr0_reg_wcsh[3:0]),
                    .mtr1_reg_wcsh      (mtr1_reg_wcsh[3:0]),
                    .mtr0_reg_ltcy      (mtr0_reg_ltcy[3:0]),
                    .mtr1_reg_ltcy      (mtr1_reg_ltcy[3:0]),
                    .lbr_reg_loopback   (lbr_reg_loopback),
                    .mcr0_reg_mlen      (mcr0_reg_mlen[8:0]),
                    .mcr1_reg_mlen      (mcr1_reg_mlen[8:0]),
                    .mcr0_reg_men       (mcr0_reg_men),
                    .mcr1_reg_men       (mcr1_reg_men),
                    .tar_reg_rta        (tar_reg_rta[1:0]),
                    .tar_reg_wta        (tar_reg_wta[1:0]),
                    .wp_n               (wp_n),
                    .IENOn              (IENOn),
                    .GPO                (GPO[1:0]),
                    // Inputs
                    .AXI_ACLK           (AXIr_ACLK),             // Templated
                    .AXI_ARESETN        (AXIr_ARESETN),          // Templated
                    .AXI_AWID           (AXIr_AWID[C_AXI_REG_ID_WIDTH-1:0]), // Templated
                    .AXI_AWADDR         (AXIr_AWADDR[C_AXI_REG_ADDR_WIDTH-1:0]), // Templated
                    .AXI_AWLEN          (AXIr_AWLEN[C_AXI_REG_LEN_WIDTH-1:0]), // Templated
                    .AXI_AWSIZE         (AXIr_AWSIZE[2:0]),      // Templated
                    .AXI_AWBURST        (AXIr_AWBURST[1:0]),     // Templated
                    .AXI_AWVALID        (AXIr_AWVALID),          // Templated
                    .AXI_WDATA          (AXIr_WDATA[C_AXI_REG_DATA_WIDTH-1:0]), // Templated
                    .AXI_WSTRB          (AXIr_WSTRB[(C_AXI_REG_DATA_WIDTH/8)-1:0]), // Templated
                    .AXI_WLAST          (AXIr_WLAST),            // Templated
                    .AXI_WVALID         (AXIr_WVALID),           // Templated
                    .AXI_BREADY         (AXIr_BREADY),           // Templated
                    .AXI_ARID           (AXIr_ARID[C_AXI_REG_ID_WIDTH-1:0]), // Templated
                    .AXI_ARADDR         (AXIr_ARADDR[C_AXI_REG_ADDR_WIDTH-1:0]), // Templated
                    .AXI_ARLEN          (AXIr_ARLEN[C_AXI_REG_LEN_WIDTH-1:0]), // Templated
                    .AXI_ARSIZE         (AXIr_ARSIZE[2:0]),      // Templated
                    .AXI_ARBURST        (AXIr_ARBURST[1:0]),     // Templated
                    .AXI_ARVALID        (AXIr_ARVALID),          // Templated
                    .AXI_RREADY         (AXIr_RREADY),           // Templated
                    .int_n              (int_n),
                    .mem_rd_active      (mem_rd_active),
                    .mem_wr_active      (mem_wr_active),
                    .mem_wr_rsto_status (mem_wr_rsto_status),
                    .mem_wr_slv_status  (mem_wr_slv_status),
                    .mem_wr_dec_status  (mem_wr_dec_status),
                    .mem_rd_stall_status(mem_rd_stall_status),
                    .mem_rd_rsto_status (mem_rd_rsto_status),
                    .mem_rd_slv_status  (mem_rd_slv_status),
                    .mem_rd_dec_status  (mem_rd_dec_status));

   //------------------------------------------------------------------
   // Sync
   //------------------------------------------------------------------
   rpc2_ctrl_sync_to_memclk
     rpc2_ctrl_sync_to_memclk (/*AUTOINST*/
                               // Outputs
                               .reg_wrap_size0  (reg_wrap_size0[1:0]),
                               .reg_wrap_size1  (reg_wrap_size1[1:0]),
                               .reg_acs0        (reg_acs0),
                               .reg_acs1        (reg_acs1),
                               .reg_mbr0        (reg_mbr0[7:0]),
                               .reg_mbr1        (reg_mbr1[7:0]),
                               .reg_tco0        (reg_tco0),
                               .reg_tco1        (reg_tco1),
                               
                               
                               .reg_dt0         (reg_dt0),
                               .reg_gb_rst      (reg_gb_rst),
                               .reg_mem_init    (reg_mem_init),
                              
                               
                               .reg_dt1         (reg_dt1),
                               .reg_crt0        (reg_crt0),
                               .reg_crt1        (reg_crt1),
                               .reg_lbr         (reg_lbr),
                               .reg_latency0    (reg_latency0[3:0]),
                               .reg_latency1    (reg_latency1[3:0]),
                               .reg_rd_cshi0    (reg_rd_cshi0[3:0]),
                               .reg_rd_cshi1    (reg_rd_cshi1[3:0]),
                               .reg_rd_css0     (reg_rd_css0[3:0]),
                               .reg_rd_css1     (reg_rd_css1[3:0]),
                               .reg_rd_csh0     (reg_rd_csh0[3:0]),
                               .reg_rd_csh1     (reg_rd_csh1[3:0]),
                               .reg_wr_cshi0    (reg_wr_cshi0[3:0]),
                               .reg_wr_cshi1    (reg_wr_cshi1[3:0]),
                               .reg_wr_css0     (reg_wr_css0[3:0]),
                               .reg_wr_css1     (reg_wr_css1[3:0]),
                               .reg_wr_csh0     (reg_wr_csh0[3:0]),
                               .reg_wr_csh1     (reg_wr_csh1[3:0]),
                               .reg_max_length0 (reg_max_length0[8:0]),
                               .reg_max_length1 (reg_max_length1[8:0]),
                               .reg_max_len_en0 (reg_max_len_en0),
                               .reg_max_len_en1 (reg_max_len_en1),
                               // Inputs
                               .clk             (clk),
                               .reset_n         (reset_n),
                               .mcr0_reg_wrapsize(mcr0_reg_wrapsize[1:0]),
                               .mcr1_reg_wrapsize(mcr1_reg_wrapsize[1:0]),
                               .mcr0_reg_acs    (mcr0_reg_acs),
                               .mcr1_reg_acs    (mcr1_reg_acs),
                               .mbr0_reg_a      (mbr0_reg_a[7:0]),
                               .mbr1_reg_a      (mbr1_reg_a[7:0]),
                               .mcr0_reg_tcmo   (mcr0_reg_tcmo),
                               .mcr1_reg_tcmo   (mcr1_reg_tcmo),
                               
                               
                               .mcr0_reg_devtype(mcr0_reg_devtype),
                               .mcr0_reg_gb_rst (mcr0_reg_gb_rst), 
                               .mcr0_reg_mem_init (mcr0_reg_mem_init),
                             
                               
                               .mcr1_reg_devtype(mcr1_reg_devtype),
                               .mcr0_reg_crt    (mcr0_reg_crt),
                               .mcr1_reg_crt    (mcr1_reg_crt),
                               .mtr0_reg_rcshi  (mtr0_reg_rcshi[3:0]),
                               .mtr1_reg_rcshi  (mtr1_reg_rcshi[3:0]),
                               .mtr0_reg_wcshi  (mtr0_reg_wcshi[3:0]),
                               .mtr1_reg_wcshi  (mtr1_reg_wcshi[3:0]),
                               .mtr0_reg_rcss   (mtr0_reg_rcss[3:0]),
                               .mtr1_reg_rcss   (mtr1_reg_rcss[3:0]),
                               .mtr0_reg_wcss   (mtr0_reg_wcss[3:0]),
                               .mtr1_reg_wcss   (mtr1_reg_wcss[3:0]),
                               .mtr0_reg_rcsh   (mtr0_reg_rcsh[3:0]),
                               .mtr1_reg_rcsh   (mtr1_reg_rcsh[3:0]),
                               .mtr0_reg_wcsh   (mtr0_reg_wcsh[3:0]),
                               .mtr1_reg_wcsh   (mtr1_reg_wcsh[3:0]),
                               .mtr0_reg_ltcy   (mtr0_reg_ltcy[3:0]),
                               .mtr1_reg_ltcy   (mtr1_reg_ltcy[3:0]),
                               .lbr_reg_loopback(lbr_reg_loopback),
                               .mcr0_reg_mlen   (mcr0_reg_mlen[8:0]),
                               .mcr1_reg_mlen   (mcr1_reg_mlen[8:0]),
                               .mcr0_reg_men    (mcr0_reg_men),
                               .mcr1_reg_men    (mcr1_reg_men));
   
   rpc2_ctrl_sync_to_regclk
     rpc2_ctrl_sync_to_regclk (/*AUTOINST*/
                               // Outputs
                               .mem_rd_active   (mem_rd_active),
                               .mem_wr_active   (mem_wr_active),
                               .mem_wr_rsto_status(mem_wr_rsto_status),
                               .mem_wr_slv_status(mem_wr_slv_status),
                               .mem_wr_dec_status(mem_wr_dec_status),
                               .mem_rd_stall_status(mem_rd_stall_status),
                               .mem_rd_rsto_status(mem_rd_rsto_status),
                               .mem_rd_slv_status(mem_rd_slv_status),
                               .mem_rd_dec_status(mem_rd_dec_status),
                               // Inputs
                               .AXIr_ACLK       (AXIr_ACLK),
                               .AXIr_ARESETN    (AXIr_ARESETN),
                               .rd_active       (rd_active),
                               .wr_active       (wr_active),
                               .wr_rsto_status  (wr_rsto_status),
                               .wr_slv_status   (wr_slv_status),
                               .wr_dec_status   (wr_dec_status),
                               .rd_stall_status (rd_stall_status),
                               .rd_rsto_status  (rd_rsto_status),
                               .rd_slv_status   (rd_slv_status),
                               .rd_dec_status   (rd_dec_status));

   rpc2_ctrl_sync_to_axiclk
     rpc2_ctrl_sync_to_axiclk (/*AUTOINST*/
                               // Outputs
                               .reg_rd_trans_alloc(reg_rd_trans_alloc[1:0]),
                               .reg_wr_trans_alloc(reg_wr_trans_alloc[1:0]),
                               // Inputs
                               .AXIm_ACLK       (AXIm_ACLK),
                               .AXIm_ARESETN    (AXIm_ARESETN),
                               .tar_reg_rta     (tar_reg_rta[1:0]),
                               .tar_reg_wta     (tar_reg_wta[1:0]));

endmodule // rpc2_ctrl_ip
