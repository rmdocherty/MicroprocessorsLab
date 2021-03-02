#include <xc.inc>

extrn	GLCD_Setup, GLCD_Draw
    
psect	udata_acs
delay_count:	ds 1

psect	code, abs	


rst: 	org 0x0
	goto	main

main:
	call	GLCD_Setup
	call	GLCD_Draw
	end	rst

