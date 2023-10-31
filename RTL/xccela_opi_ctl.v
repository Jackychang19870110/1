`define       FPGA                  
module xccela_opi_ctl #
(

    parameter MEM_LEN       = 'd9,
    //0.4ns @200M
    parameter       integer INIT_CLOCK_HZ     = 200_000000,
    //0.5ns @166M
//    parameter       integer INIT_CLOCK_HZ     = 166_000000,
    //0.6ns @133M
//    parameter       integer INIT_CLOCK_HZ     = 133_000000,
    //0.6ns @133M
//    parameter       integer INIT_CLOCK_HZ     = 133_000000,

    parameter   integer INIT_DRIVE_STRENGTH  = 50, //ohm

    parameter integer C_ISERDES_CLOCKING_MODE = 0,
    parameter           RWDS_DIR_INPUT = 1,
    parameter           RWDS_DIR_OUTPUT = 0    
)
(
    input   wire            rst,
    output  wire            xl_ck,
    output  wire            xl_ce,
    inout   wire            xl_dqs,   
    inout   wire    [7:0]   xl_dq,



    
  //  input   wire            clk_iserdes,
    input   wire            clk_idelay_ref,

   
//    input   wire            clk_in,
    
 
    input   wire            clk_in_0,
    input   wire            clk_in_90,

    
//output reg[5:0]   state,
//output reg     [15:0]  power_up_tc,
/*--------- bridge signals-----------*/
    input   bd_instruction_req,
//    output  reg bd_instruction_ack,
    output  reg bd_instruction_ready,
    input   [7:0] bd_command,
    input   [31:0]bd_address,
    output  reg bd_wdata_ready,
    input   [15:0] bd_wdata,     
    input   [1:0] bd_wdata_mask,
//    input   [8:0] bd_data_len,
    input   [MEM_LEN-1:0] bd_data_len,    

    output  bd_rdata_valid,
//    input   w_fifo_wen,    
    output[15:0]  bd_rdata
/*-----------------------------------*/
);


reg      [5:0]   state;
reg     [15:0]  power_up_tc;
//////////////////////////////////////////////////
wire [31:0] ctrl_CLOCK_MHZ;
assign  ctrl_CLOCK_MHZ = INIT_CLOCK_HZ/1000000;

//////////////////////////////////////////////////
/******************************************************************************/
/*                          localparam parameter                              */
/******************************************************************************/
    localparam  DQ_DIR_OUTPUT   = 8'h00,
                DQ_DIR_INPUT    = 8'hff;
                
/*--------------------------------  ------------------------------------------*/
    localparam  real    HBMC_CLOCK_PERIOD_NS = 1000000000.0 / INIT_CLOCK_HZ;
    
    localparam  integer MEM_POWER_UP_DELAY_US = 160;
    localparam  integer MEM_POWER_UP_DELAY = (INIT_CLOCK_HZ / 1000000) * MEM_POWER_UP_DELAY_US;
    localparam  integer MEM_TRST_US = 2;    
    localparam  integer MEM_TRST_DELAY = (INIT_CLOCK_HZ / 1000000) * MEM_TRST_US;
    localparam  integer MEM_TCPH_US = 1;    
    localparam  integer MEM_TCPH_DELAY = (INIT_CLOCK_HZ / 1000000) * MEM_TCPH_US;

 //APS256XXN-OBR LC configuation   
    localparam  integer READ_LATENCY =   (INIT_CLOCK_HZ <=  66_000000)? 3 :       
                                          (INIT_CLOCK_HZ <= 109_000000)? 4 :     
                                          (INIT_CLOCK_HZ <= 133_000000)? 5 :     
                                          (INIT_CLOCK_HZ <= 166_000000)? 6 :     
                                          (INIT_CLOCK_HZ <= 200_000000)? 7 : 7;      
    localparam  integer WRITE_LATENCY =  (INIT_CLOCK_HZ <=  66_000000)? 3 :      
                                          (INIT_CLOCK_HZ <= 109_000000)? 4 :     
                                          (INIT_CLOCK_HZ <= 133_000000)? 5 :     
                                          (INIT_CLOCK_HZ <= 166_000000)? 6 :     
                                          (INIT_CLOCK_HZ <= 200_000000)? 7 : 7;      
     
    localparam  integer MIN_RWR = READ_LATENCY - 3;                              /* Min Read-Write recovery time */
    
    localparam [1:0] MR_0_DRIVE_STRENGTH  = (INIT_DRIVE_STRENGTH ==  25)? 2'b00  :
                                       (INIT_DRIVE_STRENGTH ==  50)? 2'b01  :
                                       (INIT_DRIVE_STRENGTH ==  100)? 2'b10 :
                                       (INIT_DRIVE_STRENGTH ==  200)? 2'b11 :00;
    
    localparam [2:0] MR_0_READ_LATENCY =    (READ_LATENCY == 3)? 3'b000 :  // 66M
                                       (READ_LATENCY == 4)? 3'b001 :  // 109M
                                       (READ_LATENCY == 5)? 3'b010 :  // 133M
                                       (READ_LATENCY == 6)? 3'b011 :  // 166M
                                       3'b100;                             // 200M
                                       
    localparam [2:0] MR_0_WRITE_LATENCY =    (WRITE_LATENCY == 3)? 3'b000 :   // 66M 
                                       (WRITE_LATENCY == 4)? 3'b100 :    // 109M
                                       (WRITE_LATENCY == 5)? 3'b010 :    // 133M
                                       (WRITE_LATENCY == 6)? 3'b110 :    // 166M
                                       3'b001;                               // 200M
                                       
                                      
    wire [7:0] MR0_INIT, MR4_INIT;                                              
    assign  MR0_INIT = {2'b00,1'b0,MR_0_READ_LATENCY,MR_0_DRIVE_STRENGTH}; // 25ohm
    assign  MR4_INIT = {MR_0_WRITE_LATENCY,2'b11,3'b000};   //  slow refresh
       
 /*--------------------------------------------------------------------------*/
                                                                           
/******************************************************************************/
/*                          global register                                   */
/*******************************************************************************/

//reg [31:0] cmd;
reg ce_n;
reg ck_ena;
reg rwds_t;
reg[7:0] dq_t;
reg[1:0] rwds_sdr_i;
reg[15:0] dq_sdr_i;
//wire[31:0] data_iserdes;
reg             dru_iserdes_rst;
//wire    [7:0]   rwds_iserdes;
//wire    [7:0]   rwds_resync;
//wire    [63:0]  data_resync;
//reg     [7:0]   latency_tc;
reg     [2:0]   rwr_tc;
//reg     [15:0]  hram_id_reg;
//reg             fifo_rd;
//reg             mem_access;
//reg             word_last;
//reg     [47:0]  ca;
//reg     [15:0]  burst_cnt;
//reg     [15:0]  burst_size;
//reg     [15:0]  word_count;
//reg     [15:0]  word_count_prev;
//reg     [31:0]  mem_addr;
//reg             wr_not_rd;
//reg             wrap_not_incr;
//wire            hb_recov_data_vld;
//wire    [15:0]  hb_recov_data;
//reg     [15:0]  reg_data;
//reg     [5:0]   tCPH_tc;
//reg     [7:0]   reg_data_out;
//wire    [5:0]  reg_raddr_in,reg_waddr_in;
//wire    [7:0]  reg_wdata_in;
//reg [1:0] reg_key_1,reg_key_2;
//wire trigger;
wire clk_hbmc_0,clk_hbmc_90;
//    wire    iserdes_clkdiv;
reg [31:0] gl_address_reg;

//reg [8:0]  gl_datalen_reg;
//reg [9:0]  gl_datalen_reg;
//reg [MEM_LEN:0] gl_datalen_reg;
reg [MEM_LEN:0] gl_datalen_reg;

reg [7:0] gl_command_reg;
reg      rwr_tc_run;
reg     rdata_valid;
reg[5:0]     r_fifo_cnt;
reg [15:0] dq_sdr_j;

 wire [MEM_LEN:0] rdata_count;  
 /******************************************************************************/
/*                            CLOCK PLL                                        */
/*******************************************************************************/
//    
// clk_wiz_0 pll0
// (
//  // Clock out ports
//          .clk_out_0(clk_hbmc_0),
//          .clk_out_90(clk_hbmc_90),
//  // Status and control signals
//          .resetn(~rst),
//          .locked(),
// // Clock in ports
//          .clk_in1(clk_in)
// );
//  

assign clk_hbmc_0 = clk_in_0;
assign clk_hbmc_90 = clk_in_90;

 /******************************************************************************/
/*                          global register                                   */
/*******************************************************************************/

/*******************************************************************************/
/*                          DQ IOBUF MODULE                                   */
/*******************************************************************************/

//    wire    iserdes_clk_iobuf,strobe_iserdes;
    localparam  integer MODE_BUFG       = 0,
                        MODE_BUFIO_BUFR = 1;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : dq
            xlmc_iobuf  /*#
           (
                .DRIVE_STRENGTH         ( C_HBMC_FPGA_DRIVE_STRENGTH                 ),
                .SLEW_RATE              ( C_HBMC_FPGA_SLEW_RATE                      ),
                .USE_IDELAY_PRIMITIVE   ( C_DQ_VECT_USE_IDELAY_PRIMITIVE[i]          ),
                .IODELAY_REFCLK_MHZ     ( C_IODELAY_REFCLK_MHZ                       ),
                .IODELAY_GROUP_ID       ( C_IODELAY_GROUP_ID                         ),
                .IDELAY_TAPS_VALUE      ( C_DQ_VECT_IDELAY_TAPS_VALUE[i*5 + 4 : i*5] )
            )*/
            xlmc_iobuf_dq
            (
                .arst           ( rst                             ),
                .oddr_clk       ( clk_hbmc_0                      ),
                .buf_io         ( xl_dq[i]                        ),
                .buf_t          ( dq_t[i]                         ),
                .sdr_i          ( {dq_sdr_i[i + 8], dq_sdr_i[i]}  )   //dq_sdr_i[7:0] positive edge , dq_sdr_i[15:8] negetive edge
            );
        end
    endgenerate
     
    
 /*******************************************************************************/
    /* Data in module
/*******************************************************************************/       
//wire [31:0] data_recov_bridge;
wire wire_empty;

wire xl_dqs_delay,read_state,rfifo_finish;
wire [2:0]           rds_delay_adj = 3'b000;
   dqs_delay_buf 
     dqs_delay (/*AUTOINST*/
                    // Outputs
                    .out                (xl_dqs_delay),               // Templated
                    // Inputs
                    .in                 (xl_dqs),               // Templated
                    .s                  (rds_delay_adj[2:0]),    // Templated
                    .rst                (rst),                 // Templated
                    .ref_clk            (clk_idelay_ref));
   


   data_in_block  #(
                   .MEM_LEN (MEM_LEN)     // burst length count
                   ) 
     data_in_block1 (/*AUTOINST*/
                           // Outputs
                           .dqinfifo_empty(wire_empty),
                           .dqinfifo_dout(bd_rdata[15:0]),
                           .rdata_count (rdata_count),
                           // Inputs
//                           .clk         (clk_hbmc_90),
                           .clk         (clk_hbmc_0),                           
                           .data_len(gl_datalen_reg),                           
                           .rst_ce(ce_n),                           
                           .reset_n     (!rst),
                           .read_state(read_state),
                           .dqs_clk     (xl_dqs_delay),
                           .dq_in       (xl_dq[7:0]),
                           .dqinfifo_rd_en(bd_rdata_valid),
                           .rfifo_finish(rfifo_finish),
                           .rdata_valid(rdata_valid));
   
/*******************************************************************************/
/*                           CLK OBUF MODULE                                   */
/*******************************************************************************/    
    xlmc_clk_obuf /*#
    (
        .DRIVE_STRENGTH ( C_HBMC_FPGA_DRIVE_STRENGTH ),
        .SLEW_RATE      ( C_HBMC_FPGA_SLEW_RATE      )
    )*/
    xlmc_clk_obuf_inst
    (
        .cen     ( ck_ena      ),
        .clk     ( clk_hbmc_90 ),
        .xl_ck_p ( xl_ck     )
        //.xl_ck_n ( xl_ck_c     )
    );
/*******************************************************************************/
/*                           DQS OBUF MODULE                                   */
/*******************************************************************************/ 
     
//    wire    rwds_imm;
    
    
    xlmc_iobuf /*#
    (
        .DRIVE_STRENGTH         ( C_HBMC_FPGA_DRIVE_STRENGTH  ),
        .SLEW_RATE              ( C_HBMC_FPGA_SLEW_RATE       ),
        .USE_IDELAY_PRIMITIVE   ( C_RWDS_USE_IDELAY           ),
        .IODELAY_REFCLK_MHZ     ( C_IODELAY_REFCLK_MHZ        ),
        .IODELAY_GROUP_ID       ( C_IODELAY_GROUP_ID          ),
        .IDELAY_TAPS_VALUE      ( C_RWDS_IDELAY_TAPS_VALUE    )
    )*/
    xlmc_iobuf_rwds_t
    (
        .arst           ( dru_iserdes_rst   ),
        .oddr_clk       ( clk_hbmc_0        ),
        
        .buf_io         ( xl_dqs         ),
        .buf_t          ( rwds_t            ),
        .sdr_i          ( rwds_sdr_i)
    );
/*******************************************************************************/
/*                          Global reset task                                  */
/*******************************************************************************/
 localparam  [2:0]      ST_GBRST_0             = 3'd0,
                        ST_GBRST_1             = 3'd1,
                        ST_GBRST_2             = 3'd2,
                        ST_GBRST_3             = 3'd3,
                        ST_GBRST_4             = 3'd4,
                        ST_GBRST_5             = 3'd5,
                        ST_GBRST_6             = 3'd6,
                        ST_GBRST_DONE          = 3'd7,
                        FSM_GBRST_RESET_STATE  = ST_GBRST_0;
    
    reg         [2:0]   gbrst_state = FSM_GBRST_RESET_STATE;
    wire                gbrst_done  = (gbrst_state == ST_GBRST_DONE);
    
    task task_gbrst;
    begin
    
        case (gbrst_state)
        // prepare registers 
            ST_GBRST_0: begin
                if (rwr_tc >= MIN_RWR) begin
                    gbrst_state <= ST_GBRST_1;
                    rwr_tc_run <= 1'b0;
                end
            end
            // INST stage --- 2 edge
            ST_GBRST_1: begin
				     gbrst_state <= ST_GBRST_2;
					  dq_sdr_i <= 16'hFFFF;
                  rwds_t       <=  RWDS_DIR_INPUT;
                  dq_t         <=  DQ_DIR_OUTPUT;
                 ce_n         <= 1'b0;                  				
            end
		    // Fixed MRW LC --- 2 edge 
            ST_GBRST_2:
             begin
                 ce_n         <= 1'b0;
                 ck_ena       <= 1'b1;        
			     dq_sdr_i <= 16'h0000;	                    
					 gbrst_state <= ST_GBRST_3;		 
            end         
            // Fixed MRW LC --- rising edge
            // issue MR Address --- falling edge                        	
            ST_GBRST_3:
				begin
					 dq_sdr_i[15:8] <= 16'h0000; // issue MR Address in negetive edge 										
					 gbrst_state <= ST_GBRST_4;
					 bd_wdata_ready <= 1'b1;
                end
             // issue MR Data --- rising edge
             // Dummry edge  --- falling edge         				
            ST_GBRST_4: begin
					 dq_sdr_i[15:8] <= 16'h0000;  // posetive edge of third cycle															 
					 gbrst_state <= ST_GBRST_5;	 
					 bd_wdata_ready <= 1'b0;					 
            end                  
            
            ST_GBRST_5: begin
					 dq_sdr_i[15:8] <= 16'h0000;  // posetive edge of third cycle															 
					 gbrst_state <= ST_GBRST_6;	 
					 bd_wdata_ready <= 1'b0;					 
            end    
                          
             ST_GBRST_6: begin
					 dq_sdr_i[15:8] <= 16'h0000;  // posetive edge of third cycle															 
					 gbrst_state <= ST_GBRST_DONE;	 
					 bd_wdata_ready <= 1'b0;	
                    ck_ena       <= 1'b0;                       					 				 
            end                  
         
            
            ST_GBRST_DONE: begin
                     ce_n  <=  1'b1;
                    rwr_tc_run <= 1'b1;                             				
                    gbrst_state <= FSM_GBRST_RESET_STATE;
            end
        endcase
    end
    endtask 
/*******************************************************************************/
/*                              MR read task                                   */
/*******************************************************************************/

localparam  [3:0]   ST_RD_REG_0             = 4'd0,
                        ST_RD_REG_1             = 4'd1,
                        ST_RD_REG_2             = 4'd2,
                        ST_RD_REG_3             = 4'd3,
                        ST_RD_REG_4             = 4'd4,
                        ST_RD_REG_5             = 4'd5,
                        ST_RD_REG_6             = 4'd6,
                        ST_RD_REG_7             = 4'd7,                        
                        ST_RD_REG_DONE          = 4'd8,
                        ST_RD_REG_dummy1            = 4'd9,
                        ST_RD_REG_dummy2            = 4'd10,                        
                        FSM_RD_REG_RESET_STATE  = ST_RD_REG_0;
    
    reg         [3:0]   rd_reg_state = FSM_RD_REG_RESET_STATE;
    reg         [31:0]  mrr_address_reg;
    reg         [9:0]  mrr_latency;
    reg         [4:0]  mrr_burst_cnt,fifo_delay_cnt;
    wire                rd_reg_done  = (rd_reg_state == ST_RD_REG_DONE);
    
    task task_rd_reg;        
		input       [31:0]  address;
    begin
    
        case (rd_reg_state)
            ST_RD_REG_0: begin
                if (rwr_tc >= MIN_RWR) begin
                    rwr_tc_run <= 1'b0;                
					mrr_address_reg <= address;
					mrr_latency <= 10'd0;	
					mrr_burst_cnt <= 5'd0;					                  
                    rd_reg_state <= ST_RD_REG_1;
                    r_fifo_cnt <= 0;
                    rdata_valid <= 0;
                    fifo_delay_cnt <= 0;
                end
            end
            // INST stage --- 2 edge
            ST_RD_REG_1: begin
				     rd_reg_state <= ST_RD_REG_2;
					 dq_sdr_i <= 16'h4040;	
                     rwds_t       <=  RWDS_DIR_INPUT;
                     dq_t         <=  DQ_DIR_OUTPUT;       
                     ce_n         <= 1'b0;                          					  	
            end
		    // Fixed MRW LC --- 2 edge 
            ST_RD_REG_2: begin
                ce_n         <= 1'b0; 
                ck_ena       <= 1'b1;           
				dq_sdr_i <= 16'h0000;	
                rd_reg_state <= ST_RD_REG_3;	 
            end         		
            // Fixed MRW LC --- rising edge
            // issue MR Address --- falling edge     				
            ST_RD_REG_3: begin
                    rd_reg_state <= ST_RD_REG_4;
					dq_sdr_i[15:8] <= mrr_address_reg[7:0]; // issue MR Address in negetive edge 										
            end
            // LATENCY CYCLE
            ST_RD_REG_4: begin
				
               if (mrr_latency == READ_LATENCY ) 
					 begin
                      rd_reg_state <= ST_RD_REG_5;
                      
                      rwds_t       <=  RWDS_DIR_INPUT;                                  					  	                      
                end 
					 else 
					   begin 
					       mrr_latency <= mrr_latency + 1'b1;
					       if (mrr_latency == 10'd2) dq_t <=  DQ_DIR_INPUT;
					   end				
            end
            
            
            ST_RD_REG_5: begin 
                if (mrr_burst_cnt == gl_datalen_reg) begin
//                if (mrr_burst_cnt == gl_datalen_reg+1) begin                
                    ck_ena <= 1'b0;
                    rd_reg_state <= ST_RD_REG_6;
                end else begin
                    mrr_burst_cnt <= mrr_burst_cnt + 1'b1;
                end            
            end
            
            ST_RD_REG_6: begin
                     ce_n <= 1'b1;                     
            
                if (fifo_delay_cnt == 6)  
                     rd_reg_state <= ST_RD_REG_7;
                     else fifo_delay_cnt <= fifo_delay_cnt + 1'b1;
                    
            end
             
            ST_RD_REG_7: begin
                       ce_n <= 1'b1; 
                       rdata_valid <= 1; 
                       if (rfifo_finish) 
                        begin
                          rd_reg_state <= ST_RD_REG_DONE;
                        end                                                       
            end           
           
                       
            ST_RD_REG_DONE: begin
                ce_n <= 1'b1;	
                rdata_valid <= 0;                 			
                rwr_tc_run <= 1'b1;                
                rd_reg_state <= FSM_RD_REG_RESET_STATE;
            end
        endcase
    end
    endtask
    
/*******************************************************************************/
/*                              MR write task                                  */
/*******************************************************************************/
 localparam  [2:0]   ST_WR_REG_0             = 3'd0,
                        ST_WR_REG_1             = 3'd1,
                        ST_WR_REG_2             = 3'd2,
                        ST_WR_REG_3             = 3'd3,
                        ST_WR_REG_4             = 3'd4,
                        ST_WR_REG_5             = 3'd5,
                        ST_WR_REG_6             = 3'd6,
                        ST_WR_REG_DONE          = 3'd7,
                        FSM_WR_REG_RESET_STATE  = ST_WR_REG_0;
    
    reg         [2:0]   wr_reg_state = FSM_WR_REG_RESET_STATE;
    reg         [31:0]  mrw_address_reg;	 
    wire                wr_reg_done  = (wr_reg_state == ST_WR_REG_DONE);
    
    task task_wr_reg;
		  input       [31:0]  address;
		  input       init_config;  //high -> init_config ; low -> bridge config
		  input       [7:0]  init_data;
    begin
    
        case (wr_reg_state)
        // prepare registers 
            ST_WR_REG_0: begin
                if (rwr_tc >= MIN_RWR) begin
                    rwr_tc_run <= 1'b0;                
					mrw_address_reg <= address;						  
                    wr_reg_state <= ST_WR_REG_1;
                end
            end
            // INST stage --- 2 edge
            ST_WR_REG_1: begin
				     wr_reg_state <= ST_WR_REG_2;
					  dq_sdr_i <= 16'hC0C0;
                  rwds_t       <=  RWDS_DIR_INPUT;
                  dq_t         <=  DQ_DIR_OUTPUT;
                  ce_n         <= 1'b0;                  				
            end
		    // Fixed MRW LC --- 2 edge 
            ST_WR_REG_2:
             begin
                 ce_n         <= 1'b0;
                 ck_ena       <= 1'b1;        
			     dq_sdr_i <= 16'h0000;	                    
					 wr_reg_state <= ST_WR_REG_3;		 
            end         
            // Fixed MRW LC --- rising edge
            // issue MR Address --- falling edge                        	
            ST_WR_REG_3:
				begin
					 dq_sdr_i[15:8] <= mrw_address_reg[7:0]; // issue MR Address in negetive edge 										
					 wr_reg_state <= ST_WR_REG_4;
					 bd_wdata_ready <= 1'b1;
                end
             // issue MR Data --- rising edge
             // Dummry edge  --- falling edge         				
            ST_WR_REG_4: begin
                     dq_sdr_i[15:8] <= 8'h00;
					 dq_sdr_i[7:0] <= (init_config) ? init_data : bd_wdata[7:0];   // posetive edge of third cycle															 
					 wr_reg_state <= ST_WR_REG_5;	 
					 bd_wdata_ready <= 1'b0;					 
            end
            
            ST_WR_REG_5: begin
			   wr_reg_state <= ST_WR_REG_6;
	           rwds_t       <=  RWDS_DIR_INPUT;
               dq_t         <=  DQ_DIR_INPUT;	 
            end

            ST_WR_REG_6: begin
			   wr_reg_state <= ST_WR_REG_DONE;
               ck_ena       <= 1'b0;                                   
            end
           
            ST_WR_REG_DONE: begin
                     ce_n  <=  1'b1;
                    rwr_tc_run <= 1'b1;                                          				
                wr_reg_state <= FSM_WR_REG_RESET_STATE;
            end
        endcase
    end
    endtask
	 	 
/*******************************************************************************/
/*                             array write task                                */
/*******************************************************************************/
 localparam  [2:0]      ST_WR_0             = 3'd0,
                        ST_WR_1             = 3'd1,
                        ST_WR_2             = 3'd2,
                        ST_WR_3             = 3'd3,
                        ST_WR_4             = 3'd4,
                        ST_WR_5             = 3'd5,
                        ST_WR_6             = 3'd6,
                        ST_WR_DONE          = 3'd7,
                        FSM_WR_RESET_STATE  = ST_WR_0;
    
    reg         [2:0]   wr_state = FSM_WR_RESET_STATE;
    reg         [31:0]  w_address_reg;	 
    wire                wr_done  = (wr_state == ST_WR_DONE);
//    reg         [9:0]   w_latency,w_burst_cnt;
//    reg         [MEM_LEN:0]  w_latency,w_burst_cnt;  
    reg         [MEM_LEN:0]  w_latency,w_burst_cnt;     
//    wire                w_fifo_empty;
    reg                 w_fifo_ren;
//    reg         [3:0]   w_len;
    //wire        [15:0]  w_fifo_data;
    //wire        [1:0]   w_fifo_dqs;
    task task_wr;
		  input       [31:0]  address;
    begin
    
        case (wr_state)
        // prepare registers 
            ST_WR_0: begin
                if (rwr_tc >= MIN_RWR) begin
                    rwr_tc_run <= 1'b0;                
					w_address_reg <= address;
					gl_datalen_reg <= bd_data_len + 1'b1;
					w_latency <= 10'd0;	
					w_burst_cnt <= 10'd0;				  
                    wr_state <= ST_WR_1;
                    w_fifo_ren <= 1'b0;
                end
            end
            // INST stage --- 2 edge
            ST_WR_1: begin
				     wr_state <= ST_WR_2;
					  dq_sdr_i <= 16'hA0A0;
                  rwds_t       <=  RWDS_DIR_INPUT;
                  dq_t         <=  DQ_DIR_OUTPUT;			
                  ce_n         <= 1'b0;                  
            end
		    // ADDR A3/A2 --- 2 edge 
            ST_WR_2:
             begin
                 ce_n         <= 1'b0;
                 ck_ena       <= 1'b1;        
			     dq_sdr_i <= {w_address_reg[23:16],w_address_reg[31:24]};	                    
					 wr_state <= ST_WR_3;		 
            end         
		    // ADDR A1/A0 --- 2 edge                        	
            ST_WR_3:
				begin
			     dq_sdr_i <= {w_address_reg[7:0],w_address_reg[15:8]};	                    
					 wr_state <= ST_WR_4;
                end
                
            // LATENCY CYCLE
            ST_WR_4: begin
				
               if (w_latency == WRITE_LATENCY - 2) 
					 begin
                      wr_state <= ST_WR_5;      
                      rwds_t   <=  RWDS_DIR_OUTPUT;
					 bd_wdata_ready <= 1'b1;                        
	                end 
					 else 
					   begin 
					       w_latency <= w_latency + 1'b1;
					       dq_sdr_i <= 16'h00;
					   end				
            end
            
            ST_WR_5: begin 
                if (w_burst_cnt == (gl_datalen_reg)  ) begin     
					 bd_wdata_ready <= 1'b0;					                         
                     rwds_t       <=  RWDS_DIR_INPUT;
                     dq_t         <=  DQ_DIR_INPUT;                        
                     wr_state <= ST_WR_6;
                end else begin
                    rwds_sdr_i <= {bd_wdata_mask[0],bd_wdata_mask[1]};
                        dq_sdr_i <= {bd_wdata[7:0],bd_wdata[15:8]};
//                        dq_sdr_j <= bd_wdata; 
                    w_burst_cnt <= w_burst_cnt + 1'b1;
                end            
            end            
            
            ST_WR_6: begin
               ck_ena <= 1'b0;
			   wr_state <= ST_WR_DONE;
            end
           
            ST_WR_DONE: begin
               ce_n  <=  1'b1;  	             
                    rwr_tc_run <= 1'b1;                               				
                wr_state <= FSM_WR_RESET_STATE;
            end
        endcase
    end
    endtask	    

/*******************************************************************************/
/*                          array read task                                */
/*******************************************************************************/


localparam  [3:0]   ST_RD_0             = 4'd0,
                        ST_RD_1             = 4'd1,
                        ST_RD_2             = 4'd2,
                        ST_RD_3             = 4'd3,
                        ST_RD_4             = 4'd4,
                        ST_RD_5             = 4'd5,
                        ST_RD_6             = 4'd6,
                        ST_RD_DONE          = 4'd7,
                            ST_RD_7             = 4'd8,
                        ST_RD_dummy1        = 4'd9,
                        ST_RD_dummy2        = 4'd10,                                                
                        FSM_RD_RESET_STATE  = ST_RD_0;
    
    reg         [3:0]   rd_state = FSM_RD_RESET_STATE;
    reg         [31:0]  r_address_reg;
    reg         [9:0]  r_latency;
//    reg         [8:0]  r_burst_cnt;   
    reg         [MEM_LEN-1:0]   r_burst_cnt;
    wire                rd_done  = (rd_state == ST_RD_DONE);
    

 
    task task_rd;        
		input       [31:0]  address;
    begin
    
        case (rd_state)
            ST_RD_0: begin
                if (rwr_tc >= MIN_RWR) begin
                    rwr_tc_run <= 1'b0;                
					r_address_reg <= address;
					r_latency <= 10'd0;	
					r_burst_cnt <= 0;  //{MEM_LEN{1'b0}};	
//                    rdata_count <= 0;                    
                    rd_state <= ST_RD_1;
                    rdata_valid <= 0;
                    r_fifo_cnt <= 0;
                end
            end
            // INST stage --- 2 edge
            ST_RD_1: begin
				     rd_state <= ST_RD_2;
					 dq_sdr_i <= 16'h2020;	
                     rwds_t       <=  RWDS_DIR_INPUT;
                     dq_t         <=  DQ_DIR_OUTPUT;   
                     ce_n         <= 1'b0;                              					  
            end
                       
		    // ADDR A3/A2 --- 2 edge 
            ST_RD_2:
             begin
                 ce_n         <= 1'b0;
                 ck_ena       <= 1'b1;        
			     dq_sdr_i <= {r_address_reg[23:16],r_address_reg[31:24]};	                    
					 rd_state <= ST_RD_3;		 
            end         
		    // ADDR A1/A0 --- 2 edge                        	
            ST_RD_3:
				begin
			     dq_sdr_i <= {r_address_reg[7:0],r_address_reg[15:8]};	                    
					 rd_state <= ST_RD_4;
                end
                            
            
            // LATENCY CYCLE
            ST_RD_4: begin
				
               if (r_latency == READ_LATENCY ) 
					 begin
                      rd_state <= ST_RD_5;                      
                      rwds_t       <=  RWDS_DIR_INPUT;                                  					  	                      
                end 
					 else 
					   begin 
					       r_latency <= r_latency + 1'b1;
					       if (r_latency == 10'd2) dq_t <=  DQ_DIR_INPUT;
					   end				
            end
            
/*            
            ST_RD_5: begin 
                if (r_burst_cnt == gl_datalen_reg) begin
//                if (rdata_count == gl_datalen_reg) begin                
                    rd_state <= ST_RD_6;
                     ck_ena <= 1'b0; 
                end else begin
                    r_burst_cnt <= r_burst_cnt + 1'b1;                     
                end        
            end
*/


            ST_RD_5: begin 
            //    if (r_burst_cnt == gl_datalen_reg) begin
                if (rdata_count == gl_datalen_reg) begin                
                    rd_state <= ST_RD_6;
                     ck_ena <= 1'b0; 
            //    end else begin
            //        r_burst_cnt <= r_burst_cnt + 1'b1;                     
                end        
            end
            

            
            ST_RD_6: begin
                     rd_state <= (wire_empty)? rd_state : ST_RD_7;
                   //  ck_ena <= 1'b0;
            end
            
            ST_RD_7: begin
             // ck_ena <= 1'b0;
                       ce_n <= 1'b1; 
                       rdata_valid <= 1; 
                       if (rfifo_finish) 
                        begin
                          rd_state <= ST_RD_DONE;
                        end                                                       
            end
            
            ST_RD_DONE: begin
                rdata_valid <= 0;             
                ce_n <= 1'b1;				
                rwr_tc_run <= 1'b1;                
                rd_state <= FSM_RD_RESET_STATE;
            end
        endcase
    end
    endtask
    
    
/*******************************************************************************/
/*                            local rst task                                  */
/*******************************************************************************/

  task local_rst;
    begin
        ce_n <= 1'b1;
        ck_ena <= 0;
        dq_t <= 8'h0;
//        bd_instruction_ack <= 1'b0;
        bd_wdata_ready <= 1'b0;
        rwr_tc_run      <= 1'b1;
        rwds_sdr_i      <= 2'b00;
        rwds_t          <= RWDS_DIR_INPUT;
        dq_sdr_i        <= {16{1'b0}};
        dq_t            <= DQ_DIR_INPUT;
       dru_iserdes_rst <= 1'b1;
       gl_datalen_reg <= 0;
       gl_address_reg <= 0;
       gl_command_reg <= 0;
        power_up_tc     <= {16{1'b0}};
        rdata_valid <= 0;
        r_fifo_cnt <= 0;
        bd_instruction_ready <= 0;
    end
    endtask
    
/*******************************************************************************/
/*                           main state machine                                */
/*******************************************************************************/

   localparam  [5:0]   st_rst                         = 6'd0,
                       st_por_delay                   = 6'd1,
                       
//                       st_gbrst                       = 6'd2,
                       power_up_init                  = 6'd2,
                       
                       st_trst_2us                    = 6'd3,
                       st_mrw                         = 6'd4,
                       st_mrr                         = 6'd5,
					   st_sync_read 	              = 6'd6,
					   st_sync_write                  = 6'd7,
					   st_linear_read                 = 6'd8,
					   st_linear_write                = 6'd9,								                         
                       st_tCPH                        = 6'd10,
                       st_idle1                       = 6'd11,
                       st_idle2                       = 6'd12,
                       st_global_rst                  = 6'd13,
                       st_ready                       = 6'd14,
                       st_init_mr0                    = 6'd15,
                       st_init_mr4                    = 6'd16;

    
    always @(posedge clk_hbmc_0 or posedge rst) begin
    
        if (rst) begin
            local_rst();
            state <= st_rst;
        end else begin
            
            case (state)
                st_rst: begin
                    local_rst();
//                    state <= st_por_delay; // wait time 150us (PSRAM time spec tPU)
                    state <= st_init_mr0; // when test use this, avoid wait time 150us
                end
                //150us tPU                               
                st_por_delay: begin
                    if (power_up_tc == MEM_POWER_UP_DELAY) begin
//                        state <= st_gbrst;
                        state <= power_up_init;
                        power_up_tc     <= {16{1'b0}};
                    end else begin
                        power_up_tc <= power_up_tc + 1'b1;
                    end
                end
                //GLOBAL RESET               
//                st_gbrst: begin
                power_up_init: begin                
                    task_gbrst();  
                    state <= (gbrst_done)? st_trst_2us : state;
                end                
                //tRST 2us
                st_trst_2us: begin
                    if (power_up_tc == MEM_TRST_DELAY) begin
                        state <= st_init_mr0;
                        power_up_tc     <= {16{1'b0}};                        
                   end else begin
                        power_up_tc <= power_up_tc + 1'b1;
                    end
                end
                st_init_mr0: begin
                    task_wr_reg(32'h0,1,MR0_INIT);                 
                    state <= (wr_reg_done)? st_init_mr4 : state;                    
                end
                
                st_init_mr4: begin
                    task_wr_reg(32'h4,1,MR4_INIT);                 
                    state <= (wr_reg_done)? st_idle1 : state;
                    bd_instruction_ready <= (wr_reg_done)? 1:0;                                        
                end
                
                st_idle1:begin
                    if (bd_instruction_req)  
                        begin 
                          state <= st_idle2; 
//                          bd_instruction_ack <= 1'b1;  
                          gl_address_reg <= bd_address;
                          gl_datalen_reg <= bd_data_len;
                          gl_command_reg <= bd_command;
//                          bd_instruction_ack <= 1'b0;
                           bd_instruction_ready <= 0;                             
                          
                        end
                            else 
                              begin 
                                bd_instruction_ready <= 1;
                                state <= state;                                
                              end
                end
                /*
                    0x00: init  ***              
                    0x01: mrw
                    0x02: mrr
                    0x04: write
                    0x08: read
                    0x80: global reset
                */
                st_idle2: begin
							case(gl_command_reg)
//							   'h00: begin state <= st_gbrst; end           //init
							   'h00: begin state <= power_up_init; end           //init	                               
                               
							   'h01: begin state <= st_mrw; end           //mrw
							   'h02: begin state <= st_mrr; end           //mrr
							   'h04: begin state <= st_linear_write; end   //sync read
							   'h08: begin state <= st_linear_read; end  //sync write
							   'h80: begin state <= st_global_rst; end    //global reset					   
								default state <= st_idle2;
							 endcase					
					end					
                //mrw                 
                st_mrw: begin
                    task_wr_reg(gl_address_reg,0,16'h0000); 
                    state <= (wr_reg_done)? st_ready : state;               
                end 
                //mrr                 
                st_mrr: begin
                    task_rd_reg(gl_address_reg);
                    state <= (rd_reg_done)? st_ready : state;                 
                end               
                 
                st_linear_write: begin
                    task_wr(gl_address_reg);
                    state <= (wr_done)? st_ready:state; 
                end
                
                st_linear_read: begin
                    task_rd(gl_address_reg);
                    state <= (rd_done)? st_ready:state;                  
                end
                
                st_ready: begin
                   bd_instruction_ready <= 1;
                   state <= st_idle1; 
                end
                    
                st_global_rst: begin
                    task_gbrst();  
                    state <= (gbrst_done)? st_ready : state;                        
                end
            
                endcase
            end
        end    
/*----------------------------------------------------------------------------------------------------------------------------*/
     /* RWR (Read-Write Recovery) counter process */
    always @(posedge clk_hbmc_0 or posedge rst) begin
        if (rst) begin
            rwr_tc <= 3'd0;
        end else begin
            if (rwr_tc_run) begin
                rwr_tc <= (rwr_tc == 3'd7)? rwr_tc : rwr_tc + 1'b1;
            end else begin
                rwr_tc <= 3'd0;
            end
        end
    end
/*----------------------------------------------------------------------------------------------------------------------------*/
`ifdef FPGA  
    OBUF/* #
    (
        .DRIVE  ( C_HBMC_FPGA_DRIVE_STRENGTH ),
        .SLEW   ( C_HBMC_FPGA_SLEW_RATE      )
    )*/
    OBUF_cs_n
    (
        .I  ( ce_n    ),
        .O  ( xl_ce )
    );        
`else
 assign xl_ce = ce_n;
 
 `endif 
 
 
  wire[125:0] inst;
  
  assign read_state = ((state == st_mrr)||(state == st_linear_read))? 1:0;
  assign inst = (state==st_rst)? "RST state": 
                (state==st_por_delay)? "tPU state":
//                (state==st_gbrst)? "Global RST":
                (state==st_global_rst)? "Global RST":
                (state==power_up_init)? "POWER_UP_INIT":

                
                (state==st_trst_2us)? "tRST State" :
                (state==st_init_mr0)? "MR0 CONFIG" :
                (state==st_init_mr4)? "MR4 CONFIG" :  
                (state==st_idle1)? "IDLE1" :
                (state==st_idle2)? "IDLE2" :                                                                                
                (state==st_mrw)? "MRW State" :
                (state==st_mrr)? "MRR State" :
                (state==st_linear_write)?"DATA WRITE":
                (state==st_linear_read)?"DATA READ":
                (state==st_ready)?"READY"
                : 0;


endmodule