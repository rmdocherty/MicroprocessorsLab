#include <xc.inc>

extrn	GLCD_Setup, GLCD_On, GLCD_Write, GLCD_Touchscreen, GLCD_Off
extrn	UART_Setup, GLCD_Send_Screen
extrn	ADC_Init
extrn	Keypad_master
extrn	update_display, sending_display, receiving_display
    
psect	udata_acs
delay_count:	ds 1

psect	code, abs	

main:
	call	GLCD_On
	call	GLCD_Setup
	call	ADC_Init
	call	UART_Setup
	call	update_display
	call	GLCD_Touchscreen
	;call	Keypad_master
	end	main

