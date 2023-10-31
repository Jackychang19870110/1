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
// Filename: rpc2_ctrl_reg.v
//
//           Control Register block for RPC2 Controller
//
// Created: yise  01/10/2014  version 2.0  - initial release
//          yise  05/15/2014  version 2.2  - added status sigs
//          yise  09/26/2014  version 2.3  - added max_len sigs
//          yise  10/30/2015  version 2.4  - added transaction alloc reg
//                                         - changed C_AXI_HIGHADDR for TAR
//*************************************************************************

module rpc2_ctrl_reg (/*AUTOARG*/
   // Outputs
   AXI_AWREADY, AXI_WREADY, AXI_BID, AXI_BRESP, AXI_BVALID,
   AXI_ARREADY, AXI_RID, AXI_RDATA, AXI_RRESP, AXI_RLAST, AXI_RVALID,
   mcr0_reg_wrapsize, mcr1_reg_wrapsize, mcr0_reg_acs, mcr1_reg_acs,
   mbr0_reg_a, mbr1_reg_a, mcr0_reg_tcmo, mcr1_reg_tcmo,
   mcr0_reg_devtype, mcr0_reg_gb_rst, mcr0_reg_mem_init,
   mcr1_reg_devtype, mcr0_reg_crt, mcr1_reg_crt,
   mtr0_reg_rcshi, mtr1_reg_rcshi, mtr0_reg_wcshi, mtr1_reg_wcshi,
   mtr0_reg_rcss, mtr1_reg_rcss, mtr0_reg_wcss, mtr1_reg_wcss,
   mtr0_reg_rcsh, mtr1_reg_rcsh, mtr0_reg_wcsh, mtr1_reg_wcsh,
   mtr0_reg_ltcy, mtr1_reg_ltcy, lbr_reg_loopback, mcr0_reg_mlen,
   mcr1_reg_mlen, mcr0_reg_men, mcr1_reg_men, tar_reg_rta,
   tar_reg_wta, wp_n, IENOn, GPO,
   // Inputs
   AXI_ACLK, AXI_ARESETN, AXI_AWID, AXI_AWADDR, AXI_AWLEN, AXI_AWSIZE,
   AXI_AWBURST, AXI_AWVALID, AXI_WDATA, AXI_WSTRB, AXI_WLAST,
   AXI_WVALID, AXI_BREADY, AXI_ARID, AXI_ARADDR, AXI_ARLEN,
   AXI_ARSIZE, AXI_ARBURST, AXI_ARVALID, AXI_RREADY, int_n,
   mem_rd_active, mem_wr_active, mem_wr_rsto_status,
   mem_wr_slv_status, mem_wr_dec_status, mem_rd_stall_status,
   mem_rd_rsto_status, mem_rd_slv_status, mem_rd_dec_status
   );
   parameter C_AXI_ID_WIDTH   = 'd4;
   parameter C_AXI_ADDR_WIDTH = 'd32;
   parameter C_AXI_DATA_WIDTH = 'd32;
   parameter C_AXI_LEN_WIDTH  = 'd8;
   parameter C_AXI_BASEADDR = 32'h00000000;
   parameter C_AXI_HIGHADDR = 32'h0000004F;
   localparam C_ADR_FIFO_ADDR_BITS = 'd0;
   localparam C_AW_FIFO_ADDR_BITS  = 'd0;
   localparam C_AR_FIFO_ADDR_BITS  = 'd0;
   localparam C_WDAT_FIFO_ADDR_BITS = 'd0;
   localparam C_RDAT_FIFO_ADDR_BITS = 'd0;
   localparam C_NOWAIT_WR_DATA_DONE = 1'b1;
   
   // Global System Signals
   input AXI_ACLK;
   input AXI_ARESETN;

   // Write Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0] AXI_AWID;
   input [C_AXI_ADDR_WIDTH-1:0] AXI_AWADDR;
   input [C_AXI_LEN_WIDTH-1:0]  AXI_AWLEN;
   input [2:0]                  AXI_AWSIZE;
   input [1:0]                  AXI_AWBURST;
   input                        AXI_AWVALID;
   output                       AXI_AWREADY;
   
   // Write Data Channel Signals
   input [C_AXI_DATA_WIDTH-1:0] AXI_WDATA;
   input [(C_AXI_DATA_WIDTH/8)-1:0] AXI_WSTRB;
   input                            AXI_WLAST;
   input                            AXI_WVALID;
   output                           AXI_WREADY;
   
   // Write Response Channel Signals
   output [C_AXI_ID_WIDTH-1:0]      AXI_BID;
   output [1:0]                     AXI_BRESP;
   output                           AXI_BVALID;
   input                            AXI_BREADY;

   // Read Address Channel Signals
   input [C_AXI_ID_WIDTH-1:0] AXI_ARID;
   input [C_AXI_ADDR_WIDTH-1:0] AXI_ARADDR;
   input [C_AXI_LEN_WIDTH-1:0]  AXI_ARLEN;
   input [2:0]                  AXI_ARSIZE;
   input [1:0]                  AXI_ARBURST;
   input                        AXI_ARVALID;
   output                       AXI_ARREADY;
   
   // Read Data Channel Signals
   output [C_AXI_ID_WIDTH-1:0]  AXI_RID;
   output [C_AXI_DATA_WIDTH-1:0] AXI_RDATA;
   output [1:0]                  AXI_RRESP;
   output                        AXI_RLAST;
   output                        AXI_RVALID;
   input                         AXI_RREADY;

   // REG
   output [1:0]  mcr0_reg_wrapsize; // wrap size
   output [1:0]  mcr1_reg_wrapsize;
   output        mcr0_reg_acs;      // asymmetric cache support
   output        mcr1_reg_acs;
   output [7:0]  mbr0_reg_a;        // memory base register address[31:24]
   output [7:0]  mbr1_reg_a;
   output        mcr0_reg_tcmo;     // tc option
   output        mcr1_reg_tcmo;
   
   output        mcr0_reg_devtype;  // device type
   output        mcr0_reg_gb_rst;
   output        mcr0_reg_mem_init;
   
   output        mcr1_reg_devtype;
   output        mcr0_reg_crt;      // configuration register target
   output        mcr1_reg_crt;
   output [3:0]  mtr0_reg_rcshi;    // read CS high time
   output [3:0]  mtr1_reg_rcshi;
   output [3:0]  mtr0_reg_wcshi;    // write CS high time
   output [3:0]  mtr1_reg_wcshi;
   output [3:0]  mtr0_reg_rcss;     // read CS setup time
   output [3:0]  mtr1_reg_rcss;
   output [3:0]  mtr0_reg_wcss;     // write CS setup time
   output [3:0]  mtr1_reg_wcss;
   output [3:0]  mtr0_reg_rcsh;     // read CS hold time
   output [3:0]  mtr1_reg_rcsh;
   output [3:0]  mtr0_reg_wcsh;     // write CS hold time
   output [3:0]  mtr1_reg_wcsh;
   output [3:0]  mtr0_reg_ltcy;     // read latency
   output [3:0]  mtr1_reg_ltcy;
   output        lbr_reg_loopback;
   output [8:0]  mcr0_reg_mlen;
   output [8:0]  mcr1_reg_mlen;
   output        mcr0_reg_men;
   output        mcr1_reg_men;
   output [1:0]  tar_reg_rta;
   output [1:0]  tar_reg_wta;
   
   // RPC
   input         int_n;
   output        wp_n;
   // Port
   output        IENOn;
   output [1:0]  GPO;
    // Status
   input         mem_rd_active;
   input         mem_wr_active;
   input         mem_wr_rsto_status;
   input         mem_wr_slv_status;
   input         mem_wr_dec_status;
   input         mem_rd_stall_status;
   input         mem_rd_rsto_status;
   input         mem_rd_slv_status;
   input         mem_rd_dec_status;
   
   /*AUTOINPUT*/
   /*AUTOOUTPUT*/
   
   wire                          clk = AXI_ACLK;
   wire                          reset_n = AXI_ARESETN;
   
   wire [1:0]                    ip_data_size = 2'b10; // 4-byte
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [31:0]          axi2ip_address;         // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v
   wire [1:0]           axi2ip_burst;           // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v
   wire [1:0]           axi2ip_size;           // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v   
   
   wire [C_AXI_DATA_WIDTH-1:0] axi2ip_data;     // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v
   wire                 axi2ip_data_ready;      // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v
   wire                 axi2ip_data_valid;      // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v
   wire [9:0]           axi2ip_len;             // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v
   wire                 axi2ip_rw_n;            // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v
   wire [(C_AXI_DATA_WIDTH/8)-1:0] axi2ip_strb; // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v
   wire                 axi2ip_valid;           // From rpc2_ctrl_axi_channel of rpc2_ctrl_axi_channel.v
   wire [31:0]          ip_data;                // From control_register of rpc2_ctrl_control_register.v
   wire                 ip_data_last;           // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire                 ip_data_ready;          // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire                 ip_data_valid;          // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire [1:0]           ip_rd_error;            // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire                 ip_ready;               // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire [3:0]           ip_strb;                // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire                 ip_wr_done;             // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire [1:0]           ip_wr_error;            // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire [4:0]           reg_addr;               // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire                 reg_rd_en;              // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   wire [3:0]           reg_wr_en;              // From rpc2_ctrl_reg_logic of rpc2_ctrl_reg_logic.v
   // End of automatics

   /* rpc2_ctrl_axi_channel AUTO_TEMPLATE (
    .axi2ip_len(axi2ip_len[9:0]),
    );
    */
   rpc2_ctrl_axi_channel
     #(C_AXI_ID_WIDTH,
       C_AXI_ADDR_WIDTH,
       C_AXI_DATA_WIDTH,
       C_AXI_LEN_WIDTH,
       C_ADR_FIFO_ADDR_BITS,
       C_AW_FIFO_ADDR_BITS,
       C_AR_FIFO_ADDR_BITS,
       C_WDAT_FIFO_ADDR_BITS,
       C_RDAT_FIFO_ADDR_BITS,
       C_NOWAIT_WR_DATA_DONE)
     rpc2_ctrl_axi_channel (/*AUTOINST*/
                            // Outputs
                            .AXI_AWREADY        (AXI_AWREADY),
                            .AXI_WREADY         (AXI_WREADY),
                            .AXI_BID            (AXI_BID[C_AXI_ID_WIDTH-1:0]),
                            .AXI_BRESP          (AXI_BRESP[1:0]),
                            .AXI_BVALID         (AXI_BVALID),
                            .AXI_ARREADY        (AXI_ARREADY),
                            .AXI_RID            (AXI_RID[C_AXI_ID_WIDTH-1:0]),
                            .AXI_RDATA          (AXI_RDATA[C_AXI_DATA_WIDTH-1:0]),
                            .AXI_RRESP          (AXI_RRESP[1:0]),
                            .AXI_RLAST          (AXI_RLAST),
                            .AXI_RVALID         (AXI_RVALID),
                            .axi2ip_valid       (axi2ip_valid),
                            .axi2ip_rw_n        (axi2ip_rw_n),
                            .axi2ip_address     (axi2ip_address[31:0]),
                            .axi2ip_burst       (axi2ip_burst[1:0]),
                            .axi2ip_size        (axi2ip_size[1:0]),
                            
                            .axi2ip_len         (axi2ip_len[9:0]), // Templated
                            .axi2ip_data_valid  (axi2ip_data_valid),
                            .axi2ip_strb        (axi2ip_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                            .axi2ip_data        (axi2ip_data[C_AXI_DATA_WIDTH-1:0]),
                            .axi2ip_data_ready  (axi2ip_data_ready),
                            // Inputs
                            .AXI_ACLK           (AXI_ACLK),
                            .AXI_ARESETN        (AXI_ARESETN),
                            .AXI_AWID           (AXI_AWID[C_AXI_ID_WIDTH-1:0]),
                            .AXI_AWADDR         (AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0]),
                            .AXI_AWLEN          (AXI_AWLEN[C_AXI_LEN_WIDTH-1:0]),
                            .AXI_AWSIZE         (AXI_AWSIZE[2:0]),
                            .AXI_AWBURST        (AXI_AWBURST[1:0]),
                            .AXI_AWVALID        (AXI_AWVALID),
                            .AXI_WDATA          (AXI_WDATA[C_AXI_DATA_WIDTH-1:0]),
                            .AXI_WSTRB          (AXI_WSTRB[(C_AXI_DATA_WIDTH/8)-1:0]),
                            .AXI_WLAST          (AXI_WLAST),
                            .AXI_WVALID         (AXI_WVALID),
                            .AXI_BREADY         (AXI_BREADY),
                            .AXI_ARID           (AXI_ARID[C_AXI_ID_WIDTH-1:0]),
                            .AXI_ARADDR         (AXI_ARADDR[C_AXI_ADDR_WIDTH-1:0]),
                            .AXI_ARLEN          (AXI_ARLEN[C_AXI_LEN_WIDTH-1:0]),
                            .AXI_ARSIZE         (AXI_ARSIZE[2:0]),
                            .AXI_ARBURST        (AXI_ARBURST[1:0]),
                            .AXI_ARVALID        (AXI_ARVALID),
                            .AXI_RREADY         (AXI_RREADY),
                            .ip_data_size       (ip_data_size[1:0]),
                            .ip_ready           (ip_ready),
                            .ip_data_ready      (ip_data_ready),
                            .ip_data_valid      (ip_data_valid),
                            .ip_data_last       (ip_data_last),
                            .ip_strb            (ip_strb[(C_AXI_DATA_WIDTH/8)-1:0]),
                            .ip_data            (ip_data[C_AXI_DATA_WIDTH-1:0]),
                            .ip_rd_error        (ip_rd_error[1:0]),
                            .ip_wr_done         (ip_wr_done),
                            .ip_wr_error        (ip_wr_error[1:0]));

   rpc2_ctrl_reg_logic
     #(C_AXI_BASEADDR,
       C_AXI_HIGHADDR)
     rpc2_ctrl_reg_logic (/*AUTOINST*/
                          // Outputs
                          .ip_ready             (ip_ready),
                          .ip_data_ready        (ip_data_ready),
                          .ip_data_valid        (ip_data_valid),
                          .ip_data_last         (ip_data_last),
                          .ip_strb              (ip_strb[3:0]),
                          .ip_rd_error          (ip_rd_error[1:0]),
                          .ip_wr_error          (ip_wr_error[1:0]),
                          .ip_wr_done           (ip_wr_done),
                          .reg_rd_en            (reg_rd_en),
                          .reg_wr_en            (reg_wr_en[3:0]),
                          .reg_addr             (reg_addr[4:0]),
                          // Inputs
                          .clk                  (clk),
                          .reset_n              (reset_n),
                          .axi2ip_valid         (axi2ip_valid),
                          .axi2ip_rw_n          (axi2ip_rw_n),
                          .axi2ip_address       (axi2ip_address[31:0]),
                          .axi2ip_burst         (axi2ip_burst[1:0]),
                          
                          .axi2ip_size          (axi2ip_size[1:0]),  
                          
                          .axi2ip_len           (axi2ip_len[7:0]),
                          .axi2ip_strb          (axi2ip_strb[3:0]),
                          .axi2ip_data_valid    (axi2ip_data_valid),
                          .axi2ip_data_ready    (axi2ip_data_ready));

   /* rpc2_ctrl_control_register AUTO_TEMPLATE (
    .reg_din(axi2ip_data[31:0]),
    .reg_dout(ip_data[31:0]),
    );
    */
   rpc2_ctrl_control_register control_register (/*AUTOINST*/
                                                // Outputs
                                                .reg_dout       (ip_data[31:0]), // Templated
                                                .mcr0_reg_wrapsize(mcr0_reg_wrapsize[1:0]),
                                                .mcr1_reg_wrapsize(mcr1_reg_wrapsize[1:0]),
                                                .mcr0_reg_acs   (mcr0_reg_acs),
                                                .mcr1_reg_acs   (mcr1_reg_acs),
                                                .mbr0_reg_a     (mbr0_reg_a[7:0]),
                                                .mbr1_reg_a     (mbr1_reg_a[7:0]),
                                                .mcr0_reg_tcmo  (mcr0_reg_tcmo),
                                                .mcr1_reg_tcmo  (mcr1_reg_tcmo),
                                                
                                                .mcr0_reg_devtype(mcr0_reg_devtype),
                                                .mcr0_reg_gb_rst(mcr0_reg_gb_rst),
                                                .mcr0_reg_mem_init(mcr0_reg_mem_init),
                                               
                                                
                                                .mcr1_reg_devtype(mcr1_reg_devtype),
                                                .mcr0_reg_crt   (mcr0_reg_crt),
                                                .mcr1_reg_crt   (mcr1_reg_crt),
                                                .mtr0_reg_rcshi (mtr0_reg_rcshi[3:0]),
                                                .mtr1_reg_rcshi (mtr1_reg_rcshi[3:0]),
                                                .mtr0_reg_wcshi (mtr0_reg_wcshi[3:0]),
                                                .mtr1_reg_wcshi (mtr1_reg_wcshi[3:0]),
                                                .mtr0_reg_rcss  (mtr0_reg_rcss[3:0]),
                                                .mtr1_reg_rcss  (mtr1_reg_rcss[3:0]),
                                                .mtr0_reg_wcss  (mtr0_reg_wcss[3:0]),
                                                .mtr1_reg_wcss  (mtr1_reg_wcss[3:0]),
                                                .mtr0_reg_rcsh  (mtr0_reg_rcsh[3:0]),
                                                .mtr1_reg_rcsh  (mtr1_reg_rcsh[3:0]),
                                                .mtr0_reg_wcsh  (mtr0_reg_wcsh[3:0]),
                                                .mtr1_reg_wcsh  (mtr1_reg_wcsh[3:0]),
                                                .mtr0_reg_ltcy  (mtr0_reg_ltcy[3:0]),
                                                .mtr1_reg_ltcy  (mtr1_reg_ltcy[3:0]),
                                                .lbr_reg_loopback(lbr_reg_loopback),
                                                .mcr0_reg_mlen  (mcr0_reg_mlen[8:0]),
                                                .mcr1_reg_mlen  (mcr1_reg_mlen[8:0]),
                                                .mcr0_reg_men   (mcr0_reg_men),
                                                .mcr1_reg_men   (mcr1_reg_men),
                                                .tar_reg_rta    (tar_reg_rta[1:0]),
                                                .tar_reg_wta    (tar_reg_wta[1:0]),
                                                .wp_n           (wp_n),
                                                .IENOn          (IENOn),
                                                .GPO            (GPO[1:0]),
                                                // Inputs
                                                .clk            (clk),
                                                .reset_n        (reset_n),
                                                .reg_addr       (reg_addr[4:0]),
                                                .reg_wr_en      (reg_wr_en[3:0]),
                                                .reg_din        (axi2ip_data[31:0]), // Templated
                                                .reg_rd_en      (reg_rd_en),
                                                .int_n          (int_n),
                                                .mem_rd_active  (mem_rd_active),
                                                .mem_wr_active  (mem_wr_active),
                                                .mem_wr_rsto_status(mem_wr_rsto_status),
                                                .mem_wr_slv_status(mem_wr_slv_status),
                                                .mem_wr_dec_status(mem_wr_dec_status),
                                                .mem_rd_stall_status(mem_rd_stall_status),
                                                .mem_rd_rsto_status(mem_rd_rsto_status),
                                                .mem_rd_slv_status(mem_rd_slv_status),
                                                .mem_rd_dec_status(mem_rd_dec_status));
   
endmodule // rpc2_ctrl_reg
// Local Variables:
// verilog-library-directories:(".")
// end:
