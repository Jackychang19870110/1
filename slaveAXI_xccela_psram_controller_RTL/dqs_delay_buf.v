
//`define       FPGA

module dqs_delay_buf (/*AUTOARG*/
   // Outputs
   out,
   // Inputs
   in, s, rst, ref_clk
   );
   parameter FIXED_DELAY = 12;
   
   input in;
   input [2:0] s;
   output out;
   input rst;
   input ref_clk;

`ifdef FPGA
`ifdef SPARTAN3ANibuf_dly_adj
   IBUF_DLY_ADJ  (.O(out),
                              .I(in),
                              .S(s[2:0]));
`else
   //   assign out = in;
   
   IDELAYE2 #(
              .CINVCTRL_SEL("FALSE"),                           // Enable dynamic clock inversion (FALSE, TRUE)
              .DELAY_SRC("IDATAIN"),                            // Delay input (IDATAIN, DATAIN)
              .HIGH_PERFORMANCE_MODE("FALSE"),  // Reduced jitter ("TRUE"), Reduced power ("FALSE")
              .IDELAY_TYPE("FIXED"),                            // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
              .IDELAY_VALUE(FIXED_DELAY),                       // Input delay tap setting (0-31)
              .PIPE_SEL("FALSE"),                                       // Select pipelined mode, FALSE, TRUE
              .REFCLK_FREQUENCY(200.0),                 // IDELAYCTRL clock input frequency in MHz (190.0-210.0).
              .SIGNAL_PATTERN("DATA")                           // DATA, CLOCK input signal
              )
   IDELAYE2_inst (
                  .CNTVALUEOUT(),               // 5-bit output: Counter value output
                  .DATAOUT(out),                // 1-bit output: Delayed data output
                  .C(1'b0),                     // 1-bit input: Clock input
                  .CE(1'b0),                    // 1-bit input: Active high enable increment/decrement input
                  .CINVCTRL(1'b0),      // 1-bit input: Dynamic clock inversion input
                  .CNTVALUEIN(5'h0),    // 5-bit input: Counter value input
                  .DATAIN(1'b0),                // 1-bit input: Internal delay data input
                  .IDATAIN(in),         // 1-bit input: Data input from the I/O
                  .INC(1'b0),                   // 1-bit input: Increment / Decrement tap delay input
                  .LD(1'b0),                    // 1-bit input: Load IDELAY_VALUE input
                  .LDPIPEEN(1'b0),      // 1-bit input: Enable PIPELINE register to load data input
                  .REGRST(1'b0)         // 1-bit input: Active-high reset tap-delay input
                  );
   
   IDELAYCTRL
     IDELAYCTRL_inst (
                      .RDY(),
                      .REFCLK(ref_clk),
                      .RST(rst)
                      );
`endif
`else
   reg    s_0, s_1, s_2, s_3, s_4, s_5, s_6;

   wire   i0_0, i0_1, i0_2, i0_3, i0_4, i0_5, i0_6;
   wire   i1_0, i1_1, i1_2, i1_3, i1_4, i1_5, i1_6;
   wire   o_0;                  // From mux_0 of rpc2_ctrl_mux2to1.v
   wire   o_1;                  // From mux_1 of rpc2_ctrl_mux2to1.v
   wire   o_2;                  // From mux_2 of rpc2_ctrl_mux2to1.v
   wire   o_3;                  // From mux_3 of rpc2_ctrl_mux2to1.v
   wire   o_4;                  // From mux_4 of rpc2_ctrl_mux2to1.v
   wire   o_5;                  // From mux_5 of rpc2_ctrl_mux2to1.v
   wire   o_6;                  // From mux_6 of rpc2_ctrl_mux2to1.v

   assign out = o_0;
   assign i0_0 = in;
   assign i0_1 = in;
   assign i0_2 = in;
   assign i0_3 = in;
   assign i0_4 = in;
   assign i0_5 = in;
   assign i0_6 = in;
   assign i1_0 = o_1;
   assign i1_1 = o_2;
   assign i1_2 = o_3;
   assign i1_3 = o_4;
   assign i1_4 = o_5;
   assign i1_5 = o_6;
   assign i1_6 = 1'b0;
   
   always @(*) begin
      case (s[2:0] )
        3'b000: {s_6, s_5, s_4, s_3, s_2, s_1, s_0} = 7'b000_0000;
        3'b001: {s_6, s_5, s_4, s_3, s_2, s_1, s_0} = 7'b000_0001;
        3'b010: {s_6, s_5, s_4, s_3, s_2, s_1, s_0} = 7'b000_0011;
        3'b011: {s_6, s_5, s_4, s_3, s_2, s_1, s_0} = 7'b000_0111;
        3'b100: {s_6, s_5, s_4, s_3, s_2, s_1, s_0} = 7'b000_1111;
        3'b101: {s_6, s_5, s_4, s_3, s_2, s_1, s_0} = 7'b001_1111;
        3'b110: {s_6, s_5, s_4, s_3, s_2, s_1, s_0} = 7'b011_1111;
        3'b111: {s_6, s_5, s_4, s_3, s_2, s_1, s_0} = 7'b111_1111;
        default: {s_6, s_5, s_4, s_3, s_2, s_1, s_0} = 7'b000_0000;
      endcase
   end

   /* mux2to1 AUTO_TEMPLATE (
    .I0(i0_@),
    .I1(i1_@),
    .S(s_@),
    .O(o_@),
    );
    */
   xccela_ctrl_mux2to1 mux_0 (/*AUTOINST*/
                  // Outputs
                  .O                    (o_0),                   // Templated
                  // Inputs
                  .I0                   (i0_0),                  // Templated
                  .I1                   (i1_0),                  // Templated
                  .S                    (s_0));                  // Templated
   xccela_ctrl_mux2to1 mux_1 (/*AUTOINST*/
                  // Outputs
                  .O                    (o_1),                   // Templated
                  // Inputs
                  .I0                   (i0_1),                  // Templated
                  .I1                   (i1_1),                  // Templated
                  .S                    (s_1));                  // Templated
   xccela_ctrl_mux2to1 mux_2 (/*AUTOINST*/
                  // Outputs
                  .O                    (o_2),                   // Templated
                  // Inputs
                  .I0                   (i0_2),                  // Templated
                  .I1                   (i1_2),                  // Templated
                  .S                    (s_2));                  // Templated
   xccela_ctrl_mux2to1 mux_3 (/*AUTOINST*/
                  // Outputs
                  .O                    (o_3),                   // Templated
                  // Inputs
                  .I0                   (i0_3),                  // Templated
                  .I1                   (i1_3),                  // Templated
                  .S                    (s_3));                  // Templated
   xccela_ctrl_mux2to1 mux_4 (/*AUTOINST*/
                  // Outputs
                  .O                    (o_4),                   // Templated
                  // Inputs
                  .I0                   (i0_4),                  // Templated
                  .I1                   (i1_4),                  // Templated
                  .S                    (s_4));                  // Templated
   xccela_ctrl_mux2to1 mux_5 (/*AUTOINST*/
                  // Outputs
                  .O                    (o_5),                   // Templated
                  // Inputs
                  .I0                   (i0_5),                  // Templated
                  .I1                   (i1_5),                  // Templated
                  .S                    (s_5));                  // Templated
   xccela_ctrl_mux2to1 mux_6 (/*AUTOINST*/
                  // Outputs
                  .O                    (o_6),                   // Templated
                  // Inputs
                  .I0                   (i0_6),                  // Templated
                  .I1                   (i1_6),                  // Templated
                  .S                    (s_6));                  // Templated
`endif
endmodule // rpc2_ctrl_rds_delay_adjust

