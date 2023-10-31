

module rpc2_ctrl_controller (
                    
   /*AUTOARG*/
   // Outputs
   AXIm_AWREADY, AXIm_WREADY, AXIm_BID, AXIm_BRESP, AXIm_BVALID, 
   AXIm_ARREADY, AXIm_RID, AXIm_RDATA, AXIm_RRESP, AXIm_RLAST, 
   AXIm_RVALID, 
   
   
   AXIr_AWREADY, AXIr_WREADY, AXIr_BID, AXIr_BRESP, AXIr_BVALID, 
   AXIr_ARREADY, AXIr_RID, AXIr_RDATA, AXIr_RRESP, AXIr_RLAST, 
   AXIr_RVALID,      
   IENOn, GPO, 
   // Inouts
 

   AXIm_ACLK, AXIm_ARESETN, AXIm_AWID, AXIm_AWADDR, AXIm_AWLEN, 
   AXIm_AWSIZE, AXIm_AWBURST, AXIm_AWVALID, AXIm_WDATA, AXIm_WSTRB, 
   AXIm_WID, AXIm_WLAST, AXIm_WVALID, AXIm_BREADY, AXIm_ARID, 
   AXIm_ARADDR, AXIm_ARLEN, AXIm_ARSIZE, AXIm_ARBURST, AXIm_ARVALID, 
   AXIm_RREADY, 
 
 
   AXIr_ACLK, AXIr_ARESETN, AXIr_AWID, AXIr_AWADDR, AXIr_AWLEN, 
   AXIr_AWSIZE, AXIr_AWBURST, AXIr_AWVALID, AXIr_WDATA, AXIr_WSTRB, 
             AXIr_WLAST, AXIr_WVALID, AXIr_BREADY, AXIr_ARID, 
   AXIr_ARADDR, AXIr_ARLEN, AXIr_ARSIZE, AXIr_ARBURST, AXIr_ARVALID, 
   AXIr_RREADY,
   
   
   sys_clk, 
   
//   ref_clk,

   xl_ck,xl_ce,xl_dqs,xl_dq

   );
   
   // psram io pad       
   output         xl_ck;
   output         xl_ce;
   inout          xl_dqs;   
   inout  [7:0]   xl_dq;

   
   
   
   
   
   parameter C_AXI_MEM_ID_WIDTH   = 'd4;
   parameter C_AXI_MEM_ADDR_WIDTH = 'd32;
   parameter C_AXI_MEM_DATA_WIDTH = 'd32;
   parameter C_AXI_MEM_LEN_WIDTH  = 'd8;
   parameter C_AXI_MEM_DATA_INTERLEAVING = 1'b0;
   parameter C_MEM_AW_FIFO_ADDR_BITS  = 'd4;
   parameter C_MEM_AR_FIFO_ADDR_BITS  = 'd4;
