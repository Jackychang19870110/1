

module rpc2_ctrl_mem_logic (
   /*AUTOARG*/
   // Outputs
   ip_ready, ip0_data_ready, ip1_data_ready, ip_data_valid, 
   ip_data_last, ip_strb, ip_data, ip_rd_error, ip0_wr_error, 
   ip0_wr_done, ip1_wr_error, ip1_wr_done, cs0n_en, cs1n_en, csn_d, 
   ck_en, dq_io_tri, dq_out_en, dq_out0, dq_out1, wds_en, wds0, wds1, 
   rwds_io_tri, wr_rsto_status, wr_slv_status, wr_dec_status, 
   rd_stall_status, rd_rsto_status, rd_slv_status, rd_dec_status, 
   // Inputs
   clk, reset_n, axi2ip_valid, axi2ip_block, axi2ip_rw_n, axi2ip_address, 
   
   axi2ip_size,
   
   axi2ip_burst, axi2ip_len, axi2ip0_strb, 
   axi2ip0_data, axi2ip0_data_valid, axi2ip1_strb, axi2ip1_data, 
   axi2ip1_data_valid, axi2ip_data_ready, reg_wrap_size0, 
   reg_wrap_size1, reg_acs0, reg_acs1, reg_mbr0, reg_mbr1, reg_tco0, 
   reg_tco1, reg_dt0, reg_gb_rst, reg_mem_init,
   
   reg_dt1, reg_crt0, reg_crt1, reg_lbr, 
   reg_latency0, reg_latency1, reg_rd_cshi0, reg_rd_cshi1, 
   reg_rd_css0, reg_rd_css1, reg_rd_csh0, reg_rd_csh1, reg_wr_cshi0, 
   reg_wr_cshi1, reg_wr_css0, reg_wr_css1, reg_wr_csh0, reg_wr_csh1, 
   reg_rd_max_length0, reg_rd_max_length1, reg_rd_max_len_en0, 
   reg_rd_max_len_en1, reg_wr_max_length0, reg_wr_max_length1, 
   reg_wr_max_len_en0, reg_wr_max_len_en1, powered_up, rds_clk, 
   dq_in, rwds_in,
//// psram controller////////////
   xl_ck,xl_ce,xl_dqs,xl_dq,clk90
 
   );
   
 

//// psram controller////////////          
   output         xl_ck;
   output         xl_ce;
   inout          xl_dqs;   
   inout  [7:0]   xl_dq;

   input clk90;    
 

   
   

   parameter    C_RX_FIFO_ADDR_BITS = 'd8;
   parameter    DPRAM_MACRO = 0;
   parameter    DPRAM_MACRO_TYPE = 0;

  
   parameter   integer INIT_CLOCK_HZ = 200_000000;
   parameter   INIT_DRIVE_STRENGTH = 50;

   localparam   MEM_LEN       = 'd9;  
   
   localparam   C_RX_FIFO_DATA_WIDTH = 'd20;
   localparam   RX_ADDR_WIDTH = 1;
   






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
   input         reg_crt0;        // configuration register target
   input         reg_crt1;
   input         reg_lbr;         // loopback
   input [3:0]   reg_latency0;    // read latency
   input [3:0]   reg_latency1;
   input [3:0]   reg_rd_cshi0;    // CS high cycle for read
   input [3:0]   reg_rd_cshi1;
   input [3:0]   reg_rd_css0;     // CS setup cycle for read
   input [3:0]   reg_rd_css1;
   input [3:0]   reg_rd_csh0;     // CS hold cycle for read
   input [3:0]   reg_rd_csh1;
   input [3:0]   reg_wr_cshi0;    // CS high cycle for write
   input [3:0]   reg_wr_cshi1;
   input [3:0]   reg_wr_css0;     // CS setup cycle for write
   input [3:0]   reg_wr_css1;
   input [3:0]   reg_wr_csh0;     // CS hold cycle for write
   input [3:0]   reg_wr_csh1;
   input [8:0]   reg_rd_max_length0;
   input [8:0]   reg_rd_max_length1;
   input         reg_rd_max_len_en0;
   input         reg_rd_max_len_en1;
   input [8:0]   reg_wr_max_length0;
   input [8:0]   reg_wr_max_length1;
   input         reg_wr_max_len_en0;
   input         reg_wr_max_len_en1;
   
   input         powered_up;
   
   // RPC IO
   input         rds_clk;
   input [7:0]   dq_in;
   input         rwds_in;
   output        cs0n_en;
   output        cs1n_en;
   output        csn_d;
   output        ck_en;
   output        dq_io_tri;
   output        dq_out_en;
   output [7:0]  dq_out0;
   output [7:0]  dq_out1;
   output        wds_en;
   output        wds0;
   output        wds1;
   output        rwds_io_tri;


   // STATUS
   output        wr_rsto_status;
   output        wr_slv_status;
   output        wr_dec_status;
   output        rd_stall_status;
   output        rd_rsto_status;
   output        rd_slv_status;
   output        rd_dec_status;
    
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [15:0]          dqinfifo_dout;          // From rpc2_ctrl_dqin_block of rpc2_ctrl_dqin_block.v
   wire                 dqinfifo_empty;         // From rpc2_ctrl_dqin_block of rpc2_ctrl_dqin_block.v
   wire                 dqinfifo_rd_en;         // From bridge of bridge.v
   wire                 dqinfifo_wr_en;         // From bridge of bridge.v
   
   
   wire [30:0]          rpc2_address;           // From rpc2_ctrl_control of rpc2_ctrl_control.v
