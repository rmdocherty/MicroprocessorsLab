#include <xc.inc>

global	Ugh
    
psect	udata_acs
a:	ds 1	; 8 bit number to multiply
b:	ds 2	; 16 bit number to multiply by
result:	ds 3	; 24 bit place to store result of a * b in
    
psect	mul_code,class=CODE
Ugh:
    movlw   0x0 
    
    
    return
