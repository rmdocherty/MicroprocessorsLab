#include <xc.inc>

global  LCD_Setup, LCD_Write_Message, LCD_Clear_Screen, LCD_Shift, update_display, sending_display, receiving_display, clearing_display
extrn	UART_Setup, UART_Transmit_Message, W_Brushsize, W_Colour, colour  ; external subroutines

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through nessage
erase:		ds 1   ; Mode variable (default = 0)
draw:		ds 1   ; Draw variable (default = 1)

LCD_E	EQU 5	; LCD enable bit
LCD_RS	EQU 4	; LCD register select bit
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
second_delay_count: ds 1 ; reserve one byte for counter in the nested delay routine
third_delay_count: ds 1
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data	
    
psect	data    
	; ******* myTable, data in programme memory, and its length *****
brush_Table:
	db	'B','r','u','s','h',' ','S','i','z','e',':',0x0a
					; message, plus carriage return
	brush_Table_l   EQU	12	; length of data
	align	2
draw_Table:
	db	'D','r','a','w','i','n','g','.','.','.',0x0a
	draw_Table_l	EQU	11
	align	2
erase_Table:
	db	'E','r','a','s','i','n','g','.','.','.',0x0a
	erase_Table_l	EQU	11
	align	2	
sending_Table:
	db	'S','e','n','d','i','n','g',0x0a
	sending_Table_l	EQU	8
	align	2
receiving_Table:
	db	'R','e','c','e','i','v','i','n','g',0x0a
	receiving_Table_l	EQU	10
	align	2
UART_Table:
	db	'v','i','a',' ','U','A','R','T','.','.','.',0x0a
	UART_Table_l	EQU	12
	align	2
clear_Table:
	db	'C','l','e','a','r','i','n','g','.','.','.',0x0a
	clear_Table_l	EQU	12
	align	2
	
psect	lcd_code,class=CODE
    
LCD_Setup:
	clrf    LATH, A
	movlw   11000000B	    ; RB0:5 all outputs
	movwf	TRISH, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00001111B	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	movlw	00000110B	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	return
LCD_Clear_Screen:
	movlw   0x01        ; From function table 0x01 is the clear screen
	call    LCD_Send_Byte_I  ; Send this byte to the instruction register
	movlw	10		 ; 40us delay
	call	LCD_delay_x4us
	return
LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter, A
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return

LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATH, A	    ; output data bits to LCD
	bcf	LATH, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATH, A	    ; output data bits to LCD
	bcf	LATH, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return
LCD_Shift:		    ; Shifts LCD cursor, without shifting display (S/C low)
	movlw   00010100B
	call    LCD_Send_Byte_I  ; Send this byte to the instruction register
	return
LCD_Disable_Cursor:
	movlw   0x0C
	call    LCD_Send_Byte_I  ; Send this byte to the instruction register
	return
LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATH, A	    ; output data bits to LCD
	bsf	LATH, LCD_RS, A	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATH, A	    ; output data bits to LCD
	bsf	LATH, LCD_RS, A	; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATH, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATH, LCD_E, A	    ; Writes data to LCD
	return
    
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

	; ******* Programme FLASH read Setup Code ***********************
write_setup:	
	call	cursor_home
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup UART
	goto	b_write_start
	
	; ******* LCD Write subroutines ****************************************
b_write_start: 	; Write setup for row 1 - brush size display
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(brush_Table)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(brush_Table)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(brush_Table)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	brush_Table_l	; bytes to read
	movwf 	counter, A		; our counter register
	return

b_write_loop:	; Write loop for row 1 - brush size display
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	b_write_loop		; keep going until finished
		
	movlw	brush_Table_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message

	movlw	brush_Table_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
	return
	
c_write_start: 	; Write setup for row 1 - brush size display
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(clear_Table)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(clear_Table)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(clear_Table)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	clear_Table_l	; bytes to read
	movwf 	counter, A		; our counter register
	return

c_write_loop:	; Write loop for row 1 - brush size display
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	c_write_loop		; keep going until finished
		
	movlw	clear_Table_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message

	movlw	clear_Table_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
	return
	
d_write_start: 	; Write setup for row 2 - Status (Drawing...)
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(draw_Table)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(draw_Table)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(draw_Table)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	draw_Table_l	; bytes to read
	movwf 	counter, A		; our counter register
	return

d_write_loop:	; Write loop for row 2 - Status (Drawing...)
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	d_write_loop		; keep going until finished
		
	movlw	draw_Table_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message

	movlw	draw_Table_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
e_write_start: 	; Write setup for row 2 - Status (Erasing...)
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(erase_Table)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(erase_Table)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(erase_Table)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	erase_Table_l	; bytes to read
	movwf 	counter, A		; our counter register
	return

e_write_loop:	; Write loop for row 2 - Status (Drawing...)
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	e_write_loop		; keep going until finished
		
	movlw	erase_Table_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message

	movlw	erase_Table_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
