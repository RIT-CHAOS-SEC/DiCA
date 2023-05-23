
`include "openMSP430_defines.v"

module dica(
    //INPUTS
	clk,
	data_addr,
	data_wr,
	reset_n,
	pc,
    sp,
    lambda,
    V_supply,
    irq,
	//max_counter, ? Q: max counter as input or parameter?
		
	//OUTPUTS
	D_Table,
	irq_chkpnt,
);

// PARAMETERs
//============
parameter [15:0] DMEM_MIN = `DMEM_BASE;
parameter [15:0] DMEM_MAX = `DMEM_BASE + `DMEM_SIZE - 1;

parameter BLK_SIZE = 128; // Memory size in bytes
parameter BLK_MSB  = $clog2(BLK_SIZE);    // MSB of block
parameter TOTAL_BLOCKS = `DMEM_SIZE >> BLK_MSB;

parameter MAX_COUNTER = 16; // THRESHOLD VALUE triggers the interrupt
parameter CTR_MSB = $clog2(MAX_COUNTER)+1;

// OUTPUTs
//============
// ? Size of counter&ctr changes based on # of blocks
// output [5:0] counter;
output reg [(TOTAL_BLOCKS-1):0] D_Table;

output irq_chkpnt;

// INPUTs
//============

// ? [15:0]?
input [15:0] data_addr; // RAM address
input clk;  // RAM clock
input data_wr;  // RAM write enable (low active)
input reset_n;
input [15:0] pc;
input [15:0] sp;
input [30:0] lambda;
input [31:0] V_supply;
input irq;

reg [15:0] i;
reg [15:0] s;

reg [(CTR_MSB-1):0] ctr;
reg [(TOTAL_BLOCKS-1):0] sf_mask;
parameter SP_LIM = 16'h6000;

initial
begin
    ctr = 0;
    i = 0;
    // tmp_table = 0;
    D_Table = 0;
    sf_mask = 0;
    sp_prev = 0;
    trigger_checkpoint = 0;
end

reg [15:0] sp_prev;

wire [15:0] id_sp = (sp-`DMEM_BASE) >> BLK_MSB;
wire [15:0] id_sp_lim = (SP_LIM-`DMEM_BASE) >> BLK_MSB;

always @(posedge clk)
begin
    if(sp != sp_prev)
    begin
        for(s=0; s<TOTAL_BLOCKS; s=s+1)
            sf_mask[s] <= ((s >= id_sp) | (s <= id_sp_lim));
        sp_prev <= sp;
    end
end

wire debug_sf_mask = sf_mask[i];
wire debug_d_table = D_Table[i];

wire dmem_write = data_wr & (data_addr >= DMEM_MIN) & (data_addr <= DMEM_MAX);

wire [31:0] V_thresh = lambda*ctr;

always @(posedge clk)
begin

    if(reset_n)
    begin
        ctr=0;
        // tmp_table=0;
    end
    else if(dmem_write)
    begin
        i = (data_addr-`DMEM_BASE) >> BLK_MSB;
        // ctr = ctr + {{CTR_MSB-1{1'b0}},{((~D_Table[i]) & data_wr)}};
        if((~D_Table[i]) & data_wr)
            ctr <= ctr + 1;

        D_Table[i] <= (D_Table[i] | data_wr);
    end
    else
        D_Table <= D_Table & sf_mask;
end

reg trigger_checkpoint;
always @(posedge clk)
begin
    if (trigger_checkpoint & irq)
        trigger_checkpoint <= 1'b0;
    else if(V_supply <= V_thresh)
    begin    
        trigger_checkpoint <= 1'b1;
        ctr <= 0;
    end
end

assign irq_chkpnt = trigger_checkpoint;
// assign D_Table = tmp_table;
endmodule

// Interrupt non-maskable - DONE
// SW side - need to put interrupt program in vrased folder
// NOTE: Debug with vrased.lst in tmpbuild folder