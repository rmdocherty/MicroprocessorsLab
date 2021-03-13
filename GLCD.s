#include <xc.inc>

extrn	ADC_Setup_X, ADC_Setup_Y, ADC_Read
extrn	Scale_X, Scale_Y
global	GLCD_Setup, GLCD_Draw, GLCD_Write, GLCD_Test, GLCD_On, GLCD_Off, GLCD_Touchscreen
global	GLCD_delay_ms
    
psect	udata_acs   ; named variables in access ram
GLCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
GLCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
GLCD_cnt_2:	ds 1
GLCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
Col_index:	ds 1	; What col do we want to go to
Row_index:	ds 1
x:		ds 1	; x position we want to write to
x1:		ds 1
y:		ds 1	; y pos we want to write to 
y1:		ds 1
colour:		ds 1	; What colour do we want to draw
read_byte:	ds 1	; Variable to read data in from GLCD
write_byte:	ds 1	; Variable to write data to GLCD
temp_div:	ds 1	; Variable to store number divided by 8 in
temp_mod:	ds 1	; Variable to store mod in 
temp_pattern:	ds 1
shift_counter:	ds 1	; Variable to count # of shifts
Clear_cnt:	ds 1	; Variable to loop clear line over
Clear_cnt_2:	ds 1	; Variable to loop clear screen over
Page_width:	ds 1	;Variable to hold half screen width
temp_adresl:	ds 1
draw:		ds 1
 
  
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM

		; GLCD bit/pin mapping, used w/ bcf & bsf later
GLCD_CS1    EQU 0
GLCD_CS2    EQU 1
GLCD_RS	    EQU 2	; GLCD register select bit
GLCD_RW	    EQU 3	; GLCD R/W bit
GLCD_E	    EQU 4	; GLCD enable bit
GLCD_RST    EQU 5	; GLCD reset bit
COL_WIDTH   EQU 63
    	
;   Control on LATB, Data on PORTD, read in on TRISD
psect	glcd_code,class=CODE

GLCD_delay_1us:
	decfsz	GLCD_cnt_2
	bra	GLCD_delay_1us
	movlw	0x0F
	movwf	GLCD_cnt_2
	return
   
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
glcdlp2:	
	movlw	250	    ; 1 ms delay
	call	GLCD_delay_x4us	
	decfsz	GLCD_cnt_ms, A
	bra	glcdlp2
	return
    	
	
GLCD_Enable_Pulse:
	bsf	LATB, GLCD_E, A    ; Set enable bit high on PORTE (maybe should be LATE)?
	movlw	0x01		    ; 4 us delay (should be 5, maybe ok)
	call	GLCD_delay_x4us
	call	GLCD_delay_1us
	bcf	LATB, GLCD_E, A    ; Set enable bit low on PORTE
	movlw	0x01		    ; Another 4 us delay
	call	GLCD_delay_x4us	
	call	GLCD_delay_1us
	return
   
GLCD_On:			    ; Turn on display
	bcf	LATB, GLCD_CS1, A  
	bcf	LATB, GLCD_CS2, A
	bcf	LATB, GLCD_RS, A   ; RS being low means it's a command
	bcf	LATB, GLCD_RW, A   ; R/W low means write
	movlw	0x3F		    ; Hex for on command (last bit = D = 1)
	movwf	PORTD		    ; Move to data
	call	GLCD_Enable_Pulse	    ; Pulse
	return
	
GLCD_Off:			    ; Turn off display
	bcf	LATB, GLCD_CS1, A  
	bcf	LATB, GLCD_CS2, A
	bcf	LATB, GLCD_RS, A   ; RS being low means it's a command
	bcf	LATB, GLCD_RW, A   ; R/W low means write
	movlw	0x3E		    ; Hex for off command
	movwf	PORTD		    ; Move to data
	call	GLCD_Enable_Pulse	    ; Pulse
	return
	
GLCD_Set_Col:			    ; Given value in W go set that x value in GLCD
	movwf	Col_index	    ; Store WREG in Col_index
	bcf	LATB, GLCD_RS, A   ; RS being low means it's a command
	bcf	LATB, GLCD_RW, A   ; R/W low means write
	cpfsgt	Page_width, A	    ; if x > 63 goto RHS, else goto LHS 
	goto	RHS		    ; switch statement
	goto	LHS
LHS:
	bcf	LATB, GLCD_CS1, A  ; CS1 = 0, select chip 1
	bsf	LATB, GLCD_CS2, A  ; CS2 = 1, deselect chip 2
	goto	Set_Col_Finish
