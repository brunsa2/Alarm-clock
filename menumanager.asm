; menumanager.asm
; Jeff Stubler
; 10 November 2010
;
; Main clock program to run menu interface for adjusting settings

.def position = r18
.def top = r19

; menuManagerInit
; Sets initial menu and cursor positions
; No arguments
; No returns

menuManagerInit:
	push immL                                      ; set cursor and top line positions to 0
	clr immL
	mov position, immL
	mov top, immL
	pop immL
	ret

; menuManagerStart
; Main program entrance point to run menu system
; No arguments
; No returns

menuManagerStart:
	rcall getCharacter                             ; wait for user to press menu key
	cpi arg0l, 16
	breq menuLaunch
	rjmp menuManagerStart

menuLaunch:
	ldi immL, 0                                    ; disable clock and clear screen
	sts timeDisplayEnabled, immL

	rcall clearLcd
	ldi immL, 0x41

waitForMainKeypress:
	rcall displayMenu                              ; show menu and wait for valid keypress

	rcall getCharacter
	cpi arg0l, 4
	breq upArrowPressed
	cpi arg0l, 8
	breq downArrowPressed
	cpi arg0l, 12
	breq enterPressed
	cpi arg0l, 16
	breq clockLaunch
	rjmp waitForMainKeypress

clockLaunch:                                     ; go back to clock and wait for menu key again
	ldi immL, 1
	sts timeDisplayEnabled, immL
	rcall displayTime
	rjmp menuManagerStart

upArrowPressed:                                  ; move cursor and maybe menu positions for up key
	dec position
	cpi position, 5
	brlo adjustMenuDisplayPosition
	ldi position, 0
	rjmp adjustMenuDisplayPosition

downArrowPressed:
	inc position                                   ; move cursor and maybe menu positions for down key
	cpi position, 5
	brlo adjustMenuDisplayPosition
	ldi position, 4
	rjmp adjustMenuDisplayPosition

adjustMenuDisplayPosition:
	mov immL, position                             ; move menu up or down if cursor has gone above or    
	sub immL, top                                  ; below viewpoint
	cpi immL, 2
	brge moveMenuDown
	cpi immL, 0
	brlt moveMenuUp
	rjmp waitForMainKeypress

moveMenuDown:
	inc top
	rjmp waitForMainKeypress

moveMenuUp:
	dec top
	rjmp waitForMainKeypress

enterPressed:                                    ; go to settings change routine based on cursor
	cpi position, 0                                 ; position
	breq changeAlarmStatus
	cpi position, 1
	breq setAlarm
	cpi position, 2
	breq setTime
	cpi position, 3
	breq changeHourFormat
	rjmp changeSecondsFormat

changeAlarmStatus:                               ; turn alarm on or off
	lds immL, alarmEnabled
	com immL
	andi immL, 0x01
	sts alarmEnabled, immL
	rjmp waitForMainKeypress

changeHourFormat:                                ; use 12- or 24-hour format
	lds immL, hourFormat
	com immL
	andi immL, 0x01
	sts hourFormat, immL
	rjmp waitForMainKeypress

changeSecondsFormat:                             ; show or hide seconds
	lds immL, secondsFormat
	com immL
	andi immL, 0x01
	sts secondsFormat, immL
	rjmp waitForMainKeypress

setAlarm:                                        ; input time and set alarm time to it
	rcall inputTime
	cli
	sts alarmHour, hourIn
	sts alarmMinute, minuteIn
	sei
	rjmp waitForMainKeypress

setTime:
	rcall inputTime                                 ; input time and set main clock to it
	cli
	sts hours, hourIn
	sts minutes, minuteIn
	clr immL
	sts seconds, immL
	sei
	rjmp waitForMainKeypress



; displayMenu
; Displays menu at appropriate location and with saved settings
; No arguments
; No returns

displayMenu:
	push XH
	push XL
	push YH
	push YL

	rcall clearLcd

showTopLine:                                     ; display top line based on menu position
	cp position, top
	breq showTopLineIndicator
	ldi XH, high(nonSelectedMarker << 1)
	ldi XL, low(nonSelectedMarker << 1)
	ldi YH, high(nonSelectedMarker << 1)
	ldi YL, low(nonSelectedMarker << 1)
	rcall writeFlashStringToLcd
	rjmp showTopLineMessage
showTopLineIndicator:
	ldi XH, high(selectedMarker << 1)
	ldi XL, low(selectedMarker << 1)
	ldi YH, high(selectedMarker << 1)
	ldi YL, low(selectedMarker << 1)
	rcall writeFlashStringToLcd
showTopLineMessage:
	cpi top, 0
	breq showTopLineAlarmStatus
	cpi top, 1
	breq showTopLineSetAlarm
	cpi top, 2
	breq showTopLineSetTime
	rjmp showTopLineHourFormat
showTopLineAlarmStatus:
	rcall displayAlarmMessage
	rjmp showBottomLine
showTopLineSetAlarm:
	ldi XH, high(setAlarmMessage << 1)
	ldi XL, low(setAlarmMessage << 1)
	ldi YH, high(setAlarmMessageEnd << 1)
	ldi YL, low(setAlarmMessageEnd << 1)
	rcall writeFlashStringToLcd
	rjmp showBottomLine
showTopLineSetTime:
	ldi XH, high(setTimeMessage << 1)
	ldi XL, low(setTimeMessage << 1)
	ldi YH, high(setTimeMessageEnd << 1)
	ldi YL, low(setTimeMessageEnd << 1)
	rcall writeFlashStringToLcd
	rjmp showBottomLine