//   wire [31:0]          rpc2_address;           // From rpc2_ctrl_control of rpc2_ctrl_control.v

   
   wire                 rpc2_chip_select;       // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rpc2_device_type;       // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rpc2_gb_rst;
   wire                 rpc2_mem_init;

   wire                 rpc2_done_request;      // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire [1:0]           rpc2_error;             // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire [8:0]           rpc2_len;               // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rpc2_loopback;          // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rpc2_rd_ready;          // From bridge of bridge.v
   wire                 rpc2_rw_n;              // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rpc2_rw_valid;          // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rpc2_subseq;            // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rpc2_subseq_rd_ready;   // From bridge of bridge.v
   wire                 rpc2_target;            // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rpc2_type;              // From rpc2_ctrl_control of rpc2_ctrl_control.v
   
   wire [1:0]           rpc2_size;              // From rpc2_ctrl_control of rpc2_ctrl_control.v
   
   wire                 rpc2_wr_done;           // From bridge of bridge.v
   wire                 rpc2_wr_ready;          // From bridge of bridge.v
   wire [RX_ADDR_WIDTH-1:0]rx_data_addr;        // From bridge of bridge.v
   wire                 rx_data_last;           // From bridge of bridge.v
   wire                 rx_data_ready;          // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rx_data_valid;          // From bridge of bridge.v
   wire [1:0]           rx_error;               // From bridge of bridge.v
   wire                 rx_stall;               // From bridge of bridge.v
   wire [19:0]          rxfifo_dout;            // From rx_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire                 rxfifo_empty;           // From rx_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire                 rxfifo_full;            // From rx_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire                 rxfifo_half_full;       // From rx_fifo_wrapper of rpc2_ctrl_dpram_wrapper.v
   wire                 rxfifo_rd_en;           // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 rxfifo_wr_en;           // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire [15:0]          tx_data;                // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire                 tx_data_ready;          // From bridge of bridge.v
   wire                 tx_data_valid;          // From rpc2_ctrl_control of rpc2_ctrl_control.v
   wire [1:0]           tx_mask;                // From rpc2_ctrl_control of rpc2_ctrl_control.v
   // End of automatics
   wire [19:0]          rxfifo_din;



   assign               rxfifo_din = {rx_data_last, rx_data_addr, rx_error[1]|rx_stall, rx_error[0], dqinfifo_dout[15:0]};

   
   
   
   
   
   rpc2_ctrl_control
     rpc2_ctrl_control (/*AUTOINST*/
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
                        .rpc2_rw_valid  (rpc2_rw_valid),
                        .rpc2_rw_n      (rpc2_rw_n),
                        .rpc2_subseq    (rpc2_subseq),
                        .rpc2_len       (rpc2_len[8:0]),
                        
                        
                        .rpc2_address   (rpc2_address[30:0]),

                        .rpc2_size      (rpc2_size[1:0]),
                        
                        .rpc2_type      (rpc2_type),
                        .rpc2_chip_select(rpc2_chip_select),
                        
                        .rpc2_device_type(rpc2_device_type),
                        .rpc2_gb_rst(rpc2_gb_rst),
                        .rpc2_mem_init(rpc2_mem_init),                        

                       
                        .rpc2_loopback  (rpc2_loopback),
                        .rpc2_error     (rpc2_error[1:0]),
                        .rpc2_done_request(rpc2_done_request),
                        .rpc2_target    (rpc2_target),
                        .tx_data_valid  (tx_data_valid),
                        .tx_data        (tx_data[15:0]),
                        .tx_mask        (tx_mask[1:0]),
                        .rx_data_ready  (rx_data_ready),
                        .rxfifo_rd_en   (rxfifo_rd_en),
                        .rxfifo_wr_en   (rxfifo_wr_en),
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
                        
                        .axi2ip_size   (axi2ip_size[1:0]), 
                        
                        .axi2ip_len     (axi2ip_len[8:0]),
                        .axi2ip0_strb   (axi2ip0_strb[3:0]),
                        .axi2ip0_data   (axi2ip0_data[31:0]),
                        .axi2ip0_data_valid(axi2ip0_data_valid),
                        .axi2ip1_strb   (axi2ip1_strb[3:0]),
                        .axi2ip1_data   (axi2ip1_data[31:0]),
                        .axi2ip1_data_valid(axi2ip1_data_valid),
                        .axi2ip_data_ready(axi2ip_data_ready),
                        .rpc2_rd_ready  (rpc2_rd_ready),
                        .rpc2_wr_ready  (rpc2_wr_ready),
                        .rpc2_subseq_rd_ready(rpc2_subseq_rd_ready),
                        .rpc2_wr_done   (rpc2_wr_done),
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
                        .reg_lbr        (reg_lbr),
                        .reg_rd_max_length0(reg_rd_max_length0[8:0]),
                        .reg_rd_max_length1(reg_rd_max_length1[8:0]),
                        .reg_rd_max_len_en0(reg_rd_max_len_en0),
                        .reg_rd_max_len_en1(reg_rd_max_len_en1),
                        .reg_wr_max_length0(reg_wr_max_length0[8:0]),
                        .reg_wr_max_length1(reg_wr_max_length1[8:0]),
                        .reg_wr_max_len_en0(reg_wr_max_len_en0),
                        .reg_wr_max_len_en1(reg_wr_max_len_en1),
                        .reg_crt0       (reg_crt0),
                        .reg_crt1       (reg_crt1),
                        .powered_up     (powered_up),
                        .tx_data_ready  (tx_data_ready),
                        .rx_data_valid  (rx_data_valid),
                        .rx_data_last   (rx_data_last),
                        .rx_stall       (rx_stall),
                        .rxfifo_empty   (rxfifo_empty),
                        .rxfifo_dout    (rxfifo_dout[19:0]),
                        .rxfifo_full    (rxfifo_full));




   wire                 bd_instruction_req;    
   wire                 bd_instruction_ready;  
   wire [7:0]           bd_command;            
   wire [31:0]          bd_address;            
   wire                 bd_wdata_ready;        

   wire [15:0]          bd_wdata;     
   wire [1:0]           bd_wdata_mask; 

   
   wire [8:0]           bd_data_len; 
   wire [15:0]          bd_rdata;     
   wire                 bd_rdata_valid;         
   
    
   
   bridge  #(
                    .RX_ADDR_WIDTH (RX_ADDR_WIDTH),
                    .MEM_LEN (MEM_LEN)
                    )
     bridge (

                     /*AUTOINST*/
                     // Outputs
                     .rpc2_rd_ready     (rpc2_rd_ready),
                     .rpc2_wr_ready     (rpc2_wr_ready),
//                     .rpc2_subseq_rd_ready(rpc2_subseq_rd_ready),
                     .rpc2_wr_done      (rpc2_wr_done),
//                     .cs0n_en           (cs0n_en),
//                     .cs1n_en           (cs1n_en),
//                     .csn_d             (csn_d),
//                     .ck_en             (ck_en),
//                     .dq_io_tri         (dq_io_tri),
//                     .dq_out_en         (dq_out_en),
//                     .dq_out0           (dq_out0[7:0]),
//                     .dq_out1           (dq_out1[7:0]),
//                     .wds_en            (wds_en),
//                     .wds0              (wds0),
//                     .wds1              (wds1),
//                     .rwds_io_tri       (rwds_io_tri),
                     .tx_data_ready     (tx_data_ready),
//                     .dqinfifo_rd_en    (dqinfifo_rd_en),
//                     .dqinfifo_wr_en    (dqinfifo_wr_en),
                     .rx_data_valid     (rx_data_valid),
                     .rx_data_last      (rx_data_last),
                     .rx_error          (rx_error[1:0]),
                     .rx_stall          (rx_stall),
                     .rx_data_addr      (rx_data_addr[RX_ADDR_WIDTH-1:0]),
                     
                     
                     // Inputs
                     .clk               (clk),
                     .reset_n           (reset_n),
                     .rpc2_rw_valid     (rpc2_rw_valid),
                     .rpc2_rw_n         (rpc2_rw_n),
//                     .rpc2_loopback     (rpc2_loopback),
//                     .rpc2_subseq       (rpc2_subseq),
                     .rpc2_done_request (rpc2_done_request),
                     .rpc2_len          (rpc2_len[MEM_LEN-1:0]),                                        
                     .rpc2_address      (rpc2_address[30:0]),
//                     .rpc2_size         (rpc2_size[1:0]),   //new                                       
                     .rpc2_type         (rpc2_type),
                     .rpc2_error        (rpc2_error[1:0]),

                     .rpc2_gb_rst       (rpc2_gb_rst), //new
                     .rpc2_mem_init     (rpc2_mem_init), //new
//                     .rpc2_error        (rpc2_error[1:0]),
//                     .rpc2_device_type  (rpc2_device_type),
//                     .rpc2_chip_select  (rpc2_chip_select),                     


                     .rpc2_target       (rpc2_target),
                     .tx_data           (tx_data[15:0]),
                     .tx_mask           (tx_mask[1:0]),
                     .tx_data_valid     (tx_data_valid),
//                     .dqinfifo_empty    (dqinfifo_empty),
//                     .rxfifo_half_full  (rxfifo_half_full),
//                     .rxfifo_empty      (rxfifo_empty),
                     .rx_data_ready     (rx_data_ready),
                    
                     
                     
/*--------- bridge to controller signals-----------*/
                     .dqinfifo_dout            (dqinfifo_dout[15:0]),  //change rx data from "bridge"

                     
                     .bd_instruction_req       (bd_instruction_req),
                     .bd_instruction_ready     (bd_instruction_ready),                               
                     .bd_command               (bd_command),
                     .bd_address               (bd_address),
                     .bd_wdata_ready           (bd_wdata_ready),
                     .bd_wdata                 (bd_wdata),
                     .bd_wdata_mask            (bd_wdata_mask),
                     .bd_data_len              (bd_data_len),
                     .bd_rdata                 (bd_rdata),
                     .bd_rdata_valid           (bd_rdata_valid)                                                                                
                     
                     );

