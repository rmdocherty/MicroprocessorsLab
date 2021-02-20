#include <pic18_chip_select.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw 	0x0
	movwf	TRISD, A	    ; Port D all outputs
	movff   0x0F, PORTD
	end	main
