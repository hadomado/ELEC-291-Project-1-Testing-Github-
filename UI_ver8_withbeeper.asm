$NOLIST
$MODLP51
$LIST

org 0000H
    ljmp main
org 0x000B
	ljmp Timer0_ISR
org 0x002B
	ljmp timer_2_isr
	
$NOLIST
$include(LCD_4bit_Norton_2.inc)
$include(math32.inc)
$include(timer1isrV4inc.inc)
$LIST

TIMER0_RELOAD_L DATA 0xf2
TIMER1_RELOAD_L DATA 0xf3
TIMER0_RELOAD_H DATA 0xf4
TIMER1_RELOAD_H DATA 0xf5

CLK 		  EQU 22118400
BAUD 		  EQU 115200
TIMER0_RATE   EQU 4096     ; 2048Hz square-wave (peak amplitude of CEM-1203 speaker)
TIMER0_RELOAD EQU ((65536-(CLK/TIMER0_RATE)))
TIMER2_RATE   EQU 1000     ; 1000Hz, for a timer tick of 1ms
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))
BRG_VAL 	  EQU (0x100-(CLK/(16*BAUD)))
COOLTEMP 	  EQU 60

CE_ADC 		EQU P2.0
MY_MOSI 	EQU P2.1
MY_MISO 	EQU P2.2
MY_SCLK 	EQU P2.3
SSRpin 		EQU P0.7
SOUND_OUT 	EQU P3.7
	
;----------------------------------------------
BSEG
ramptosoak: 	dbit 1
preheat: 		dbit 1
ramptopeak: 	dbit 1
reflow_flag: 	dbit 1
cooling: 		dbit 1
digit0: 		dbit 1
digit1: 		dbit 1
digit2: 		dbit 1
mf:			  	dbit 1
reflowon:	  	dbit 1
reflow_suc:	  	dbit 1
temp_err:	  	dbit 1
mfbackup:		dbit 1
;new ones
transition:		dbit 1
open:			dbit 1
cool:			dbit 1
transition_on:	dbit 1
open_on:		dbit 1
cool_on:		dbit 1
six_beeps_flag:	dbit 1
beeper_on:		dbit 1
skip_beeper: 	dbit 1
;----------------------------------------------

;----------------------------------------------
DSEG at 30H

Count1ms:     	ds 2 ; Used to determine when half second has passed
Count250ms:     ds 1 ; Used to determine when to send temp
BCD_counter:  	ds 1 ; The BCD counter incrememted in the ISR and displayed in the main loop
reflowtime: 	ds 2
state: 			ds 1
ktypetemp: 		ds 2
coldjtemp: 		ds 2

voltage_return: 		ds 2
voltage_return_ktype: 	ds 2
counter: 				ds 1 ; counter for power check
multiple_of_200: 		ds 1 ; 5 stage counter for 20% power check

x:			ds 4 ; 4 bytes for 32-bit math
y:			ds 4
bcd:		ds 5

reflowtimesec: 	ds 2
currtemp:		ds 2
adjusted_time:  ds 2

ramptosoaktemp:	ds 1	; = preheat temp
preheattime:	ds 1	; = soak Time
ramptopeaktemp:	ds 1	; = liquid temp
reflowheattime:	ds 1 	; = peak time
peak_temp:		ds 1	; not used during reflow


PreheatTemp_1:	ds 1
SoakTime_1:		ds 1
PeakTemp_1:		ds 1
PeakTime_1:		ds 1
LiquidTemp_1:	ds 1

PreheatTemp_2:	ds 1
SoakTime_2:		ds 1
PeakTemp_2:		ds 1
PeakTime_2:		ds 1
LiquidTemp_2:	ds 1

PreheatTemp_3:	ds 1
SoakTime_3:		ds 1
PeakTemp_3:		ds 1 
PeakTime_3:		ds 1
LiquidTemp_3:	ds 1

PreheatTemp_4:	ds 1
SoakTime_4:		ds 1
PeakTemp_4:		ds 1
PeakTime_4:		ds 1
LiquidTemp_4:	ds 1

counter0: ds 1
counter1: ds 1
counter2: ds 1
;----------------------------------------------

;----------------------------------------------
CSEG

LCD_RS 	equ P1.1
LCD_RW 	equ P1.2
LCD_E  	equ P1.3
LCD_D4 	equ P3.2
LCD_D5 	equ P3.3
LCD_D6 	equ P3.4
LCD_D7 	equ P3.5

