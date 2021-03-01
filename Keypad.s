#include <xc.inc>

global Keypad_master
extrn  delay3, delay2, delay

psect	udata_acs
Keypad_Row:	ds 1
Keypad_Col:	ds 1
Result:		ds 1
Skip:		ds 1
    
psect	keypad_code,class=CODE
    
Row_setup:
	movlw	0x0F       ; Ports 0:3 inputs (0) and ports 4:7 (1) outputs
	movwf   TRISE      ; Set this config to rise
	banksel PADCFG1	   ; PADCFG1 not in access bank
	bsf	REPU       ; Set pull ups
	movlb	0x00	   ; Reset BSR 
	movlw	0x0F       ; Ports 0:3 inputs (0) and ports 4:7 (1) outputs
	movwf   PORTE      ; Set this config to rise
	return

Read_row:
	movff	PORTE, Keypad_Row; Store PORTE state in 0x20
	return

Col_setup:
	movlw	0xF0       ; Ports 0:3 inputs (0) and ports 4:7 (1) outputs
	movwf   TRISE      ; Set this config to rise
	banksel PADCFG1	   ; PADCFG1 not in access bank
	bsf	REPU       ; Set pull ups
	movlb	0x00	   ; Reset BSR 
	movlw	0xF0       ; Ports 0:3 inputs (0) and ports 4:7 (1) outputs
	movwf   PORTE      ; Set this config to rise	
	return

Read_col:
	movff	PORTE, Keypad_Col; Store PORTE state in 0x20
	return	

Decode:
	movf	Keypad_Col, 0, 0	   ; Move 0x30 to W - the state of PORTE4:7
	xorwf	Keypad_Row, 0, 0	   ; Add 0x30 to 0x20, store result in 0x20 - combined state of PORTE0:7
	movwf	Result, A
	
	movlw	0x00	   ; Binary code for no input
	cpfseq	Result, A ; If W equals the given bit pattern, skip next instruction
	infsnz	Skip, A   ; Skip next instruction as skip register != 0 always
	retlw	0x00	   ; Return 0x00. Skipped if W != f
	
	movlw	0x77  ; Binary code for the 1 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'1'

	movlw	10110111B  ; Binary code for the 2 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'2'
	
	movlw	11010111B  ; Binary code for the 3 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'3'

	movlw	01111011B  ; Binary code for the 4 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'4'	
	
	movlw	10111011B  ; Binary code for the 5 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'5'	
	
	movlw	11011011B  ; Binary code for the 6 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'6'

	movlw	01111101B  ; Binary code for the 7 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'7'
	
	movlw	10111101B  ; Binary code for the 8 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'8'

	movlw	11011101B  ; Binary code for the 9 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'9'
	
	movlw	10111110B  ; Binary code for the 0 input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'0'
	
	movlw	01111110B  ; Binary code for the A input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'A'
	
	movlw	11011110B  ; Binary code for the B input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'B'
	
	movlw	11101110B  ; Binary code for the C input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'C'

	movlw	11101101B  ; Binary code for the D input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'D'
	
	movlw	11101011B  ; Binary code for the E input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'E'

	movlw	11100111B  ; Binary code for the F input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'F'
	
	retlw	0xFF	    ; Else return error
Keypad_master:
	movlw	0x01	    ; Reset the skip variable
	movwf	Skip, A	    ; Move this to skip
	call	Row_setup   ; Setup rows by setting correct input/output rows
	call	delay3	    ; Delay to avoid double triggers
	call	Read_row    ; Read the value
	call	Col_setup   ; Setup cols by setting correct input/output rows
	call	delay3	    ; Delay to avoid double triggers
	call	Read_col    ; Read the value
	call	Decode	    ; Throw this bit pattern into decode which stores result in W
	
	return