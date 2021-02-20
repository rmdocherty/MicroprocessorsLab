#include <pic18_chip_select.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw 	0x0
	movwf	TRISD, A	    ; Port D all outputs
	movlw   0xFF                ; Move FF to W
	movwf   0x20, A             ; Move FF to 0x20 - # of loops
	bra     test                ; Jump to test
setlights:
        movff   0x20, PORTD         ; Move value of 0x20 to PORTD
	decf    0x20                ; Decrement the value in 0x20
test:
	cpfsgt  0x20, A             ; Check if 0 and if so skip 
	bra     setlights
	end	main