wire clk_iserdes;
wire clk_idelay_ref;


  
xccela_opi_ctl
                   #(
                   .MEM_LEN (MEM_LEN),     // burst length count    
                   .INIT_CLOCK_HZ (INIT_CLOCK_HZ),
                   .INIT_DRIVE_STRENGTH (INIT_DRIVE_STRENGTH),
                   .C_ISERDES_CLOCKING_MODE (0),
                   .RWDS_DIR_INPUT (1),
                   .RWDS_DIR_OUTPUT (0)
                    )
                  u0(
//                     .clk_iserdes       (clk),
                     .clk_idelay_ref    (clk),                     
                     
                                  
    
                     .clk_in_0          (clk),
                     .clk_in_90         (clk90),


                     .rst               (!reset_n), 
                     .xl_ck             (xl_ck),
                     .xl_ce             (xl_ce),
                     .xl_dqs            (xl_dqs),   
                     .xl_dq             (xl_dq),
                     

/*--------- bridge signals-----------*/

                     .bd_instruction_req       (bd_instruction_req),
                     .bd_instruction_ready     (bd_instruction_ready),                               
//                     .bd_instruction_ack       (ctl_instruction_ack),
                     .bd_command               (bd_command),
                     .bd_address               (bd_address),
                     .bd_wdata_ready           (bd_wdata_ready),
                     .bd_wdata                 (bd_wdata),
                     .bd_wdata_mask            (bd_wdata_mask),
                     .bd_data_len              (bd_data_len),
                     .bd_rdata                 (bd_rdata),
                     .bd_rdata_valid           (bd_rdata_valid)
                    );

 


    rpc2_ctrl_dpram_wrapper 
      #(1,     // 0=async_fifo_axi, 1=sync_fifo_axi
        C_RX_FIFO_ADDR_BITS,
        C_RX_FIFO_DATA_WIDTH,
        DPRAM_MACRO,  // 0=not used, 1=used macro
        8,  // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX
        DPRAM_MACRO_TYPE // 0=STD, 1=LowLeak
        ) 
   rx_fifo_wrapper (/*AUTOINST*/
                    // Outputs
                    .rd_data            (rxfifo_dout[19:0]),     
                    .empty              (rxfifo_empty),          
                    .full               (rxfifo_full),           
                    .pre_full           (),                      
                    .half_full          (rxfifo_half_full),      
                    // Inputs
                    .rd_rst_n           (reset_n),               
                    .rd_clk             (clk),                   
                    .rd_en              (rxfifo_rd_en),          
                    .wr_rst_n           (1'b0),                  
                    .wr_clk             (1'b0),                  
                    .wr_en              (rxfifo_wr_en),          
                    .wr_data            (rxfifo_din[19:0]));     
endmodule 
