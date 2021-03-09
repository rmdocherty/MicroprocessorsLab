#include <xc.inc>

global  ADC_Setup_X, ADC_Setup_Y, ADC_Read    
 
    
PSECT	udata_acs

READX	    EQU 5
READY	    EQU	2
DRIVEA	    EQU	4
DRIVEB	    EQU	5	    
  
psect	adc_code,class=CODE

ADC_Setup_X:
	;clrf	TRISE
	;clrf	TRISF
    
	bcf	TRISE, DRIVEB, A    ; Set Drive B direction to 0 (outputs)
	bsf	TRISF, READY, A	    ; Set Read-Y direction to 1  (input/disconnected)
	
	bcf	TRISE, DRIVEA, A    ; Set Drive A direction to 0 (output)
	bsf	PORTE, DRIVEA, A    ; Set Drive A high (5V)
	
	bcf	PORTE, DRIVEB, A    ; Set Drive B low (0V)
	
	bsf	TRISF, READX, A	    ; pin RF5==AN10 output, set to as READX = RF5
	banksel	ANCON1		    ; ANCON1 not in acess bank
	bsf	ANSEL10		    ; RF5 = AN10 
	movlb	0x01		    ; reset BSR
	movlw   00101001B	    ; select AN10 for measurement - need to change this to select ANSEL10    
	movwf   ADCON0, A	    ; and turn ADC on
	movlw   0x30		    ; Select 4.096V positive reference
	movwf   ADCON1,	A	    ; 0V for -ve reference and -ve input
	movlw   0xF6		    ; Right justified output
	movwf   ADCON2, A	    ; Fosc/64 clock and acquisition times
	return

ADC_Setup_Y:
	;clrf	TRISE
	;clrf	TRISF
    
	bcf	TRISE, DRIVEA, A    ; Set Drive A direction to 0 (outputs)
	bsf	TRISF, READX, A	    ; Set Read-X direction to 1  (input/disconnected)
	
	bcf	TRISE, DRIVEB, A    ; Set Drive B direction to 0 (input)
	bsf	PORTE, DRIVEB, A    ; set Drive B high (5V)
	
	bcf	PORTE, DRIVEA, A    ; Set Drive A low (0V)
	
	bsf	TRISF, READY, A	    ; pin RF2==AN7 input, set to as READY = RF2
	banksel	ANCON0		    ; Set correct bank
	bsf	ANSEL7		    ; RF2 = AN7
	movlb	0x01		    ; reset BSR
	movlw   0011101B	    ; select AN7 for measurement    
	movwf   ADCON0, A	    ; and turn ADC on
	movlw   0x30		    ; Select 4.096V positive reference
	movwf   ADCON1,	A	    ; 0V for -ve reference and -ve input
	movlw   0xF6		    ; Right justified output
	movwf   ADCON2, A	    ; Fosc/64 clock and acquisition times
	return
	
ADC_Read:
	bsf	GO		    ; Start conversion by setting GO bit in ADCON0
adc_loop:
	btfsc   GO		    ; check to see if finished
	bra	adc_loop
	return


end