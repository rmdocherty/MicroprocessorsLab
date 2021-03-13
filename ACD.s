#include <xc.inc>

global  ADC_Setup_X, ADC_Setup_Y, ADC_Read, ADC_Init
extrn	GLCD_delay_ms
    
;PSECT	udata_acs
PSECT udata_acs_ovr,space=1,ovrld,class=COMRAM
READX	    EQU 5
READY	    EQU	2
DRIVEA	    EQU	4
DRIVEB	    EQU	5	    
  
psect	adc_code,class=CODE

	    ; TRIS 0 output from board, TRIS 1 input from device
	    
ADC_Init:
	bsf	TRISF, READX, A
	bsf	TRISF, READY, A	    ; Set Tri-state of RF5, RF2 to high (input)
	bcf	TRISE, DRIVEB, A    ; Set Tri-state of RE4, RE5 to low (output)
	bcf	TRISE, DRIVEA, A
	return
	
ADC_Setup_X:
	bsf	LATE, DRIVEA, A    ; Set Drive A high (5V)
	bcf	LATE, DRIVEB, A    ; Set Drive B low (0V)
	
	banksel ANCON1
	bsf	ANSEL10	    ; ANSEL10 - uses RF5 as I/O
	movlb	0x00
	movlw	0x00
	movwf   ADCON0, A   ; and turn ADC on
	movlw	00101001B
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x00	    ; Select 0V positive reference, otherwise x sensitivity truncated
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Setup_Y:
	bcf	LATE, DRIVEA, A    ; Set Drive A low (0V)
	bsf	LATE, DRIVEB, A    ; Set Drive B high (5V), use LATE as setting bits here much quicker

	banksel	ANCON0
	bsf	ANSEL7	    ; ANSEL7 - uses RF2 as I/O
	movlb	0x00

	movlw	00011101B  ; select configuration for ADC (channel select 7)
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x00	    ; Select 0V positive reference
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