#include <xc.inc>

global	move_adres_X, Convert_X, move_adres_Y, Convert_Y

; Module to convert digital voltage measured by the ADC stored in ADRES to physical pixel coordinates
; x-range: 300-3300 --> each pixel = 25 ADRES units
; y-range: 500-3300 --> each pixel = 44 ADRES units
psect	udata_acs   ; named variables in access ram
x_counter:	ds 1	; Number of divisions by 25: x-coordinate
y_counter:	ds 1	; Number of divisions by 44: y-coordinate
;x_temp:		ds 1	; Storage for x-coordinate while counter resets
;y_temp:		ds 1	; Storage for y-coordinate while counter resets
x_voltage_h:	ds 1	; Cannot operate on SFR ADRES, need to move two 8-bit numbers (L,H)
x_voltage_l:	ds 1	; Move two numbers for each coordinate before doing integer division
y_voltage_h:	ds 1
y_voltage_l:	ds 1
inv_const:	ds 1	; Inversion constant - 64 for y
    
    
psect	glcd_code,class=CODE
    
; Subtraction - high 8-bit number incremented by 1, in order to have decfsz skip once lower 8-bit reaches 0
; i.e. (high) 0001 (low) 0003 would cause a skip (and coord save) with next subtract, but would now be (high) 0002 (low) 0003
; Need to subtract by an offset of 300 = 1 00101100 (x) and 500 = 1 11110100 (y)
; +1 -1 on high 8-bit number = no incf needed 
move_adres_X:		; Should be called before Convert_X
	movff   ADRESL, x_voltage_l	; Moving ADRES value to x_voltage (low,high)
	movff   ADRESH, x_voltage_h
	movlw	0x00
	movwf	x_counter, A		; Reset x-counter to zero
	movlw	00101100B
	subwf	x_voltage_l, F, A	; Subtract low byte of offest from xl
	btfss   STATUS, 0		; If subtracting the low offset causes carry, dec high byte
        decf	x_voltage_h, F, A	 
	decf	x_voltage_h, F, A	; Decf again to subtract 1 from high byte
	return
		
Convert_X:
	tstfsz	x_voltage_h		; Check if xh = 0, if it is skip and start dividing low byte only
	goto	x_divide_high		; If xh != 0 still need to subtract w/ carry
	goto	x_divide_low
	
x_divide_high:
	incf	x_counter, A		; Increment division counter
	movlw	0x19			; Move 25 (decimal) to W
        subwf	x_voltage_l, F, A	; Subtract 25 from low 8-bit 
        btfss   STATUS, 0		; Check if carry bit (bit 0 of STATUS) is 1, if not, skip next
        decfsz  x_voltage_h, F, A	; If carry = 1, decrement high 8-bit
	bra	Convert_X		; Loop again
x_divide_low:
	movlw	0x19
	cpfsgt	x_voltage_l		; skip if xl > scale factor
	goto	x_div_finish
	subwf	x_voltage_l, F, A	; Subtract 25 from low 8-bit 
	incf	x_counter, A		; Increment division counter
	goto	x_divide_low		; Loop
x_div_finish:
	movf	x_counter, W		; Move counter value to W as finished
	return

move_adres_Y:		; Should be called before Convert_Y
	movff   ADRESL, y_voltage_l	; Moving ADRES value to y_voltage (low,high)
	movff   ADRESH, y_voltage_h
	movlw	0x00
	movwf	y_counter, A		; Reset y-counter to zero
	movlw	0x40			; Moving 64 to inversion constant (for subtraction later)
	movwf	inv_const, A
	movlw	11110100B
	subwf	y_voltage_l, F, A
	btfss   STATUS, 0		; If subtracting the low offset causes carry, dec high byte
        decf	y_voltage_h, F, A	
	decf	y_voltage_h, F, A	; Decf again to subtract 1 from high byte
	return
		
Convert_Y:
	tstfsz	y_voltage_h
	goto	y_divide_high
	goto	y_divide_low
	
y_divide_high:
	incf	y_counter, A		; Increment division counter
	movlw	0x2C			; Move 25 (decimal) to W
        subwf	y_voltage_l, F, A	; Subtract 25 from low 8-bit 
        btfss   STATUS, 0		; Check if carry bit (bit 0 of STATUS) is 1, if not, skip next
        decfsz  y_voltage_h, F, A	; If carry = 1, decrement high 8-bit
	bra	Convert_Y		; Loop again
y_divide_low:
	movlw	0x2C
	cpfsgt	y_voltage_l		; skip if xl > scale factor
	goto	y_div_finish
	subwf	y_voltage_l, F, A	; Subtract 25 from low 8-bit 
	incf	y_counter, A		; Increment division counter
	goto	y_divide_low
y_div_finish:
	movf	y_counter, W		; Move counter value to W if high 8-bit is zero
	subwf	inv_const, W
	return
