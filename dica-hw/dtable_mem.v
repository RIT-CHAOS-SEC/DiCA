
module dtable_mem (

// OUTPUTs
	per_dout,                       // Peripheral data output

// INPUTs
    mclk,                           // Main system clock
    per_addr,                       // Peripheral address
    per_din,                        // Peripheral data input
    per_en,                         // Peripheral enable (high active)
    per_we,                         // Peripheral write enable (high active)
    puc_rst,                         // Main system reset
    //
    D_table_in
);


// PARAMETERs
//============ 
parameter [15:0] DMEM_MIN = `DMEM_BASE;
parameter [15:0] DMEM_MAX = `DMEM_BASE + `DMEM_SIZE - 1;

parameter BLK_SIZE = 128; // Memory size in bytes
parameter BLK_MSB  = $clog2(BLK_SIZE);    // MSB of block
parameter TOTAL_BLOCKS = `DMEM_SIZE >> BLK_MSB;
parameter 				MEM_SIZE   =  TOTAL_BLOCKS >> 3;       // Memory size in bytes
parameter 				ADDR_MSB   =  14;         // MSB of the address bus                                                          
parameter       [14:0] DTABLE_BASE_ADDR = 14'h0192;
parameter       [13:0] DTABLE_PER_ADDR  = DTABLE_BASE_ADDR[14:1];

// INPUTs
//============
// From MSP430
input              mclk;            // Main system clock
input       [13:0] per_addr;        // Peripheral address
input       [15:0] per_din;         // Peripheral data input
input              per_en;          // Peripheral enable (high active)
input        [1:0] per_we;          // Peripheral write enable (high active)
input              puc_rst;         // Main system reset
input       []

// OUTPUTs
//============
// To MSP430
output      [15:0] per_dout;       // RAM data output

// Detect if peripheral access is to Control-Flow Log
//------------------------------  
// software read
wire  [ADDR_MSB:0] dtable_addr_reg  =  {1'b0, 1'b0, per_addr-DTABLE_PER_ADDR};
wire               dtable_cen       = per_en & (per_addr >= DTABLE_PER_ADDR) & (per_addr < DTABLE_PER_ADDR+DTABLE_SIZE);
wire  [15:0]       dtable_dout;
wire  [15:0]       dtable_rd        = dtable_dout & {16{dtable_cen & ~|per_we}};
wire  [ADDR_MSB:0] read_addr = dtable_addr_reg;        		   // Read address


// Emulate RAM Block Memory 
//============
(* ram_style = "block" *) reg         [15:0] dtable_mem [0:DTABLE_SIZE-1]; 
reg         [ADDR_MSB:0] ram_addr_reg;

reg        [15:0] dtable_val;


// Emulate Memory Access
//============

integer i;
initial 
    begin
        for(i=0; i<MEM_SIZE; i=i+1)
        begin
            dtable_mem[i] <= 0;
        end
        ram_addr_reg <= 0;
        dtable_val <=  dtable_mem[0];
    end

always @(posedge mclk)
begin
    for(i=0; i<MEM_SIZE; i=i+8)
        dtable_mem <= D_table_in[(i+7):i];   
end

assign per_dout = dtable_mem[read_addr] & {16{dtable_cen}};
 
endmodule // cflogmem
