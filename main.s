#include <pic18_chip_select.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
sendCp1:
        movlw   0x4                 ; Want to negate bit 2 of PORTD 
	xorwf   PORTD               ; XOR 0x4 w/ PORTD FR to negate 2nd bit and keep other bits the same (i.e EO states)
	call    delay
        movlw   0x4                 ; Want to negate bit 2 of PORTD 
	xorwf   PORTD               ; XOR 0x4 w/ PORTD FR to negate 2nd bit and keep other bits the same (i.e EO states)
	return
sendCp2:
        movlw   0x8                 ; Want to negate bit 3 of PORTD 
	xorwf   PORTD               ; XOR 0x8 w/ PORTD FR to negate 2nd bit and keep other bits the same (i.e EO states)
	call    delay               ; Should make delay 250ns if possible
        movlw   0x8                 ; Want to negate bit 3 of PORTD 
	xorwf   PORTD               ; XOR 0x8 w/ PORTD FR to negate 2nd bit and keep other bits the same (i.e EO states)
	return
read1:                          ; Toggle value at E01, i.e switch between read (0)/write (1)
        movlw   0xF                 ; We don't care about Cp1:2 and we want OE2 to be high (no collision!)
	movwf   PORTD               ; Reset PORTD before changing EO1 - this ensures EO1 and EO2 aren't low @ same time
        movlw   0xE                 ; All pins H except RD0 = EO1
	movwf   PORTD               ; Move this to PORTD
	call    readDelay
	movlw   0xF                 ; We don't care about Cp1:2 and we want OE2 to be high (no collision!)
	movwf   PORTD               ; Reset PORTD before changing EO1 - this ensures EO1 and EO2 aren't low @ same time
	return
read2:                          ; Toggle value at E01, i.e switch between read (0)/write (1)
        movlw   0xF                 ; We don't care about Cp1:2 and we want OE2 to be high (no collision!)
	movwf   PORTD               ; Reset PORTD before changing EO1 - this ensures EO1 and EO2 aren't low @ same time
        movlw   0xD                 ; All pins H except RD0 = EO1
	movwf   PORTD               ; Move this to PORTD
	call    readDelay
	movlw   0xF                 ; We don't care about Cp1:2 and we want OE2 to be high (no collision!)
	movwf   PORTD               ; Reset PORTD before changing EO1 - this ensures EO1 and EO2 aren't low @ same time
	return
delay:                              ; Delay by decrementing value @ 0x20 N times
        decfsz  0x20, A             ; Check if 0
	bra     delay               ; If not loop back
	movlw   0x10                ; Reset loop counter here
	movwf   0x20          
	return                      ; Jump back to execution
readDelay:
        decfsz  0x40, A             ; Check if 0
	bra     delay               ; If not loop back
	movlw   0x40                ; Reset loop counter here
	movwf   0x40          
	return                      ; Jump back to execution
setPullUps:
        setf    TRISE               ; Tri-state PORTE
	banksel PADCFG1             ; PADCFG1 not in access bank
	bsf     REPU                ; PORTE pull ups on
	movlb   0x00                ; BSR back to bank 0
	return
write1:
	clrf    TRISE               ; Port E all outputs
        ; call    switchEO1           ; Set E01 to write mode
        movff   0x30, LATE          ; Write the data we want (assumed to be saved @ 0x30) to LATE
	call    sendCp1             ; Send a clock pulse to mem 1 
	call    setPullUps              ; Set PORTE to Tristate again
	return
write2:
	clrf    TRISE               ; Port E all outputs
        ; call    switchEO1           ; Set E01 to write mode
        movff   0x30, LATE          ; Write the data we want (assumed to be saved @ 0x30) to LATE
	call    sendCp2             ; Send a clock pulse to mem 1 
	call    setPullUps              ; Set PORTE to Tristate again
	return
start:
	call    setPullUps          ; Set PORTE tristate; set Pullups
	clrf	TRISD   	    ; Port D all outputs
	movlw   0x0F                ; Move 0xF to W
        movwf   PORTD               ; Move value of 0x20 to PORTD - RD0-RD3 high
	movlw   0x10
 	movwf   0x20		    ; Move 0xFF to 0x20 - the delay timer = 250 ns
	movlw   0x01                ; Move 0x01 to W
	movwf   0x30                ; Move 0x01 to 0x30 - this is the data to be written to one byte of memory
	movlw   0x40                ; Move 0x01 to W
	movwf   0x40                ; Move 0x01 to 0x30 - this is the data to be written to one byte of memory
	call    write1
	
	; call    sendCp1
	; call    switchEO1
	end	main
