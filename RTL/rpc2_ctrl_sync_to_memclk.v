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
// Filename: rpc2_ctrl_sync_to_memclk.v
//
//           Sync to Memory clock from Register clock
//
// Created: yise    01/12/2013  version 2.0 - initial release
//          yise    09/26/2014  version 2.3 - added max_len sigs
//*************************************************************************

module rpc2_ctrl_sync_to_memclk (/*AUTOARG*/
   // Outputs
   reg_wrap_size0, reg_wrap_size1, reg_acs0, reg_acs1, reg_mbr0, 
   reg_mbr1, reg_tco0, reg_tco1, reg_dt0, reg_gb_rst, reg_mem_init,
   reg_dt1, reg_crt0, 
   reg_crt1, reg_lbr, reg_latency0, reg_latency1, reg_rd_cshi0, 
   reg_rd_cshi1, reg_rd_css0, reg_rd_css1, reg_rd_csh0, reg_rd_csh1, 
   reg_wr_cshi0, reg_wr_cshi1, reg_wr_css0, reg_wr_css1, reg_wr_csh0, 
   reg_wr_csh1, reg_max_length0, reg_max_length1, reg_max_len_en0, 
   reg_max_len_en1, 
   // Inputs
   clk, reset_n, mcr0_reg_wrapsize, mcr1_reg_wrapsize, mcr0_reg_acs, 
   mcr1_reg_acs, mbr0_reg_a, mbr1_reg_a, mcr0_reg_tcmo, 
   mcr1_reg_tcmo, mcr0_reg_devtype, mcr0_reg_gb_rst, mcr0_reg_mem_init,
   mcr1_reg_devtype, mcr0_reg_crt, 
   mcr1_reg_crt, mtr0_reg_rcshi, mtr1_reg_rcshi, mtr0_reg_wcshi, 
   mtr1_reg_wcshi, mtr0_reg_rcss, mtr1_reg_rcss, mtr0_reg_wcss, 
   mtr1_reg_wcss, mtr0_reg_rcsh, mtr1_reg_rcsh, mtr0_reg_wcsh, 
   mtr1_reg_wcsh, mtr0_reg_ltcy, mtr1_reg_ltcy, lbr_reg_loopback, 
   mcr0_reg_mlen, mcr1_reg_mlen, mcr0_reg_men, mcr1_reg_men
   );
   input clk;
   input reset_n;

   input [1:0] mcr0_reg_wrapsize; // wrap size
   input [1:0] mcr1_reg_wrapsize;
   input       mcr0_reg_acs;      // asymmetric cache support
   input       mcr1_reg_acs;
   input [7:0] mbr0_reg_a;        // memory base register address[31:24]
   input [7:0] mbr1_reg_a;
   input       mcr0_reg_tcmo;     // tc option
   input       mcr1_reg_tcmo;
   input       mcr0_reg_devtype;  // device type
   input       mcr0_reg_gb_rst;
   input       mcr0_reg_mem_init;   

   
   input       mcr1_reg_devtype;
   input       mcr0_reg_crt;      // configuration register target
   input       mcr1_reg_crt;
   input [3:0] mtr0_reg_rcshi;    // read CS high time
   input [3:0] mtr1_reg_rcshi;
   input [3:0] mtr0_reg_wcshi;    // write CS high time
   input [3:0] mtr1_reg_wcshi;
   input [3:0] mtr0_reg_rcss;     // read CS setup time
   input [3:0] mtr1_reg_rcss;
   input [3:0] mtr0_reg_wcss;     // write CS setup time
   input [3:0] mtr1_reg_wcss;
   input [3:0] mtr0_reg_rcsh;     // read CS hold time
   input [3:0] mtr1_reg_rcsh;
   input [3:0] mtr0_reg_wcsh;     // write CS hold time
   input [3:0] mtr1_reg_wcsh;
   input [3:0] mtr0_reg_ltcy;     // read latency
   input [3:0] mtr1_reg_ltcy;
   input       lbr_reg_loopback;
   input [8:0] mcr0_reg_mlen;
   input [8:0] mcr1_reg_mlen;
   input       mcr0_reg_men;
   input       mcr1_reg_men;
   
   output [1:0] reg_wrap_size0;
   output [1:0] reg_wrap_size1;
   output       reg_acs0;
   output       reg_acs1;
   output [7:0] reg_mbr0;
   output [7:0] reg_mbr1;
   output       reg_tco0;
   output       reg_tco1;
   
   
   output       reg_dt0;
   output       reg_gb_rst;
   output       reg_mem_init;

   
   output       reg_dt1;
   output       reg_crt0;
   output       reg_crt1;
   output       reg_lbr;
   output [3:0] reg_latency0;
   output [3:0] reg_latency1;
   output [3:0] reg_rd_cshi0;
   output [3:0] reg_rd_cshi1;
   output [3:0] reg_rd_css0;
   output [3:0] reg_rd_css1;
   output [3:0] reg_rd_csh0;
   output [3:0] reg_rd_csh1;
   output [3:0] reg_wr_cshi0;
   output [3:0] reg_wr_cshi1;
   output [3:0] reg_wr_css0;
   output [3:0] reg_wr_css1;
   output [3:0] reg_wr_csh0;
   output [3:0] reg_wr_csh1;
   output [8:0] reg_max_length0;
   output [8:0] reg_max_length1;
   output       reg_max_len_en0;
   output       reg_max_len_en1;
   
   reg [1:0]    reg_wrap_size0_ff1;
   reg [1:0]    reg_wrap_size1_ff1;
   reg          reg_acs0_ff1;
   reg          reg_acs1_ff1;
   reg [7:0]    reg_mbr0_ff1;
   reg [7:0]    reg_mbr1_ff1;
   reg          reg_tco0_ff1;
   reg          reg_tco1_ff1;
   
   reg          reg_dt0_ff1;
   reg          reg_gb_rst_ff1;
   reg          reg_mem_init_ff1;
  
   reg          reg_dt1_ff1;
   reg          reg_crt0_ff1;
   reg          reg_crt1_ff1;
   reg          reg_lbr_ff1;
   reg [3:0]    reg_latency0_ff1;
   reg [3:0]    reg_latency1_ff1;
   reg [3:0]    reg_rd_cshi0_ff1;
   reg [3:0]    reg_rd_cshi1_ff1;
   reg [3:0]    reg_rd_css0_ff1;
   reg [3:0]    reg_rd_css1_ff1;
   reg [3:0]    reg_rd_csh0_ff1;
   reg [3:0]    reg_rd_csh1_ff1;
   reg [3:0]    reg_wr_cshi0_ff1;
   reg [3:0]    reg_wr_cshi1_ff1;
   reg [3:0]    reg_wr_css0_ff1;
   reg [3:0]    reg_wr_css1_ff1;
   reg [3:0]    reg_wr_csh0_ff1;
   reg [3:0]    reg_wr_csh1_ff1;
   reg [8:0]    reg_max_length0_ff1;
   reg [8:0]    reg_max_length1_ff1;
   reg          reg_max_len_en0_ff1;
   reg          reg_max_len_en1_ff1;

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg                  reg_acs0;
   reg                  reg_acs1;
   reg                  reg_crt0;
   reg                  reg_crt1;
   
   
   reg                  reg_dt0;
   reg                  reg_gb_rst;
   reg                  reg_mem_init;   
   
   
   reg                  reg_dt1;
   reg [3:0]            reg_latency0;
   reg [3:0]            reg_latency1;
   reg                  reg_lbr;
   reg                  reg_max_len_en0;
   reg                  reg_max_len_en1;
   reg [8:0]            reg_max_length0;
   reg [8:0]            reg_max_length1;
   reg [7:0]            reg_mbr0;
   reg [7:0]            reg_mbr1;
   reg [3:0]            reg_rd_csh0;
   reg [3:0]            reg_rd_csh1;
   reg [3:0]            reg_rd_cshi0;
   reg [3:0]            reg_rd_cshi1;
   reg [3:0]            reg_rd_css0;
   reg [3:0]            reg_rd_css1;
   reg                  reg_tco0;
   reg                  reg_tco1;
   reg [3:0]            reg_wr_csh0;
   reg [3:0]            reg_wr_csh1;
   reg [3:0]            reg_wr_cshi0;
   reg [3:0]            reg_wr_cshi1;
   reg [3:0]            reg_wr_css0;
   reg [3:0]            reg_wr_css1;
   reg [1:0]            reg_wrap_size0;
   reg [1:0]            reg_wrap_size1;
   // End of automatics
   
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         reg_wrap_size0_ff1 <= 2'b00;
         reg_wrap_size0     <= 2'b00;
         reg_wrap_size1_ff1 <= 2'b00;
         reg_wrap_size1     <= 2'b00;
         reg_acs0_ff1 <= 1'b0;
         reg_acs0     <= 1'b0;
         reg_acs1_ff1 <= 1'b0;
         reg_acs1     <= 1'b0;
         reg_mbr0_ff1 <= 8'h00;
         reg_mbr0     <= 8'h00;
         reg_mbr1_ff1 <= 8'h00;
         reg_mbr1     <= 8'h00;
         reg_tco0_ff1 <= 1'b0;
         reg_tco0     <= 1'b0;
         reg_tco1_ff1 <= 1'b0;
         reg_tco1     <= 1'b0;
         
         reg_dt0_ff1  <= 1'b0;
         reg_dt0      <= 1'b0;
         reg_gb_rst_ff1  <= 1'b0;
         reg_gb_rst      <= 1'b0;
         reg_mem_init_ff1  <= 1'b0;
         reg_mem_init      <= 1'b0;
         
         
         
         reg_dt1_ff1  <= 1'b0;
         reg_dt1      <= 1'b0;
         reg_crt0_ff1 <= 1'b0;
         reg_crt0     <= 1'b0;
         reg_crt1_ff1 <= 1'b0;
         reg_crt1     <= 1'b0;
         reg_lbr_ff1  <= 1'b0;
         reg_lbr      <= 1'b0;
         reg_latency0_ff1 <= 4'h0;
         reg_latency0     <= 4'h0;
         reg_latency1_ff1 <= 4'h0;
         reg_latency1     <= 4'h0;
         reg_rd_cshi0_ff1 <= 4'h0;
         reg_rd_cshi0     <= 4'h0;
         reg_rd_cshi1_ff1 <= 4'h0;
         reg_rd_cshi1     <= 4'h0;
         reg_rd_css0_ff1  <= 4'h0;
         reg_rd_css0      <= 4'h0;
         reg_rd_css1_ff1  <= 4'h0;
         reg_rd_css1      <= 4'h0;
         reg_rd_csh0_ff1  <= 4'h0;
         reg_rd_csh0      <= 4'h0;
         reg_rd_csh1_ff1  <= 4'h0;
         reg_rd_csh1      <= 4'h0;
         reg_wr_cshi0_ff1 <= 4'h0;
         reg_wr_cshi0     <= 4'h0;
         reg_wr_cshi1_ff1 <= 4'h0;
         reg_wr_cshi1     <= 4'h0;
         reg_wr_css0_ff1  <= 4'h0;
         reg_wr_css0      <= 4'h0;
         reg_wr_css1_ff1  <= 4'h0;
         reg_wr_css1      <= 4'h0;
         reg_wr_csh0_ff1  <= 4'h0;
         reg_wr_csh0      <= 4'h0;
         reg_wr_csh1_ff1  <= 4'h0;
         reg_wr_csh1      <= 4'h0;
         reg_max_length0     <= 9'h000;
         reg_max_length0_ff1 <= 9'h000;
         reg_max_length1     <= 9'h000;
         reg_max_length1_ff1 <= 9'h000;
         reg_max_len_en0     <= 1'b0;
         reg_max_len_en0_ff1 <= 1'b0;
         reg_max_len_en1     <= 1'b0;
         reg_max_len_en1_ff1 <= 1'b0; 
      end
      else begin
         reg_wrap_size0_ff1 <= mcr0_reg_wrapsize;
         reg_wrap_size0     <= reg_wrap_size0_ff1;
         reg_wrap_size1_ff1 <= mcr1_reg_wrapsize;
         reg_wrap_size1     <= reg_wrap_size1_ff1;
         reg_acs0_ff1 <= mcr0_reg_acs;
         reg_acs0     <= reg_acs0_ff1;
         reg_acs1_ff1 <= mcr1_reg_acs;
         reg_acs1     <= reg_acs1_ff1;
         reg_mbr0_ff1 <= mbr0_reg_a;
         reg_mbr0     <= reg_mbr0_ff1;
         reg_mbr1_ff1 <= mbr1_reg_a;
         reg_mbr1     <= reg_mbr1_ff1;
         reg_tco0_ff1 <= mcr0_reg_tcmo;
         reg_tco0     <= reg_tco0_ff1;
         reg_tco1_ff1 <= mcr1_reg_tcmo;
         reg_tco1     <= reg_tco1_ff1;
         
         reg_dt0_ff1     <= mcr0_reg_devtype;
         reg_dt0         <= reg_dt0_ff1;
         
         reg_gb_rst_ff1  <= mcr0_reg_gb_rst;
         reg_gb_rst      <= reg_gb_rst_ff1;         

         reg_mem_init_ff1  <= mcr0_reg_mem_init;
         reg_mem_init      <= reg_mem_init_ff1; 

         
        
         reg_dt1_ff1  <= mcr1_reg_devtype;
         reg_dt1      <= reg_dt1_ff1;
         reg_crt0_ff1 <= mcr0_reg_crt;
         reg_crt0     <= reg_crt0_ff1;
         reg_crt1_ff1 <= mcr1_reg_crt;
         reg_crt1     <= reg_crt1_ff1;
         reg_lbr_ff1  <= lbr_reg_loopback;
         reg_lbr      <= reg_lbr_ff1;

         reg_latency0_ff1 <= mtr0_reg_ltcy;
         reg_latency0     <= reg_latency0_ff1;
         reg_latency1_ff1 <= mtr1_reg_ltcy;
         reg_latency1     <= reg_latency1_ff1;
         reg_rd_cshi0_ff1 <= mtr0_reg_rcshi;
         reg_rd_cshi0     <= reg_rd_cshi0_ff1;
         reg_rd_cshi1_ff1 <= mtr1_reg_rcshi;
         reg_rd_cshi1     <= reg_rd_cshi1_ff1;
         reg_rd_css0_ff1  <= mtr0_reg_rcss;
         reg_rd_css0      <= reg_rd_css0_ff1;
         reg_rd_css1_ff1  <= mtr1_reg_rcss;
         reg_rd_css1      <= reg_rd_css1_ff1;
         reg_rd_csh0_ff1  <= mtr0_reg_rcsh;
         reg_rd_csh0      <= reg_rd_csh0_ff1;
         reg_rd_csh1_ff1  <= mtr1_reg_rcsh;
         reg_rd_csh1      <= reg_rd_csh1_ff1;
         reg_wr_cshi0_ff1 <= mtr0_reg_wcshi;
         reg_wr_cshi0     <= reg_wr_cshi0_ff1;
         reg_wr_cshi1_ff1 <= mtr1_reg_wcshi;
         reg_wr_cshi1     <= reg_wr_cshi1_ff1;
         reg_wr_css0_ff1  <= mtr0_reg_wcss;
         reg_wr_css0      <= reg_wr_css0_ff1;
         reg_wr_css1_ff1  <= mtr1_reg_wcss;
         reg_wr_css1      <= reg_wr_css1_ff1;
         reg_wr_csh0_ff1  <= mtr0_reg_wcsh;
         reg_wr_csh0      <= reg_wr_csh0_ff1;
         reg_wr_csh1_ff1  <= mtr1_reg_wcsh;
         reg_wr_csh1      <= reg_wr_csh1_ff1;

         reg_max_length0     <= reg_max_length0_ff1;
         reg_max_length0_ff1 <= mcr0_reg_mlen;
         reg_max_length1     <= reg_max_length1_ff1;
         reg_max_length1_ff1 <= mcr1_reg_mlen;
         reg_max_len_en0     <= reg_max_len_en0_ff1;
         reg_max_len_en0_ff1 <= mcr0_reg_men;
         reg_max_len_en1     <= reg_max_len_en1_ff1;
         reg_max_len_en1_ff1 <= mcr1_reg_men; 
      end
   end
endmodule // rpc2_ctrl_sync_to_memclk

