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
//  Filename:   rpc2_ctrl_dpram_generator.v
//
//              DPRAM interface for RPC2 Memory Controller IP
//
// Created:     kshouji     01/16/2014  RPC2_Ctrl version 2.00
//                                      - initial release
// Modified:    kshouji     01/21/2014  RPC2_Ctrl version 2.01
//                                      - Reduced unnecessary logic
//              yise        10/29/2015  HyperBus Ctrl version 2.4
//                                      - Added AWR FIFO
//
// ***********************************************************************************************
module rpc2_ctrl_dpram_generator #(
    parameter FIFO_ADDR_BITS = 32'd3,
    parameter FIFO_DATA_WIDTH = 32'd16,
    parameter DPRAM_MACRO = 1'd0,      // 0=not used, 1=used macro
    parameter DPRAM_MACRO_SIZE = 4'd0, // 0=AW, 1=AR, 2=AWID, 3=ARID, 4=WID, 5=WDAT, 6=RDAT, 7=BDAT, 8=RX, 9=ADR
    parameter DPRAM_MACRO_TYPE = 1'd0  // 0=type-A(STD), 1=type-B(LowLeak)
)(
    // Outputs
    b_odata, 
    // Inputs
    clka, clkb, ceia_n, cejb_n, ia, jb, i_idata
);
    localparam  STD_CELL      = 1'd0;
    localparam  LOW_LEAK_CELL = 1'd1;
    localparam  AW_FIFO       = 4'd0;
    localparam  AR_FIFO       = 4'd1;
    localparam  AWID_FIFO     = 4'd2;
    localparam  ARID_FIFO     = 4'd3;
    localparam  WID_FIFO      = 4'd4;
    localparam  WDAT_FIFO     = 4'd5;
    localparam  RDAT_FIFO     = 4'd6;
    localparam  BDAT_FIFO     = 4'd7;
    localparam  RX_FIFO       = 4'd8;
    localparam  ADR_FIFO      = 4'd9;
    localparam  AWR_FIFO      = 4'd10;

    localparam  BUS_LOW       = {FIFO_DATA_WIDTH{1'b0}};
    localparam  SIG_LOW       = 1'b0;
    localparam  SIG_HIGH      = 1'b1;

    output  wire    [FIFO_DATA_WIDTH-1:0] b_odata;  // b port output data

    input   wire    clka;                           // a port clock
    input   wire    clkb;                           // b port clock
    input   wire    ceia_n;                         // a port chip enable signal
    input   wire    cejb_n;                         // b port chip enable signal
    input   wire    [FIFO_ADDR_BITS-1:0] ia;        // a port address
    input   wire    [FIFO_ADDR_BITS-1:0] jb;        // b port address
    input   wire    [FIFO_DATA_WIDTH-1:0] i_idata;  // a port input data

    generate
    if(DPRAM_MACRO == 0) begin
        if((DPRAM_MACRO_SIZE == WDAT_FIFO) || (DPRAM_MACRO_SIZE == RDAT_FIFO) || (DPRAM_MACRO_SIZE == RX_FIFO)) begin
            reg     [(FIFO_DATA_WIDTH/2)-1:0] mem_h[0:(1<<FIFO_ADDR_BITS)-1];
            reg     [(FIFO_DATA_WIDTH/2)-1:0] mem_l[0:(1<<FIFO_ADDR_BITS)-1];
            reg     [FIFO_DATA_WIDTH-1:0] int_b_odata; // b port output data

            assign b_odata = int_b_odata;

            always @(posedge clka) begin
                if (!ceia_n) begin
                    mem_h[ia] <= i_idata[FIFO_DATA_WIDTH-1:FIFO_DATA_WIDTH/2];
                    mem_l[ia] <= i_idata[(FIFO_DATA_WIDTH/2)-1:0];
                end // if !ceia_n
            end

            always @(posedge clkb) begin
                if (!cejb_n) begin
                    int_b_odata[FIFO_DATA_WIDTH-1:FIFO_DATA_WIDTH/2] <= mem_h[jb];
                    int_b_odata[(FIFO_DATA_WIDTH/2)-1:0]             <= mem_l[jb];
                end // if !cejb_n
            end
        end
        else begin
            reg     [FIFO_DATA_WIDTH-1:0] mem[0:(1<<FIFO_ADDR_BITS)-1];
//            reg     [FIFO_DATA_WIDTH-1:0] int_a_odata; // a port output data
            reg     [FIFO_DATA_WIDTH-1:0] int_b_odata; // b port output data

//            assign a_odata = int_a_odata;
            assign b_odata = int_b_odata;

            always @(posedge clka) begin
                if (!ceia_n) begin
//                    if(wei_n)   int_a_odata <= mem[ia];
//                    else        mem[ia] <= (~dmi & i_idata) | (dmi & mem[ia]);
                    mem[ia] <= i_idata;
                end // if !ceia_n
            end

            always @(posedge clkb) begin
                if (!cejb_n) begin
//                    if(wej_n)   int_b_odata <= mem[jb];
//                    else        mem[jb] <= (~dmj & j_idata) | (dmj & mem[jb]);
                    int_b_odata <= mem[jb];
                end // if !cejb_n
            end
        end
    end // if DPRAM_MACRO == 0
    else if(DPRAM_MACRO == 1) begin
        case(DPRAM_MACRO_TYPE)
        STD_CELL: begin
            case(DPRAM_MACRO_SIZE)
            AW_FIFO: begin
            /***************************************************************************/
            /* Please describe the instance (type-A) of AW_FIFO (44bit x 16word) here. */
            /***************************************************************************/
                end
            AR_FIFO: begin
            /***************************************************************************/
            /* Please describe the instance (type-A) of AR_FIFO (44bit x 16word) here. */
            /***************************************************************************/
                end
            AWID_FIFO: begin
            /********************************************************************************/
            /* Please describe the instance (type-A) of AWID_FIFO (ID width x 16word) here. */
            /********************************************************************************/
                end
            ARID_FIFO: begin
            /****************************************************************************************/
            /* Please describe the instance (type-A) of ARID_FIFO ((14bit+ID width) x 16word) here. */
            /****************************************************************************************/
                end
            WID_FIFO: begin
            /*******************************************************************************/
            /* Please describe the instance (type-A) of WID_FIFO (ID width x 16word) here. */
            /*******************************************************************************/
                end
            WDAT_FIFO: begin
            /******************************************************************************/
            /* Please describe the instance (type-A) of WDAT_FIFO (40bit x 128word) here. */
            /******************************************************************************/
                end
            RDAT_FIFO: begin
            /******************************************************************************/
            /* Please describe the instance (type-A) of RDAT_FIFO (40bit x 128word) here. */
            /******************************************************************************/
                end
            BDAT_FIFO: begin
            /****************************************************************************/
            /* Please describe the instance (type-A) of BDAT_FIFO (2bit x 16word) here. */
            /****************************************************************************/
                end
            RX_FIFO: begin
            /****************************************************************************/
            /* Please describe the instance (type-A) of RX_FIFO (20bit x 256word) here. */
            /****************************************************************************/
                end
            ADR_FIFO: begin
            /****************************************************************************/
            /* Please describe the instance (type-A) of RX_FIFO (46bit x 16word) here. */
            /****************************************************************************/
                end
            AWR_FIFO: begin
            /****************************************************************************/
            /* Please describe the instance (type-A) of AWR_FIFO (45bit x 16word) here. */
            /****************************************************************************/
                end
            default: ;
            endcase // case DPRAM_MACRO_SIZE
        end
        LOW_LEAK_CELL: begin
            case(DPRAM_MACRO_SIZE)
            AW_FIFO: begin
            /***************************************************************************/
            /* Please describe the instance (type-B) of AW_FIFO (44bit x 16word) here. */
            /***************************************************************************/
                end
            AR_FIFO: begin
            /***************************************************************************/
            /* Please describe the instance (type-B) of AR_FIFO (44bit x 16word) here. */
            /***************************************************************************/
                end
            AWID_FIFO: begin
            /********************************************************************************/
            /* Please describe the instance (type-B) of AWID_FIFO (ID width x 16word) here. */
            /********************************************************************************/
                end
            ARID_FIFO: begin
            /****************************************************************************************/
            /* Please describe the instance (type-B) of ARID_FIFO ((14bit+ID width) x 16word) here. */
            /****************************************************************************************/
                end
            WID_FIFO: begin
            /*******************************************************************************/
            /* Please describe the instance (type-B) of WID_FIFO (ID width x 16word) here. */
            /*******************************************************************************/
                end
            WDAT_FIFO: begin
            /******************************************************************************/
            /* Please describe the instance (type-B) of WDAT_FIFO (40bit x 128word) here. */
            /******************************************************************************/
                end
            RDAT_FIFO: begin
            /******************************************************************************/
            /* Please describe the instance (type-B) of RDAT_FIFO (40bit x 128word) here. */
            /******************************************************************************/
                end
            BDAT_FIFO: begin
            /****************************************************************************/
            /* Please describe the instance (type-B) of BDAT_FIFO (2bit x 16word) here. */
            /****************************************************************************/
                end
            RX_FIFO: begin
            /****************************************************************************/
            /* Please describe the instance (type-B) of RX_FIFO (20bit x 256word) here. */
            /****************************************************************************/
                end
            ADR_FIFO: begin
            /****************************************************************************/
            /* Please describe the instance (type-B) of RX_FIFO (46bit x 16word) here. */
            /****************************************************************************/
                end
            AWR_FIFO: begin
            /****************************************************************************/
            /* Please describe the instance (type-B) of AWR_FIFO (45bit x 16word) here. */
            /****************************************************************************/
                end
            default: ;
            endcase // case DPRAM_MACRO_SIZE
        end
        default: ;
        endcase // case DPRAM_MACRO_TYPE
    end // else if DPRAM_MACRO == 1
    endgenerate
endmodule // rpc2_ctrl_dpram_generator
