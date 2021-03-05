#include <xc.inc>

extrn	GLCD_Setup, GLCD_Draw, GLCD_Off, GLCD_On, Int_Hi, Int_Setup, delay_long
    
psect	udata_acs
delay_count:	ds 1

psect	code, abs	

rst: 	org	0x0
	goto	main

int_hi:
	org	0x0008
	goto	Int_Hi
	
main:
	call	Int_Setup
	call	GLCD_Setup
	call	GLCD_Draw
	call	delay_long
	call	GLCD_Off
	end	rst

