; secondtimer.asm
; Jeff Stubler
; 10 November 2010
;
; Timer tick interrupt and routines to update and display clock

.equ timerPrescaler = 1024
.equ debugAdjust = 1
.equ oneSecondCount = processorFrequency / timerPrescaler / debugAdjust

initialiseSecondTimer:
	push immH
	push immL

	ldi immH, 0x01                                 ; start with clock displayed at 12:00 AM
	ldi immL, 0x00
	sts timeDisplayEnabled, immH
	sts seconds, immL
	sts minutes, immL
	sts hours, immL
	sts alarmEnabled, immL
	sts alarmHour, immL
	sts alarmMinute, immL
	sts hourFormat, immL
	sts secondsFormat, immL

	ldi immH, (1<<COM1A1) | (1<<COM1A0)            ; timer tick every second in clear on timer compare
	ldi immL, (1<<WGM12) | (1<<CS12) | (1<<CS10)   ; mode
	out TCCR1A, immH
	out TCCR1B, immL
	ldi immH, high(oneSecondCount)
	ldi immL, low(oneSecondCount)
	out OCR1AH, immH
	out OCR1Al, immL

	in immL, TIMSK                                 ; enable the tick
	ori immL, (1<<OCIE1A)
	out TIMSK, immL

	rcall displayTime                              ; show the initial time upon power on

	pop immL
	pop immH

	ret



; sixtyAdjustAfterAddition
; Reformats sum in packed BCD with a maximum value of 59
; r24 - byte to readjust
; r25 - carry out

sixtyAdjustAfterAddition:
	push immL

	ldi arg1l, 0x00

	brcs sAdjustHigherNibbleForCarry
	rjmp sCheckLowerNibble

sAdjustHigherNibbleForCarry:
	ldi immL, 0xa0
	add arg0l, immL
	ldi arg1l, 0x01
	
sCheckLowerNibble:
	brhs sAdjustLowerNibble
	mov immL, arg0l
	andi immL, 0x0f
	cpi immL, 0x0a
	brsh sAdjustLowerNibble
	rjmp sCheckHigherNibble

sAdjustLowerNibble:
	ldi immL, 0x06
	add arg0l, immL

sCheckHigherNibble:
	mov immL, arg0l
	swap immL
	andi immL, 0x0f
	cpi immL, 0x06
	brsh sAdjustHigherNibble
	rjmp sFinishDecimalAdjust

sAdjustHigherNibble:
	ldi immL, 0xa0
	add arg0l, immL
	ldi arg1l, 0x01

sFinishDecimalAdjust:
	pop immL
	ret


; twentyFourAdjustAfterAddition
; Reformats sum in packed BCD with a maximum value of 23
; r24 - byte to readjust
; r25 - carry out

twentyFourAdjustAfterAddition:
	push immL

	ldi arg1l, 0x00

	brcs tAdjustHigherNibbleForCarry
	rjmp tCheckLowerNibble

tAdjustHigherNibbleForCarry:
	ldi immL, 0x60
	add arg0l, immL
	ldi arg1l, 0x01
	
tCheckLowerNibble:
	brhs tAdjustLowerNibble
	mov immL, arg0l
	andi immL, 0x0f
	cpi immL, 0x0a
	brsh tAdjustLowerNibble
	rjmp tCheckHigherNibble

tAdjustLowerNibble:
	ldi immL, 0x06
	add arg0l, immL

tCheckHigherNibble:
	mov immL, arg0l
	swap immL
	andi immL, 0x0f
	cpi immL, 0x0a
	brsh tAdjustHigherNibble
	rjmp tDoFinalNumberCheck

tAdjustHigherNibble:
	ldi immL, 0x60
	add arg0l, immL
	ldi arg1l, 0x01

tDoFinalNumberCheck:
	cpi arg0l, 0x24
	brcs tFinishDecimalAdjust

	ldi arg0l, 0
	ldi arg1l, 1

tFinishDecimalAdjust:
	pop immL
	ret




; handleSecondTick
; Main timer tick ISR

handleSecondTick:
	push immL
	push immH
	in immL, SREG
	push immL

	in immL, PORTB                                 ; remnant code from oscilloscope testing
	ldi immH, 0x01
	eor immL, immH
	out PORTB, immL

	rcall updateInternalTime
	rcall displayTime
	rcall runAlarmSystem

leaveInterrupt:
	pop immL
	out SREG, immL
	pop immH
	pop immL
	reti



; updateInternalTime
; Updates internal clock by one second
; No arguments
; No returns

updateInternalTime:
	push immH
	push immL
	push arg0l

	lds immL, seconds                              ; add one to seconds
	ldi immH, 0x01
	add immL, immH
	mov arg0l, immL
	rcall sixtyAdjustAfterAddition
	mov immL, arg0l
	sts seconds, immL

	lds immL, minutes                              ; add carry to minutes
	mov immH, arg1l
	add immL, immH
	mov arg0l, immL
	rcall sixtyAdjustAfterAddition
	mov immL, arg0l
	sts minutes, immL

	lds immL, hours                                ; add carry to hours
	mov immH, arg1l
	add immL, immH
	mov arg0l, immL
	rcall twentyFourAdjustAfterAddition
	mov immL, arg0l
	sts hours, immL

	pop arg0l
	pop immL
	pop immH 
	ret