//   parameter C_MEM_WDAT_FIFO_ADDR_BITS = 'd7;
   parameter C_MEM_WDAT_FIFO_ADDR_BITS = 'd8;
   parameter C_MEM_RDAT_FIFO_ADDR_BITS = 'd7;

   parameter C_AXI_REG_ID_WIDTH   = 'd4;
   parameter C_AXI_REG_ADDR_WIDTH = 'd32;
   parameter C_AXI_REG_DATA_WIDTH = 'd32;
   parameter C_AXI_REG_LEN_WIDTH  = 'd8;
   parameter C_AXI_REG_BASEADDR = 32'h00000000;
   parameter C_AXI_REG_HIGHADDR = 32'h0000004F;
   
   parameter C_RX_FIFO_ADDR_BITS = 'd8;
   parameter DPRAM_MACRO = 0;       // 0=Macro is not used, 1=Macro is used
   parameter DPRAM_MACRO_TYPE = 0;  // 0=type-A(e.g. Standard cell), 1=type-B(e.g. Low Leak cell)


   parameter   integer INIT_CLOCK_HZ = 200_000000;
   parameter   INIT_DRIVE_STRENGTH = 50;
   
   
   // Global System Signals for MEM
   input AXIm_ACLK;
   input AXIm_ARESETN;

   // Write Address Channel Signals for MEM
   input [C_AXI_MEM_ID_WIDTH-1:0] AXIm_AWID;
   input [C_AXI_MEM_ADDR_WIDTH-1:0] AXIm_AWADDR;
   input [C_AXI_MEM_LEN_WIDTH-1:0]  AXIm_AWLEN;
   input [2:0]                      AXIm_AWSIZE;
   input [1:0]                      AXIm_AWBURST;
   input                            AXIm_AWVALID;
   output                           AXIm_AWREADY;
   
   // Write Data Channel Signals for MEM
   input [C_AXI_MEM_DATA_WIDTH-1:0] AXIm_WDATA;
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
   input AXIr_ACLK;
   input AXIr_ARESETN;

   // Write Address Channel Signals for REG
   input [C_AXI_REG_ID_WIDTH-1:0] AXIr_AWID;
   input [C_AXI_REG_ADDR_WIDTH-1:0] AXIr_AWADDR;
   input [C_AXI_REG_LEN_WIDTH-1:0]  AXIr_AWLEN;
   input [2:0]                      AXIr_AWSIZE;
   input [1:0]                      AXIr_AWBURST;
   input                            AXIr_AWVALID;
   output                           AXIr_AWREADY;
   
   // Write Data Channel Signals for REG
   input [C_AXI_REG_DATA_WIDTH-1:0] AXIr_WDATA;
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
   input [C_AXI_REG_ID_WIDTH-1:0] AXIr_ARID;
   input [C_AXI_REG_ADDR_WIDTH-1:0] AXIr_ARADDR;
   input [C_AXI_REG_LEN_WIDTH-1:0]  AXIr_ARLEN;
   input [2:0]                      AXIr_ARSIZE;
   input [1:0]                      AXIr_ARBURST;
   input                            AXIr_ARVALID;
   output                           AXIr_ARREADY;
   
   // Read Data Channel Signals for REG
   output [C_AXI_REG_ID_WIDTH-1:0]  AXIr_RID;
   output [C_AXI_REG_DATA_WIDTH-1:0] AXIr_RDATA;
   output [1:0]                      AXIr_RRESP;
   output                            AXIr_RLAST;
   output                            AXIr_RVALID;
   input                             AXIr_RREADY;



   
   input       sys_clk;  // RPC Clock
