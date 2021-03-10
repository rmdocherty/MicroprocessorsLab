#include <xc.inc>

global  ADC_Setup_X, ADC_Setup_Y, ADC_Read, Clear_X, Clear_Y    
 
    
PSECT	udata_acs

READX	    EQU 5
READY	    EQU	2
DRIVEA	    EQU	4
DRIVEB	    EQU	5	    
  
psect	adc_code,class=CODE

	    ; TRIS 0 output from board, TRIS 1 input from device
ADC_Setup_X:
	
	
	bsf	TRISF, READX, A
	bcf	TRISF, READY, A	    ; Set Tri-state of RF5, RF2 to high (input)
	bcf	TRISE, DRIVEB, A    ; Set Tri-state of RE4, RE5 to low (output)
	bcf	TRISE, DRIVEA, A
	
	;bcf	PORTF, READX, A	    ; Turn LEDs of RF4, RF5 off so they don't pull current
	bcf	PORTF, READY, A
	
	bsf	PORTE, DRIVEA, A    ; Set Drive A high (5V)
	bcf	PORTE, DRIVEB, A    ; Set Drive B low (0V)
	
	banksel ANCON1
;	banksel	ANCON0
	bsf	ANSEL10	    ; ANSEL10 - uses RF5 as I/O
;	bsf	ANSEL7	    ; ANSEL7 - uses RF2 as I/O
	movlb	0x00
;	movlw   0x29	    ; select configuration for ADC (channel select 10)
;	movlw	0x1D	    ; select configuration for ADC (channel select 7)
	movlw	0x00
	movwf   ADCON0, A   ; and turn ADC on
	movlw	00101001B
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x00	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Setup_Y:
	bsf	TRISF, READY, A	    ; Set Tri-state of RF5, RF2 to high (input)
	bcf	TRISF, READX, A
	bcf	TRISE, DRIVEB, A    ; Set Tri-state of RE4, RE5 to low (output)
	bcf	TRISE, DRIVEA, A
	
	bcf	PORTF, READX, A	    ; Turn LEDs of RF4, RF5 off so they don't pull current
	bcf	PORTF, READY, A
	
	bcf	PORTE, DRIVEA, A    ; Set Drive A low (0V)
	bsf	PORTE, DRIVEB, A    ; Set Drive B high (5V)
	
 
	banksel	ANCON0
;	banksel	ANCON1
;	bsf	ANSEL10	    ; ANSEL10 - uses RF5 as I/O
	bsf	ANSEL7	    ; ANSEL7 - uses RF2 as I/O
	movlb	0x00
    ;	movlw   0x29	    ; select configuration for ADC (channel select 10)
    	movlw	0x00
	movwf   ADCON0, A   ; and turn ADC on
	movlw	00011101B  ; select configuration for ADC (channel select 7)
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x00	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return
	
ADC_Read:
	bsf	GO	    ; Start conversion by setting GO bit in ADCON0
adc_loop:
	btfsc   GO	    ; check to see if finished
	bra	adc_loop
	return
Clear_X:		    ; Clear ANSEL10 bit after reading X (to allow a different channel to be selected)
	banksel	ANCON1
	bcf	ANSEL10	    ; ANSEL7 - uses RF2 as I/O
	movlb	0x00
	return
Clear_Y:		    ; Clear ANSEL7 bit after reading Y (to allow a different channel to be selected)
	banksel	ANCON0
	bcf	ANSEL7
	movlb	0x00
	return

end