down 	equ p0.1
back	equ p0.2
click	equ p0.4

;----------------------------------------------
;		     		1234567890123456
prof_1:  		db 'Prof1', 0
prof_2:  		db 'Prof2', 0
prof_3:  		db 'PYTH ', 0
prof_4:  		db 'Prof4', 0
Profile_1:  	db 'Profile 1', 0
Profile_2:  	db 'Profile 2', 0
Profile_3:  	db 'Profile 2', 0
Profile_4:  	db 'Profile 4', 0
Edit:			db 'Edit', 0
Reflow:			db 'Reflow', 0
PreheatTemp:	db 'Preheat Temp', 0
SoakTime:		db 'Soak Time', 0
PeakTemp:		db 'Peak Temp', 0
PeakTime:		db 'Peak Time',0
LiquidTemp:		db 'Liquid Temp', 0
arrow:			db '<<', 0
clr_arrow:		db '  ', 0
blank:  		db '                ', 0
tempUnit:		db '(C)', 0
timeUnit:		db '(s)', 0
Confirm_symbol: db 'Confirm', 0
Time_sym:		db 'Time', 0
Temp_sym:		db 'Temp', 0
Reflowing_p1:	db 'P1', 0
Reflowing_p2:	db 'P2', 0
Reflowing_p3:	db 'P3', 0
Reflowing_p4:	db 'P4', 0
tempUnit_sym:	db 'C', 0
timeUnit_sym:	db 's', 0
emerg_stop:		db 'Emergency Stop!', 0
reflow_suc_sym: db 'Reflow Done!', 0
temp_err_sym:	db 'Temp Error!', 0
check_thermo:	db 'Check ThermoCP!', 0
Hello_World:	db  'Hello, World!', '\r', '\n', 0
Python_in_Prog:	db 'Python in Prog..', 0
Py_update_sym:  db 'Upload done!', 0

;----------------------------------------------------------------------------------------;
;        PUTTY INTERFACE
;----------------------------------------------------------------------------------------;
InitSerialPort:
    ; Since the reset button bounces, we need to wait a bit before
    ; sending messages, otherwise we risk displaying gibberish!
    mov R1, #222
    mov R0, #166
    djnz R0, $   ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, $-4 ; 22.51519us*222=4.998ms
    ; Now we can proceed with the configuration
	orl	PCON,#0x80
	mov	SCON,#0x52	;mov SCON,#0x53
	mov	BDRCON,#0x00
	mov	BRL,#BRG_VAL
	mov	BDRCON,#0x1E ; BDRCON=BRR|TBCK|RBCK|SPD;
    ret


; Send a character using the serial port
putchar:
    jnb TI, putchar
    clr TI
    mov SBUF, a
    ret

; Gets a character (1 byte number) from the serial port
pullchar:
	jnb RI, pullchar
	clr RI
	mov a, SBUF
	ret

; Gets one character from python, if it is the reflow signal jump to reflow, else if it is set preset signal, change preset 3
GetMessage:
	push acc
	lcall pullchar
	cjne a, #63, jmp_Py_set
	sjmp Py_reflow
jmp_Py_set:
	ljmp Py_set
Py_reflow:
	pop acc
;If the python signal is for reflow
;Start Reflow (not implemented)
	mov	SCON,#0x52
	Start_reflow_py(3)
	