//   input       ref_clk;  // 200MHz

   output      IENOn;
   output [1:0] GPO;
   

   wire                 ck_en;                  // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 clk0;                   // From rpc2_ctrl_clk_gen of rpc2_ctrl_clk_gen.v
   wire                 clk180;                 // From rpc2_ctrl_clk_gen of rpc2_ctrl_clk_gen.v
   wire                 clk270;                 // From rpc2_ctrl_clk_gen of rpc2_ctrl_clk_gen.v
   wire                 clk90;                  // From rpc2_ctrl_clk_gen of rpc2_ctrl_clk_gen.v
   wire                 cs0n_en;                // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 cs1n_en;                // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 csn_d;                  // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire [7:0]           dq_in;                  // From rpc2_ctrl_io of rpc2_ctrl_io.v
   wire                 dq_io_tri;              // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire [7:0]           dq_out0;                // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire [7:0]           dq_out1;                // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 dq_out_en;              // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 hwreset_n;              // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 int_n;                  // From rpc2_ctrl_io of rpc2_ctrl_io.v
   wire                 rds_clk;                // From rpc2_ctrl_io of rpc2_ctrl_io.v
   wire                 reset_n;                // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 rsto_n;                 // From rpc2_ctrl_io of rpc2_ctrl_io.v
   wire                 rwds_in;                // From rpc2_ctrl_io of rpc2_ctrl_io.v
   wire                 rwds_io_tri;            // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 wds0;                   // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 wds1;                   // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 wds_en;                 // From rpc2_ctrl_ip of rpc2_ctrl_ip.v
   wire                 wp_n;                   // From rpc2_ctrl_ip of rpc2_ctrl_ip.v

   wire [2:0]           rds_delay_adj = 3'b000;
   wire                 IENOn;

   

   rpc2_ctrl_ip
     #(C_AXI_MEM_ID_WIDTH,
       C_AXI_MEM_ADDR_WIDTH,
       C_AXI_MEM_DATA_WIDTH,
       C_AXI_MEM_LEN_WIDTH,
       C_AXI_MEM_DATA_INTERLEAVING,
       C_MEM_AW_FIFO_ADDR_BITS,
       C_MEM_AR_FIFO_ADDR_BITS,
       C_MEM_WDAT_FIFO_ADDR_BITS,
       C_MEM_RDAT_FIFO_ADDR_BITS,
       C_AXI_REG_ID_WIDTH,
       C_AXI_REG_ADDR_WIDTH,
       C_AXI_REG_DATA_WIDTH,
       C_AXI_REG_LEN_WIDTH,
       C_AXI_REG_BASEADDR,
       C_AXI_REG_HIGHADDR,
       C_RX_FIFO_ADDR_BITS,
       DPRAM_MACRO,
       DPRAM_MACRO_TYPE,
       INIT_CLOCK_HZ,
       INIT_DRIVE_STRENGTH
       )
     rpc2_ctrl_ip (
                   // Outputs
                   .AXIm_AWREADY        (AXIm_AWREADY),
                   .AXIm_WREADY         (AXIm_WREADY),
                   .AXIm_BID            (AXIm_BID[C_AXI_MEM_ID_WIDTH-1:0]),
                   .AXIm_BRESP          (AXIm_BRESP[1:0]),
                   .AXIm_BVALID         (AXIm_BVALID),
                   .AXIm_ARREADY        (AXIm_ARREADY),
                   .AXIm_RID            (AXIm_RID[C_AXI_MEM_ID_WIDTH-1:0]),
                   .AXIm_RDATA          (AXIm_RDATA[C_AXI_MEM_DATA_WIDTH-1:0]),
                   .AXIm_RRESP          (AXIm_RRESP[1:0]),
                   .AXIm_RLAST          (AXIm_RLAST),
                   .AXIm_RVALID         (AXIm_RVALID),
                   .AXIr_AWREADY        (AXIr_AWREADY),
                   .AXIr_WREADY         (AXIr_WREADY),
                   .AXIr_BID            (AXIr_BID[C_AXI_REG_ID_WIDTH-1:0]),
                   .AXIr_BRESP          (AXIr_BRESP[1:0]),
                   .AXIr_BVALID         (AXIr_BVALID),
                   .AXIr_ARREADY        (AXIr_ARREADY),
                   .AXIr_RID            (AXIr_RID[C_AXI_REG_ID_WIDTH-1:0]),
                   .AXIr_RDATA          (AXIr_RDATA[C_AXI_REG_DATA_WIDTH-1:0]),
                   .AXIr_RRESP          (AXIr_RRESP[1:0]),
                   .AXIr_RLAST          (AXIr_RLAST),
                   .AXIr_RVALID         (AXIr_RVALID),
                   .reset_n             (reset_n),
                   .cs0n_en             (cs0n_en),
                   .cs1n_en             (cs1n_en),
                   .csn_d               (csn_d),
                   .ck_en               (ck_en),
                   .dq_io_tri           (dq_io_tri),
                   .dq_out_en           (dq_out_en),
                   .dq_out0             (dq_out0[7:0]),
                   .dq_out1             (dq_out1[7:0]),
                   .wds_en              (wds_en),
                   .wds0                (wds0),
                   .wds1                (wds1),
                   .rwds_io_tri         (rwds_io_tri),
                   .hwreset_n           (hwreset_n),
                   .wp_n                (wp_n),
                   .IENOn               (IENOn),
                   .GPO                 (GPO[1:0]),
                   // Inputs
                   .AXIm_ACLK           (AXIm_ACLK),
                   .AXIm_ARESETN        (AXIm_ARESETN),
                   .AXIm_AWID           (AXIm_AWID[C_AXI_MEM_ID_WIDTH-1:0]),
                   .AXIm_AWADDR         (AXIm_AWADDR[C_AXI_MEM_ADDR_WIDTH-1:0]),
                   .AXIm_AWLEN          (AXIm_AWLEN[C_AXI_MEM_LEN_WIDTH-1:0]),
                   .AXIm_AWSIZE         (AXIm_AWSIZE[2:0]),
                   .AXIm_AWBURST        (AXIm_AWBURST[1:0]),
                   .AXIm_AWVALID        (AXIm_AWVALID),
                   .AXIm_WDATA          (AXIm_WDATA[C_AXI_MEM_DATA_WIDTH-1:0]),
                   .AXIm_WSTRB          (AXIm_WSTRB[(C_AXI_MEM_DATA_WIDTH/8)-1:0]),
                   .AXIm_WID            (AXIm_WID[C_AXI_MEM_ID_WIDTH-1:0]),
                   .AXIm_WLAST          (AXIm_WLAST),
                   .AXIm_WVALID         (AXIm_WVALID),
                   .AXIm_BREADY         (AXIm_BREADY),
                   .AXIm_ARID           (AXIm_ARID[C_AXI_MEM_ID_WIDTH-1:0]),
                   .AXIm_ARADDR         (AXIm_ARADDR[C_AXI_MEM_ADDR_WIDTH-1:0]),
                   .AXIm_ARLEN          (AXIm_ARLEN[C_AXI_MEM_LEN_WIDTH-1:0]),
                   .AXIm_ARSIZE         (AXIm_ARSIZE[2:0]),
                   .AXIm_ARBURST        (AXIm_ARBURST[1:0]),
                   .AXIm_ARVALID        (AXIm_ARVALID),
                   .AXIm_RREADY         (AXIm_RREADY),
                   .AXIr_ACLK           (AXIr_ACLK),
                   .AXIr_ARESETN        (AXIr_ARESETN),
                   .AXIr_AWID           (AXIr_AWID[C_AXI_REG_ID_WIDTH-1:0]),
                   .AXIr_AWADDR         (AXIr_AWADDR[C_AXI_REG_ADDR_WIDTH-1:0]),
                   .AXIr_AWLEN          (AXIr_AWLEN[C_AXI_REG_LEN_WIDTH-1:0]),
                   .AXIr_AWSIZE         (AXIr_AWSIZE[2:0]),
                   .AXIr_AWBURST        (AXIr_AWBURST[1:0]),
                   .AXIr_AWVALID        (AXIr_AWVALID),
                   .AXIr_WDATA          (AXIr_WDATA[C_AXI_REG_DATA_WIDTH-1:0]),
                   .AXIr_WSTRB          (AXIr_WSTRB[(C_AXI_REG_DATA_WIDTH/8)-1:0]),
                   .AXIr_WLAST          (AXIr_WLAST),
                   .AXIr_WVALID         (AXIr_WVALID),
                   .AXIr_BREADY         (AXIr_BREADY),
                   .AXIr_ARID           (AXIr_ARID[C_AXI_REG_ID_WIDTH-1:0]),
                   .AXIr_ARADDR         (AXIr_ARADDR[C_AXI_REG_ADDR_WIDTH-1:0]),
                   .AXIr_ARLEN          (AXIr_ARLEN[C_AXI_REG_LEN_WIDTH-1:0]),
                   .AXIr_ARSIZE         (AXIr_ARSIZE[2:0]),
                   .AXIr_ARBURST        (AXIr_ARBURST[1:0]),
                   .AXIr_ARVALID        (AXIr_ARVALID),
                   .AXIr_RREADY         (AXIr_RREADY),
                   .clk                 (clk0),                
 
 
                   .rds_clk             (rds_clk),
                   .dq_in               (dq_in[7:0]),
                   .rwds_in             (rwds_in),
                   .int_n               (int_n),
                   .rsto_n              (rsto_n),
                   
   // psram io pad                        
                        .xl_ck          (xl_ck),
                        .xl_ce          (xl_ce),
                        .xl_dqs         (xl_dqs),
                        .xl_dq          (xl_dq),
                        .clk90         (clk90)  
                   
                   
                   );

clk_wiz_1 
ctrl_clk_gen
                    (/*AUTOINST*/
                        // Outputs
                        .clk0           (clk0),
                        .clk90          (clk90),
                        .clk180         (clk180),
                        .clk270         (clk270),
                        // Inputs
                        .sys_clk        (sys_clk)
                        
                    );


 
endmodule 