RHS:
	bsf	LATB, GLCD_CS1, A  ; CS1 = 1
	bcf	LATB, GLCD_CS2, A  ; CS2 = 0
	movlw	0x40
	subwf	Col_index, 1, 0	    ; Col_index - 64 stored to col_index
	goto	Set_Col_Finish
Set_Col_Finish:
	movlw	0x40
	iorwf	Col_index, 1, 0
	movlw	0x7F
	andwf	Col_index, 1, 0	    ; This puts the value in WREG of column into command format
	movff	Col_index, PORTD    ; Move this to data before pulse
	call	GLCD_Enable_Pulse
	return

GLCD_Set_Row:			    ; Given value in WREG set that y addr in GLCD
	movwf	Row_index
	
	bcf	LATB, GLCD_RS, A    ; RS being low means it's a command
	bcf	LATB, GLCD_RW, A    ; R/W low means write
	
	movlw	0xB8
	iorwf	Row_index, 1, 0
	movlw	0xBF
	andwf	Row_index, 1, 0	    ; This puts the value in WREG of column into command format
	movff	Row_index, PORTD    ; Move this to data before pulse
	call	GLCD_Enable_Pulse
	return
	
GLCD_Write:			    ; Write byte in WREG to GLCD
	bsf	LATB, GLCD_RS, A    ; RS being high means it's data
	bcf	LATB, GLCD_RW, A    ; R/W low means write
	movwf	PORTD		    ; put data on PORTD to write
	call	GLCD_delay_1us	    ; 4 NOP = 1 us delay
	call	GLCD_Enable_Pulse
	return

GLCD_Read:			    ; given column to read in WREG, read that data and store in read_byte
	setf	TRISD, A	    ; PORTD as input
	bsf	LATB, GLCD_RS, A    ; RS being high means it's data
	bsf	LATB, GLCD_RW, A    ; R/W high means read
	
	call	GLCD_delay_1us
	bsf	LATB, GLCD_E	    ; latch RAM data into output register - dummy read
	call	GLCD_delay_1us
	
	bcf	LATB, GLCD_E	    ; pulse the enable bit on portb
	movlw	0x01
	call	GLCD_delay	; should be 5 us
	call	GLCD_delay_1us
	bsf	LATB, GLCD_E	
	call	GLCD_delay_1us
	
	movff	PORTD, read_byte; data now stored in read_byte
	bcf	LATB, GLCD_E
	call	GLCD_delay_1us
	clrf	TRISD		; Set PORTD to be output again
	return

div_by_8:			; given number in WREG, integer divide it by 8 store result in temp_div
	movwf	temp_div
	rrncf	temp_div, 1, 0
	rrncf	temp_div, 1, 0
	rrncf	temp_div, 1, 0	; rrncf 3 times is same as dividnign by 8 in base 2
	return			; store result in temp_div

mod_8:
	movwf	temp_mod
	movlw	7		; x & 7 is same as taking mod 8 in binary
	andwf	temp_mod, 1, 0	; store result in temp mod!
	return

mod_to_pattern:			; Given value in mod_8, return byte with kth bit on
	movlw	0x01
	movwf	temp_pattern
pattern_loop:
	rlncf	temp_pattern	; rotate 0x01 left temp_mod times to go from 0xk -> 0k000000B
	decfsz	temp_mod
	goto	pattern_loop
	return
	
GLCD_Draw_Pixel:
	movf	x, 0, 1
	call	GLCD_Set_Col	
	movf	y, 0, 1	
	call	div_by_8	; Divide y by 8 and have result in temp_div
	movf	temp_div, 0, 1
	call	GLCD_Set_Row	
	
	call	GLCD_Read	; get the data out from x,y
	movf	read_byte, 0, 1	; move read byte into WREG
	movwf	write_byte	; move read byte into the byte to write - this is to avoid overwriting neighbouring pixels
	
	movf	x, 0, 1		; have to set where we're going to write to again!
	call	GLCD_Set_Col	
	movf	y, 0, 1	
	call	div_by_8	; Divide y by 8 and have result in temp_div
	movf	temp_div, 0, 1
	call	GLCD_Set_Row
	
	movf	y, 0, 1	
	call	mod_8		; calculate mod_8 of y
	
	call	mod_to_pattern	; convert mod y to binary number with kth bit on
	movwf	0x00		; check if colour is blue (0x00) or 'black'
	cpfseq	colour
	goto	Draw_blue
	goto	Draw_black
Draw_black:
	movf	temp_pattern, 0, 1
	iorwf	write_byte	; ior this binary number with the write byte to draw a pixel
	goto	Draw_finish
