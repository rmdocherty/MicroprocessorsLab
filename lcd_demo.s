#include <xc.inc>
; Main program file - converted over from LCD branch. Include in main.s for setup or call as separate module.
extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Clear_Screen, LCD_Change_level
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
second_delay_count: ds 1 ; reserve one byte for counter in the nested delay routine
third_delay_count: ds 1
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data    
	; ******* myTable, data in programme memory, and its length *****
myTable:
	db	'H','e','l','l','o',' ','W','o','r','l','d','!',0x0a
					; message, plus carriage return
	myTable_l   EQU	13	; length of data
	align	2
 
	
psect	code, abs	
	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup UART
	goto	start
	
	; ******* Main programme ****************************************
start: 	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop		; keep going until finished
		
	movlw	myTable_l	; output message to UART
	lfsr	2, myArray
	call	UART_Transmit_Message

	movlw	myTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
	movlw   0xFF
	movwf   delay_count
	movlw   0xFF
	movwf   second_delay_count
	movlw   0xAA
	movwf   third_delay_count ; triple nested delay
	call    delay3
	call    LCD_Clear_Screen  ; clear the screen
	
	
	call    delay3
	movlw	0x1F
	movwf	0x20
	call	move_cursor
	
	movlw   0xFF
	movwf   delay_count
	movlw   0xFF
	movwf   second_delay_count
	movlw   0xAA
	movwf   third_delay_count ; triple nested delay
	call    delay3
	
	movlw	myTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
	goto	$		; goto current line in code

	; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return
delay2: 
        call    delay
	movlw   0xFF
	movwf   delay_count
        decfsz  second_delay_count, A
	bra     delay2
	movlw   0xFF
	movwf   second_delay_count
	return
delay3:
        call    delay2
	decfsz  third_delay_count, A
	bra     delay3
	movlw   0xFF
	movwf   third_delay_count
	return
move_cursor:
	call    LCD_Change_level
	decfsz  0x20
	bra     move_cursor
	movlw   0x28
	movwf   0x20
	return
	
	end	rst


