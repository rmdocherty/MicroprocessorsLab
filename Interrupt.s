#include <xc.inc>
	
global	Int_Setup, Int_Hi, delay_long, delay_mid, delay_short, delaySetup
    
psect	interrupt_code, class=CODE
    
delaySetup:
	movlw   0xFF                ; Setting up delay counters
	movwf   0x10, A             ; Moving 0xFF to all delay counters in access
	movlw   0xFF                
	movwf   0x20, A                
	movlw   0xFF		    
	movwf   0x30, A	
	
delay_long:			    ; Outermost delay loop (each loop = 510 * 510 * 510 cycles)
	call	delay_mid	    ; Call middle delay loop (each loop = 510 * 510 cycles)
        decfsz  0x10, A             ; Decrement counter at 0x10 (access)
	bra     delay_long          ; If not 0, loop again
	movlw   0xFF                ; Reset the loop counter to 0xFF
	movwf   0x10, A          
	return                      ; Jump back to execution	
	
delay_mid:			    ; Middle delay loop
	call    delay_short         ; Call third delay loop layer (each loop = 255 * 2 = 510 cycles)
        decfsz  0x20, A             ; Decrement counter at 0x20 (access)
	bra     delay_mid           ; If not 0, loop again
	movlw   0xFF                ; Reset the loop counter to 0xFF
	movwf   0x20, A          
	return                      ; Jump back to execution    
	
delay_short:				    ; Innermost delay loop
        decfsz  0x30, A             ; Decrement counter at 0x30 (access)
	bra     delay_short         ; If not 0, loop again
	movlw   0xFF                ; Reset the loop counter to 0xFF
	movwf   0x30, A          
	return                      ; Jump back to execution 
	
Int_Hi:				; Interrupt Service Routine (ISR)
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
;	incf	LATD, F, A	; increment PORTD - for DAC only
	clrf	PORTH, A	; Sample Interrupt routine - light up all PORTH
	movlw	0x00
	movwf	TRISH, A
	movlw	0xFF
	movwf	LATH, A
	bcf	TMR0IF		; clear interrupt flag
	retfie	f		; fast return from interrupt
	movlw	0x00		; Turn off all PORTH
	movwf	LATH		
	
Int_Setup:
;	clrf	TRISD, A	; Set PORTD as all outputs
;	clrf	LATD, A		; Clear PORTD outputs
	movlw	10000111B	; Set timer0 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts (Global Interrupt Enable)
	return
	
	end

