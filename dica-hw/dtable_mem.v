//----------------------------------------------------------------------------
// Copyright (C) 2001 Authors
//
// This source file may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// This source file is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
//
// This source is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
// License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this source; if not, write to the Free Software Foundation,
// Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
//
//----------------------------------------------------------------------------
// 
// *File Name: ram.v
// 
// *Module Description:
//                      Scalable RAM model
//
// *Author(s):
//              - Olivier Girard,    olgirard@gmail.com
//
//----------------------------------------------------------------------------
// $Rev$
// $LastChangedBy$
// $LastChangedDate$
//----------------------------------------------------------------------------

module dtable_mem (

// OUTPUTs
    per_dout,                      // RAM data output


// INPUTs
    dtable_write,
    dtable_idx,

    mclk,                           // Main system clock
    per_addr,                       // Peripheral address
    per_din,                        // Peripheral data input
    per_en,                         // Peripheral enable (high active)
    per_we,                         // Peripheral write enable (high active)
    puc_rst,                         // Main system reset
);

// PARAMETERs
//============ 
parameter BLK_SIZE = 256; // Memory size in bytes
parameter BLK_MSB  = $clog2(BLK_SIZE);    // MSB of block
parameter TOTAL_BLOCKS = `DMEM_SIZE >> BLK_MSB;

parameter MEM_SIZE   =  TOTAL_BLOCKS >> 3; // Memory size in bytes = TOTAL BLOCKS / 8 
parameter ADDR_MSB   =  $clog2(MEM_SIZE);         // MSB of the address bus
// ADDR_MSB = LOG_2(MEM_SIZE)-1

// OUTPUTs
//============
output      [15:0] per_dout;       // RAM data output

// INPUTs
//============
// DICA output
input     [15:0] dtable_idx;
input          dtable_write;
input                  mclk;
input       [13:0] per_addr;        // Peripheral address
input       [15:0] per_din;         // Peripheral data input
input              per_en;          // Peripheral enable (high active)
input        [1:0] per_we;          // Peripheral write enable (high active)
input              puc_rst;         // Main system reset

// software read
parameter       [14:0] DTABLE_BASE_ADDR = 14'h0194; //METADATA_BASE_ADDR+METADATA_SIZE;    // Spans 0x1a6-0x3a6
parameter       [13:0] DTABLE_PER_ADDR  = DTABLE_BASE_ADDR[14:1];

wire  [ADDR_MSB:0] dtable_addr  =  per_addr-DTABLE_PER_ADDR;
wire               dtable_cen   = ~(per_en & (per_addr >= DTABLE_PER_ADDR) & (per_addr < DTABLE_PER_ADDR+(MEM_SIZE/2))); // low active
wire  [ADDR_MSB:0] read_addr    = dtable_addr;                 // Read address
wire  [1:0]        dtable_wen   = ~(per_we & {2{per_en}});

// hardware write
wire  [ADDR_MSB:0] write_addr = dtable_idx >> 4;   // Write address
wire  [15:0] mask = 16'h000f;
wire  [15:0] write_idx = (mask & dtable_idx); // mask out all but lower 16 bits

// RAM 
//============

(* dtable_style = "block" *) reg         [15:0] dtable_mem [0:(MEM_SIZE/2)-1]; 

wire       [15:0] mem_val = dtable_mem[dtable_addr];

integer i;
initial 
    begin
        for(i=0; i<MEM_SIZE; i=i+1)
        begin
            dtable_mem[i] <= 0;
        end
    end
  
always @(posedge mclk)
    begin
        
        if (dtable_write & write_addr<MEM_SIZE/2)
        begin
            dtable_mem[write_addr][write_idx] <= 1'b1;
        end

        else if(~dtable_cen & dtable_addr<(MEM_SIZE/2))
        begin
            if      (dtable_wen==2'b00) dtable_mem[dtable_addr]        <= per_din;
            else if (dtable_wen==2'b01) dtable_mem[dtable_addr][15:8]  <= per_din[15:8];
            else if (dtable_wen==2'b10) dtable_mem[dtable_addr][7:0]   <= per_din[7:0];
        end
    end

assign per_dout = dtable_mem[read_addr] & {16{~dtable_cen}};
 
endmodule // logger