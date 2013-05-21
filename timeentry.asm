; timeentry.asm
; Jeff Stubler
; 10 November 2010
;
; Routine to get time input from user

.def hourIn = r3
.def minuteIn = r2

; inputTime
; Gets time from user
; No arguments
; r3 - hours entered by user
; r2 - minutes entered by user

inputTime:
	push XH
	push XL
	push YH
	push YL
	push arg0h
	push arg0l
	push arg1h
	push arg1l

	rcall clearLcd                                 ; clear LCD and prompt for time
	ldi XH, high(enterTimeMessage << 1)
	ldi XL, low(enterTimeMessage << 1)
	ldi YH, high(enterTimeMessageEnd << 1)
	ldi YL, low(enterTimeMessageEnd << 1)
	rcall writeFlashStringToLcd
	rcall nextLine
	rjmp getFirstNumber

errorEntry:                                      ; give error message and reprompt
	rcall clearLcd
	ldi XH, high(errorMessage << 1)
	ldi XL, low(errorMessage << 1)
	ldi YH, high(errorMessageEnd << 1)
	ldi YL, low(errorMessageEnd << 1)
	rcall writeFlashStringToLcd
	rcall nextLine

getFirstNumber:                                  ; get first number and store it in high nibble
	rcall getCharacter
	cpi arg0l, 4
	breq getFirstNumber
	cpi arg0l, 8
	breq getFirstNumber
	cpi arg0l, 12
	breq getFirstNumber
	cpi arg0l, 13
	breq getFirstNumber
	cpi arg0l, 15
	breq getFirstNumber
	cpi arg0l, 16
	breq finishJump
	rcall getNumberFromScanCode
	mov arg0h, arg0l
	swap arg0h
	mov hourIn, arg0h
	ldi immL, 0x30
	add arg0l, immL
	call writeCharacterToLcd

getSecondNumber:                                 ; get second number and store in low nibble
	rcall getCharacter
	cpi arg0l, 4
	breq getSecondNumber
	cpi arg0l, 8
	breq getSecondNumber
	cpi arg0l, 12
	breq getSecondNumber
	cpi arg0l, 13
	breq getSecondNumber
	cpi arg0l, 15
	breq getSecondNumber
	cpi arg0l, 16
	breq finish
	rcall getNumberFromScanCode
	add hourIn, arg0l
	ldi immL, 0x30
	add arg0l, immL
	call writeCharacterToLcd
	rjmp showColon

finishJump:                                      ; relative branch jump relay from earlier
	rjmp finish

showColon:                                       ; show colon after hours if valid number, else
	mov arg0l, hourIn                               ; start over with error prompt
	cpi arg0l, 0x24
	brsh errorEntry

	ldi arg0l, ':'
	call writeCharacterToLcd

getThirdNumber:                                  ; get third number and store in high nibble
	rcall getCharacter
	cpi arg0l, 4
	breq getThirdNumber
	cpi arg0l, 8
	breq getThirdNumber
	cpi arg0l, 12
	breq getThirdNumber
	cpi arg0l, 13
	breq getThirdNumber
	cpi arg0l, 15
	breq getThirdNumber
	cpi arg0l, 16
	breq finish
	rcall getNumberFromScanCode
	mov arg0h, arg0l
	swap arg0h
	mov minuteIn, arg0h
	ldi immL, 0x30
	add arg0l, immL
	call writeCharacterToLcd

getFourthNumber:                                 ; get fourth number and store in low nibble
	rcall getCharacter
	cpi arg0l, 4
	breq getFourthNumber
	cpi arg0l, 8
	breq getFourthNumber
	cpi arg0l, 12
	breq getFourthNumber
	cpi arg0l, 13
	breq getFourthNumber
	cpi arg0l, 15
	breq getFourthNumber
	cpi arg0l, 16
	breq finish
	rcall getNumberFromScanCode
	add minuteIn, arg0l
	ldi immL, 0x30
	add arg0l, immL
	call writeCharacterToLcd

	mov arg0l, minuteIn                            ; check for validity; if good, wait for key and
	cpi arg0l, 0x60                                ; return, else reprompt with error message
	brsh toErrorEntry

	rcall getCharacter


finish:
	pop arg1l
	pop arg1h
	pop arg0l
	pop arg0h
	pop YL
	pop YH
	pop XL
	pop XH
	ret

toErrorEntry:                                    ; relative branch relay
	rjmp errorEntry



; getNumberFromScanCode
; Translates scan code into decimal number
; r24 - scan code
; r24 - BCD of scan code

getNumberFromScanCode:
	cpi arg0l, 1
	brne key2
	ldi arg0l, 1
	ret
key2:
	cpi arg0l, 2
	brne key3
	ldi arg0l, 2
	ret
key3:
	cpi arg0l, 3
	brne key4
	ldi arg0l, 3
	ret
key4:
	cpi arg0l, 5
	brne key5
	ldi arg0l, 4
	ret
key5:
	cpi arg0l, 6
	brne key6
	ldi arg0l, 5
	ret
key6:
	cpi arg0l, 7
	brne key7
	ldi arg0l, 6
	ret
key7:
	cpi arg0l, 9
	brne key8
	ldi arg0l, 7
	ret
key8:
	cpi arg0l, 10
	brne key9
	ldi arg0l, 8
	ret
key9:
	cpi arg0l, 11
	brne key0
	ldi arg0l, 9
	ret
key0:
	ldi arg0l, 0
	ret

.org 0x1000

enterTimeMessage:
	.db "Enter time: "
enterTimeMessageEnd:
	.db "  "

errorMessage:
	.db "Try again:"
errorMessageEnd:
	.db "  "
