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

	bcf	TRISE, DRIVEB, A    ; Set Drive B to 0 (outputs)
	bcf	TRISF, READY, A	    ; Set Read-Y to 0  (outputs)
	
	bsf	TRISE, DRIVEA, A    ; disconnected (input?)
	bcf	PORTE, DRIVEA, A    ; disconnected
	
	bsf	PORTE, DRIVEB, A    ; Set Drive A high (5V)
	bcf	PORTF, READY, A	    ; Set Read-Y low (0V)
	
	bsf	TRISF, READX, A  ; pin RA0==AN0 input, set to as READY = RF5
	bsf	ANSEL0	    ; set AN0 to analog
	movlw   0x01	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x00	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Setup_Y:
	bcf	TRISE, DRIVEA, A    
	bcf	TRISF, READX, A
	
	bsf	TRISE, DRIVEB, A	; disconnected
	bcf	PORTE, DRIVEB, A
	
	bsf	PORTE, DRIVEA, A    ; Set Drive B high (5V)
	bcf	PORTF, READX, A	; Set Read-X low (0V)
 
	bsf	TRISF, READY, A ; pin RF2==AN0 input, set to as READY = RF2
	bsf	ANSEL0	    ; set AN0 to analog output
	movlw   0x01	    ; select AN0 for measurement
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


end