s_write_start: 	; Write setup for UART transfer - row 1 
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(sending_Table)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(sending_Table)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(sending_Table)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	sending_Table_l	; bytes to read
	movwf 	counter, A		; our counter register
	return

s_write_loop:	; Write loop for UART transfer - row 1
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	s_write_loop		; keep going until finished
		
	movlw	sending_Table_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message

	movlw	sending_Table_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message	

r_write_start: 	; Write setup for UART transfer - row 1
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(receiving_Table)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(receiving_Table)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(receiving_Table)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	receiving_Table_l	; bytes to read
	movwf 	counter, A		; our counter register
	return

r_write_loop:	; Write loop for row 2 - Status (Drawing...)
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	r_write_loop		; keep going until finished
		
	movlw	receiving_Table_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message

	movlw	receiving_Table_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message

u_write_start: 	; Write setup for UART transfer - row 2 (via UART...)
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(UART_Table)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(UART_Table)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(UART_Table)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	UART_Table_l	; bytes to read
	movwf 	counter, A		; our counter register
	return

u_write_loop:	; Write loop for UART transfer - row 2 (via UART...)
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	u_write_loop		; keep going until finished
		
	movlw	UART_Table_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message

	movlw	UART_Table_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message	
	
delay_2s:   ; 2s delay
    	movlw   0xAA
	movwf   delay_count
	movlw   0xFF
	movwf   second_delay_count
	movlw   0xFF
	movwf   third_delay_count ; triple nested delay
	call    delay
	return
delay_1s:  ; 0.5s delay
    	movlw   0x42
	movwf   delay_count
	movlw   0xFF
	movwf   second_delay_count
	movlw   0xFF
	movwf   third_delay_count ; triple nested delay
	call    delay
	return
delay:	
	call	delay2
	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return
delay2: 
        call    delay3
        decfsz  second_delay_count, A
	bra     delay2
	movlw   0xFF
	movwf   second_delay_count
	return
delay3:
	decfsz  third_delay_count, A
	bra     delay3
	movlw   0xFF
	movwf   third_delay_count
	return	
	
move_cursor:	    ; Shifts cursor to right - moves to second row after 40th char of line 1
	call    LCD_Shift    ; Shift cursor right (w/o display shift) - executed a given number of times.
	decfsz  0x20
	bra     move_cursor
	return

change_row:	    ; Change row. Change address in DDRAM to 0x40 (second row)
	movlw	11000000B
	call	LCD_Send_Byte_I
	return
	
comparison_setup:	; Setup of comparison variables
    	movlw	0x00
	movwf	erase, A    ; 0 moved to erase
	movlw	0x01
	movwf	draw, A	    ; 1 moved to draw
	return
	
update_display:		; Update of display (call whenever brush size changed?)
	call	comparison_setup	; Setup of comparison variables for row 2
	call	write_setup		; Setup for LCD writing
	call	LCD_Clear_Screen
	movlw	0x01
	call	LCD_delay_x4us
	call	b_write_start
	call	b_write_loop
	
	movlw	0x01
	call	LCD_delay_x4us
	call	W_Brushsize
	addlw	0x30		    ; ASCII char conversion: 0x30 - 0x39 is 0-9
	call	LCD_Send_Byte_D
	
	movlw	0x04
	call	LCD_delay_x4us ; 16us delay
	call	change_row
	call	W_Colour    ; Move colour to W
	cpfseq	erase	    ; Erase mode display if colour = 0
	call	drawing
	call	W_Colour
	cpfseq	draw	    ; Draw mode display if colour = 1
	call	erasing
	return
	
drawing:    ; Displays 'Drawing...' on LCD
    	call	d_write_start
	call	d_write_loop
	movlw	0x01
	movwf	colour, A
	return
erasing:    ; Displays 'Erasing...' on LCD
    	call	e_write_start
	call	e_write_loop
	movlw	0x00
	movwf	colour, A
	return
clearing_display:	    ; Displays 'Clearing...' on LCD
	call	write_setup
	call	LCD_Clear_Screen
	movlw	0x1
	call	LCD_delay_x4us
	call	c_write_start
	call	c_write_loop
	call	delay_1s
	return
sending_display:		; Display when image is sent via UART
	call	write_setup
	call	LCD_Clear_Screen
	movlw	0x01
	call	LCD_delay_x4us
	call	s_write_start
	call	s_write_loop
	
	movlw	0x04
	call	LCD_delay_x4us ; 16us delay
	call	change_row
	call	u_write_start
	call	u_write_loop
	return
receiving_display:	    ; Display when image is received via UART
	call	write_setup
	call	LCD_Clear_Screen
	movlw	0x01
	call	LCD_delay_x4us
	call	r_write_start
	call	r_write_loop
	
	movlw	0x04
	call	LCD_delay_x4us ; 16us delay
	call	change_row
	call	u_write_start
	call	u_write_loop
	return
cursor_home:
	movlw	00000010B
	call	LCD_Send_Byte_I
	return
    end


