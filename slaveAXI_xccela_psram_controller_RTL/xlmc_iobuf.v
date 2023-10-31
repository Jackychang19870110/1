/* 
 * ----------------------------------------------------------------------------
 *  Project:  OpenHBMC
 *  Filename: hbmc_iobuf.v
 *  Purpose:  HyperBus I/O logic.
------------------------------------------
 */
`define       FPGA
 
//`default_nettype none
//`timescale 1ps / 1ps


module xlmc_iobuf #
(
    parameter   integer DRIVE_STRENGTH          = 8,
    parameter           SLEW_RATE               = "SLOW",
    parameter   integer USE_IDELAY_PRIMITIVE    = 1,
    parameter   real    IODELAY_REFCLK_MHZ      = 300.0,
    parameter   [9:0]   IDELAY_TAPS_VALUE       = 900
)
(
    input   wire            arst,



    input   wire            oddr_clk,

//    input   wire            oddr_clk,
//    input   wire            oddr_clk_180, 
  

   
    inout   wire            buf_io,
    input   wire            buf_t,
    input   wire    [1:0]   sdr_i
);
    
    wire            buf_o;
    wire            buf_i;
    wire            tristate;
//    wire            idelay_o;
    
/*----------------------------------------------------------------------------------------------------------------------------*/
`ifdef FPGA    
    IOBUF #
    (
        .DRIVE  ( DRIVE_STRENGTH ),     // Specify the output drive strength
        .SLEW   ( SLEW_RATE      )      // Specify the output slew rate
    )
    IOBUF_io_buf
    (
        .O  ( buf_o     ),  // Buffer output
        .IO ( buf_io    ),  // Buffer inout port (connect directly to top-level port)
        .I  ( buf_i     ),  // Buffer input
        .T  ( tristate  )   // 3-state enable input, high = input, low = output
    );


`else
    PIOBUF 
    IOBUF_io_buf
    (
        .O  ( buf_o     ),  // Buffer output
        .IO ( buf_io    ),  // Buffer inout port (connect directly to top-level port)
        .I  ( buf_i     ),  // Buffer input
        .T  ( tristate  )   // 3-state enable input, high = input, low = output
    );
