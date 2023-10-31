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
// Filename: rpc2_ctrl_reg_logic.v
//
//           Logic block for RPC2 Controller
//
// Created: yise  01/12/2014  version 2.0  - initial release
//*************************************************************************
// Burst
`define FIXED  2'b00
//`define INCR   2'b01
`define WRAP   2'b10
// Error
`define OKAY   2'b00
`define SLVERR 2'b10
`define DECERR 2'b11

module rpc2_ctrl_reg_logic (/*AUTOARG*/
   // Outputs
   ip_ready, ip_data_ready, ip_data_valid, ip_data_last, ip_strb, 
   ip_rd_error, ip_wr_error, ip_wr_done, reg_rd_en, reg_wr_en, 
   reg_addr, 
   // Inputs
   clk, reset_n, axi2ip_valid, axi2ip_rw_n, axi2ip_address,
   axi2ip_size,   
   axi2ip_burst, axi2ip_len, axi2ip_strb, axi2ip_data_valid, 
   axi2ip_data_ready
   );
   parameter C_AXI_REG_BASEADDR = 32'h00000000;
   parameter C_AXI_REG_HIGHADDR = 32'h0000004B;
   
   // state
   localparam INIT    = 4'b0001;
   localparam READ    = 4'b0010;
   localparam RD_DONE = 4'b0100;
   localparam WRITE   = 4'b1000;
   
   input clk;
   input reset_n;

   // AXI address
   output    ip_ready;
   input     axi2ip_valid;
   input     axi2ip_rw_n;
   input [31:0] axi2ip_address;
   input [1:0]  axi2ip_burst;
   input [1:0]  axi2ip_size;
   
   input [7:0]  axi2ip_len;
   
   // AXI write data
   output       ip_data_ready;
   input [3:0]  axi2ip_strb;
//   input [31:0] axi2ip_data;
   input        axi2ip_data_valid;
   
   // AXI read data
   output       ip_data_valid;
   output       ip_data_last;
   output [3:0] ip_strb;
//   output [31:0] ip_data;
   output [1:0]  ip_rd_error;
   input         axi2ip_data_ready;
   
   // AXI write response
   output [1:0]  ip_wr_error;
   output        ip_wr_done;

   // REG interface
   output        reg_rd_en;
   output [3:0]  reg_wr_en;
   output [4:0]  reg_addr;
      
   wire          axi2ip_data_valid;

   wire          reg_rd_en;
   wire [3:0]    reg_wr_en;
   reg [4:0]     reg_addr;
//   wire [31:0]   reg_dout;
//   wire [31:0]   reg_din;
   
   wire          rd_last;
   wire          wr_en;
   wire          wr_last;

      
   reg [7:0]     rw_counter;
   
   reg [7:0]     burst_length;
   reg           burst_fixed;

   wire          rd_slave_error;
   wire          rd_dec_error;
   wire          wr_slave_error;
   wire          wr_dec_error;

   wire          addr_vr;
   wire          rd_data_vr;
   wire          wr_data_vr;

   reg [3:0]     state;
   reg [3:0]     next_state;

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   // End of automatics
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg                  ip_data_last;
   reg                  ip_data_valid;
   reg [1:0]            ip_rd_error;
   reg [1:0]            ip_wr_error;
   // End of automatics
   
   assign  addr_vr = axi2ip_valid & ip_ready;
   assign  rd_data_vr = axi2ip_data_ready & ip_data_valid;
   assign  wr_data_vr = axi2ip_data_valid & ip_data_ready;
   
   assign  rd_slave_error = ((axi2ip_burst==`WRAP) || (|axi2ip_len)) ? 1'b1: 1'b0;
   assign  rd_dec_error = ((axi2ip_address<C_AXI_REG_BASEADDR) ||
                           (axi2ip_address>C_AXI_REG_HIGHADDR)) ? 1'b1: 1'b0;
   assign  wr_slave_error = rd_slave_error;
   assign  wr_dec_error = rd_dec_error;
   
   // state
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        state <= INIT;
      else
        state <= next_state;
   end

   // State transition
   always @(*) begin
      next_state = state;
      case (state)
        INIT: begin
           if (axi2ip_valid & axi2ip_rw_n)
             next_state = READ;
           else if (axi2ip_valid & ~axi2ip_rw_n)
             next_state = WRITE;
        end
        READ: begin
           if (rd_last)
             next_state = RD_DONE;
        end
        RD_DONE: begin
           if (rd_data_vr)
             next_state = INIT;
        end
        WRITE: begin
           if (wr_last)
             next_state = INIT;
        end
        default:
          next_state = INIT;
      endcase // case(state)
   end
      
   // Decode
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         burst_length <= 8'h00;
         burst_fixed <= 1'b0;
      end
      else if (addr_vr) begin
         burst_length <= axi2ip_len[7:0];
         burst_fixed <= (axi2ip_burst==`FIXED) ? 1'b1: 1'b0; 
      end
   end
   
   
   assign rd_last = reg_rd_en & (rw_counter == burst_length);
   
   assign wr_en = ((state == WRITE)&wr_data_vr) & ~(|ip_wr_error);
   assign wr_last = ((state == WRITE)&wr_data_vr) & (rw_counter == burst_length);

   // read/write counter
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        rw_counter <= 8'h00;
      else if (addr_vr)
        rw_counter <= 8'h00;
      else if (reg_rd_en | ((state == WRITE)&wr_data_vr))
        rw_counter <= rw_counter + 1'b1;
   end
      
   //----------------------------------------
   // IP -> AXI
   //----------------------------------------
   assign ip_ready = (state==INIT);
   assign ip_strb = 4'b1111;
   assign ip_data_ready = (state == WRITE);
   assign ip_wr_done = (state == WRITE) & (next_state == INIT);
//   assign ip_data = reg_dout[31:0];
   
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ip_data_valid <= 1'b0;
      else if (reg_rd_en)
        ip_data_valid <= 1'b1;
      else if (rd_data_vr)
        ip_data_valid <= 1'b0;
   end

   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ip_data_last <= 1'b0;
      else if (rd_last)
        ip_data_last <= 1'b1;
      else if (rd_data_vr)
        ip_data_last <= 1'b0;
   end

   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ip_rd_error <= `OKAY;
      else if (addr_vr)
        ip_rd_error <= (rd_dec_error) ? `DECERR:
                       (rd_slave_error) ? `SLVERR: `OKAY;
   end

   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ip_wr_error <= `OKAY;
      else if (addr_vr)
        ip_wr_error <= (wr_dec_error) ? `DECERR:
                       (wr_slave_error) ? `SLVERR: `OKAY;
   end
   
   //----------------------------------------
   // REGISTER
   //----------------------------------------
   assign reg_rd_en = (state == READ) & (rd_data_vr | ~ip_data_valid);
   assign reg_wr_en[0] = wr_en & axi2ip_strb[0];
   assign reg_wr_en[1] = wr_en & axi2ip_strb[1];
   assign reg_wr_en[2] = wr_en & axi2ip_strb[2];
   assign reg_wr_en[3] = wr_en & axi2ip_strb[3];
//   assign reg_din = axi2ip_data[31:0];
   
   // read/write address
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        reg_addr <= 5'h00;
      else if (addr_vr)
        reg_addr <= axi2ip_address[6:2];
      else if ((reg_rd_en | ((state == WRITE)&wr_data_vr)) && ~burst_fixed)
        reg_addr <= reg_addr + 1'b1;
   end
   
endmodule // rpc2_ctrl_reg_logic

   
