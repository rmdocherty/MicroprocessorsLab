#include <xc.inc>

global  ADC_Setup_X, ADC_Setup_Y, ADC_Read    
 
psect	udata_acs
X_low:	    ds 1
X_high:	    ds 1
Y_low:	    ds 1
Y_high:	    ds 1
    
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM

BOTTOM	    EQU 5
LEFT	    EQU	2
TOP	    EQU	4
RIGHT	    EQU	5	    
  
psect	adc_code, class=CODE

	    
ADC_Setup_X:
	bcf	TRISE, RIGHT, A    ; Set Drive B to 0
	bcf	TRISF, LEFT, A	; Set Read-Y to 0
	
	bsf	TRISF, BOTTOM, A; pin RA0==AN0 input, set to as READY = RF5
	bsf	ANSEL0	    ; set AN0 to analog
	
	bsf	TRISE, TOP, A	; disconnected
	bcf	TRISE, TOP, A
	
	bsf	PORTE, RIGHT, A    ; Set Drive B high (5V)
	bcf	PORTF, LEFT, A	; Set Read-Y low (0V)
	
	;bsf	TRISF, BOTTOM, A  ; pin RF5==AN0 input, set to as READX = RF5
	
	movlw   0x01	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Setup_Y:
	
	bcf	TRISE, TOP, A    
	bcf	TRISF, BOTTOM, A	; Set Read-Y to 0
	
	bsf	TRISF, LEFT, A ; pin RF2==AN0 input, set to as READY = RF2
	bsf	ANSEL0	    ; set AN0 to analog output
	
	bsf	TRISE, RIGHT, A	; disconnected
	bcf	PORTE, RIGHT, A
	
	bsf	PORTE, TOP, A    ; Set Drive B high (5V)
	bcf	PORTF, BOTTOM, A	; Set Read-Y low (0V)
    
	
	movlw   0x01	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
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


end