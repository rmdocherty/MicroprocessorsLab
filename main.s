#include <xc.inc>

extrn	GLCD_Setup, GLCD_Draw, GLCD_Write, GLCD_Test
    
psect	udata_acs
delay_count:	ds 1

psect	code, abs	


rst: 	org 0x0
	goto	main

main:
	call	GLCD_Setup
	call	GLCD_Test
	call	GLCD_Draw
	end	rst

