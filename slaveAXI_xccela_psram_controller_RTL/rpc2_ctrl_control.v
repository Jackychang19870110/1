//`define TC_WRITE

module rpc2_ctrl_control (/*AUTOARG*/
   // Outputs
   ip_ready, ip0_data_ready, ip1_data_ready, ip_data_valid, 
   ip_data_last, ip_strb, ip_data, ip_rd_error, ip0_wr_error, 
   ip0_wr_done, ip1_wr_error, ip1_wr_done, rpc2_rw_valid, rpc2_rw_n, 
   rpc2_subseq, rpc2_len, rpc2_address, 
   rpc2_size,
   rpc2_type, rpc2_chip_select, 
   rpc2_device_type, rpc2_gb_rst, rpc2_mem_init,
   rpc2_loopback, rpc2_error, rpc2_done_request, 
   rpc2_target, tx_data_valid, tx_data, tx_mask, rx_data_ready, 
   rxfifo_rd_en, rxfifo_wr_en, wr_rsto_status, wr_slv_status, 
   wr_dec_status, rd_stall_status, rd_rsto_status, rd_slv_status, 
   rd_dec_status, 
   // Inputs
   clk, reset_n, axi2ip_valid, axi2ip_block, axi2ip_rw_n, 
   axi2ip_address, axi2ip_burst, 
   axi2ip_size,   
   axi2ip_len, axi2ip0_strb, 
   axi2ip0_data, axi2ip0_data_valid, axi2ip1_strb, axi2ip1_data, 
   axi2ip1_data_valid, axi2ip_data_ready, rpc2_rd_ready, 
   rpc2_wr_ready, rpc2_subseq_rd_ready, rpc2_wr_done, reg_wrap_size0, 
   reg_wrap_size1, reg_acs0, reg_acs1, reg_mbr0, reg_mbr1, reg_tco0, 
   reg_tco1, reg_dt0, reg_gb_rst, reg_mem_init,
   reg_dt1, reg_lbr, reg_rd_max_length0, 
   reg_rd_max_length1, reg_rd_max_len_en0, reg_rd_max_len_en1, 
   reg_wr_max_length0, reg_wr_max_length1, reg_wr_max_len_en0, 
   reg_wr_max_len_en1, reg_crt0, reg_crt1, powered_up, tx_data_ready, 
   rx_data_valid, rx_data_last, rx_stall, rxfifo_empty, rxfifo_dout, 
   rxfifo_full
   );
   // Burst
   localparam FIXED = 2'b00;
   localparam INCR  = 2'b01;
   localparam WRAP  = 2'b10;
   
   // AXI Error
   localparam OKAY   = 2'b00;
   localparam SLVERR = 2'b10;
   localparam DECERR = 2'b11;
   
   // Wrap size
   localparam WRAP_SIZE_16B = 2'b10;
   localparam WRAP_SIZE_32B = 2'b11;
   localparam WRAP_SIZE_64B = 2'b01;

   // state
   localparam INIT     = 8'b0000_0001; //0x01
   localparam DEC      = 8'b0000_0010; //0x02
   localparam RDWR     = 8'b0000_0100; //0x04
   localparam EMU_DEC  = 8'b0000_1000; //0x08
   localparam SPLT_DEC = 8'b0001_0000; //0x10
   localparam DONE     = 8'b0010_0000; //0x20
   localparam LB_WR    = 8'b0100_0000; //0x40
   localparam LB_RD    = 8'b1000_0000; //0x80
   
   input clk;
   input reset_n;

   // AXI address
   output    ip_ready;
   input     axi2ip_valid;
   input     axi2ip_block;
   input     axi2ip_rw_n;
   input [31:0] axi2ip_address;
   input [1:0]  axi2ip_burst;
   
   input [1:0]  axi2ip_size;
   
   input [8:0]  axi2ip_len;
   
   // AXI write data 0
   output       ip0_data_ready;
   input [3:0]  axi2ip0_strb;
   input [31:0] axi2ip0_data;
   input        axi2ip0_data_valid;

   // AXI write data 1
   output       ip1_data_ready;
   input [3:0]  axi2ip1_strb;
   input [31:0] axi2ip1_data;
   input        axi2ip1_data_valid;
   
   // AXI read data
   output       ip_data_valid;
   output       ip_data_last;
   output [3:0] ip_strb;
   output [31:0] ip_data;
   output [1:0]  ip_rd_error;
   input         axi2ip_data_ready;

   // AXI write response 0
   output [1:0]  ip0_wr_error;
   output        ip0_wr_done;

   // AXI write response 1
   output [1:0]  ip1_wr_error;
   output        ip1_wr_done;
   
   // RPC2 CORE
   output        rpc2_rw_valid;
   output        rpc2_rw_n;
   output        rpc2_subseq;
   output [8:0]  rpc2_len;
   
   
   
   
   output [30:0] rpc2_address;
