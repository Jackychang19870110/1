
module rpc2_ctrl_mem (

   /*AUTOARG*/
   // Outputs
   AXI_AWREADY, AXI_WREADY, AXI_BID, AXI_BRESP, AXI_BVALID,
   AXI_ARREADY, AXI_RID, AXI_RDATA, AXI_RRESP, AXI_RLAST, AXI_RVALID,
   reset_n, cs0n_en, cs1n_en, csn_d, ck_en, dq_io_tri, dq_out_en,
   dq_out0, dq_out1, wds_en, wds0, wds1, rwds_io_tri, rd_active,
   wr_active, wr_rsto_status, wr_slv_status, wr_dec_status,
   rd_stall_status, rd_rsto_status, rd_slv_status, rd_dec_status,
   // Inputs
   AXI_ACLK, AXI_ARESETN, AXI_AWID, AXI_AWADDR, AXI_AWLEN, AXI_AWSIZE,
   AXI_AWBURST, AXI_AWVALID, AXI_WDATA, AXI_WSTRB, AXI_WLAST,
   AXI_WVALID, AXI_WID, AXI_BREADY, AXI_ARID, AXI_ARADDR, AXI_ARLEN,
   AXI_ARSIZE, AXI_ARBURST, AXI_ARVALID, AXI_RREADY, clk, rds_clk,
   dq_in, rsto_n, rwds_in, reg_wrap_size0, reg_wrap_size1, reg_acs0,
   reg_acs1, reg_mbr0, reg_mbr1, reg_tco0, reg_tco1, reg_dt0, reg_gb_rst, reg_mem_init,
   
   reg_dt1,
   reg_crt0, reg_crt1, reg_lbr, reg_latency0, reg_latency1,
   reg_rd_cshi0, reg_rd_cshi1, reg_rd_css0, reg_rd_css1, reg_rd_csh0,
   reg_rd_csh1, reg_wr_cshi0, reg_wr_cshi1, reg_wr_css0, reg_wr_css1,
   reg_wr_csh0, reg_wr_csh1, reg_rd_max_len_en0, reg_rd_max_len_en1,
   reg_rd_max_length0, reg_rd_max_length1, reg_wr_max_len_en0,
   reg_wr_max_len_en1, reg_wr_max_length0, reg_wr_max_length1,
   reg_rd_trans_alloc, reg_wr_trans_alloc,
//// psram controller////////////
   xl_ck,xl_ce,xl_dqs,xl_dq,clk90
 
   );
   
  

          
   output         xl_ck;
   output         xl_ce;
   inout          xl_dqs;   
   inout  [7:0]   xl_dq;

   input clk90;    
 
   
   

   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_ADDR_WIDTH = 'd32;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_LEN_WIDTH  = 'd8;
   parameter C_AW_FIFO_ADDR_BITS  = 'd4;
   parameter C_AR_FIFO_ADDR_BITS  = 'd4;
   parameter C_WDAT_FIFO_ADDR_BITS = 'd9;
   parameter C_RDAT_FIFO_ADDR_BITS = 'd9;
   parameter C_RX_FIFO_ADDR_BITS   = 'd8;
   parameter C_AXI_DATA_INTERLEAVING = 1'b1;
   
   parameter DPRAM_MACRO = 0;       // 0=Macro is not used, 1=Macro is used
   parameter DPRAM_MACRO_TYPE = 0;  // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)

   parameter   integer INIT_CLOCK_HZ = 200_000000;
   parameter   INIT_DRIVE_STRENGTH = 50;
        
        
   localparam C_NOWAIT_WR_DATA_DONE = 1'b0;
   
   // Global System Signals
   input                            AXI_ACLK;
   input                            AXI_ARESETN;
   
   // Write Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0]       AXI_AWID;
   input [C_AXI_ADDR_WIDTH-1:0]     AXI_AWADDR;
   input [C_AXI_LEN_WIDTH-1:0]      AXI_AWLEN;
   input [2:0]                      AXI_AWSIZE;
   input [1:0]                      AXI_AWBURST;
   input                            AXI_AWVALID;
   output                           AXI_AWREADY;
   
   // Write Data Channel Signals
   input [C_AXI_DATA_WIDTH-1:0]     AXI_WDATA;
   input [(C_AXI_DATA_WIDTH/8)-1:0] AXI_WSTRB;
   input                            AXI_WLAST;
   input                            AXI_WVALID;
   input [C_AXI_ID_WIDTH-1:0]       AXI_WID;
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
   
   input                            clk;
   output                           reset_n;
   
   // RPC IO
   input                            rds_clk;
   input [7:0]                      dq_in;
   input                            rsto_n;
   input                            rwds_in;
   output                           cs0n_en;
   output                           cs1n_en;
   output                           csn_d;
   output                           ck_en;
   output                           dq_io_tri;
   output                           dq_out_en;
   output [7:0]                     dq_out0;
   output [7:0]                     dq_out1;
   output                           wds_en;
   output                           wds0;
   output                           wds1;
   output                           rwds_io_tri;