`endif    
    
/*----------------------------------------------------------------------------------------------------------------------------*/
 `ifdef FPGA     
    ODDR #
    (
        .DDR_CLK_EDGE   ( "SAME_EDGE" ),    // "OPPOSITE_EDGE" or "SAME_EDGE"
        .INIT           ( 1'b0            ),    // Initial value of Q: 1'b0 or 1'b1
        .SRTYPE         ( "ASYNC"         )     // Set/Reset type: "SYNC" or "ASYNC"
    )
    ODDR_buf_i
    (
        .Q  ( buf_i     ),  // 1-bit DDR output
        .C  ( oddr_clk),  // 1-bit clock input
        .CE ( 1'b1      ),  // 1-bit clock enable input
        .D1 ( sdr_i[0]  ),  // 1-bit data input (positive edge)
        .D2 ( sdr_i[1]  ),  // 1-bit data input (negative edge)
        .R  ( 1'b0      ),  // 1-bit reset
        .S  ( 1'b0      )   // 1-bit set
    );
`else


    output_ddr #(.INIT(1'b1)) 
    ODDR_buf_i 
    (/*AUTOINST*/
        // Outputs
        .Q          (buf_i),             // Templated  1-bit DDR output
        // Inputs   
        .C_0        (oddr_clk),        // Templated  1-bit clock input for D1 (positive edge)
        .C_180       (oddr_clk_180),       // Templated  1-bit clock input for D2 (negative edge)
        .CE         (1'b1),              // Templated  1-bit clock enable input
        .D1         (sdr_i[0]),          // Templated  1-bit data input (positive edge)
        .D2         (sdr_i[1]),           // Templated  1-bit data input (negative edge)
        .R          (1'b0)             // Templated  1-bit reset
    );
  
`endif 

/*----------------------------------------------------------------------------------------------------------------------------*/
 `ifdef FPGA    
    ODDR #
    (
        .DDR_CLK_EDGE   ( "SAME_EDGE" ),    // "OPPOSITE_EDGE" or "SAME_EDGE"
        .INIT           ( 1'b0            ),    // Initial value of Q: 1'b0 or 1'b1
        .SRTYPE         ( "ASYNC"         )     // Set/Reset type: "SYNC" or "ASYNC"
    )
    ODDR_buf_t
    (
        .Q  ( tristate  ),  // 1-bit DDR output
        .C  ( oddr_clk  ),  // 1-bit clock input
        .CE ( 1'b1      ),  // 1-bit clock enable input
        .D1 ( buf_t     ),  // 1-bit data input (positive edge)
        .D2 ( buf_t     ),  // 1-bit data input (negative edge)
        .R  ( 1'b0      ),  // 1-bit reset
        .S  ( 1'b0      )   // 1-bit set
    );

`else
wire oddr_clk_180;
assign oddr_clk_180 = ~oddr_clk;
    output_ddr #(.INIT(1'b1)) 
    ODDR_buf_t 
    (/*AUTOINST*/
        // Outputs
        .Q          (tristate),             // Templated  1-bit DDR output
        // Inputs   
        .C_0        (oddr_clk),        // Templated  1-bit clock input for D1 (positive edge)
        .C_180       (oddr_clk_180),       // Templated  1-bit clock input for D2 (negative edge)
        .CE         (1'b1),              // Templated  1-bit clock enable input
        .D1         (buf_t),          // Templated  1-bit data input (positive edge)
        .D2         (buf_t),           // Templated  1-bit data input (negative edge)
        .R          (1'b0)             // Templated  1-bit reset
    );
  
`endif


   
endmodule
//`default_nettype wire



/*----------------------------------------------------------------------------------------------------------------------------*/




module PIOBUF
    (
        output       O   ,
        inout        IO  ,
        input        I   ,
        input        T   
    );

    assign O      = T     ? IO : I;
    assign IO     = ~T    ? I  : 1'bz;

endmodule

/*----------------------------------------------------------------------------------------------------------------------------*/

//module output_ddr (/*AUTOARG*/
//   // Outputs
//   Q,
//   // Inputs
//   R, C_0, C_180, CE, D1, D2
//   );
//   parameter INIT = 1'b0;
//   
//   input R;
//   
//   input C_0;
//   input C_180;
//   input CE;
//   input D1;  // data for C_0
//   input D2;  // data for C_180
//   output Q;
//   reg                  Q;
//   // End of automatics
//
//   always @(posedge C_0 or posedge R) begin
//      if (R)
//        Q <= INIT;
//      else if (CE)
//        Q <= D1;
//   end
//
//   always @(posedge C_180 or posedge R) begin
//      if (R)
//        Q <= INIT;
//      else if (CE)
//        Q <= D2;
//   end
   
   
module output_ddr (/*AUTOARG*/
   // Outputs
   Q,
   // Inputs
   R, C_0, C_180, CE, D1, D2
   );
   parameter INIT = 1'b0;

   input R;

   input C_0;
   input C_180;
   input CE;
   input D1;  // data for C_0
   input D2;  // data for C_180
   output Q;
   reg                  Q,D1_reg,D2_reg; 
   // End of automatics
   always @(posedge C_180 or posedge R) begin
      if (R)   
         begin 
         D1_reg<=INIT;
         D2_reg<=INIT;
         end         
        else if (CE)
         begin 
         D1_reg<=D1;
         D2_reg<=D2;
         end
    end

 

   always @(posedge C_0 or posedge R) begin
      if (R)
        Q <= INIT;
      else if (CE)
        Q <= D1_reg;
   end

 

   always @(posedge C_180 or posedge R) begin
      if (R)
        Q <= INIT;
      else if (CE)
        Q <= D2_reg;
   end




endmodule // output_ddr