//   output [31:0] rpc2_address;   
   

   output [1:0]  rpc2_size;            
   
   output        rpc2_type;         // burst type 0:WRAP, 1:INCR 
   output        rpc2_chip_select;  // chip select
   output        rpc2_device_type;  // device type 0:FLASH, 1:PSRAM
   output        rpc2_gb_rst;
   output        rpc2_mem_init;   

   
   output        rpc2_loopback;     // dummy request
   output [1:0]  rpc2_error;        // return read data w/ error flag & retrive write data
   output        rpc2_done_request; // 1: rpc2_wr_done or rx_data_last occurs
   output        rpc2_target;
   
   input         rpc2_rd_ready;
   input         rpc2_wr_ready;
   input         rpc2_subseq_rd_ready;
//   input         rpc2_subseq_wr_ready;
   input         rpc2_wr_done;

   // REG
   input [1:0]   reg_wrap_size0;  // wrap size
   input [1:0]   reg_wrap_size1;
   input         reg_acs0;        // asymmetric cache support
   input         reg_acs1;
   input [7:0]   reg_mbr0;        // memory base register address[31:24]
   input [7:0]   reg_mbr1;
   input         reg_tco0;        // tc option
   input         reg_tco1;
   
   input         reg_dt0;         // device type
   input         reg_gb_rst;
   input         reg_mem_init;
   
   input         reg_dt1;
   input         reg_lbr;
   input [8:0]   reg_rd_max_length0;
   input [8:0]   reg_rd_max_length1;
   input         reg_rd_max_len_en0;
   input         reg_rd_max_len_en1;
   input [8:0]   reg_wr_max_length0;
   input [8:0]   reg_wr_max_length1;
   input         reg_wr_max_len_en0;
   input         reg_wr_max_len_en1;
   input         reg_crt0;        // configuration register target
   input         reg_crt1;
   
   input         powered_up;
   
   // TX
   input         tx_data_ready;
   output        tx_data_valid;
   output [15:0] tx_data;
   output [1:0]  tx_mask;

   // RX
   input         rx_data_valid;
   input         rx_data_last;
   input         rx_stall;
   output        rx_data_ready;
   
   // RXFIFO
   input         rxfifo_empty;
   input [19:0]  rxfifo_dout;    // [15:0] data, [16] error, [17] timeout, [18] address, [19] last
   input         rxfifo_full;
   output        rxfifo_rd_en;
   output        rxfifo_wr_en;
   
   // STATUS
   output        wr_rsto_status;
   output        wr_slv_status;  // protocol error for write
   output        wr_dec_status;
   output        rd_stall_status;
   output        rd_rsto_status;
   output        rd_slv_status;  // protocol error for read
   output        rd_dec_status;
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg                  ip0_wr_done;
   reg [1:0]            ip0_wr_error;
   reg                  ip1_wr_done;
   
   
   reg [31:0]           ip_data;
   reg [31:0]           ip_data_high;
   reg [31:0]           ip_data_low;

   
   reg                  ip_data_last;
   reg                  ip_data_valid;
   reg [1:0]            ip_rd_error;
   reg [3:0]            ip_strb;
   reg                  rd_dec_status;
   reg                  rd_rsto_status;
   reg                  rd_slv_status;
   reg                  rd_stall_status;
   
   
   
   
   reg [30:0]           rpc2_address;