; displayTime
; Displays time on LCD panel with appropriate formatting
; No arguments
; No returns

displayTime:
	push immH
	push immL
	push arg0l

	lds immL, timeDisplayEnabled                   ; leave if the menu is displayed
	cpi immL, 0x01
	brne skipToEnd
	rjmp showTime
skipToEnd:
	rjmp finishedDisplayingTime

showTime:                                        ; determine hour format and adjust as necessary
	lds immL, hourFormat
	cpi immL, 1
	breq twentyFourHourTime
	
	lds immH, hours
	cpi immH, 0
	breq adjustForTwelveAm
	cpi immH, 0x13
	brsh adjustForPm
	rjmp showHour

adjustForTwelveAm:
	ldi immH, 0x12
	rjmp showHour

adjustForPm:
	mov immL, immH
	ldi immH, 0x12
	sub immL, immH
	mov immH, immL
	rjmp showHour

twentyFourHourTime:
	lds immH, hours

showHour:                                        ; create ASCII values from packed hour number
	mov immL, immH
	swap immH
	andi immL, 0x0f
	andi immH, 0x0f
	ldi arg0l, 0x30
	add immL, arg0l
	add immH, arg0l

	rcall clearLcd
	mov arg0l, immH
	rcall writeCharacterToLcd
	mov arg0l, immL
	rcall writeCharacterToLcd

	lds immL, seconds                              ; determine if colon to be shown
	andi immL, 1
	breq noShowColon
	ldi separator, ':'
	rjmp showMinutes
noShowColon:
	ldi separator, ' '

showMinutes:                                     ; create ASCII values from packed minute number
	lds immL, minutes

	mov immH, immL
	swap immH
	andi immL, 0x0f
	andi immH, 0x0f
	ldi arg0l, 0x30
	add immL, arg0l
	add immH, arg0l

	mov arg0l, separator
	rcall writeCharacterToLcd
	mov arg0l, immH
	rcall writeCharacterToLcd
	mov arg0l, immL
	rcall writeCharacterToLcd

	lds immL, secondsFormat                        ; create ASCII values from packed second number
	cpi immL, 0                                    ; if it is to be displayed
	breq showAmPm

	lds immL, seconds

	mov immH, immL
	swap immH
	andi immL, 0x0f
	andi immH, 0x0f
	ldi arg0l, 0x30
	add immL, arg0l
	add immH, arg0l

	mov arg0l, separator
	rcall writeCharacterToLcd
	mov arg0l, immH
	rcall writeCharacterToLcd
	mov arg0l, immL
	rcall writeCharacterToLcd

showAmPm:                                        ; if 12-hour time, show AM/PM indicator
	ldi immL, hourFormat
	cpi immL, 1
	breq finishedDisplayingTime

	lds immL, hours
	cpi immL, 12
	brsh showPm

	ldi arg0l, ' '
	rcall writeCharacterToLcd
	ldi arg0l, 'A'
	rcall writeCharacterToLcd
	ldi arg0l, 'M'
	rcall writeCharacterToLcd
	rjmp finishedDisplayingTime

showPm:
	ldi arg0l, ' '
	rcall writeCharacterToLcd
	ldi arg0l, 'P'
	rcall writeCharacterToLcd
	ldi arg0l, 'M'
	rcall writeCharacterToLcd


finishedDisplayingTime:
	pop arg0l
	pop immL
	pop immH
	ret



; runAlarmSystem
; determines if the alarm should be triggered
; No arguments
; No returns

runAlarmSystem:
	push immH
	push immL
	push arg0h
	push arg0l

	lds immL, alarmEnabled                         ; if alarm enabled and no turned off with button
	cpi immL, 0                                    ; check for time
	brne testForAlarmOn
	rcall turnAlarmOff
	rjmp finishAlarmHandler

testForAlarmOn:                                 
	lds immL, alarmOn
	cpi immL, 0
	brne testForAlarmMatch
	rcall turnAlarmOff
	rjmp finishAlarmHandler

testForAlarmMatch:                               ; if proper time, trigger alarm and leave
	lds immH, hours
	lds immL, minutes
	ldi arg0h, alarmHour
	ldi arg0l, alarmMinute
	cp arg0l, immL
	cpc arg0h, immH
	breq triggerAlarm
	ldi immL, 0
	sts alarmOn, immL
	rjmp finishAlarmHandler

triggerAlarm:
	rcall turnAlarmOn

finishAlarmHandler:
	pop arg0l
	pop arg0h
	pop immL
	pop immH
	ret


; turnAlarmOff
; Turns off alarm by stopping sound-generating square wave
; No arguments
; No returns

turnAlarmOff:
	push immL
	ldi immL, 0
	out TCCR2, immL
	pop immL
	ret



; turnAlarmOn
; Turns on alarm by generating a 50% duty cycle square wave to drive a filter and speaker.
; No arguments
; No returns

turnAlarmOn:
	push immL
	ldi immL, (1 << CS22) | (1 << CS20) | (1 << WGM20) | (1 << COM21) | (1 << COM20)
	out TCCR2, immL
	ldi immL, 128
	out OCR2, immL
	ldi immL, 0
	out TCNT2, immL
	pop immL
	ret
