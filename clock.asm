; clock.asm
; Jeff Stubler
; 10 November 2010
;
; Programme to implement a 12- or 24-hour display digital alarm clock

#include "m32def.inc"

.def immH = r17
.def immL = r16
.def separator = r20
.def arg0l = r24
.def arg0h = r25
.def arg1l = r22
.def arg1h = r23

.equ ramOrigin = 0x0060
.equ stackBottom = 0x065f
.equ stackSize = 512
.equ stackTop = stackBottom + stackSize - 1

.equ resetVector = 0x0000
.equ secondTimerVector = OC1Aaddr
.equ codeOrigin = 0x002a

.equ processorFrequency = 16000000





.dseg
.org ramOrigin
seconds:
.byte 1
minutes:
.byte 1
hours:
.byte 1
timeDisplayEnabled:                              ; menu or clock mode
.byte 1
alarmEnabled:                                    ; user setting
.byte 1
alarmOn:                                         ; turns off for alarm off button
.byte 1
alarmMinute:
.byte 1
alarmHour:
.byte 1
hourFormat:                                      ; 12 or 24 hour
.byte 1
secondsFormat:                                   ; show or hide seconds
.byte 1

.org stackBottom
.byte stackSize





.cseg
.org resetVector
	rjmp main
.org secondTimerVector
	jmp handleSecondTick
.org codeOrigin

main:

	ldi immH, high(stackTop)                       ; initialise stack pointer
	ldi immL, low(stackTop)
	out SPH, immH
	out SPL, immL

	rcall initialiseLcd
	rcall initialiseSecondTimer
	rcall menuManagerInit

 	sei                                            ; start accepting one second tick
	
	rjmp menuManagerStart                          ; launch main menu manager program



; delay
; Small delay for debouncing, approximately 16 milliseconds
; No arguments
; No return value

delay:
	push immL

	ldi immL, (1 << CS02) | (1 << CS00)
	out TCCR0, immL
waitForDelay:	
	in immL, TIFR
	andi immL, (1 << OCF0)
	brne waitForDelay

	clr immL
	out TCCR0, immL

	pop immL
	ret


#include "lcd.asm"
#include "secondtimer.asm"
#include "keypress.asm"
#include "menumanager.asm"
#include "timeentry.asm"
