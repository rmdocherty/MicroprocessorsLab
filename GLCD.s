#include <xc.inc>

global	GLCD_Setup
    
psect	udata_acs   ; named variables in access ram
GLCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
GLCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
GLCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
Col_index:	ds 1	; What col do we want to go to
Row_index:	ds 1
x:		ds 1	; x position we want to write to
y:		ds 1	; y pos we want to write to 
colour:		ds 1	; What colour do we want to draw
read_byte:	ds 1	; Variable to read data in from GLCD
write_byte:	ds 1	; Variable to write data to GLCD
temp_div:	ds 1	; Variable to store number divided by 8 in
temp_mod:	ds 1	; Variable to store mod in 
shift_counter:	ds 1	; Variable to count # of shifts
  
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM

		; GLCD bit/pin mapping, used w/ bcf & bsf later
GLCD_CS1    EQU 0
GLCD_CS2    EQU 1
GLCD_RS	    EQU 2	; GLCD register select bit
GLCD_RW	    EQU 3	; GLCD R/W bit
GLCD_E	    EQU 4	; GLCD enable bit
GLCD_RST    EQU 5	; GLCD reset bit
COL_WIDTH   EQU 64
    	
;   Control on PORTB, Data on PORTD, read in on TRISD
psect	glcd_code,class=CODE

GLCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	GLCD_cnt_l, A	    ; now need to multiply by 16
	swapf   GLCD_cnt_l, F, A    ; swap nibbles
	movlw	0x0f	    
	andwf	GLCD_cnt_l, W, A    ; move low nibble to W
	movwf	GLCD_cnt_h, A	    ; then to GLCD_cnt_h
	movlw	0xf0	    
	andwf	GLCD_cnt_l, F, A    ; keep high nibble in GLCD_cnt_l
	call	GLCD_delay
	return

GLCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
glcdlp1:	
	decf 	GLCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	GLCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	glcdlp1		; carry, then loop again
	return			; carry reset so return	

GLCD_delay_ms:		    ; delay given in ms in W
	movwf	GLCD_cnt_ms, A
glcdlp2:	movlw	250	    ; 1 ms delay
	call	GLCD_delay_x4us	
	decfsz	GLCD_cnt_ms, A
	bra	glcdlp2
	return
    	
	
GLCD_Enable_Pulse:
	bsf	PORTB, GLCD_E, A    ; Set enable bit high on PORTE (maybe should be LATE)?
	movlw	0x01		    ; 4 us delay (should be 5, maybe ok)
	call	GLCD_delay_x4us
	bcf	PORTB, GLCD_E, A    ; Set enable bit low on PORTE
	movlw	0x01		    ; Another 4 us delay
	call	GLCD_delay_x4us	
	return
   
GLCD_On:			    ; Turn on display
	bcf	PORTB, GLCD_CS1, A  
	bcf	PORTB, GLCD_CS2, A
	bcf	PORTB, GLCD_RS, A   ; RS being low means it's a command
	bcf	PORTB, GLCD_RW, A   ; R/W low means write
	movlw	0x3F		    ; Hex for on command
	movwf	PORTD		    ; Move to data
	call GLCD_Enable_Pulse	    ; Pulse
	return

GLCD_Set_Col:			    ; Given value in W go set that x value in GLCD
	movwf	Col_index	    ; Store WREG in Col_index
	bcf	PORTB, GLCD_RS, A   ; RS being low means it's a command
	bcf	PORTB, GLCD_RW, A   ; R/W low means write
	cpfsgt	COL_WIDTH, A	    ; if x > 64 goto RHS, else goto LHS
	goto	LHS		    ; switch statement
	goto	RHS
LHS:
	bcf	PORTB, GLCD_CS1, A  ; CS1 = 0, select chip 1
	bsf	PORTB, GLCD_CS2, A  ; CS2 = 1, deselect chip 2
	goto	Set_Col_Finish
RHS:
	bsf	PORTB, GLCD_CS1, A  ; CS1 = 1
	bcf	PORTB, GLCD_CS2, A  ; CS2 = 0
	movlw	64
	subwf	Col_index, 1, 0	    ; Col_index - 64 stored to col_index
	goto	Set_Col_Finish
Set_Col_Finish:
	movlw	0x40
	iorwf	Col_index, 1, 0
	movlw	0xBF
	andwf	Col_index, 1, 0	    ; This puts the value in WREG of column into command format
	call	GLCD_Enable_Pulse
	return

GLCD_Set_Row:			    ; Given value in WREG set that y addr in GLCD
	movwf	Row_index
	
	bcf	PORTB, GLCD_RS, A   ; RS being low means it's a command
	bcf	PORTB, GLCD_RW, A   ; R/W low means write
	
	movlw	0xB8
	iorwf	Row_index, 1, 0
	movlw	0xBF
	andwf	Row_index, 1, 0	    ; This puts the value in WREG of column into command format
	call	GLCD_Enable_Pulse
	return
	
