#include <stdio.h>
#include <stdint.h>
#include "hardware.h"

// --------------------- Main ------------------//


#define DMEM_MIN        0x200
#define DMEM_SIZE       0x2000
#define DMEM_BASE       DMEM_SIZE+DMEM_MIN
#define SP_LIM          DMEM_BASE - 0x800

#define DMEM_MAX        SP_LIM

#define BLOCK_SIZE      512
#define BLOCK_MSB       9 
#define TOTAL_BLOCKS    (DMEM_SIZE >> BLOCK_MSB)

#define DICA_CTL       (*(volatile unsigned long  *) 0x0190)
#define DICA_RST_ON    (unsigned long (0x80000000))
#define DICA_RST_OFF   (unsigned long (0x00000000))

#define DTABLE_BASE_ADDR    0x0194
#define DTABLE_SIZE         (TOTAL_BLOCKS >> 2) // Bytes = Total Blocks / 8, 16-bit Addresses = Bytes * 2 = Total Blocks / 4 = Total Blocks >> 2

#define P1_PULSE()          P1OUT = 0x00; P1OUT = 0xff; P1OUT = 0x00

char calculate(unsigned long a, unsigned long b, unsigned long c, unsigned long d){
    if (a < b){
        if(c > d){
            return 0;
        }
        else{
            return 1;
        }
    } else{
        if(c > d){
            return 2;
        }
        else{
            return 3;
        }
    }
}



int main(){
    P1OUT = 0x00;
    // Test write to DICA_CTL (set lambda, cause reset)
    // DICA_CTL = [31 bits Lambda | 1 bit reset]
    // lambda = 10, reset = 0
    volatile unsigned long lambda = 1;
    DICA_CTL = lambda;

    // DICA_CTL = 1;

    uint8_t * mem = (uint8_t*)(DMEM_MIN);

    mem[0] = calculate(0, 1, 2, 3);    
    // int iterations = 20;
    // int count = 0;

    // write to all blocks
    for(int i=1; i<DMEM_MAX-DMEM_MIN; i = i+(BLOCK_SIZE >> 2)){
        mem[i] = i;
    }

    return 0;
}

// CHECKPOINT ISR 
#pragma vector=CHECKPOINT_VECTOR
__interrupt void checkpoint(){

    // Save checkpoint
    // do_something()

    // "Print" (to P1) and clear DTABLE
    uint8_t * dtable = (uint8_t *)(DTABLE_BASE_ADDR);
    unsigned int i;
    P1_PULSE(); // show start
    for(i=0; i<DTABLE_SIZE; i++){
        P1OUT = dtable[i];
         dtable[i] = 0;
    }
    P1_PULSE(); // show end
}