//   reg [31:0]           rpc2_address;  
   
   
   
   
   reg                  rpc2_chip_select;
   
   reg                  rpc2_device_type;
   reg                  rpc2_gb_rst;
   reg                  rpc2_mem_init;
   
   reg                  rpc2_done_request;
   reg [1:0]            rpc2_error;
   reg [8:0]            rpc2_len;
   reg                  rpc2_loopback;
   reg                  rpc2_rw_n;
   reg                  rpc2_rw_valid;
   reg                  rpc2_subseq;
   reg                  rpc2_target;
   
   reg [1:0]            rpc2_size;
   
   reg                  rpc2_type;
   reg [1:0]            tx_mask;
   reg                  wr_dec_status;
   reg                  wr_rsto_status;
   reg                  wr_slv_status;
   // End of automatics
   wire                 ip_ready;
   
   wire                 rd_vr;
   wire                 wr_vr;
   wire                 subseq_rd_vr;
`ifdef TC_WRITE
   wire                 subseq_wr_vr;
`endif
   wire [1:0]           wrap_size;
   reg                  wrap_size_match;
   wire [8:0]           wrap_len;
   wire                 asymmetric_cache;
   reg                  burst_type;
   reg [8:0]            burst_len;
   
   
   
  
   
   
   
   reg                  emu_wrap_burst;
   reg                  emu_wrap_mode;
   reg [8:0]            emu_2nd_len;

   reg [8:0]            next_length;
   reg [8:0]            length;
   
   
   
   
   reg [30:0]           next_address;
   wire [30:0]          wrap_boundary;
   wire [30:0]          pre_next_address;
   wire [30:0]          pre_next_wrap_address;
   wire [30:0]          address;


//   reg [31:0]           next_address;
//   wire [31:0]          wrap_boundary; 
//   wire [31:0]          pre_next_address;
//   wire [31:0]          pre_next_wrap_address;
//   wire [31:0]          address;

   
   wire                 cs;
   wire [7:0]           base_address;
   
   

   wire                 merge_cond;
   wire                 tc_rd_length_cond;
   wire                 tc_wr_length_cond;
   
   wire                 addr_range_error;
   wire                 rd_slave_error;
   wire                 wr_slave_error;
   
   reg [7:0]            state;
   reg [7:0]            next_state;
   reg                  rxfifo_data_valid;
   
   wire                 wdat_last;
   reg [8:0]            wdat_counter;
   wire                 lb_data_valid;
   wire [31:0]          lb_data;
   wire [3:0]           lb_strb;
   wire                 lb_data_ready;
   wire                 lb0_data_ready;
   wire                 lb1_data_ready;
   wire                 lb0_wr_done;
   wire                 lb1_wr_done;
   
   reg                  wr_block;
   reg [1:0]            wr_error;
   
   reg [7:0]            wdata_high;
   reg [7:0]            wdata_low;

   wire                 rd_protocol_error;
   wire                 wr_protocol_error;

   wire [8:0]           rd_max_len;
   wire [8:0]           wr_max_len;

   wire                 rd_max_len_en;
   wire                 wr_max_len_en;
   reg [8:0]            tc_length;

   wire                 mr_target;

   wire                 rxout_data_valid;
   wire                 rxout_data_ready;
   
   assign ip_ready = (state == DONE);

   //------------------------------------------------------
   // STATE
   //------------------------------------------------------
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
           if (axi2ip_valid) begin
              if (reg_lbr)
                next_state = (axi2ip_rw_n) ? LB_RD: LB_WR;
              else
                next_state = DEC;
           end
        end
        DEC: begin
           next_state = RDWR;
        end
        RDWR: begin
`ifdef TC_WRITE
           if (rd_vr | subseq_rd_vr | wr_vr | subseq_wr_vr) begin
`else
           if (rd_vr | subseq_rd_vr | wr_vr) begin
`endif
              if (length==rpc2_len)
                next_state = (emu_wrap_mode) ? EMU_DEC: DONE;
              else
                next_state = SPLT_DEC;
           end
        end
        EMU_DEC: begin
           next_state = RDWR;
        end
        SPLT_DEC: begin
           next_state = RDWR;
        end
        LB_WR: begin
           if (wdat_last)
             next_state = DONE;
        end
        LB_RD: begin
           next_state = DONE;
        end
        default:
          next_state = INIT;
      endcase
   end

   ////////////////////////////////////////////
   // MEMORY
   ////////////////////////////////////////////
   assign rd_vr = rpc2_rw_valid & rpc2_rd_ready & rpc2_rw_n;
   assign wr_vr = rpc2_rw_valid & rpc2_wr_ready & (~rpc2_rw_n);
   assign subseq_rd_vr = rpc2_rw_valid & rpc2_subseq_rd_ready & rpc2_subseq & rpc2_rw_n;
`ifdef TC_WRITE
   assign subseq_wr_vr = rpc2_rw_valid & rpc2_subseq_wr_ready & rpc2_subseq & (~rpc2_rw_n);