GLCD_Write:			    ; Write byte in WREG to GLCD
	bsf	PORTB, GLCD_RS, A   ; RS being high means it's data
	bcf	PORTB, GLCD_RW, A   ; R/W low means write
	movwf	PORTD		    ; put data on PORTD to write
	movlw	0x01		    
	call	GLCD_delay_x4us	    ; 1 us delay
	call	GLCD_Enable_Pulse
	return

GLCD_Read:			    ; given column to read in WREG, read that data and store in read_byte
	setf	TRISD, A	    ; PORTD as input
	bsf	PORTB, GLCD_RS, A   ; RS being high means it's data
	bcf	PORTB, GLCD_RW, A   ; R/W high means read
	cpfsgt	COL_WIDTH, A	    ; if x > 64 skip
	goto	Read_CS1
	goto	Read_CS2
Read_CS1:
	bcf	PORTB, GLCD_CS1	    ; CS1 low to be read
	bsf	PORTB, GLCD_CS2	    ; CS2 high
	goto	Read_Finish
Read_CS2:
	bsf	PORTB, GLCD_CS1	    ; CS1 high
	bcf	PORTB, GLCD_CS2	    ; CS2 low to be read
	goto	Read_Finish
Read_Finish:
	movlw	0x01
	call	GLCD_delay	; should be 1 us not 4!
	bsf	PORTB, GLCD_E	; latch RAM data into output register
	movlw	0x01
	call	GLCD_delay	; should be 1 us not 4!
	
	bcf	PORTB, GLCD_E	; pulse the enable bit on portb
	movlw	0x01
	call	GLCD_delay	; should be 5 us
	bsf	PORTB, GLCD_E	
	movlw	0x01
	call	GLCD_delay	; should be 5 us
	
	movff	PORTD, read_byte; data now stored in read_byte
	bcf	PORTB, GLCD_E
	movlw	0x01
	call	GLCD_delay	; should be 1 us
	
	clrf	TRISD		; Set PORTD to be output again
	return

div_by_8:			; given number in WREG, integer divide it by 8 store result in temp_div
	movwf	temp_div
	rrncf	temp_div, 1, 0
	rrncf	temp_div, 1, 0
	rrncf	temp_div, 1, 0
	return

mod_8:
	movwf	0x7
	andwf	temp_mod, 1, 0
	return
	
GLCD_Draw_Pixel:
	movf	x
	call	GLCD_Set_Col	
	movf	y		
	call	div_by_8	; Divide y by 8 and have result in temp_div
	movf	temp_div
	call	GLCD_Set_Row
	movlw	0x00
	cpfseq	colour		; draw black pixel if colour != 0
	goto	Draw_Black
	goto	Draw_White
Draw_Black:
	movff	y, temp_div
	call	mod_8		; find y mod 8 and store in temp_mod
	movf	temp_mod	; temp mod now in W
	clrf	shift_counter	; clear temp mod
	bsf	shift_counter, temp_mod	; set the y%8 th bit on, rest off
	comf	shift_counter, 1, 0	; apply logical NOT
	movf	x		; move x to GLCD read as an argument
	call	GLCD_Read	; get the data out from x
	movf	read_byte
	andwf	shift_counter, 0, 0
	movwf	write_byte
	goto	Write_Finish
Draw_White:	
	movff	y, temp_div
	call	mod_8		; find y mod 8 and store in temp_mod
	movf	temp_mod	; temp mod now in W
	clrf	shift_counter	; clear temp mod
	bsf	shift_counter, temp_mod	; set the y%8 th bit on, rest off
	movf	x		; move x to GLCD read as an argument
	call	GLCD_Read	; get the data out from x
	movf	read_byte	; move value in read byte (set by GLCD_read) to W
	iorwf	shift_counter, 0, 0	; OR WREG w/ temp mod, stor result in W
	movwf	write_byte	; Move W to write_byte variable
	goto	Write_Finish
Write_Finish:
	movf	x
	call	GLCD_Set_Col	
	movf	y		
	call	div_by_8	; Divide y by 8 and have result in temp_div
	movf	temp_div
	call	GLCD_Set_Row
	movf	write_byte
	call	GLCD_Write
	return
	
GLCD_Setup:
	
	clrf	TRISB
	clrf	TRISD
	clrf	PORTB
	clrf	PORTD
	bsf	PORTB, GLCD_CS1
	bsf	PORTB, GLCD_CS2
	bsf	PORTB, GLCD_RST
	call	GLCD_On
	
	movlw	0
	movwf	x
	movlw	0
	movwf	y
	setf	colour
	call	GLCD_Draw_Pixel
	movlw	1000
	call	GLCD_delay_ms