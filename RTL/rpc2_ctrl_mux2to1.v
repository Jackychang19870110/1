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
// ***********************************************************************************************
//
//      Filename:       rpc2_ctrl_mux2to1.v
//
//                              Sample I/O block for Trinity Memory Controller IP using SPARTAN-3 library
//
//      Created:        yise            03/21/2013      Trinity_Ctrl version 1.00
//                                                                              - initial release
//
//      Modified:       
//                                                                              
//
// ***********************************************************************************************

`timescale 1ns/1ps
`define Tilo  (0.62)
module rpc2_ctrl_mux2to1 (/*AUTOARG*/
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

