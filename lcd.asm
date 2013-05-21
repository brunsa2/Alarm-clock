; lcd.asm
; Jeff Stubler
; 10 November 2010
;
; Routines to initialise and interact with the LCD screen

.equ lcdBaudRate = 9600
.equ usartBaudValue = processorFrequency/(lcdBaudRate * 16) - 1

initialiseLcd:
	push immH
	push immL

	ldi immH, high(usartBaudValue)                 ; sets USART to use 9600 baud rate
	ldi immL, low(usartBaudValue)
	out UBRRH, immH
	out UBRRL, immL

	ldi immL, (1 << TXEN)                          ; enables transmitter but not receiver
	out UCSRB, immL

	ldi arg0l, 0x16                                ; turns off screen cursor
	rcall writeCharacterToLcd

	pop immL
	pop immH
	ret



; sendByteToUsart
; writeCharacterToLcd (alias)
; Sends one byte via the USART to the LCD
; r24 - Byte to transmit
; No returns

sendByteToUsart:
writeCharacterToLcd:
	sbis UCSRA, UDRE
	rjmp sendByteToUsart
	out UDR, arg0l
	ret



; clearLcd
; Clears LCD panel and turns off cursor
; No arguments
; No returns

clearLcd:
	push immL
	ldi arg0l, 0x0c                                ; clear screen
	rcall writeCharacterToLcd
	rcall delay
	ldi arg0l, 0x16                                ; turn on screen without cursor
	rcall writeCharacterToLcd
	pop immL
	ret



; nextLine
; Moves to next line on LCD panel
; No arguments
; No returns

nextLine:
	push immL
	ldi arg0l, 0x94                                ; move cursor to line 1 column 0
	rcall writeCharacterToLcd
	pop immL
	ret



; sendStringToUsart
; writeStringToLcd (alias)
; Sends a string from RAM to the LCD screen
; X - pointer to string start
; Y - pointer to string end
; No returns

sendStringToUsart:
writeStringToLcd:
	push XH
	push XL

sendStringLoop:
	ld arg0l, X+                                   ; load byte to send
	rcall sendByteToUsart                          ; send byte
	cp YL, XL                                      ; check to see if at end and loop back if not
	cpc YH, XH
	brge sendStringLoop

	pop XL
	pop XH
	ret



; sendFlasgStringToUsart
; writeFlashStringToLcd (alias)
; Sends a string from flash to the LCD screen
; X - pointer to string start (must be multiple of 2 bytes long)
; Y - pointer to string end (must be multiple of 2 bytes long)

sendFlashStringToUsart:
writeFlashStringToLcd:
	push XH
	push XL
	push ZH
	push ZL

	movw ZH:ZL, XH:XL                              ; flash load requires Z, not X, pointer

sendFlashStringLoop:
	lpm arg0l, Z+                                  ; load byte to send
	rcall sendByteToUsart                          ; send byte
	cp YL, ZL                                      ; check to see if at end and loop back if not
	cpc YH, ZH
	brge sendFlashStringLoop

	pop ZL
	pop ZH
	pop XL
	pop XH
	ret