Draw_blue:
	comf	temp_pattern, 1, 1  ; to draw blue/empty pixel complement pattern
	movf	temp_pattern, 0, 1  
	andwf	write_byte	    ; andwf this pattern with the read bye (draw everything as usual except the pixel at the pattern location)
	goto	Draw_finish
Draw_finish:
	movf	write_byte, 0, 1
	call	GLCD_Write
	return

GLCD_Clear_Line:
	call	GLCD_Set_Row	    ; Go to row specified by WREG
	movlw	0x00		    ; Reset clear counter here before beginning
	movwf	Clear_cnt
Clear_loop:
	movlw	0x00		    ; Write blank data to LCD screen to clear
	call	GLCD_Write	    ; Don't need to increment col as X incremented when Write called
	incf	Clear_cnt, 1, 0	    ; Increment until we reach 0x40 = 64
	movlw	0x80		    ; 0x40 = 64 or 0x3F = 63?
	cpfseq	Clear_cnt	    ; Only skip when Clear_cnt = 0x40
	goto	Clear_loop
	return
	
GLCD_Clear_Screen:
	movlw	0x00		    ; Reset clear row counter
	movwf	Clear_cnt_2
Clear_screen_loop:
	movf	Clear_cnt_2, 0, 0   ; Move current value to WREG, this is the row supplied to Clear_Line
	call	GLCD_Clear_Line	    ; Clear given Line/row
	incf	Clear_cnt_2, 1, 0   ; Increment clear counter
	movlw	0x08		    ; 8 rows -> 8 times
	cpfseq	Clear_cnt_2	    ; Skip if eq to 8
	goto	Clear_screen_loop   ; If not loop
	return

GLCD_Set_Line:			    ; Given line addr in WREG start line threre
	bcf	LATB, GLCD_RS
	bcf	LATB, GLCD_RW
	bcf	LATB, GLCD_CS1
	bcf	LATB, GLCD_CS2
	movlw	0xC0		    ; Set line to 0, edit this later to use temp variale and any line addr
	movwf	PORTD
	call	GLCD_Enable_Pulse
	return
	
GLCD_Setup:
	clrf	TRISB		    ; Clear all these ports/tris before loop
	clrf	TRISD
	clrf	LATB
	clrf	PORTD
	bsf	LATB, GLCD_CS1	    ; Set the bits - don't care about cs rn
	bsf	LATB, GLCD_CS2
	bsf	LATB, GLCD_RST
	
	movlw	0x0F
	movwf	GLCD_cnt_2
	movlw	0x3F
	movwf	Page_width	    ; The 'width' of the page - 63, used for chip sel in set_col
	movlw	0x00
	movwf	draw
	
	call	GLCD_On		    ; Turn on the GLCD
	call	GLCD_Clear_Screen   ; Clear screen by writing 0's to everything
	return

GLCD_Draw:
	movlw	1		    ; These don't matter just for testing
	movwf	x
	movlw	2
	movwf	y
	movlw	0x01
	movwf	colour		    ; Draw in 'black'
	call	GLCD_Draw_Pixel	
	movlw	1000
	call	GLCD_delay_ms
	
	movlw	1		    ; These don't matter just for testing
	movwf	x
	movlw	5
	movwf	y
	movlw	0x00
	movwf	colour		    ; Draw in 'black'
	call	GLCD_Draw_Pixel	
	movlw	1000
	call	GLCD_delay_ms
	goto	GLCD_Draw   
	return
	
GLCD_Test:
	movlw	1
	call	GLCD_Set_Col
	movlw	0
	call	GLCD_Set_Row
	movlw	0xAA
	call	GLCD_Write
	movlw	1000
	call	GLCD_delay_ms
	return

Set_X:
	call	Scale_X
	movwf	x
	return
Set_Y:
	call	Scale_Y
	movwf	y
	movlw	0x01
	movwf	draw
	return
	
GLCD_Touchscreen:
	call	ADC_Setup_X
	movlw	1
	call	GLCD_delay_ms
	call	ADC_Read
	tstfsz	ADRESH
	call	Set_X

	call	ADC_Setup_Y
	movlw	1
	call	GLCD_delay_ms
	call	ADC_Read
	tstfsz	ADRESH
	call	Set_Y

	movlw	0x01
	movwf	colour		    ; Draw in 'black'
	movlw	0x00
	cpfseq	draw
	call	GLCD_Draw_Pixel
	movlw	0x00
	movwf	draw
	
	goto	GLCD_Touchscreen
	return