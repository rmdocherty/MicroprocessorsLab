#include <xc.inc>

global  LCD_Setup, LCD_Write_Message, LCD_Clear_screen, LCD_Change_level, LCD_Send_Byte_D, LCD_Write_Hex

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
LCD_tmp:	ds 1	; reserve 1 byte for temporary use
LCD_counter:	ds 1	; reserve 1 byte for counting through nessage

PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
LCD_hex_tmp:	ds 1    ; reserve 1 byte for variable LCD_hex_tmp

	LCD_CS1	EQU 0
	LCD_CS2	EQU 1
	LCD_RS	EQU 2	; LCD register select bit
	LCD_RW	EQU 3
	LCD_E	EQU 4	; LCD enable bit
    	

psect	lcd_code,class=CODE
    
LCD_Setup:
	setf    LATB, A
	movlw   00011011B	    ; RB0:5 all outputs
	movwf	TRISB, A		    ; WAS TRIB
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	
	clrf    LATD, A
	movlw   0x00	    ; RD0:7 all outputs
	movwf	TRISD, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	
	return

LCD_Write_Hex:			; Writes byte stored in W as hex
	movwf	LCD_hex_tmp, A
	swapf	LCD_hex_tmp, W, A	; high nibble first
	call	LCD_Hex_Nib
	movf	LCD_hex_tmp, W, A	; then low nibble
LCD_Hex_Nib:			; writes low nibble as hex character
	andlw	0x0F
	movwf	LCD_tmp, A
	movlw	0x0A
	cpfslt	LCD_tmp, A
	addlw	0x07		; number is greater than 9 
	addlw	0x26
	addwf	LCD_tmp, W, A
	call	LCD_Send_Byte_D ; write out ascii
	return	
	
LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter, A
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return
LCD_Clear_screen:
	movlw   0x01        ; From function table 0x01 is the clear screen
	call    LCD_Send_Byte_I  ; Send this byte to the instruction register
	return
LCD_Change_level:
	movlw   11100B
	call    LCD_Send_Byte_I  ; Send this byte to the instruction register
	return
LCD_Disable_Cursor:
	movlw   0x0C
	call    LCD_Send_Byte_I  ; Send this byte to the instruction register
	return
	
LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
	bcf	LATB, LCD_E, A	    ; Take enable high, was LCD_E
	call	NOP_delay
	bcf	LATB, LCD_RW, A	    ; Take enable high, was LCD_E
	
	bcf	LATB, LCD_CS1, A	    ; Take enable high, was LCD_E
	bcf	LATB, LCD_CS2, A	    ; Take enable high, was LCD_E
	bsf	LATB, LCD_RS, A	    ; Take enable high, was LCD_E
	movwf   LATD, A	    ; output data bits to LCD
	
	call	NOP_delay
	
	bsf	LATB, LCD_E, A	    ; Take enable high, was LCD_E
	
	call	NOP_delay

	bcf	LATB, LCD_E, A	    ; Take enable high, was LCD_E
	bsf	LATB, LCD_RW, A	    ; Take enable high, was LCD_E
	bsf	LATB, LCD_CS1, A	    ; Take enable high, was LCD_E
	bsf	LATB, LCD_CS2, A	    ; Take enable high, was LCD_E
	bcf	LATB, LCD_RS, A	    ; Take enable high, was LCD_E
	clrf	LATD, A	    ; output data bits to LCD
	
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
	bsf	LATB, LCD_E, A	    ; Take enable high, was LCD_E
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD, was LCD_E
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
NOP_delay:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	return

end