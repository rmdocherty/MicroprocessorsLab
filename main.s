	#include <xc.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw   0xFF                ; Move 0xFF to W
	movwf   0x20, A             ; Store 0xFF in FR 0x20
	movlw 	0x0 
	movwf	TRISC, A	    ; Port C all outputs
	bra 	test
delay:
        decfsz  0x20, A             ; Decrement literal at 0x20 until 0
	bra     delay               ; Loop if not 0
	return
loop:
	movff 	0x06, PORTC
	incf 	0x06, W, A
	call delay                  ; Call delay subroutine
test:
	movwf	0x06, A	            ; Test for end of loop condition
	movlw   0xFF                ; move FF to working register
	cpfsgt 	0x06, A
	bra 	loop		    ; Not yet finished goto start of loop again
	goto 	0x0		    ; Re-run program from start

	end	main
