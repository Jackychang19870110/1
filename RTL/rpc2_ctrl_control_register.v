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
// Filename: rpc2_ctrl_control_register.v
//
//           Control Register in RPC2 Controller
//
// Created: yise  05/14/2014  version 2.2  - initial release
//          yise  09/26/2014  version 2.3  - added max_len registers
//          yise  10/30/2015  version 2.4  - added transaction alloc reg
//*************************************************************************

module rpc2_ctrl_control_register (/*AUTOARG*/
   // Outputs
   reg_dout, mcr0_reg_wrapsize, mcr1_reg_wrapsize, mcr0_reg_acs,
   mcr1_reg_acs, mbr0_reg_a, mbr1_reg_a, mcr0_reg_tcmo, mcr1_reg_tcmo,
   mcr0_reg_devtype, mcr0_reg_gb_rst, mcr0_reg_mem_init,
   mcr1_reg_devtype, mcr0_reg_crt, mcr1_reg_crt,
   mtr0_reg_rcshi, mtr1_reg_rcshi, mtr0_reg_wcshi, mtr1_reg_wcshi,
   mtr0_reg_rcss, mtr1_reg_rcss, mtr0_reg_wcss, mtr1_reg_wcss,
   mtr0_reg_rcsh, mtr1_reg_rcsh, mtr0_reg_wcsh, mtr1_reg_wcsh,
   mtr0_reg_ltcy, mtr1_reg_ltcy, lbr_reg_loopback, mcr0_reg_mlen,
   mcr1_reg_mlen, mcr0_reg_men, mcr1_reg_men, tar_reg_rta,
   tar_reg_wta, wp_n, IENOn, GPO,
   // Inputs
   clk, reset_n, reg_addr, reg_wr_en, reg_din, reg_rd_en, int_n,
   mem_rd_active, mem_wr_active, mem_wr_rsto_status,
   mem_wr_slv_status, mem_wr_dec_status, mem_rd_stall_status,
   mem_rd_rsto_status, mem_rd_slv_status, mem_rd_dec_status
   );
   localparam CSR_ADDR  = 5'd0;
   localparam IEN_ADDR  = 5'd1;
   localparam ISR_ADDR  = 5'd2;
   localparam ICR_ADDR  = 5'd3;
   localparam MBR0_ADDR = 5'd4;
   localparam MBR1_ADDR = 5'd5;
   localparam MBR2_ADDR = 5'd6;
   localparam MBR3_ADDR = 5'd7;
   localparam MCR0_ADDR = 5'd8;
   localparam MCR1_ADDR = 5'd9;
   localparam MCR2_ADDR = 5'd10;
   localparam MCR3_ADDR = 5'd11;
   localparam MTR0_ADDR = 5'd12;
   localparam MTR1_ADDR = 5'd13;
   localparam MTR2_ADDR = 5'd14;
   localparam MTR3_ADDR = 5'd15;
   localparam GPOR_ADDR = 5'd16;
   localparam WPR_ADDR  = 5'd17;
   localparam LBR_ADDR  = 5'd18;
   localparam TAR_ADDR  = 5'd19;
   
   input clk;
   input reset_n;

   input [4:0] reg_addr;
   input [3:0] reg_wr_en;
   input [31:0] reg_din;
   input        reg_rd_en;
   output [31:0] reg_dout;

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
   output        mcr0_reg_gb_rst;  // global reset  
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
//   output [8:0]  mcr0_reg_rmlen;    // read max length
//   output [8:0]  mcr1_reg_rmlen;
//   output [8:0]  mcr0_reg_wmlen;    // write max length
//   output [8:0]  mcr1_reg_wmlen;
//   output        mcr0_reg_rmen;     // read max length enable
//   output        mcr1_reg_rmen;
//   output        mcr0_reg_wmen;     // write max length enable
//   output        mcr1_reg_wmen;
   output [1:0]  tar_reg_rta;      // read transaction allocation
   output [1:0]  tar_reg_wta;      // write transaction allocation
   
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
   
   reg [7:0]     mbr0_reg_a;
   reg [7:0]     mbr1_reg_a;
   reg           mcr0_reg_tcmo;
   reg           mcr1_reg_tcmo;
   reg           mcr0_reg_acs;
   reg           mcr1_reg_acs;
   reg           mcr0_reg_crt;
   reg           mcr1_reg_crt;
   reg           mcr0_reg_devtype;
   reg           mcr0_reg_gb_rst;
   reg           mcr0_reg_mem_init;   

   
   reg           mcr1_reg_devtype;
   reg [1:0]     mcr0_reg_wrapsize;
   reg [1:0]     mcr1_reg_wrapsize;
   reg [1:0]     gpor_reg_gpo;
   reg           wpr_reg_wp;       // write protect 0:not protected, 1:protected
   reg           ien_reg_intp;     // interrupt polarity
   reg           ien_reg_rpcinte;  // interrupt enable
   reg           lbr_reg_loopback; // loopback

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg                  mcr0_reg_men;
   reg                  mcr1_reg_men;
   reg [3:0]            mtr0_reg_ltcy;
   reg [3:0]            mtr0_reg_rcsh;
   reg [3:0]            mtr0_reg_rcshi;
   reg [3:0]            mtr0_reg_rcss;
   reg [3:0]            mtr0_reg_wcsh;
   reg [3:0]            mtr0_reg_wcshi;
   reg [3:0]            mtr0_reg_wcss;
   reg [3:0]            mtr1_reg_ltcy;
   reg [3:0]            mtr1_reg_rcsh;
   reg [3:0]            mtr1_reg_rcshi;
   reg [3:0]            mtr1_reg_rcss;
   reg [3:0]            mtr1_reg_wcsh;
   reg [3:0]            mtr1_reg_wcshi;
   reg [3:0]            mtr1_reg_wcss;
   reg [31:0]           reg_dout;
   // End of automatics
   reg                  int_status;
   reg                  int_status_in;
   wire                 ieno_n;
   reg [5:0]            max_len_l0;
   reg [5:0]            max_len_l1;
   reg [2:0]            max_len_h0;
   reg [2:0]            max_len_h1;
   reg [1:0]            tar_reg_rta;
   reg [1:0]            tar_reg_wta;

   
   assign wp_n = ~wpr_reg_wp;
   assign ieno_n = ~(ien_reg_rpcinte & int_status);
   assign IENOn = (ien_reg_intp) ? ~ieno_n : ieno_n;
   assign GPO = gpor_reg_gpo;
   assign mcr0_reg_mlen = {max_len_h0, max_len_l0};
   assign mcr1_reg_mlen = {max_len_h1, max_len_l1};
   
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         int_status_in <= 1'b0;
         int_status <= 1'b0;
      end
      else begin
         int_status_in <= ~int_n;
         int_status <= int_status_in;
      end
   end
   
   //----------------------------------------
   // READ
   //----------------------------------------
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        reg_dout <= 32'h00000000;
      else if (reg_rd_en) begin
         case (reg_addr[4:0])
           CSR_ADDR: reg_dout  <= {5'h00, mem_wr_rsto_status, mem_wr_slv_status, mem_wr_dec_status, 7'h00, mem_wr_active, 
                                   4'h0, mem_rd_stall_status, mem_rd_rsto_status, mem_rd_slv_status, mem_rd_dec_status, 7'h00, mem_rd_active};
           IEN_ADDR: reg_dout  <= {ien_reg_intp, 30'h00000000, ien_reg_rpcinte};
           ISR_ADDR: reg_dout  <= {31'h00000000, int_status};
           ICR_ADDR: reg_dout  <= 32'h00000000;
           MBR0_ADDR: reg_dout <= {mbr0_reg_a, 24'h000000};
           MBR1_ADDR: reg_dout <= {mbr1_reg_a, 24'h000000};
           MBR2_ADDR: reg_dout <= 32'h00000000;
           MBR3_ADDR: reg_dout <= 32'h00000000;
           MCR0_ADDR: reg_dout <= {mcr0_reg_men, 4'h0, mcr0_reg_mlen, mcr0_reg_tcmo, mcr0_reg_acs,
//                                   10'h000, mcr0_reg_crt, mcr0_reg_devtype, 2'b00, mcr0_reg_wrapsize};
                                   10'h000, mcr0_reg_crt, mcr0_reg_devtype, mcr0_reg_gb_rst, mcr0_reg_mem_init, mcr0_reg_wrapsize};                                   
           MCR1_ADDR: reg_dout <= {mcr1_reg_men, 4'h0, mcr1_reg_mlen, mcr1_reg_tcmo, mcr1_reg_acs, 
                                   10'h000, mcr1_reg_crt, mcr1_reg_devtype, 2'b00, mcr1_reg_wrapsize};
           MCR2_ADDR: reg_dout <= 32'h00000000;
           MCR3_ADDR: reg_dout <= 32'h00000000;
           MTR0_ADDR: reg_dout <= {mtr0_reg_rcshi, mtr0_reg_wcshi, mtr0_reg_rcss, mtr0_reg_wcss, mtr0_reg_rcsh, mtr0_reg_wcsh, 4'h0, mtr0_reg_ltcy};
           MTR1_ADDR: reg_dout <= {mtr1_reg_rcshi, mtr1_reg_wcshi, mtr1_reg_rcss, mtr1_reg_wcss, mtr1_reg_rcsh, mtr1_reg_wcsh, 4'h0, mtr1_reg_ltcy};
           MTR2_ADDR: reg_dout <= 32'h00000000;
           MTR3_ADDR: reg_dout <= 32'h00000000;
           GPOR_ADDR: reg_dout <= {30'h00000000, gpor_reg_gpo};
           WPR_ADDR: reg_dout  <= {31'h00000000, wpr_reg_wp};
           LBR_ADDR: reg_dout  <= {31'h00000000, lbr_reg_loopback};
           TAR_ADDR: reg_dout  <= {26'h0000000, tar_reg_rta, 2'b00, tar_reg_wta};
         endcase
      end
   end

   //----------------------------------------
   // WRITE
   //----------------------------------------
   // [7:0]
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         ien_reg_rpcinte <= 1'b0;
         mcr0_reg_wrapsize <= 2'b11;
         mcr1_reg_wrapsize <= 2'b11;
         
         mcr0_reg_devtype <= 1'b0;
         mcr0_reg_gb_rst  <= 1'b0;
         
         mcr1_reg_devtype <= 1'b0;
         mcr0_reg_crt <= 1'b0;
         mcr1_reg_crt <= 1'b0;
         mtr0_reg_ltcy <= 4'h1;
         mtr1_reg_ltcy <= 4'h1;
         gpor_reg_gpo <= 2'b00;
         wpr_reg_wp <= 1'b0;
         lbr_reg_loopback <= 1'b0;
         tar_reg_rta <= 2'b00;
         tar_reg_wta <= 2'b00;
      end
      else if (reg_wr_en[0]) begin
         case (reg_addr[4:0])
//         CSR_ADDR:
           IEN_ADDR: ien_reg_rpcinte <= reg_din[0];
//         ISR_ADDR:
//         ICR_ADDR:
//         MBR0_ADDR:
//         MBR1_ADDR:
//         MBR2_ADDR:
//         MBR3_ADDR:
           MCR0_ADDR: begin
              mcr0_reg_wrapsize <= reg_din[1:0];
              mcr0_reg_mem_init <= reg_din[2];
              mcr0_reg_gb_rst   <= reg_din[3];              
              mcr0_reg_devtype  <= reg_din[4];
              mcr0_reg_crt      <= reg_din[5];
           end
           MCR1_ADDR: begin
              mcr1_reg_wrapsize <= reg_din[1:0];
              mcr1_reg_devtype  <= reg_din[4];
              mcr1_reg_crt      <= reg_din[5];
           end
//         MCR2_ADDR:;
//         MCR3_ADDR:;
           MTR0_ADDR: mtr0_reg_ltcy <= reg_din[3:0];
           MTR1_ADDR: mtr1_reg_ltcy <= reg_din[3:0];
//         MTR2_ADDR:;
//         MTR3_ADDR:;
           GPOR_ADDR: gpor_reg_gpo <= reg_din[1:0];
           WPR_ADDR: wpr_reg_wp <= reg_din[0];
           LBR_ADDR: lbr_reg_loopback <= reg_din[0];
           TAR_ADDR: begin
              tar_reg_rta <= reg_din[5:4];
              tar_reg_wta <= reg_din[1:0];
           end
         endcase
      end
   end

   // [15:8]
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         mtr0_reg_rcsh <= 4'h0;
         mtr1_reg_rcsh <= 4'h0;
         mtr0_reg_wcsh <= 4'h0;
         mtr1_reg_wcsh <= 4'h0;
      end
      else if (reg_wr_en[1]) begin
         case (reg_addr[4:0])
//         CSR_ADDR:
//         IEN_ADDR:
//         ISR_ADDR:
//         ICR_ADDR:
//         MBR0_ADDR:
//         MBR1_ADDR:
//         MBR2_ADDR:
//         MBR3_ADDR:
//         MCR0_ADDR: 
//         MCR1_ADDR:
//         MCR2_ADDR:;
//         MCR3_ADDR:;
           MTR0_ADDR: begin
              mtr0_reg_wcsh <= reg_din[11:8];
              mtr0_reg_rcsh <= reg_din[15:12];
           end
           MTR1_ADDR: begin
              mtr1_reg_wcsh <= reg_din[11:8];
              mtr1_reg_rcsh <= reg_din[15:12];
           end
//         MTR2_ADDR:;
//         MTR3_ADDR:;
//         GPOR_ADDR:;     
//         WPR_ADDR:;
//         LBR_ADDR:;
//         TAR_ADDR:;
         endcase
      end
   end


   // [23:16]
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         mcr0_reg_acs <= 1'b0;
         mcr1_reg_acs <= 1'b0;
         mcr0_reg_tcmo <= 1'b0;
         mcr1_reg_tcmo <= 1'b0;
         mtr0_reg_rcss <= 4'h0;
         mtr1_reg_rcss <= 4'h0;
         mtr0_reg_wcss <= 4'h0;
         mtr1_reg_wcss <= 4'h0;
         max_len_l0 <= 6'h00;
         max_len_l1 <= 6'h00;
      end
      else if (reg_wr_en[2]) begin
         case (reg_addr[4:0])
//         CSR_ADDR:
//         IEN_ADDR:
//         ISR_ADDR:
//         ICR_ADDR:
//         MBR0_ADDR:
//         MBR1_ADDR:
//         MBR2_ADDR:
//         MBR3_ADDR:
           MCR0_ADDR: begin
              mcr0_reg_acs  <= reg_din[16];
              mcr0_reg_tcmo <= reg_din[17];
              max_len_l0 <= reg_din[23:18];
           end
           MCR1_ADDR: begin
              mcr1_reg_acs  <= reg_din[16];
              mcr1_reg_tcmo <= reg_din[17];
              max_len_l1 <= reg_din[23:18];
           end
//         MCR2_ADDR:;
//         MCR3_ADDR:;
           MTR0_ADDR: begin
              mtr0_reg_wcss <= reg_din[19:16];
              mtr0_reg_rcss <= reg_din[23:20];
           end
           MTR1_ADDR: begin
              mtr1_reg_wcss <= reg_din[19:16];
              mtr1_reg_rcss <= reg_din[23:20];
           end
//         MTR2_ADDR:;
//         MTR3_ADDR:;
//         GPOR_ADDR:;     
//         WPR_ADDR:;
//         LBR_ADDR:;
//         TAR_ADDR:;
         endcase
      end
   end

   // [31:24]
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         ien_reg_intp <= 1'b0;
         mbr0_reg_a <= 8'h00;
         mbr1_reg_a <= 8'h00;
         mtr0_reg_rcshi <= 4'h0;
         mtr0_reg_wcshi <= 4'h0;
         mtr1_reg_rcshi <= 4'h0;
         mtr1_reg_wcshi <= 4'h0;
         max_len_h0  <= 3'h0;
         max_len_h1  <= 3'h0;
         mcr0_reg_men <= 1'b0;
         mcr1_reg_men <= 1'b0;
      end
      else if (reg_wr_en[3]) begin
         case (reg_addr[4:0])
//         CSR_ADDR:
           IEN_ADDR: ien_reg_intp <= reg_din[31];
//         ISR_ADDR:
//         ICR_ADDR:
           MBR0_ADDR: mbr0_reg_a <= reg_din[31:24];
           MBR1_ADDR: mbr1_reg_a <= reg_din[31:24];
//         MBR2_ADDR:
//         MBR3_ADDR:
           MCR0_ADDR: begin
              mcr0_reg_men <= reg_din[31];
              max_len_h0 <= reg_din[26:24];
           end
           MCR1_ADDR: begin
              mcr1_reg_men <= reg_din[31];
              max_len_h1 <= reg_din[26:24];
           end
//         MCR2_ADDR:;
//         MCR3_ADDR:;
           MTR0_ADDR: begin
              mtr0_reg_wcshi <= reg_din[27:24];
              mtr0_reg_rcshi <= reg_din[31:28];
           end
           MTR1_ADDR: begin
              mtr1_reg_wcshi <= reg_din[27:24];
              mtr1_reg_rcshi <= reg_din[31:28];
           end
//         MTR2_ADDR:;
//         MTR3_ADDR:;
//         GPOR_ADDR:;     
//         WPR_ADDR:;
//         LBR_ADDR:;
//         TAR_ADDR:;
         endcase
      end
   end
endmodule // rpc2_ctrl_control_register
