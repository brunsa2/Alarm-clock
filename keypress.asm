; keypress.asm
; Jeff Stubler
; 10 November 2010
;
; Routines to initialise and use port B for keypad input

.equ row1 = 0
.equ row2 = 7
.equ row3 = 6
.equ row4 = 4
.equ col1 = 5
.equ col2 = 3
.equ col3 = 2
.equ col4 = 1

.equ row1Pressed = 0xd0
.equ row2Pressed = 0x51
.equ row3Pressed = 0x91
.equ row4Pressed = 0xc1
.equ col1Pressed = 0x0e
.equ col2Pressed = 0x26
.equ col3Pressed = 0x2a
.equ col4Pressed = 0x2c

.equ noKeyCode = 0
.equ row1Code = 1 
.equ row2Code = 5
.equ row3Code = 9
.equ row4Code = 13
.equ col1Code = 0
.equ col2Code = 1
.equ col3Code = 2
.equ col4Code = 3

.equ scanRowDataDirection = (1 << col1) | (1 << col2) | (1 << col3) | (1 << col4)
.equ scanRowPort = (1 << row1) | (1 << row2) | (1 << row3) | (1 << row4)
.equ scanColDataDirection = (1 << row1) | (1 << row2) | (1 << row3) | (1 << row4)
.equ scanColPort = (1 << col1) | (1 << col2) | (1 << col3) | (1 << col4)

; scanForKeypress
; Check both row and column of key pressed
; No arguments
; r24 - scan code of key

scanForKeypress:
	push immH
	push immL

scanRow:
	ldi immH, scanRowDataDirection                 ; set ports, wait a bit, then check each row and 
	ldi immL, scanRowPort                          ; set part of the scan code
	out DDRB, immH
	out PORTB, immL

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	in immL, PINB

checkForRow1:
	cpi immL, row1Pressed
	brne checkForRow2
	ldi arg0l, row1Code
	rjmp scanColumn

checkForRow2:
	cpi immL, row2Pressed
	brne checkForRow3
	ldi arg0l, row2Code
	rjmp scanColumn

checkForRow3:
	cpi immL, row3Pressed
	brne checkForRow4
	ldi arg0l, row3Code
	rjmp scanColumn

checkForRow4:
	cpi immL, row4Pressed
	brne noKeyPressedRow
	ldi arg0l, row4Code
	rjmp scanColumn

noKeyPressedRow:
	ldi arg0l, noKeyCode
	rjmp finishKeypadScan

scanColumn:                                      ; set ports, wait a bit, then check each col and
	ldi immH, scanColDataDirection                  ; finish making scan code
	ldi immL, scanColPort
	out DDRB, immH
	out PORTB, immL

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	in immL, PINB

checkForCol1:
	cpi immL, col1Pressed
	brne checkForCol2
	ldi immH, col1Code
	add arg0l, immH
	rjmp finishKeypadScan

checkForCol2:
	cpi immL, col2Pressed
	brne checkForCol3
	ldi immH, col2Code
	add arg0l, immH
	rjmp finishKeypadScan

checkForCol3:
	cpi immL, col3Pressed
	brne checkForCol4
	ldi immH, col3Code
	add arg0l, immH
	rjmp finishKeypadScan

checkForCol4:
	cpi immL, col4Pressed
	brne noKeyPressedCol
	ldi immH, col4Code
	add arg0l, immH
	rjmp finishKeypadScan

noKeyPressedCol:
	ldi arg0l, noKeyCode

finishKeypadScan:
	pop immL
	pop immH
	ret


; getCharacter
; Polls for character from keypad (including both press and release), also handles alarm off and
; snooze functionality which is always enabled regardless of the purpose of the keypress
; No arguments
; r24 - scan code

getCharacter:
	push immH
	push immL

waitForPress:                                    ; wait till a key is detected
	rcall scanForKeypress
	cpi arg0l, 0
	breq waitForPress

	push arg0l                                     ; save keypress
	rcall delay

waitForRelease:                                  ; wait till all keys are released
	rcall scanForKeypress
	cpi arg0l, 0
	brne waitForRelease

	pop arg0l                                      ; restore keypress

	cpi arg0l, 13                                  ; check for snooze or alarm off keys
	breq snoozeHandler
	cpi arg0l, 15
	breq alarmOffHandler

	pop immL
	pop immH
	ret

snoozeHandler:
	push arg0l
	push arg0h

	ldi immL, 0                                    ; turns off alarm immediately
	sts alarmOn, immL

	lds immL, alarmMinute                          ; sets alarm time for 5 minutes later
	ldi immH, 5
	add immL, immH
	mov arg0l, immL
	rcall sixtyAdjustAfterAddition
	sts alarmMinute, arg0l

	lds arg0l, alarmHour
	add arg0l, arg0h
	rcall twentyFourAdjustAfterAddition
	sts alarmHour, arg0l

	pop arg0h
	pop arg0l
	pop immL
	pop immH
	ret

alarmOffHandler:
	ldi immL, 0
	sts alarmOn, immL                              ; turns off alarm immediately without readjusting
                                                 ; alarm time
	pop immL
	pop immH
	ret