`endif
   
   assign rd_protocol_error = (axi2ip_burst == FIXED);
   assign wr_protocol_error = (axi2ip_burst == FIXED) || (axi2ip_burst == WRAP);
   
   assign addr_range_error = (reg_mbr0 > axi2ip_address[31:24]) ? 1'b1: 1'b0; // out of address range
   assign rd_slave_error = (rd_protocol_error || ~powered_up) ? 1'b1: 1'b0; // not support
   assign wr_slave_error = (wr_protocol_error || ~powered_up) ? 1'b1: 1'b0; // not support
   
   //------------------------------------------------------
   // DECODE
   //------------------------------------------------------
   // chip select
   assign cs = ((reg_mbr1 <= reg_mbr0) || (reg_mbr1 > axi2ip_address[31:24])) ? 1'b0: 1'b1;
   
   
   
   // address 
   assign base_address = axi2ip_address[31:24]-((cs) ? reg_mbr1: reg_mbr0);
   
   
   
   assign address = {base_address[7:0], axi2ip_address[23:1]};
// assign address = {base_address[7:0], axi2ip_address[23:0]};  
   
   
   
   // conditon of tc
   assign merge_cond = (((~cs)&reg_tco0)|(cs&reg_tco1)) ? 1'b1: rpc2_type;
   assign tc_rd_length_cond = (rd_max_len_en) ? ({1'b0,rd_max_len} > (tc_length+length+10'h000)): 1'b1;
   assign tc_wr_length_cond = (wr_max_len_en) ? ({1'b0,wr_max_len} > (tc_length+length+10'h000)): 1'b1;
   
   assign wrap_size = (cs) ? reg_wrap_size1: reg_wrap_size0;
   
   
   
   assign wrap_boundary = address[30:0] & {{22{1'b1}}, ~wrap_len[8:0]};
//   assign wrap_boundary = address[31:0] & {{22{1'b1}}, ~wrap_len[8:0]};   
   
   
   
   
   
   
   assign asymmetric_cache = (cs) ? reg_acs1: reg_acs0;
   assign wrap_len = axi2ip_len[8:0] - axi2ip_address[0];
   assign pre_next_address = rpc2_address + rpc2_len + 1'b1;
   assign pre_next_wrap_address = wrap_boundary | (pre_next_address & {{22{1'b0}}, wrap_len[8:0]});
         
   assign rd_max_len_en = (cs) ? reg_rd_max_len_en1: reg_rd_max_len_en0;
   assign wr_max_len_en = (cs) ? reg_wr_max_len_en1: reg_wr_max_len_en0;
   assign rd_max_len = (cs) ? ((reg_rd_max_len_en1) ? reg_rd_max_length1: 9'h1FF): 
                              ((reg_rd_max_len_en0) ? reg_rd_max_length0: 9'h1FF);
   assign wr_max_len = (cs) ? ((reg_wr_max_len_en1) ? reg_wr_max_length1: 9'h1FF): 
                              ((reg_wr_max_len_en0) ? reg_wr_max_length0: 9'h1FF);
   assign mr_target = (cs) ? reg_crt1: reg_crt0;
   
   function [8:0] regulated_len;
      input [8:0] max_len;
      input [8:0] len;
      regulated_len = (max_len > len) ? len: max_len;
   endfunction
   
   // wrap size between reg and request
   always @(*) begin
      wrap_size_match = 1'b0;
      case (wrap_size)
        WRAP_SIZE_16B: begin
           if (wrap_len[8:0] == 9'h007)
             wrap_size_match = 1'b1;
        end
        WRAP_SIZE_32B: begin
           if (wrap_len[8:0] == 9'h00F)
             wrap_size_match = 1'b1;
        end
        WRAP_SIZE_64B: begin
           if (wrap_len[8:0] == 9'h01F)
             wrap_size_match = 1'b1;
        end
        default: begin
           wrap_size_match = 1'b1;
        end
      endcase
   end
   
   always @(*) begin
      case (axi2ip_burst)
        INCR: begin
           burst_type = 1'b1;
           burst_len = axi2ip_len[8:0];
           emu_wrap_burst = 1'b0;
        end
        WRAP: begin
           if ((wrap_boundary == address) && (~axi2ip_address[0])) begin
              burst_type = 1'b1;
              burst_len = axi2ip_len[8:0];
              emu_wrap_burst = 1'b0;
           end
           else if (asymmetric_cache && (~wrap_size_match)) begin
              burst_type = 1'b1;
              burst_len = wrap_len[8:0] - (wrap_len[8:0]&address[8:0]);
              emu_wrap_burst = ((wrap_len==9'h000)&(~(axi2ip_address[1]&axi2ip_address[0]))) ? 1'b0: 1'b1;
           end
           else begin
              burst_type = 1'b0;
              burst_len = ((wrap_len==9'h000)&(~(axi2ip_address[1]&axi2ip_address[0]))) ? wrap_len[8:0]: axi2ip_len[8:0];
              emu_wrap_burst = 1'b0;
           end
        end
        default: begin
           burst_type = 1'b1;
           burst_len = axi2ip_len[7:0]<<1;  // burst type is FIXED
           emu_wrap_burst = 1'b0;
        end
      endcase
   end

   // length 
   // size   
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         length <= 9'h000;
         
//         axi_size <= 2'b00; 
         
         emu_wrap_mode <= 1'b0;
      end
      else if (next_state == DEC) begin
         length <= (axi2ip_rw_n) ? burst_len[8:0]: axi2ip_len[8:0];
         
//         axi_size <= 2'b00; 
         
         emu_wrap_mode <= (axi2ip_rw_n) ? emu_wrap_burst: 1'b0;
      end
      else if (next_state == EMU_DEC) begin
         length <= emu_2nd_len;
         emu_wrap_mode <= 1'b0;
      end
      else if (next_state == SPLT_DEC) begin
         length <= next_length;
      end
   end

   // size




   
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         rpc2_rw_n <= 1'b0;
         rpc2_len <= 9'h000;
         
         
         
         rpc2_address <= 31'h00000000;
//         rpc2_address <= 32'h00000000;         
         
         
         rpc2_size <= 2'b00;  
         
         rpc2_type <= 1'b0;
         rpc2_chip_select <= 1'b0;
         
         rpc2_device_type <= 1'b0;
         rpc2_gb_rst <= 1'b0;
         rpc2_mem_init <= 1'b0;
         
         rpc2_loopback <= 1'b0;
         rpc2_error <= 2'b00;
         rpc2_done_request <= 1'b0;
         rpc2_target <= 1'b0;
      end
      else if (state == DEC) begin
         rpc2_rw_n <= axi2ip_rw_n;
         rpc2_len <= regulated_len(((axi2ip_rw_n) ? rd_max_len: wr_max_len), length);
         
         
         
         rpc2_address <= address[30:0];
//         rpc2_address <= address[31:0]; 
        
         rpc2_size <= axi2ip_size;  
         
         rpc2_type <= burst_type;
         
         rpc2_chip_select <= cs;
         rpc2_device_type <= (cs) ? reg_dt1: reg_dt0;
         rpc2_gb_rst <= reg_gb_rst;
         rpc2_mem_init <= reg_mem_init;
         
         rpc2_loopback <= ((axi2ip_rw_n) ? rd_slave_error: wr_slave_error) || addr_range_error;
         rpc2_error <= (axi2ip_rw_n) ? {rd_slave_error, addr_range_error}: {wr_slave_error, addr_range_error};
         rpc2_done_request <= (regulated_len(((axi2ip_rw_n) ? rd_max_len: wr_max_len), length)==length);
         rpc2_target <= mr_target;
      end
      else if (state == EMU_DEC) begin
         rpc2_len <= regulated_len(((axi2ip_rw_n) ? rd_max_len: wr_max_len), length);
         rpc2_size <= axi2ip_size; 
         
         rpc2_address <= rpc2_address & {{22{1'b1}}, ~wrap_len};
         rpc2_done_request <= (regulated_len(((axi2ip_rw_n) ? rd_max_len: wr_max_len), length)==length);
      end
      else if (state == SPLT_DEC) begin
         rpc2_len <= regulated_len(((axi2ip_rw_n) ? rd_max_len: wr_max_len), length);
         rpc2_size <= axi2ip_size; 
         
         rpc2_address <= (rpc2_type) ? pre_next_address: pre_next_wrap_address;
         rpc2_done_request <= (regulated_len(((axi2ip_rw_n) ? rd_max_len: wr_max_len), length)==length);
      end
   end

   // Emulated wrap len
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        emu_2nd_len <= 9'h000;
      else if (state == DEC)
        emu_2nd_len <= (axi2ip_address[0]) ? (wrap_len - length): (wrap_len - length) - 1'b1;
   end
   
   // Valid for RPC2
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        rpc2_rw_valid <= 1'b0;
      else if (next_state == RDWR)
        rpc2_rw_valid <= 1'b1;
`ifdef TC_WRITE
      else if (rd_vr | wr_vr | subseq_rd_vr | subseq_wr_vr)
