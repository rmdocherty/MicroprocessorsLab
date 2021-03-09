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
;	clrf	TRISE		    
;	clrf	TRISF
	bcf	TRISE, DRIVEA, A    ; Set Tri-state of RE4, RE5 to low (output) - DRIVEA, DRIVEB
	bcf	TRISE, DRIVEB, A    
	
	bsf	PORTE, DRIVEA, A    ; Set Drive A (RE4) high (5V)
	bcf	PORTE, DRIVEB, A    ; Set Drive B (RE5) low (0V)
	
	bsf	TRISF, READY, A	    ; Set Tri-state of RF5, RF2 to high (input) - READX, READY
	bsf	TRISF, READX, A	    
	
	banksel	ANCON1	    ; Selecting ANCON1 - Analogue/Digital control register 1
	bsf	ANSEL10	    ; Select ANSEL10, activating channel 10 for measurement (= RF5 I/O)
	movlb	0x00	    ; Reset BSR
	movlw   00101001B   ; Set channel select bits (bits 2-6) - ch10, and enable ADC measurements (bit 0)  
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Setup_Y:
	;clrf	TRISE
	;clrf	TRISF
    
	bcf	TRISE, DRIVEA, A    ; Set Tri-state of RE4, RE5 to low (output) - DRIVEA, DRIVEB
	bcf	TRISE, DRIVEB, A

	bsf	PORTE, DRIVEB, A    ; Set Drive B (RE5) high (5V)
	bcf	PORTE, DRIVEA, A    ; Set Drive A (RE4) low (0V)
	
	bsf	TRISF, READX, A	    ; Set Tri-state of RF5, RF2 to high (input) - READX, READY
	bsf	TRISF, READY, A  
	
	banksel	ANCON0	    ; Selecting ANCON0 - Analogue/Digital control register 0
	bsf	ANSEL7	    ; Select ANSEL7, activating channel 7 for measurement (= RF2 I/O)
	movlb	0x00	    ; reset BSR
	movlw   0011101B    ; Set channel select bits (bits 2-6) - ch7, and enable ADC measurements (bit 0)     
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