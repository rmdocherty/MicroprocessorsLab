#include <xc.inc>

global Keypad_master, Row_setup
extrn  GLCD_Clear_Screen, GLCD_Send_Screen
extrn  Toggle_Pen, Set_Brushsize
extrn  GLCD_delay_ms
extrn  update_display, sending_display, clearing_display

psect	udata_acs
Keypad_Row:	ds 1
Keypad_Col:	ds 1
Result:		ds 1
Skip:		ds 1
Tmp_result:	ds 1
    
psect	keypad_code,class=CODE
    
Row_setup:
	movlw	0x0F       ; Ports 0:3 inputs (0) and ports 4:7 (1) outputs
	movwf   TRISJ      ; Set this config to rise
	banksel PADCFG1	   ; PADCFG1 not in access bank
	bsf	RJPU       ; Set pull ups
	movlb	0x00	   ; Reset BSR 
	movlw	0x0F       ; Ports 0:3 inputs (0) and ports 4:7 (1) outputs
	movwf   PORTJ      ; Set this config to rise
	return

Read_row:
	movff	PORTJ, Keypad_Row; Store PORTJ state in 0x20
	return

Col_setup:
	movlw	0xF0       ; Ports 0:3 inputs (0) and ports 4:7 (1) outputs
	movwf   TRISJ      ; Set this config to rise
	banksel PADCFG1	   ; PADCFG1 not in access bank
	bsf	RJPU       ; Set pull ups
	movlb	0x00	   ; Reset BSR 
	movlw	0xF0       ; Ports 0:3 inputs (0) and ports 4:7 (1) outputs
	movwf   PORTJ      ; Set this config to rise	
	return

Read_col:
	movff	PORTJ, Keypad_Col; Store PORTJ state in 0x20
	return	

Decode:
	movf	Keypad_Col, 0, 0	   ; Move 0x30 to W - the state of PORTJ4:7
	xorwf	Keypad_Row, 0, 0	   ; Add 0x30 to 0x20, store result in 0x20 - combined state of PORTJ0:7
	movwf	Result, A
	
	movlw	0x00	   ; Binary code for no input
	cpfseq	Result, A ; If W equals the given bit pattern, skip next instruction
	goto	one;infsnz	Skip, A   ; Skip next instruction as skip register != 0 always
	retlw	0x00	   ; Return 0x00. Skipped if W != f

one:
	movlw	11101110B  ; Binary code for the 1 input
	cpfseq	Result, A
	goto	two ;infsnz	Skip, A
	movlw	0x01
	call	Set_Brushsize
	call	update_display	   ; Update brush size on display
	retlw	0x01

two:
	movlw	11101101B  ; Binary code for the 2 input
	cpfseq	Result, A
	goto	three ; infsnz	Skip, A
	movlw	0x02
	call	Set_Brushsize
	call	update_display	   ; Update brush size on display
	retlw	0x02

three:
	movlw	11101011B  ; Binary code for the 3 input
	cpfseq	Result, A
	goto	four;infsnz	Skip, A
	movlw	0x03
	call	Set_Brushsize
	call	update_display	   ; Update brush size on display
	retlw	0x03
	
four:
	movlw	11011110B  ; Binary code for the 4 input
	cpfseq	Result, A
	goto	five;infsnz	Skip, A
	movlw	0x04
	call	Set_Brushsize
	call	update_display	   ; Update brush size on display
	retlw	0x04

five:
	movlw	11011101B  ; Binary code for the 5 input
	cpfseq	Result, A
	goto	six ;infsnz	Skip, A
	movlw	0x05
	call	Set_Brushsize
	call	update_display	   ; Update brush size on display
	retlw	0x05	

six:
	movlw	11011011B  ; Binary code for the 6 input
	cpfseq	Result, A
	goto	seven;infsnz	Skip, A
	movlw	0x06
	call	Set_Brushsize
	call	update_display	   ; Update brush size on display
	retlw	0x06

seven:
	movlw	10111110B  ; Binary code for the 7 input
	cpfseq	Result, A
	goto	eight ;infsnz	Skip, A
	movlw	0x07
	call	Set_Brushsize
	call	update_display	   ; Update brush size on display
	retlw	0x07

eight:
	movlw	10111101B  ; Binary code for the 8 input
	cpfseq	Result, A
	goto	nine;infsnz	Skip, A
	movlw	0x08
	call	Set_Brushsize
	call	update_display	   ; Update brush size on display
	retlw	0x08

nine:
	movlw	10111011B  ; Binary code for the 9 input
	cpfseq	Result, A
	goto	zero;infsnz	Skip, A
	movlw	0x09
	call	Set_Brushsize
	call	update_display	   ; Update brush size on display
	retlw	0x09
	;retlw	'9'

zero:
	movlw	01111101B  ; Binary code for the 0 input
	cpfseq	Result, A
	goto	a_press;infsnz	Skip, A
	retlw	'0'

a_press:
	movlw	01111110B  ; Binary code for the A input
	cpfseq	Result, A
	goto	b_press;infsnz	Skip, A
	call	sending_display
	call	GLCD_Send_Screen
	;retlw	'A'
	
b_press:
	movlw	01111011B  ; Binary code for the B input
	cpfseq	Result, A
	goto	c_press    ;   infsnz	Skip, A
	retlw	'B'

c_press:
	movlw	01110111B  ; Binary code for the C input
	cpfseq	Result, A
	goto	d_press;infsnz	Skip, A
	call	GLCD_Clear_Screen
	call	clearing_display
	call	update_display
	;retlw	'C'

d_press:
	movlw	10110111B  ; Binary code for the D input
	cpfseq	Result, A
	goto	e_press;infsnz	Skip, A
	retlw	'D'

e_press:
	movlw	11010111B  ; Binary code for the E input
	cpfseq	Result, A
	goto	f_press;infsnz	Skip, A
	call	Toggle_Pen
	call	update_display	   ; Update brush size on display
	;retlw	'E'

f_press:
	movlw	11100111B  ; Binary code for the F input
	cpfseq	Result, A
	infsnz	Skip, A
	retlw	'F'

no_key_pressed:
	retlw	0xFF	    ; Else return error

Keypad_master:
	movlw	0x01	    ; Reset the skip variable
	movwf	Skip, A	    ; Move this to skip
	call	Row_setup   ; Setup rows by setting correct input/output rows
	movlw	1
	call	GLCD_delay_ms ; Delay to avoid double triggers
	call	Read_row    ; Read the value
	call	Col_setup   ; Setup cols by setting correct input/output rows
	movlw	1
	call	GLCD_delay_ms ; Delay to avoid double triggers
	call	Read_col    ; Read the value
	call	Decode	    ; Throw this bit pattern into decode which stores result in W
;	movwf	Tmp_result, A	   ; Store result in Tmp_result for now
;	call	update_display	   ; Update brush size on display
;	movf	Tmp_result, A	   ; Return result of decoding to W
	return