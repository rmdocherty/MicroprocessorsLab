#include <pic18_chip_select.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100

SPI_MasterInit:
	bcf     CKE                 ; CKE bit in  SSP2STAT
	; MSSP enable, CKP=1, SPI_Master, clock=osc/64 (1MHz)
	movlw   (SSP2CON1_SSPEN_MASK)|(SSP2CON1_CKP_MASK)|(SSP2CON1_SSPM1_MASK)
	movwf   SSP2CON1, A
	bcf     TRISD, PORTD_SDO2_POSN, A  ; SD02 output
	bcf     TRISD, PORTD_SCK2_POSN, A  ; SCK2 output
	return
waitTransmit:
        btfss   SSP2IF              ; Check interrupt flag to see if data sent yet
	bra     waitTransmit	    ; Loop back if not
	bcf     SSP2IF		    ; Rest interrupt flag
	return
	
resetLEDS:                   ; Send a pulse (high->low->high) along MR to reset extrenal bit register
        movlw   0x0                 ; Want to flip bit 0 of PORTD off 
	movwf   PORTE               
	call    delay
        movlw   0x1                 ; Want to flip bit 0 of PORTD on
	movwf   PORTE               
	return
delay:                       ; Delay by decrementing value @ 0x20 N times
        decfsz  0x20, A             ; Check if 0
	bra     delay               ; If not loop back
	movlw   0xFF                ; Reset loop counter here
	movwf   0x20          
	return                      ; Jump back to execution	
delay2:			    ; Nested loop delay, calls previous delay method
	call    delay               ; Inner loop delay
        decfsz  0x30, A             ; Check if 0
	bra     delay2              ; If not loop back
	movlw   0xFF                ; Reset loop counter here
	movwf   0x30          
	return                      ; Jump back to execution    
delay3:			    ; Triple loop delay so pattersn visible
	call    delay2               ; Inner loop delay
        decfsz  0x40, A             ; Check if 0
	bra     delay3              ; If not loop back
	movlw   0xFF                ; Reset loop counter here
	movwf   0x40          
	return                      ; Jump back to execution  
start:
	movlw   0xFF                ; Short delay length
	movwf   0x20                ; Short delay memory addr
	movlw   0xFF                ; Delay 2 length
	movwf   0x30                ; Delay 2 memory addr
	movlw   0xFF		    ; Delay 3 length
	movlw   0x40		    ; Delay 3 memory addr
	
	movlw   0x0		    ; Port E all output
	movwf   TRISE, A
	movlw   0x1		    ; We want MR pin high at all times except when resetting
	movwf   PORTE
	call    SPI_MasterInit	    ; Initialise SPI
	
SPITest:		    ; NB The patterns are bit flipped - i.e dark = 1 light = 0
	movlw   0x44		    ; Pattern 1
	movwf   SSP2BUF, A	    ; Throw into SSP buffer
	call    waitTransmit	    ; Transmit to 174
	call    delay3		    ; Wait with 3 level cascaded delay
	
	call    resetLEDS	    ; Reset the pattern
	
	movlw   0x33		    ; Pattern 2
	movwf   SSP2BUF, A
	call    waitTransmit	
	call    delay3
	
	call    resetLEDS
	
	movlw   0xD9		    ; Pattern 3
	movwf   SSP2BUF, A
	call    waitTransmit	
	call    delay3
	
	end     main
