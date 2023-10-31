`define       FPGA

`timescale 1ns/1ps
`define Tilo  (0.62)
module xccela_ctrl_mux2to1 (/*AUTOARG*/
   // Outputs
   O,
   // Inputs
   I0, I1, S
   );
   input I0;
   input I1;
   output O;
   input  S;

`ifdef FPGA
   wire   O;
   MUXF5 muxf5 (.O(O),
                .S(S),
                .I0(I0),
                .I1(I1));
`else
   reg                  O;   
   always @(*) begin
      if (S)
        O = #(`Tilo)I1;
      else
        O = #(`Tilo)I0;
   end
`endif
endmodule // rpc2_ctrl_mux2to1

