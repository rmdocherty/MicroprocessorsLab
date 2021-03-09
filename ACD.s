#include <xc.inc>

global  ADC_Setup_X, ADC_Setup_Y, ADC_Read    
 
    
PSECT	udata_acs

READX	    EQU 5
READY	    EQU	2
DRIVEA	    EQU	4
DRIVEB	    EQU	5	    
  
psect	adc_code,class=CODE

	    ; TRIS 0 output from board, TRIS 1 input from device
ADC_Setup_X:
	clrf	TRISE
	clrf	TRISF
    
	bcf	TRISE, DRIVEB, A    ; Set Drive B to 0 (outputs)
	bsf	TRISF, READY, A	    ; Set Read-Y to 1  (outputs)
	
	bcf	TRISE, DRIVEA, A  
	bsf	PORTE, DRIVEA, A    ; et Drive A low (5V)
	
	bcf	PORTE, DRIVEB, A    ; Set Drive B low (0V)
	
	bsf	TRISF, READX, A  ; pin RF5==AN20 input, set to as READY = RF5
	banksel	ANCON1
	bsf	ANSEL10	    ; should be ANSELF10, also need to consider where ANSEL registers are in
	movlb	0x00	    ; reset BSR
	movlw   00101001B   ; select AN10 for measurement - need to change this to select ANSEL10    
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Setup_Y:
	;clrf	TRISE
	;clrf	TRISF
    
	bcf	TRISE, DRIVEA, A    ; Set Drive B to 0 (outputs)
	bsf	TRISF, READX, A	    ; Set Read-Y to 1  (outputs)
	
	
	bcf	TRISE, DRIVEB, A  
	bsf	PORTE, DRIVEB, A    ; et Drive A low (5V)
	
	bcf	PORTE, DRIVEA, A    ; Set Drive B low (0V)
	
	bsf	TRISF, READY, A  ; pin RF5==AN20 input, set to as READY = RF5
	banksel	ANCON0
	bsf	ANSEL7	    ; should be ANSELF10, also need to consider where ANSEL registers are in
	movlb	0x00	    ; reset BSR
	movlw   0011101B   ; select AN10 for measurement - need to change this to select ANSEL10    
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