`ifdef CK2
   output                           ck2_en;
`endif
   
   // REG
   input [1:0]                      reg_wrap_size0;  // wrap size
   input [1:0]                      reg_wrap_size1;
   input                            reg_acs0;        // asymmetric cache support
   input                            reg_acs1;
   input [7:0]                      reg_mbr0;        // memory base register address[31:24]
   input [7:0]                      reg_mbr1;
   input                            reg_tco0;        // tc option
   input                            reg_tco1;
   
   
   input                            reg_dt0;         // device type
   input                            reg_gb_rst;
   input                            reg_mem_init;   
   
   input                            reg_dt1;
   input                            reg_crt0;        // configuration register target
   input                            reg_crt1;
   input                            reg_lbr;         // loopback
   input [3:0]                      reg_latency0;    // read latency
   input [3:0]                      reg_latency1;
   input [3:0]                      reg_rd_cshi0;    // CS high cycle for read
   input [3:0]                      reg_rd_cshi1;
   input [3:0]                      reg_rd_css0;     // CS setup cycle for read
   input [3:0]                      reg_rd_css1;
   input [3:0]                      reg_rd_csh0;     // CS hold cycle for read
   input [3:0]                      reg_rd_csh1;
   input [3:0]                      reg_wr_cshi0;    // CS high cycle for write
   input [3:0]                      reg_wr_cshi1;
   input [3:0]                      reg_wr_css0;     // CS setup cycle for write
   input [3:0]                      reg_wr_css1;
   input [3:0]                      reg_wr_csh0;     // CS hold cycle for write
   input [3:0]                      reg_wr_csh1;
   input                            reg_rd_max_len_en0;  // read max length enable
   input                            reg_rd_max_len_en1;
   input [8:0]                      reg_rd_max_length0;  // read max length
   input [8:0]                      reg_rd_max_length1;
   input                            reg_wr_max_len_en0;  // write max length enable
   input                            reg_wr_max_len_en1;
   input [8:0]                      reg_wr_max_length0;  // write max length
   input [8:0]                      reg_wr_max_length1;
   input [1:0]                      reg_rd_trans_alloc;  // read transaction allocation
   input [1:0]                      reg_wr_trans_alloc;  // write transaction allocation
   
   // STATUS
   output                           rd_active;
   output                           wr_active;
   output                           wr_rsto_status;
   output                           wr_slv_status;
   output                           wr_dec_status;
   output                           rd_stall_status;
   output                           rd_rsto_status;
   output                           rd_slv_status;
   output                           rd_dec_status;
   
   /*AUTOINPUT*/

   /*AUTOOUTPUT*/
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [C_AXI_DATA_WIDTH-1:0] axi2ip0_data;    // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire                 axi2ip0_data_valid;     // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire [(C_AXI_DATA_WIDTH/8)-1:0] axi2ip0_strb;// From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire [C_AXI_DATA_WIDTH-1:0] axi2ip1_data;    // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire                 axi2ip1_data_valid;     // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire [(C_AXI_DATA_WIDTH/8)-1:0] axi2ip1_strb;// From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire [31:0]          axi2ip_address;         // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire                 axi2ip_block;           // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire [1:0]           axi2ip_burst;           // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v

   wire [9:0]           axi2ip_size;            // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v

   wire                 axi2ip_data_ready;      // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v  
   wire [9:0]           axi2ip_len;             // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire                 axi2ip_rw_n;            // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire                 axi2ip_valid;           // From rpc2_ctrl_axi_async_channel2 of rpc2_ctrl_axi_async_channel2.v
   wire                 ip0_data_ready;         // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire                 ip0_wr_done;            // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire [1:0]           ip0_wr_error;           // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire                 ip1_data_ready;         // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire                 ip1_wr_done;            // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire [1:0]           ip1_wr_error;           // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire [31:0]          ip_data;                // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire                 ip_data_last;           // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire                 ip_data_valid;          // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire [1:0]           ip_rd_error;            // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire                 ip_ready;               // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire [3:0]           ip_strb;                // From rpc2_ctrl_mem_logic of rpc2_ctrl_mem_logic.v
   wire                 powered_up;             // From rpc2_ctrl_mem_reset_block of rpc2_ctrl_mem_reset_block.v
   // End of automatics
   wire [1:0]           ip_data_size = 2'b01; // 2-byte
