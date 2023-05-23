#include <stdio.h>
#include <stdint.h>
#include "hardware.h"

// --------------------- Main ------------------//

#define MEM_ADDR_1  0x2000
#define MEM_ADDR_2  0x3000
#define MEM_ADDR_3  0x4000
#define MEM_ADDR_4  0x5000

#define  DICA_CTL       (*(volatile unsigned long  *) 0x0190)

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

    // Test write to DICA_CTL (set lambda, cause reset)
    // DICA_CTL = [31 bits Lambda | 1 bit reset]
    // lambda = 10, reset = 0
    DICA_CTL = (10 << 1);

    uint8_t * mem = (uint8_t*)(MEM_ADDR_1);
    uint8_t * mem2 = (uint8_t*)(MEM_ADDR_2);
    uint8_t * mem3 = (uint8_t*)(MEM_ADDR_3);
    uint8_t * mem4 = (uint8_t*)(MEM_ADDR_4);

    mem[0] = calculate(0, 1, 2, 3);    
    for(int i=0; i<5; i++){
        mem2[i] = i;
    }
    mem3[0] = calculate(3, 0, 2, 1);
    for(int i=0; i<5; i++){
        mem4[i] = i;
    }
    return 0;
}

// CHECKPOINT ISR 
#pragma vector=CHECKPOINT_VECTOR
__interrupt void checkpoint(){
    P1OUT = 0xff;
    P1OUT = 0x00;
}