`else
      else if (rd_vr | wr_vr | subseq_rd_vr)
`endif  
        rpc2_rw_valid <= 1'b0;
   end

   // Subsequent read/write
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        rpc2_subseq <= 1'b0;
      else if ((state == DEC) & (next_address==address) & burst_type & 
               (rpc2_chip_select==cs) & merge_cond & (~mr_target))
//        rpc2_subseq <= (axi2ip_rw_n) ? tc_rd_length_cond: 1'b0;  //TODO: write is not supporting tc
        rpc2_subseq <= (axi2ip_rw_n) ? tc_rd_length_cond: tc_wr_length_cond&(~address[0]);
      else if (state != RDWR)
        rpc2_subseq <= 1'b0;
   end

   // Reserved next address
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        next_address <= 31'h00000000;
      else if (state == RDWR)
        next_address <= (rpc2_type) ? pre_next_address: pre_next_address & {{22{1'b1}}, ~rpc2_len[8:0]};
   end

   always @(*) next_length = (length - rpc2_len) - 1'b1;
/*   always @(posedge clk or negedge reset_n) begin   // for timing
      if (~reset_n)
        next_length <= 9'h000;
      else if (state == RDWR)
        next_length <= length - rpc2_len - 1'b1;
   end
*/
   
   // length of true continuous
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        tc_length <= 9'h000;
      else if (rd_vr | wr_vr)
        tc_length <= rpc2_len[8:0];
`ifdef TC_WRITE
      else if (subseq_rd_vr | subseq_wr_vr)
`else
      else if (subseq_rd_vr)
`endif
        tc_length <= tc_length + rpc2_len + 1'b1;
   end
   
   // for write response
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         wr_block <= 1'b0;
         wr_error <= OKAY;
      end
`ifdef TC_WRITE
      else if (wr_vr | subseq_wr_vr) begin
`else
      else if (wr_vr) begin
`endif
         wr_block <= axi2ip_block;
         wr_error <= rpc2_error[0] ? DECERR:
                     rpc2_error[1] ? SLVERR: OKAY;
      end
   end

   //------------------------------------------------------
   // WRITE RESP
   //------------------------------------------------------
   assign ip1_wr_error = ip0_wr_error;

   // ip0_wr_error
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ip0_wr_error <= OKAY;
      else if (wdat_last)
        ip0_wr_error <= OKAY;
      else if (rpc2_wr_done)
        ip0_wr_error <= wr_error;
   end
   
   // ip0_wr_done
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ip0_wr_done <= 1'b0;
      else
        ip0_wr_done <= lb0_wr_done || ((~wr_block)&rpc2_wr_done);
   end
   
   // ip1_wr_done
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ip1_wr_done <= 1'b0;
      else
        ip1_wr_done <= lb1_wr_done || (wr_block&rpc2_wr_done);
   end
   
   //------------------------------------------------------
   // TX
   //------------------------------------------------------
   assign ip0_data_ready = ((~wr_block) & tx_data_ready) | lb0_data_ready;
   assign ip1_data_ready = (wr_block & tx_data_ready) | lb1_data_ready;

   // Write data
   assign tx_data = {wdata_high[7:0], wdata_low[7:0]};
   assign tx_data_valid = (wr_block) ? axi2ip1_data_valid: axi2ip0_data_valid;







   // [7:0]
   always @(*) begin
      if (wr_block) begin
         if (axi2ip1_strb[0])
           wdata_low[7:0] = axi2ip1_data[7:0];
//           wdata_low[7:0] = axi2ip1_data[23:16];  //  32bit data [31:16]wdata_high + [15:0]wdata_low  swap           
         else if (axi2ip1_strb[2])
           wdata_low[7:0] = axi2ip1_data[23:16];
//           wdata_low[7:0] = axi2ip1_data[7:0];  //  32bit data [31:16]wdata_high + [15:0]wdata_low  swap            
         else
           wdata_low[7:0] = 8'hFF;
      end
      else begin
         if (axi2ip0_strb[0])
           wdata_low[7:0] = axi2ip0_data[7:0];  
//           wdata_low[7:0] = axi2ip0_data[23:16];  //  32bit data [31:16]wdata_high + [15:0]wdata_low  swap      
         else if (axi2ip0_strb[2])
           wdata_low[7:0] = axi2ip0_data[23:16];
//           wdata_low[7:0] = axi2ip0_data[7:0];  //  32bit data [31:16]wdata_high + [15:0]wdata_low  swap            
         else
           wdata_low[7:0] = 8'hFF;
      end
   end

   // [15:8]
   always @(*) begin
      if (wr_block) begin
         if (axi2ip1_strb[1])
           wdata_high[7:0] = axi2ip1_data[15:8];
//           wdata_high[7:0] = axi2ip1_data[31:24];  //  32bit data [31:16]wdata_high + [15:0]wdata_low  swap            
         else if (axi2ip1_strb[3])
           wdata_high[7:0] = axi2ip1_data[31:24];
//           wdata_high[7:0] = axi2ip1_data[15:8];  //  32bit data [31:16]wdata_high + [15:0]wdata_low  swap            
         else
           wdata_high[7:0] = 8'hFF;
      end
      else begin
         if (axi2ip0_strb[1])
           wdata_high[7:0] = axi2ip0_data[15:8];
//           wdata_high[7:0] = axi2ip0_data[31:24];  //  32bit data [31:16]wdata_high + [15:0]wdata_low  swap            
         else if (axi2ip0_strb[3])
           wdata_high[7:0] = axi2ip0_data[31:24];
//           wdata_high[7:0] = axi2ip0_data[15:8];  //  32bit data [31:16]wdata_high + [15:0]wdata_low  swap            
         else
           wdata_high[7:0] = 8'hFF;
      end      
   end





   always @(*) begin
      if (wr_block) begin
         if (|axi2ip1_strb[1:0])
           tx_mask[1:0] = ~axi2ip1_strb[1:0];
         else if (|axi2ip1_strb[3:2])
           tx_mask[1:0] = ~axi2ip1_strb[3:2];
         else
           tx_mask[1:0] = 2'b11;
      end
      else begin
         if (|axi2ip0_strb[1:0])
           tx_mask[1:0] = ~axi2ip0_strb[1:0];
//           tx_mask[0:1] = ~axi2ip0_strb[1:0];
           
         else if (|axi2ip0_strb[3:2])
           tx_mask[1:0] = ~axi2ip0_strb[3:2];
//           tx_mask[0:1] = ~axi2ip0_strb[3:2];          
         else
           tx_mask[1:0] = 2'b11;
      end
   end

   //------------------------------------------------------
   // RX
   //------------------------------------------------------
   assign rx_data_ready = ~rxfifo_full;
   assign rxfifo_wr_en = rx_data_valid & rx_data_ready;
   assign rxfifo_rd_en = (~rxfifo_empty) & (rxout_data_ready | (~rxout_data_valid));
   
   assign rxout_data_valid = (state == LB_WR) ? lb_data_valid: rxfifo_data_valid;
   assign rxout_data_ready = (~ip_data_valid) | axi2ip_data_ready;
   
   // rxfifo_data_valid
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        rxfifo_data_valid <= 1'b0;
      else if (rxfifo_rd_en)
        rxfifo_data_valid <= 1'b1;
      else if (axi2ip_data_ready)
        rxfifo_data_valid <= 1'b0;
   end   

   /////
   
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        ip_data_valid <= 1'b0;
      else if (rxout_data_valid & rxout_data_ready)
        ip_data_valid <= 1'b1;
      else if (axi2ip_data_ready)
        ip_data_valid <= 1'b0;
   end

   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         ip_data <= {32{1'b0}};
         ip_strb <= {4{1'b0}};
         ip_rd_error <= OKAY;
         ip_data_last <= 1'b0;
      end
      else if (rxout_data_valid & rxout_data_ready) begin
         ip_data_last <= (state == LB_WR) ? wdat_last: rxfifo_dout[19];
         ip_data <= (state == LB_WR) ? lb_data: {rxfifo_dout[15:0], rxfifo_dout[15:0]};
         
         ip_data_high <= ip_data;
         ip_data_low <= ip_data_high;
         
         ip_strb <= (state == LB_WR) ? lb_strb: (rxfifo_dout[18]) ? 4'b1100: 4'b0011;
//         ip_strb <= (state == LB_WR) ? lb_strb: (rxfifo_dout[18]) ? 4'b1100: 4'b1111;         
         ip_rd_error <= (state == LB_WR) ? OKAY:
                        (rxfifo_dout[16]) ? DECERR:
                        (rxfifo_dout[17]) ? SLVERR: OKAY;
      end
   end
   
   //------------------------------------------------------
   // STATUS
   //------------------------------------------------------
   // write
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         wr_rsto_status <= 1'b0;
         wr_slv_status  <= 1'b0;
         wr_dec_status  <= 1'b0;
      end
      else if ((state==INIT) & axi2ip_valid & (~axi2ip_rw_n)) begin
         wr_rsto_status <= (reg_lbr || addr_range_error || powered_up) ? 1'b0: 1'b1;
         wr_slv_status  <= (reg_lbr || addr_range_error || (~wr_protocol_error)) ? 1'b0: 1'b1;
         wr_dec_status  <= (reg_lbr || (~addr_range_error)) ? 1'b0: 1'b1;
      end
   end

   // read
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n) begin
         rd_rsto_status  <= 1'b0;
         rd_slv_status   <= 1'b0;
         rd_dec_status   <= 1'b0;
      end
      else if ((state==INIT) & axi2ip_valid & axi2ip_rw_n) begin
         rd_rsto_status <= (reg_lbr || addr_range_error || powered_up) ? 1'b0: 1'b1;
         rd_slv_status  <= (reg_lbr || addr_range_error || (~rd_protocol_error)) ? 1'b0: 1'b1;
         rd_dec_status  <= (reg_lbr || (~addr_range_error)) ? 1'b0: 1'b1;
      end
   end

   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        rd_stall_status <= 1'b0;
      else if (rx_data_valid & rx_data_ready & rx_data_last)
        rd_stall_status <= rx_stall;
   end

   /////////////////////////////////////////////////////
   // LOOPBACK - read data from axi wr data channel to
   //            write its data to axi rd data channel
   /////////////////////////////////////////////////////
   assign wdat_last = (wdat_counter == axi2ip_len[8:0]) & lb_data_valid & lb_data_ready;

   assign lb_data_valid = (axi2ip_block) ? axi2ip1_data_valid: axi2ip0_data_valid;
   assign lb_data = (axi2ip_block) ? axi2ip1_data[31:0]: axi2ip0_data[31:0];
   assign lb_strb = (axi2ip_block) ? axi2ip1_strb[3:0]: axi2ip0_strb[3:0];
   assign lb_data_ready = axi2ip_data_ready & (state == LB_WR);
   assign lb0_data_ready = (~axi2ip_block) & axi2ip_data_ready & (state == LB_WR);
   assign lb1_data_ready = axi2ip_block & axi2ip_data_ready & (state == LB_WR);

   assign lb0_wr_done = (~axi2ip_block) & wdat_last;
   assign lb1_wr_done = axi2ip_block & wdat_last;

    // wdat counter
   always @(posedge clk or negedge reset_n) begin
      if (~reset_n)
        wdat_counter <= 9'h000;
      else if (state == INIT)
        wdat_counter <= 9'h000;
      else if (lb_data_ready && lb_data_valid)
        wdat_counter <= wdat_counter + 1'b1;
   end

endmodule // rpc2_ctrl_control
