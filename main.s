#include <xc.inc>

extrn	GLCD_Setup, GLCD_Draw, GLCD_On, GLCD_Write, GLCD_Test, GLCD_Touchscreen, GLCD_Off
    
psect	udata_acs
delay_count:	ds 1

psect	code, abs	

main:
	call	GLCD_On
	call	GLCD_Setup
	;call	GLCD_Test
;	call	GLCD_Draw
	call	GLCD_Touchscreen
	call	GLCD_Off
	end	main