//   wire [1:0]           ip_data_size = 2'b10; // 4-byte

   /* rpc2_ctrl_mem_reset_block AUTO_TEMPLATE (
    .areset_n(AXI_ARESETN),
    );
    */
   rpc2_ctrl_mem_reset_block
     rpc2_ctrl_mem_reset_block (/*AUTOINST*/
                                // Outputs
                                .reset_n        (reset_n),
                                .powered_up     (powered_up),
                                // Inputs
                                .clk            (clk),
                                .rsto_n         (rsto_n),
                                .areset_n       (AXI_ARESETN));  // Templated

   /* rpc2_ctrl_axi_async_channel2 AUTO_TEMPLATE (
    .ip_clk(clk),
    .ip_reset_n(reset_n),
    .axi2ip_len(axi2ip_len[9:0]),
    );
    */
   rpc2_ctrl_axi_async_channel2
     #(C_AXI_ID_WIDTH,
       C_AXI_ADDR_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_LEN_WIDTH,
       C_AW_FIFO_ADDR_BITS,
       C_AR_FIFO_ADDR_BITS,
       C_WDAT_FIFO_ADDR_BITS,
       C_RDAT_FIFO_ADDR_BITS,
       C_NOWAIT_WR_DATA_DONE,
       C_AXI_DATA_INTERLEAVING,
       DPRAM_MACRO,
       DPRAM_MACRO_TYPE)
   rpc2_ctrl_axi_async_channel2 (/*AUTOINST*/
                                 // Outputs
                                 .AXI_AWREADY           (AXI_AWREADY),
                                 .AXI_WREADY            (AXI_WREADY),
                                 .AXI_BID               (AXI_BID[C_AXI_ID_WIDTH-1:0]),
                                 .AXI_BRESP             (AXI_BRESP[1:0]),
                                 .AXI_BVALID            (AXI_BVALID),
                                 .AXI_ARREADY           (AXI_ARREADY),
                                 .AXI_RID               (AXI_RID[C_AXI_ID_WIDTH-1:0]),
                                 .AXI_RDATA             (AXI_RDATA[C_AXI_DATA_WIDTH-1:0]),
                                 .AXI_RRESP             (AXI_RRESP[1:0]),
                                 .AXI_RLAST             (AXI_RLAST),
                                 .AXI_RVALID            (AXI_RVALID),
                                 .axi2ip_valid          (axi2ip_valid),
                                 .axi2ip_block          (axi2ip_block),
                                 .axi2ip_rw_n           (axi2ip_rw_n),
                                 .axi2ip_address        (axi2ip_address[31:0]),
                                 .axi2ip_burst          (axi2ip_burst[1:0]),
                                 
                                 .axi2ip_size           (axi2ip_size[1:0]),
                                 
                                 .axi2ip_len            (axi2ip_len[9:0]), // Templated
                                 .axi2ip0_data_valid    (axi2ip0_data_valid),
                                 .axi2ip0_strb          (axi2ip0_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                 .axi2ip0_data          (axi2ip0_data[C_AXI_DATA_WIDTH-1:0]),
                                 .axi2ip1_data_valid    (axi2ip1_data_valid),
                                 .axi2ip1_strb          (axi2ip1_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                 .axi2ip1_data          (axi2ip1_data[C_AXI_DATA_WIDTH-1:0]),
                                 .axi2ip_data_ready     (axi2ip_data_ready),
                                 .rd_active             (rd_active),
                                 .wr_active             (wr_active),
                                 // Inputs
                                 .AXI_ACLK              (AXI_ACLK),
                                 .AXI_ARESETN           (AXI_ARESETN),
                                 .AXI_AWID              (AXI_AWID[C_AXI_ID_WIDTH-1:0]),
                                 .AXI_AWADDR            (AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0]),
                                 .AXI_AWLEN             (AXI_AWLEN[C_AXI_LEN_WIDTH-1:0]),
                                 .AXI_AWSIZE            (AXI_AWSIZE[2:0]),
                                 .AXI_AWBURST           (AXI_AWBURST[1:0]),
                                 .AXI_AWVALID           (AXI_AWVALID),
                                 .AXI_WDATA             (AXI_WDATA[C_AXI_DATA_WIDTH-1:0]),
                                 .AXI_WSTRB             (AXI_WSTRB[(C_AXI_DATA_WIDTH/8)-1:0]),
                                 .AXI_WLAST             (AXI_WLAST),
                                 .AXI_WVALID            (AXI_WVALID),
                                 .AXI_WID               (AXI_WID[C_AXI_ID_WIDTH-1:0]),
                                 .AXI_BREADY            (AXI_BREADY),
                                 .AXI_ARID              (AXI_ARID[C_AXI_ID_WIDTH-1:0]),
                                 .AXI_ARADDR            (AXI_ARADDR[C_AXI_ADDR_WIDTH-1:0]),
                                 .AXI_ARLEN             (AXI_ARLEN[C_AXI_LEN_WIDTH-1:0]),
                                 .AXI_ARSIZE            (AXI_ARSIZE[2:0]),
                                 .AXI_ARBURST           (AXI_ARBURST[1:0]),
                                 .AXI_ARVALID           (AXI_ARVALID),
                                 .AXI_RREADY            (AXI_RREADY),
                                 .ip_data_size          (ip_data_size[1:0]),
                                 .ip_ready              (ip_ready),
                                 .ip0_data_ready        (ip0_data_ready),
                                 .ip1_data_ready        (ip1_data_ready),
                                 .ip_data_valid         (ip_data_valid),
                                 .ip_data_last          (ip_data_last),
                                 .ip_strb               (ip_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                                 .ip_data               (ip_data[C_AXI_DATA_WIDTH-1:0]),
                                 .ip_rd_error           (ip_rd_error[1:0]),
                                 .ip0_wr_done           (ip0_wr_done),
                                 .ip0_wr_error          (ip0_wr_error[1:0]),
                                 .ip1_wr_done           (ip1_wr_done),
                                 .ip1_wr_error          (ip1_wr_error[1:0]),
                                 .ip_clk                (clk),           // Templated
                                 .ip_reset_n            (reset_n),       // Templated
                                 .reg_rd_trans_alloc    (reg_rd_trans_alloc[1:0]),
                                 .reg_wr_trans_alloc    (reg_wr_trans_alloc[1:0]));
   
   rpc2_ctrl_mem_logic 
      #(C_RX_FIFO_ADDR_BITS,
        DPRAM_MACRO,
        DPRAM_MACRO_TYPE,  
        INIT_CLOCK_HZ,
        INIT_DRIVE_STRENGTH
        ) 
   rpc2_ctrl_mem_logic (
                        /*AUTOINST*/
                        // Outputs
                        .ip_ready       (ip_ready),
                        .ip0_data_ready (ip0_data_ready),
                        .ip1_data_ready (ip1_data_ready),
                        .ip_data_valid  (ip_data_valid),
                        .ip_data_last   (ip_data_last),
                        .ip_strb        (ip_strb[3:0]),
                        .ip_data        (ip_data[31:0]),
                        .ip_rd_error    (ip_rd_error[1:0]),
                        .ip0_wr_error   (ip0_wr_error[1:0]),
                        .ip0_wr_done    (ip0_wr_done),
                        .ip1_wr_error   (ip1_wr_error[1:0]),
                        .ip1_wr_done    (ip1_wr_done),
                        .cs0n_en        (cs0n_en),
                        .cs1n_en        (cs1n_en),
                        .csn_d          (csn_d),
                        .ck_en          (ck_en),
                        .dq_io_tri      (dq_io_tri),
                        .dq_out_en      (dq_out_en),
                        .dq_out0        (dq_out0[7:0]),
                        .dq_out1        (dq_out1[7:0]),
                        .wds_en         (wds_en),
                        .wds0           (wds0),
                        .wds1           (wds1),
                        .rwds_io_tri    (rwds_io_tri),
                        .wr_rsto_status (wr_rsto_status),
                        .wr_slv_status  (wr_slv_status),
                        .wr_dec_status  (wr_dec_status),
                        .rd_stall_status(rd_stall_status),
                        .rd_rsto_status (rd_rsto_status),
                        .rd_slv_status  (rd_slv_status),
                        .rd_dec_status  (rd_dec_status),
                        // Inputs
                        .clk            (clk),
                        .reset_n        (reset_n),
                        .axi2ip_valid   (axi2ip_valid),
                        .axi2ip_block   (axi2ip_block),
                        .axi2ip_rw_n    (axi2ip_rw_n),
                        .axi2ip_address (axi2ip_address[31:0]),
                        .axi2ip_burst   (axi2ip_burst[1:0]),
                        
                        .axi2ip_size    (axi2ip_size[1:0]),
                        
                        .axi2ip_len     (axi2ip_len[8:0]),
                        .axi2ip0_strb   (axi2ip0_strb[3:0]),
                        .axi2ip0_data   (axi2ip0_data[31:0]),
                        .axi2ip0_data_valid(axi2ip0_data_valid),
                        .axi2ip1_strb   (axi2ip1_strb[3:0]),
                        .axi2ip1_data   (axi2ip1_data[31:0]),
                        .axi2ip1_data_valid(axi2ip1_data_valid),
                        .axi2ip_data_ready(axi2ip_data_ready),
                        .reg_wrap_size0 (reg_wrap_size0[1:0]),
                        .reg_wrap_size1 (reg_wrap_size1[1:0]),
                        .reg_acs0       (reg_acs0),
                        .reg_acs1       (reg_acs1),
                        .reg_mbr0       (reg_mbr0[7:0]),
                        .reg_mbr1       (reg_mbr1[7:0]),
                        .reg_tco0       (reg_tco0),
                        .reg_tco1       (reg_tco1),
                        
                        
                        .reg_dt0        (reg_dt0),
                        .reg_gb_rst     (reg_gb_rst),
                        .reg_mem_init   (reg_mem_init),
                        
                       
                        .reg_dt1        (reg_dt1),
                        .reg_crt0       (reg_crt0),
                        .reg_crt1       (reg_crt1),
                        .reg_lbr        (reg_lbr),
                        .reg_latency0   (reg_latency0[3:0]),
                        .reg_latency1   (reg_latency1[3:0]),
                        .reg_rd_cshi0   (reg_rd_cshi0[3:0]),
                        .reg_rd_cshi1   (reg_rd_cshi1[3:0]),
                        .reg_rd_css0    (reg_rd_css0[3:0]),
                        .reg_rd_css1    (reg_rd_css1[3:0]),
                        .reg_rd_csh0    (reg_rd_csh0[3:0]),
                        .reg_rd_csh1    (reg_rd_csh1[3:0]),
                        .reg_wr_cshi0   (reg_wr_cshi0[3:0]),
                        .reg_wr_cshi1   (reg_wr_cshi1[3:0]),
                        .reg_wr_css0    (reg_wr_css0[3:0]),
                        .reg_wr_css1    (reg_wr_css1[3:0]),
                        .reg_wr_csh0    (reg_wr_csh0[3:0]),
                        .reg_wr_csh1    (reg_wr_csh1[3:0]),
                        .reg_rd_max_length0(reg_rd_max_length0[8:0]),
                        .reg_rd_max_length1(reg_rd_max_length1[8:0]),
                        .reg_rd_max_len_en0(reg_rd_max_len_en0),
                        .reg_rd_max_len_en1(reg_rd_max_len_en1),
                        .reg_wr_max_length0(reg_wr_max_length0[8:0]),
                        .reg_wr_max_length1(reg_wr_max_length1[8:0]),
                        .reg_wr_max_len_en0(reg_wr_max_len_en0),
                        .reg_wr_max_len_en1(reg_wr_max_len_en1),
                        .powered_up     (powered_up),
                        .rds_clk        (rds_clk),
                        .dq_in          (dq_in[7:0]),
                        .rwds_in        (rwds_in),
                        
                        
//// psram controller////////////                         
                        .xl_ck          (xl_ck),
                        .xl_ce          (xl_ce),
                        .xl_dqs         (xl_dqs),
                        .xl_dq          (xl_dq),
                        .clk90         (clk90)  


                        
                        );
   
endmodule 