showTopLineHourFormat:
	rcall displayHourFormatMessage

showBottomLine:                                  ; display bottom line based on menu position
	rcall nextLine
	cp position, top
	breq showBottomLineSpace
	ldi XH, high(selectedMarker << 1)
	ldi XL, low(selectedMarker << 1)
	ldi YH, high(selectedMarker << 1)
	ldi YL, low(selectedMarker << 1)
	rcall writeFlashStringToLcd
	rjmp showBottomLineMessage
showBottomLineSpace:
	ldi XH, high(nonSelectedMarker << 1)
	ldi XL, low(nonSelectedMarker << 1)
	ldi YH, high(nonSelectedMarker << 1)
	ldi YL, low(nonSelectedMarker << 1)
	rcall writeFlashStringToLcd
showBottomLineMessage:
	cpi top, 0
	breq showBottomLineSetAlarm
	cpi top, 1
	breq showBottomLineSetTime
	cpi top, 2
	breq showBottomLineHourFormat
	rjmp showBottomLineSecondsFormat
showBottomLineSetAlarm:
	ldi XH, high(setAlarmMessage << 1)
	ldi XL, low(setAlarmMessage << 1)
	ldi YH, high(setAlarmMessageEnd << 1)
	ldi YL, low(setAlarmMessageEnd << 1)
	rcall writeFlashStringToLcd
	rjmp finishDisplayMenu
showBottomLineSetTime:
	ldi XH, high(setTimeMessage << 1)
	ldi XL, low(setTimeMessage << 1)
	ldi YH, high(setTimeMessageEnd << 1)
	ldi YL, low(setTimeMessageEnd << 1)
	rcall writeFlashStringToLcd
	rjmp finishDisplayMenu
showBottomLineHourFormat:
	rcall displayHourFormatMessage
	rjmp finishDisplayMenu
showBottomLineSecondsFormat:
	rcall displaySecondsFormatMessage



finishDisplayMenu:                               ; call point for terminating routing
	pop YL
	pop YH
	pop XL
	pop XH
	ret

displayAlarmMessage:                             ; reads alarm setting and shows proper message
	push immL
	lds immL, alarmEnabled
	cpi immL, 0
	brne displayAlarmOnMessage
	ldi XH, high(alarmOffMessage << 1)
	ldi XL, low(alarmOffMessage << 1)
	ldi YH, high(alarmOffMessageEnd << 1)
	ldi YL, low(alarmOffMessageEnd << 1)
	rcall writeFlashStringToLcd
	pop immL
	ret
displayAlarmOnMessage:
	ldi XH, high(alarmOnMessage << 1)
	ldi XL, low(alarmOnMessage << 1)
	ldi YH, high(alarmOnMessageEnd << 1)
	ldi YL, low(alarmOnMessageEnd << 1)
	rcall writeFlashStringToLcd
	pop immL
	ret

displayHourFormatMessage:                        ; reads hour format setting and shows proper
	push immL                                      ; message
	lds immL, hourFormat
	cpi immL, 0
	brne displayTwentyFourHourMessage
	ldi XH, high(twelveHourMessage << 1)
	ldi XL, low(twelveHourMessage << 1)
	ldi YH, high(twelveHourMessageEnd << 1)
	ldi YL, low(twelveHourMessageEnd << 1)
	rcall writeFlashStringToLcd
	pop immL
	ret
displayTwentyFourHourMessage:
	ldi XH, high(twentyFourHourMessage << 1)
	ldi XL, low(twentyFourHourMessage << 1)
	ldi YH, high(twentyFourHourMessageEnd << 1)
	ldi YL, low(twentyFourHourMessageEnd << 1)
	rcall writeFlashStringToLcd
	pop immL
	ret


displaySecondsFormatMessage:                     ; reads seconds format setting and shows proper
	push immL                                       ; message
	lds immL, secondsFormat
	cpi immL, 0
	brne displaySecondsOnMessage
	ldi XH, high(secondsOffMessage << 1)
	ldi XL, low(secondsOffMessage << 1)
	ldi YH, high(secondsOffMessageEnd << 1)
	ldi YL, low(secondsOffMessageEnd << 1)
	rcall writeFlashStringToLcd
	pop immL
	ret
displaySecondsOnMessage:
	ldi XH, high(secondsOnMessage << 1)
	ldi XL, low(secondsOnMessage << 1)
	ldi YH, high(secondsOnMessageEnd << 1)
	ldi YL, low(secondsOnMessageEnd << 1)
	rcall writeFlashStringToLcd
	pop immL
	ret



.org 0x0800

nonSelectedMarker:
	.db "  "

selectedMarker:
	.db "> "

alarmOffMessage:
	.db "Alarm: Off"
alarmOffMessageEnd:
	.db "  "

alarmOnMessage:
	.db "Alarm: On "
alarmOnMessageEnd:
	.db "  "

setAlarmMessage:
	.db "Set alarm "
setAlarmMessageEnd:
	.db "  "

setTimeMessage:
	.db "Set time  "
setTimeMessageEnd:
	.db "  "

twelveHourMessage:
	.db "12/24 Hour: 12"
twelveHourMessageEnd:
	.db "  "

twentyFourHourMessage:
	.db "12/24 Hour: 24"
twentyFourHourMessageEnd:
	.db "  "

secondsOffMessage:
	.db "Seconds: Off"
secondsOffMessageEnd:
	.db "  "

secondsOnMessage:
	.db "Seconds: On "
secondsOnMessageEnd:
	.db "  "
