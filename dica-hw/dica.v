
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
    dtable_idx,
    dtable_write
);

// EXTERNAL PARAMETERS: Overwritten by in by top module
parameter BLK_SIZE = 0;

// INTERNAL PARAMETERs
//============
parameter BLK_MSB  = $clog2(BLK_SIZE);    // MSB of block
parameter TOTAL_BLOCKS = `DMEM_SIZE >> BLK_MSB;
parameter [15:0] DMEM_MIN = `DMEM_BASE;
parameter [15:0] DMEM_MAX = `DMEM_BASE + `DMEM_SIZE - 1;

parameter MAX_COUNTER = 16; // THRESHOLD VALUE triggers the interrupt
parameter CTR_MSB = $clog2(MAX_COUNTER)+1;

parameter SP_LIM = DMEM_MAX-16'h800;

parameter V_MIN = 32'h100;

// OUTPUTs
//============
// ? Size of counter&ctr changes based on # of blocks
// output [5:0] counter;
output reg [(TOTAL_BLOCKS-1):0] D_Table;
output [15:0] dtable_idx;
output dtable_write;
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
reg [15:0] d;

reg [(CTR_MSB-1):0] ctr;
reg [(TOTAL_BLOCKS-1):0] sf_mask;

reg [31:0] V_thresh = 0;

initial
begin
    ctr <= 0;
    i <= 0;
    D_Table <= 0;
    sf_mask <= {(TOTAL_BLOCKS){1'b1}};
    sp_prev <= 0;
    trigger_checkpoint <= 0;
    V_thresh <= V_MIN;
end

reg [15:0] sp_prev;

parameter [15:0] id_sp_lim = (SP_LIM-`DMEM_BASE) >> BLK_MSB;

wire sp_in_DMEM = (sp >= DMEM_MIN) & (sp <= DMEM_MAX);
wire sp_prev_in_DMEM = (sp_prev >= DMEM_MIN) & (sp_prev <= DMEM_MAX);

wire [15:0] id_sp = ((sp-`DMEM_BASE) >> BLK_MSB) & {16{sp_in_DMEM}};
wire [15:0] id_sp_prev = ((sp_prev-`DMEM_BASE) >> BLK_MSB) & {16{sp_prev_in_DMEM}};

wire initial_val = (id_sp == 16'hfffe) | (id_sp_prev == 16'hfffe);

always @(posedge clk)
begin
    if(sp != sp_prev && sp != 16'h0)
    begin
        for(s=0; s<TOTAL_BLOCKS; s=s+1)
            sf_mask[s] <= ((s >= (id_sp-1)) | (s <= id_sp_lim));
        sp_prev <= sp;

        if((id_sp > id_sp_prev && ~initial_val) & ~D_Table[id_sp_prev])
            ctr <= ctr - (id_sp-id_sp_prev);
    end
end

wire debug_sf_mask = sf_mask[i];
wire debug_d_table = D_Table[i];

wire dmem_write = data_wr & (data_addr >= DMEM_MIN) & (data_addr <= DMEM_MAX);

assign dtable_write = dtable_write_reg;

reg dtable_write_reg = 1'b0;
always @(posedge clk)
begin

    if(reset_n)
    begin
        ctr=0;
        dtable_write_reg <= 1'b0;
        D_Table <= 0;
    end
    else if(dmem_write)
    begin
        i = (data_addr-`DMEM_BASE) >> BLK_MSB;
        // ctr = ctr + {{CTR_MSB-1{1'b0}},{((~D_Table[i]) & data_wr)}};
        if((~D_Table[i]) & data_wr)
        begin
            dtable_write_reg <= 1'b1;
            ctr <= ctr + 1;
            // V_thresh <= V_thresh + lambda;
        end
        else
            dtable_write_reg <= 1'b0;

        D_Table[i] <= (D_Table[i] | data_wr);
    end
    else
    begin
        D_Table[(TOTAL_BLOCKS-1):id_sp_lim] <= D_Table[(TOTAL_BLOCKS-1):id_sp_lim] & sf_mask[(TOTAL_BLOCKS-1):id_sp_lim];
        dtable_write_reg <= 1'b0;
    end

    // V_thresh <= 0;
    // for(d=0; d<TOTAL_BLOCKS; d=d+1)
    // begin
    //     if(D_Table[d] == 1'b1)
    //     begin
    //         ctr <= ctr + 1;
    //         V_thresh <= V_thresh + lambda;
    //     end
    // end
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
        V_thresh <= V_MIN;
    end
    else if((~D_Table[i]) & data_wr)
        V_thresh <= V_thresh + lambda;
end

assign dtable_idx = i;

assign irq_chkpnt = trigger_checkpoint;
// assign D_Table = tmp_table;
endmodule

// Interrupt non-maskable - DONE
// SW side - need to put interrupt program in vrased folder
// NOTE: Debug with vrased.lst in tmpbuild folder