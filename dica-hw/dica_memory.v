//----------------------------------------------------------------------------
// Copyright (C) 2009 , Olivier Girard
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the authors nor the names of its contributors
//       may be used to endorse or promote products derived from this software
//       without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
// THE POSSIBILITY OF SUCH DAMAGE
//
//----------------------------------------------------------------------------
//
// *File Name: template_periph_16b.v
// 
// *Module Description:
//                       16 bit peripheral template.
//
// *Author(s):
//              - Olivier Girard,    olgirard@gmail.com
//
//----------------------------------------------------------------------------
// $Rev$
// $LastChangedBy$
// $LastChangedDate$
//----------------------------------------------------------------------------

module dica_memory(

// OUTPUTs
    per_dout,                       // Peripheral data output
    dica_reset,
    lambda,

// INPUTs
    mclk,                           // Main system clock
    per_addr,                       // Peripheral address
    per_din,                        // Peripheral data input
    per_en,                         // Peripheral enable (high active)
    per_we,                         // Peripheral write enable (high active)
    per_din_chkpnt,
    puc_rst                         // Main system reset
);

// OUTPUTs
//=========
output       [15:0] per_dout;       // Peripheral data output
output              dica_reset;     // reset D_Table through software
output       [30:0] lambda;         // write Lambda value through software

// INPUTs
//=========
input               mclk;           // Main system clock
input        [13:0] per_addr;       // Peripheral address
input        [15:0] per_din;        // Peripheral data input
input               per_en;         // Peripheral enable (high active)
input         [1:0] per_we;         // Peripheral write enable (high active)
input        [15:0] per_din_chkpnt;
input               puc_rst;        // Main system reset


//=============================================================================
// 1)  PARAMETER DECLARATION
//=============================================================================

// Register base address (must be aligned to decoder bit width)
parameter       [14:0] BASE_ADDR   = 15'h0190;

// Decoder bit width (defines how many bits are considered for address decoding)
parameter              DEC_WD      =  3;

// Register addresses offset
parameter [DEC_WD-1:0] DICA_CTL_UPPER = 'h0,
                       DICA_CTL_LOWER = 'h2;
                       //CNTRL3      = 'h4,
                       //CNTRL4      = 'h6;

// Register one-hot decoder utilities
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};

// Register one-hot decoder
parameter [DEC_SZ-1:0] CNTRL1_D    = (BASE_REG << DICA_CTL_UPPER),
                       CNTRL2_D    = (BASE_REG << DICA_CTL_LOWER);
                       //CNTRL3_D    = (BASE_REG << CNTRL3),
                       //CNTRL4_D    = (BASE_REG << CNTRL4);


//============================================================================
// 2)  REGISTER DECODER
//============================================================================

// Local register selection
wire              reg_sel   =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);

// Register local address
wire [DEC_WD-1:0] reg_addr  =  {per_addr[DEC_WD-2:0], 1'b0};

// Register address decode
wire [DEC_SZ-1:0] reg_dec   =  (CNTRL1_D  &  {DEC_SZ{(reg_addr == DICA_CTL_UPPER )}})  |
                               (CNTRL2_D  &  {DEC_SZ{(reg_addr == DICA_CTL_LOWER )}});//  |
                               //(CNTRL3_D  &  {DEC_SZ{(reg_addr == CNTRL3 )}})  |
                               //(CNTRL4_D  &  {DEC_SZ{(reg_addr == CNTRL4 )}});

// Read/Write probes
wire              reg_write =  |per_we & reg_sel;
wire              reg_read  = ~|per_we & reg_sel;

// Read/Write vectors
wire [DEC_SZ-1:0] reg_wr    = reg_dec & {DEC_SZ{reg_write}};
wire [DEC_SZ-1:0] reg_rd    = reg_dec & {DEC_SZ{reg_read}};


//============================================================================
// 3) REGISTERS
//============================================================================

// DICA_CTL_UPPER Register
//-----------------   
reg  [15:0] dica_ctl_upper;

wire        dica_ctl_upper_wr = reg_wr[DICA_CTL_UPPER];

always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        dica_ctl_upper <=  16'h0000;
  else if (dica_ctl_upper_wr) dica_ctl_upper <=  per_din_chkpnt;


  // DICA_CTL_LOWER Register
  //-----------------   
  reg  [15:0] dica_ctl_lower;

  wire        dica_ctl_lower_wr = reg_wr[DICA_CTL_LOWER];

  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)        dica_ctl_lower <=  16'h0000;
    else if (dica_ctl_lower_wr) dica_ctl_lower <=  per_din_chkpnt;


//============================================================================
// 4) DATA OUTPUT GENERATION
//============================================================================

// Data output mux
wire [15:0] dica_ctl_upper_rd  = dica_ctl_upper  & {16{reg_rd[DICA_CTL_UPPER]}};
wire [15:0] dica_ctl_lower_rd  = dica_ctl_lower & {16{reg_rd[DICA_CTL_UPPER]}};

wire [15:0] per_dout   =  dica_ctl_upper_rd |  //|
                          dica_ctl_lower_rd;//  |
                          // cntrl3_rd  |
                          // cntrl4_rd;

assign lambda = {dica_ctl_upper, dica_ctl_lower[14:1]};
assign dica_reset = dica_ctl_upper[0]; 


endmodule