Py_set:
;If the python signal is not for set data, error
	cjne a, #77, Py_error
	
	;pull each byte of data individually and save to preset 3
	lcall pullchar
	mov PreheatTemp_3, a
	lcall pullchar
	mov SoakTime_3, a
	lcall pullchar
	mov PeakTemp_3, a
	lcall pullchar
	mov PeakTime_3, a
	lcall pullchar
	mov LiquidTemp_3, a
	
	Set_Cursor(2, 1)
	Send_Constant_String(#Py_update_sym)
	
Py_error:	
	pop acc
	ljmp GetMessage
	;jump back to GetMessage and wait for reflow signal
	
Py_error2:
	pop acc
	Set_Cursor(1, 1)
	Display_char(#'?')
Py_error_loop:
	sjmp Py_error_loop	
	

; Send a constant-zero-terminated string using the serial port
SendString:
    clr A
    movc A, @A+DPTR
    jz SendStringDone
    lcall putchar
    inc DPTR
    sjmp SendString
SendStringDone:
    ret	
;---------------------------------;
; Send a BCD number to PuTTY      ;
;---------------------------------;
Send_BCD mac
	push ar0
	mov r0, %0
	lcall ?Send_BCD
	pop ar0
endmac

?Send_BCD:
	push acc
	; Write most significant digit
	mov a, r0
	swap a
	anl a, #0fh
	orl a, #30h
	lcall putchar
	; write least significant digit
	mov a, r0
	anl a, #0fh
	orl a, #30h
	lcall putchar
	pop acc
	ret
;----------------------------------------------------------------------------------------;
;        BIT-BANG SPI
;----------------------------------------------------------------------------------------;
INIT_SPI: 
    setb MY_MISO    ; Make MISO an input pin
    clr MY_SCLK     ; For mode (0,0) SCLK is zero
    ret
    
DO_SPI_G: 
    push acc 
    mov R1, #0      ; Received byte stored in R1
    mov R2, #8    ; Loop counter (8-bits)
    
DO_SPI_G_LOOP: mov a, R0       ; Byte to write is in R0
    rlc a           ; Carry flag has bit to write
    mov R0, a 
    mov MY_MOSI, c 
    setb MY_SCLK    ; Transmit
    mov c, MY_MISO  ; Read received bit
    mov a, R1       ; Save received bit in R1
    rlc a 
    mov R1, a 
    clr MY_SCLK 
    djnz R2, DO_SPI_G_LOOP 
    pop acc 
    ret

;----------------------------------------------------------------------------------------;
setpins:
    clr P2.4 ;bit 3 where 4-bits in order of 3-2-1-0
    clr P2.5 ;bit 2
    clr P2.6 ;bit 1
    clr P2.7 ;bit 0
    ;clr P4.5 ;display 0
    ;clr P4.4 ;display 1
    ;clr P0.6
    ret
;----------------------------------------------------------------------------------------;
Timer0_Init:
	mov a, TMOD
	anl a, #0xf0 ; Clear the bits for timer 0
	orl a, #0x01 ; Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH0, #high(TIMER0_RELOAD)
	mov TL0, #low(TIMER0_RELOAD)
	; Set autoreload value
	mov TIMER0_RELOAD_H, #high(TIMER0_RELOAD)
	mov TIMER0_RELOAD_L, #low(TIMER0_RELOAD)
	; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
	ret
;------------------------------------------------------------------------------------------
Timer0_ISR:
	;clr TF0  ; According to the data sheet this is done for us already.
	jnb beeper_on, Timer0_ISR_done
	cpl SOUND_OUT ; Connect speaker to P3.7!
Timer0_ISR_done:
	reti
;----------------------------------------------------------------------------------------;
;        TIMER 2 ISR INITIALIZE
;----------------------------------------------------------------------------------------;
Timer2_Init:
    mov T2CON, #0 ; Stop timer/counter.  Autoreload mode.
    mov TH2, #high(TIMER2_RELOAD)
    mov TL2, #low(TIMER2_RELOAD)
    ; Set the reload value
    mov RCAP2H, #high(TIMER2_RELOAD)
    mov RCAP2L, #low(TIMER2_RELOAD)
    ; Init One millisecond interrupt counter.  It is a 16-bit variable made with two 8-bit parts
    clr a
    mov Count1ms+0, a
    mov Count1ms+1, a
    mov Count250ms, a
    ; Enable the timer and interrupts
    setb ET2  ; Enable timer 2 interrupt
    setb TR2  ; Enable timer 2
    ret
	

;----------------------------------------------------------------------------------------;
;        TIMER 2 ISR
;----------------------------------------------------------------------------------------;

timer_2_isr:
    clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
; The two registers used in the ISR must be saved in the stack
    push acc 
    push psw
    ;push lower 2 bytes of x and y 
	mov a, x
	push acc
	mov a, x+1
	push acc
	mov a, x+2
	push acc
	mov a, x+3
	push acc
	mov a, y
	push acc
	mov a, y+1
	push acc
	mov a, y+2
	push acc
	mov a, y+3
	push acc
	mov a, bcd
	push acc
	mov a, bcd+1
	push acc
	mov a, bcd+2
	push acc
	mov a, bcd+3
	push acc
	mov a, bcd+4
	push acc
	
	setb mfbackup
	jnb mf, digitcheck
	clr mfbackup
digitcheck:
	
;--------------------------------------------------------------------	
	;mov a, R0 ;counter up to 100
	;push ACC
	;mov a, R1 ;counter up to 10
	;push ACC
	;mov a, R2
	;push ACC
	;clr a
beeper_check:
	jb transition, short_beep_init
	jb open, long_beep_init
	jb cool, six_beeps_init
	jb transition_on, short_beep
	jb open_on, long_beep
	jb cool_on, six_beeps
	ljmp beeper_end
short_beep_init:
	mov counter0, #0
	mov counter1, #0
	setb transition_on
	clr transition
	sjmp beeper_check
long_beep_init:
	mov counter0, #0
	mov counter1, #0
	setb open_on
	clr open
	sjmp beeper_check
six_beeps_init:
	mov counter0, #0
	mov counter1, #0
	mov counter2, #0
	setb cool_on
	clr cool
	sjmp beeper_check
short_beep: ;for beginning and transitions
	setb beeper_on
	inc counter0
	mov a, counter0
	cjne a, #100, beeper_end
	mov counter0, #0
	inc counter1
	mov a, counter1
	cjne a, #10, beeper_end
	mov counter1, #0
	clr beeper_on
	clr transition_on
	ljmp beeper_end
long_beep: ;for when to open oven door
	setb beeper_on
	inc counter0
	mov a, counter0
	cjne a, #100, beeper_end
	mov counter0, #0
	inc counter1
	mov a, counter1
	cjne a, #30, beeper_end
	mov counter1, #0
	clr beeper_on
	clr open_on
	ljmp beeper_end
six_beeps: ;for when pcb is cool enough to handle
	mov a, counter2
	cjne a, #6, continue
	clr beeper_on
	setb skip_beeper
continue:
	jb skip_beeper, beeper_end
	jnb six_beeps_flag, six_beeps_on
	jb six_beeps_flag, six_beeps_off
six_beeps_on:
	setb beeper_on
	inc counter0
	mov a, counter0
	cjne a, #100, beeper_end
	mov counter0, #0
	inc counter1
	mov a, counter1
	cjne a, #10, beeper_end
	mov counter1, #0
	setb six_beeps_flag
	ljmp beeper_end
six_beeps_off:	
	clr beeper_on
	inc counter0
	mov a, counter0
	cjne a, #100, beeper_end
	mov counter0, #0
	inc counter1
	mov a, counter1
	cjne a, #10, beeper_end
	mov counter1, #0
	inc counter2
	clr six_beeps_flag
	ljmp beeper_end
beeper_end:
	;pop ACC
	;mov R2, a
	;pop ACC
	;mov R1, a
	;pop ACC
	;mov R0, a
;--------------------------------------------------------------------	

	
;---------------------------------------------------
    ;mov currtemp+0, #0x12 ;just to test remove after
    ;mov currtemp+1, #0x1 ;just to test remove after
;begin:
	;Wait_Milli_Seconds(#255)	next 6 lines used for testing
	;Wait_Milli_Seconds(#255)
	;Wait_Milli_Seconds(#255)
	;Wait_Milli_Seconds(#255)
	;mov currtemp+0, #0x23
	;mov currtemp+1, #0x1
	mov x+3, #0
	mov x+2, #0
	mov x+1, currtemp+1
	mov x+0, currtemp+0
	lcall hex2bcd
    jb digit0, check4
    jb digit1, check8
    jb digit2, start
start:
    mov a, bcd+1
    lcall setpins ;setting to 1 turns off
    clr digit0 ;makes it so that next time it enters the function, it changes correct led
    setb digit1
    clr digit2
    clr P0.6
    setb P4.4
    setb P4.5
    jnb ACC.3, check11
    setb P2.4
check11:
    jnb ACC.2, check10
    setb P2.5
check10:
    jnb ACC.1, check9
    setb P2.6
check9:
    jnb ACC.0, return1
    setb P2.7
return1:
    ljmp begin
;----------------------------------
check8:
    mov a, bcd+0
    lcall setpins
    setb digit0
    clr digit1
    clr digit2
    clr P4.4
    setb P0.6
    setb P4.5
    jnb ACC.7, check7
    setb P2.4
check7:
    jnb ACC.6, check6
    setb P2.5
check6:
    jnb ACC.5, check5
    setb P2.6
check5:
    jnb ACC.4, return2
    setb P2.7
return2:
;----------------------------------
    ljmp begin
check4:
    mov a, bcd+0
    lcall setpins
    clr digit0
    clr digit1
    setb digit2
    setb P4.4
    setb P0.7
    clr P4.5
    jnb ACC.3, check3
    setb P2.4
check3:
    jnb ACC.2, check2
    setb P2.5
check2:
    jnb ACC.1, check1
    setb P2.6
check1:
    jnb ACC.0, checkdone
    setb P2.7
checkdone:
    ljmp begin
;-------------------------------------------------------
begin:
;---------------------------------------------------------
power_start:
    jb ramptosoak, power_100 ;first_stage should be changed to name of flag for specific stage
    jb preheat, power_20
    jb ramptopeak, power_100
    jb reflow_flag, power_20 ;not sure if needed, but should be to same place as third stage
    jb cooling, power_0 ;off
	ljmp timerinc1

power_100:
    clr SSRpin ;change to whatever name of the pin is called and also does clearing bit turn it on?
    ljmp end_power_check
    
power_20:
    ;mov a, counter ;NEED TO CLEAR COUNTER AND MULTIPLE_OF_200 AT THE VERY BEGINNING
    ;add a, #1
    ;mov counter, a
    inc counter
    mov a, counter
    cjne a, #200, stage_check
    clr a
    mov counter, a
    ;mov a, multiple_of_200
    ;add a , #1
    ;mov multiple_of_200
    inc multiple_of_200 ;stage: 0-1-2-3-4, turns SSR on if at stage 4
    mov a, multiple_of_200
    cjne a, #5, stage_check
    clr a
    mov multiple_of_200, a
stage_check:
    mov a, multiple_of_200
    cjne a, #4, end_stage_check
    clr SSRpin
    ljmp end_power_check
end_stage_check:
    setb SSRpin
    ljmp end_power_check
    
power_0:
    setb SSRpin
end_power_check:
    ljmp timerinc1
;------------------------------------------------------------------
Timer2_ISR_donejmp:
    ljmp Timer2_ISR_done
No_reflowjmp:
    ljmp No_reflow
timerinc1:
    ; Increment the 16-bit one mili second counter
    inc Count1ms+0    ; Increment the low 8-bits first
    mov a, Count1ms+0 ; If the low 8-bits overflow, then increment high 8-bits
    jnz Inc_Done
    inc Count1ms+1
    

Inc_Done:
    ; Check if half second has passed
    mov a, Count1ms+0
    cjne a, #low(1000), Timer2_ISR_donejmp ; Warning: this instruction changes the carry flag!
    mov a, Count1ms+1
    cjne a, #high(1000), Timer2_ISR_donejmp

	mov count1ms, #0
	mov count1ms+1, #0
    ;check if reflowing if not turn off ssr, clear timer, reset state
    jnb reflowon, No_reflowjmp
    
    ;reflowing increment reflowtime
    
    inc reflowtime
    mov a, reflowtime
    jnz reflow_inc_done
    inc reflowtime+1
    
reflow_inc_done:
	;--------
    ;Clear_screen()
	;Set_Cursor(1, 1)
	;Display_char(#'1')
	;-------------
    move2byte(x, reflowtime)
    ;mov y+0, #4
    ;mov y+1, #0
    ;mov y+2, #0
    ;mov y+3, #0
    ;lcall div32 ;reflowtime/4 = reflowtimesec
    move2byte(reflowtimesec, x);set the reflow time in seconds
    
    
    ;read the current temperature
read_temp:
    MCP3008_protocall(0,0)
    MCP3008_protocall(1,1)
    lcall convert_temp ;cold junction temp in hex stored in x
    move2byte(coldjtemp, x);move x into coldjtemp
    lcall convert_temp_ktype ;ktype temp in hex stored in x
    move2byte(ktypetemp, x);move x into ktypetemp
    move2byte(y, coldjtemp);move coldjtemp to y for addition
    lcall add32 ;add the coldjunction and k-type temp together for the current temperature
    move2byte(currtemp, x);store the current temp in currtemp

	lcall hex2bcd
	Send_BCD(bcd+1)
	Send_BCD(bcd)
	mov a, #'\n'
	lcall putchar
	mov a, #'\r'
	lcall putchar	
	
    ;check the current state, and possibly switch to the next one
eval_state:
	;check for emergency shutdown - under 50C in 60 seconds
    mov a, state
	cjne a, #0, state1
	Move2byte (x, reflowtime) 
	mov x+2, #0
	mov x+3, #0  
	mov y+0, #0x3C	; 3C = 60 
	mov y+1, #0
	mov y+2, #0
	mov y+3, #0
	lcall x_gt_y ;if reflow time is greater than 60 seconds
	jnb mf, state0
	Move2byte (x, currtemp)
	mov y, #50
	lcall x_lt_y ;if temp less than 60
	jnb mf, state0
	;-shut it down boys-
	setb temp_err ;set under temperature error flag
	ljmp Reflow_done
state0:
	mov a, state
    ;ramp to soak - stay in state until over ramp to soak limit temp
    cjne a, #0, state1
    
    setb ramptosoak
    move2byte(x, currtemp)
    mov y, ramptosoaktemp
    mov y+1, #0
    lcall x_gt_y ;if currtemp > ramptosoaktemp set state to state 1
    jb mf, state0to1
    ljmp state0end
state0to1:
    clr ramptosoak
    setb preheat
    setb transition
    move2byte(x, reflowtimesec)
    mov x+2, #0
	mov x+3, #0
	mov y, preheattime
	mov y+1, #0
	mov y+2, #0
	mov y+3, #0
	lcall add32
	move2byte(adjusted_time, x)
    mov state, #1
    
state0end:
    ljmp Timer2_ISR_done ;finish state 0
    
state1:
    ;preheat - stay until time limit reached for preheat time
    mov a, state
    cjne a, #1, state2
    setb preheat
    move2byte(x, reflowtimesec)
    mov x+2, #0
	mov x+3, #0
    move2byte(y, adjusted_time)
    mov y+2, #0
	mov y+3, #0
    lcall x_gt_y
    jb mf, state1to2
    ljmp state1end
state1to2:
    clr preheat
    setb ramptopeak
    setb transition
    mov state, #2
    
state1end:
    ljmp Timer2_ISR_done ;finish state 1
    
state2:
    ;ramp to peak - stay until peak temp reached
    mov a, state
    cjne a, #2, state3
    setb ramptopeak
    move2byte(x, currtemp)
    mov x+2, #0
	mov x+3, #0
    mov y, ramptopeaktemp
    mov y+1, #0
    mov y+2, #0
	mov y+3, #0
	
    lcall x_gt_y ;if currtemp > ramptosoaktemp set state to state 1
    jb mf, state2to3
    ljmp state2end
state2to3:
    clr ramptopeak
    setb reflow_flag
    setb transition
    move2byte(x, reflowtimesec)
    mov x+2, #0
	mov x+3, #0
	mov y, reflowheattime
	mov y+1, #0
	mov y+2, #0
	mov y+3, #0
	lcall add32
	move2byte(adjusted_time, x)
    mov state, #3

state2end:
    ljmp Timer2_ISR_done ;finish state 2

state3:
    ;reflow - stay until reflowheattime reached
    mov a, state
    cjne a, #3, state4
    setb reflow_flag
    move2byte(x, reflowtimesec)
    mov x+2, #0
	mov x+3, #0
	move2byte(y, adjusted_time)
   	mov y+2, #0
	mov y+3, #0
    lcall x_gt_y ;if we are overtime switch to next state
    jb mf, state3to4
    ljmp state3end
state3to4:
    clr reflow_flag
    setb cooling
    setb open
    mov state, #4
    
state3end:
    ljmp Timer2_ISR_done ;finish state 3

state4:
    ;cooling - stay until cool enough to touch
    ;cjne a, #3, state4
    setb cooling
    clr open
    move2byte(y, currtemp)
    mov y+2, #0
    mov y+3, #0
    mov a, #COOLTEMP
    mov x, a
    mov x+1, #0
    mov x+2, #0
    mov x+3, #0
    lcall x_gt_y ;if cooltemp > currtemp set state to 
    jb mf, Reflow_done_suc ;reflow is finished, reset
    ljmp Timer2_ISR_done ;finish state 4
    
Reflow_done_suc:
	setb reflow_suc; reflow finish message
	setb cool
Reflow_done:
    clr reflowon;turn reflow off
    

No_reflow:
    ;not currently reflowing, reset timer state and turn off the ssr
    setb SSRpin
    clr ramptosoak
    clr preheat
    clr ramptopeak
    clr reflow_flag
    clr cooling
    mov a, #0
    mov state, a
    mov reflowtime, a
    mov reflowtime+1,a
    
    
Timer2_ISR_done:
	;pop lower 2 bytes of x and y 
	setb mf
	jnb mfbackup, mf_not_set
	clr mf
    
mf_not_set:

	pop acc
	mov bcd+4, a
	pop acc
	mov bcd+3, a
    pop acc
	mov bcd+2, a
	pop acc
	mov bcd+1, a
	pop acc
	mov bcd, a
	pop acc
    mov y+3, a
    pop acc
    mov y+2, a
    pop acc
    mov y+1, a
    pop acc
    mov y, a
    pop acc
    mov x+3, a
    pop acc
    mov x+2, a
    pop acc
    mov x+1, a 
    pop acc
    mov x, a

    
    pop psw
    pop acc
    reti
	
;---------------------------------------------------------------------------;
convert_temp:
    ;temp conversion for the cold junction, value in x
    mov a, voltage_return
    mov x, a
    mov a, voltage_return+1
    mov x+1, a
    mov a, #0x00
    mov x+2, a
    mov x+3, a
    mov a, #low(410)
    mov y, a
    mov a, #high(410)
    mov y+1, a
    mov a, #0x00
    mov y+2, a 
    mov y+3, a
    lcall mul32 ;x = x * y
    mov a, #low(1023)
    mov y, a
    mov a, #high(1023)
    mov y+1, a
    mov a, #0x00
    mov y+2, a 
    mov y+3, a
    lcall div32 ;x = x / y
    mov a, #low(273)
    mov y, a
    mov a, #high(273)
    mov y+1, a
    mov a, #0x00
    mov y+2, a 
    mov y+3, a
    lcall sub32 ;x = x - y
    ret

convert_temp_ktype:
    ;temp conversion for the ktype
    mov a, voltage_return_ktype
    mov x, a
    mov a, voltage_return_ktype+1
    mov x+1, a
    mov a, #0x00
    mov x+2, a
    mov x+3, a
    mov a, #low(4)
    mov y, a
    mov a, #high(4)
    mov y+1, a
    mov a, #0x00
    mov y+2, a 
    mov y+3, a
    lcall div32 ;x = x / y
    ret
;---------------------------------------------------------------------------;



;---------------------------------------------------------------------------;
; 				MAIN PROGRAM; LCD menu									  	;
;---------------------------------------------------------------------------;
main:
; Initialization
    mov SP, #0x7F
    mov P0M0, #0
    mov P0M1, #0
; clear/init for jerry/john
	mov counter+0, #0
	mov multiple_of_200+0, #0
; clear wesley isr values 
	init_all_var()

; initialize serial port for graphing
	lcall InitSerialPort
	
; initialize for ISR
	setb CE_ADC
	lcall Timer0_Init
	lcall Timer2_Init
	lcall INIT_SPI
	setb EA
	;Preload_Property_n(PreheatTemp, 1, 0x96) ; 0x00000096 = 150
	Preload_Property_n(PreheatTemp, 1, 0x96) ; 0x00000096 = 150
	Preload_Property_n(SoakTime, 	1, 0x5A) ; 0x0000005A = 90
	Preload_Property_n(PeakTemp, 	1, 0xEB) ; 0x000000EB = 235
	Preload_Property_n(PeakTime, 	1, 0x3C) ; 0x0000003C = 60
	Preload_Property_n(LiquidTemp, 	1, 0xDB) ; 0x000000DB = 219
	
	
;1234567890123456;
;----------------;
;prof1<<  prof3  ;
;prof2	  prof4  ;
;----------------;
page1_select_profile:
	jnb back, page1_select_profile
	jnb click, page1_select_profile
	lcall LCD_4BIT
	Display_page1(#prof_1, #prof_2, #prof_3, #prof_4)

main_prof1:
	Display_arrow(1, 6)
	Wait_Milli_Seconds(#250)
loop_main_prof1:
	Check_page1_prof_n(1, 6, prof1)
	sjmp main_prof2
click_prof1?:
	Wait_Milli_Seconds(#50)
	jb click, loop_main_prof1
	lcall page2_profile_1
	
main_prof2:
	Display_arrow(2, 6)
	Wait_Milli_Seconds(#250)
loop_main_prof2:
	Check_page1_prof_n(2, 6, prof2)
	sjmp main_prof3
click_prof2?:
	Wait_Milli_Seconds(#50)
	jb click, loop_main_prof2
	lcall page2_profile_2

main_prof3:
	Display_arrow(1, 15)
	Wait_Milli_Seconds(#250)
loop_main_prof3:
	Check_page1_prof_n(1, 15, prof3)
	sjmp main_prof4
click_prof3?:
	Wait_Milli_Seconds(#50)
	Clear_screen()
	Set_Cursor(1, 1)
	Send_Constant_String(#Python_in_Prog)
	
	lcall InitSerialPort
    mov DPTR, #Hello_World
    lcall SendString
    
    mov	SCON,#0x51
    
	ljmp GetMessage
	
main_prof4:
	Display_arrow(2, 15)
	Wait_Milli_Seconds(#250)
loop_main_prof4:
	Check_page1_prof_n(2, 15, prof4)
	ljmp main_prof1
click_prof4?:
	Wait_Milli_Seconds(#50)
	jb click, loop_main_prof4
	lcall page2_profile_4
	

;1234567890123456;
;----------------;
;Profile 1       ;
;Edit<<  Reflow  ;
;----------------;
page2_profile_1:
	Func_page2_profile_n(1)
	
page2_profile_2:
	Func_page2_profile_n(2)

page2_profile_3:
	Func_page2_profile_n(3)
	
page2_profile_4:
	Func_page2_profile_n(4)
	
	

	
;1234567890123456;
;----------------;
;Preheat Temp << ;
;	Soak Time    ;
;----------------;	
page3_Edit_Profile_1:
	Display_Edit_Profile_n(1)
edit_PreheatTemp_1:
	Edit_Property_Temp_n(PreheatTemp, 1)	
edit_SoakTime_1:
	Edit_Property_Time_n(SoakTime, 1)
edit_PeakTemp_1:
	Edit_Property_Temp_n(PeakTemp, 1)
edit_PeakTime_1:
	Edit_Property_Time_n(PeakTime, 1)
edit_LiquidTemp_1:
	Edit_Property_Temp_n(LiquidTemp, 1)

	
page3_Edit_Profile_2:
	Display_Edit_Profile_n(2)
edit_PreheatTemp_2:
	Edit_Property_Temp_n(PreheatTemp, 2)	
edit_SoakTime_2:
	Edit_Property_Time_n(SoakTime, 2)
edit_PeakTemp_2:
	Edit_Property_Temp_n(PeakTemp, 2)
edit_PeakTime_2:
	Edit_Property_Time_n(PeakTime, 2)
edit_LiquidTemp_2:
	Edit_Property_Temp_n(LiquidTemp, 2)
	
	
page3_Edit_Profile_3:
	;Display_Edit_Profile_n(3)
edit_PreheatTemp_3:
	;Edit_Property_Temp_n(PreheatTemp, 3)	
edit_SoakTime_3:
	;Edit_Property_Time_n(SoakTime, 3)
edit_PeakTemp_3:
	;Edit_Property_Temp_n(PeakTemp, 3)
edit_PeakTime_3:
	;Edit_Property_Time_n(PeakTime, 3)
edit_LiquidTemp_3:
	;Edit_Property_Temp_n(LiquidTemp, 3)
	
	
page3_Edit_Profile_4:
	Display_Edit_Profile_n(4)
edit_PreheatTemp_4:
	Edit_Property_Temp_n(PreheatTemp, 4)	
edit_SoakTime_4:
	Edit_Property_Time_n(SoakTime, 4)
edit_PeakTemp_4:
	Edit_Property_Temp_n(PeakTemp, 4)
edit_PeakTime_4:
	Edit_Property_Time_n(PeakTime, 4)
edit_LiquidTemp_4:
	Edit_Property_Temp_n(LiquidTemp, 4)



;1234567890123456;
;----------------;
;P1 Time   Temp  ;
;	1234 s 0250 C;
;----------------;	
page4_start_Reflow_Profile_1:
	setb ramptosoak
	Start_reflow_n(1)	
page4_start_Reflow_Profile_2:
	setb ramptosoak
	Start_reflow_n(2)
page4_start_Reflow_Profile_3:
	setb ramptosoak
	Start_reflow_n(3)
page4_start_Reflow_Profile_4:
	setb ramptosoak
	Start_reflow_n(4)
	
	
	
	