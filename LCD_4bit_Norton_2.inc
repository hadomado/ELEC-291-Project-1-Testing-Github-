cseg

; When using a 22.1184MHz crystal in fast mode
; one cycle takes 1.0/22.1184MHz = 45.21123 ns

;---------------------------------;
; Wait 40 microseconds            ;
;---------------------------------;
Wait40uSec:
	push AR0
	mov R0, #177
L0: 
	nop
	nop
	djnz R0, L0 ; 1+1+3 cycles->5*45.21123ns*177=40us
	pop AR0
    ret

;---------------------------------;
; Wait 'R2' milliseconds          ;
;---------------------------------;
Wait_Milli_Seconds mac
	push AR2
	mov R2, %0
	lcall ?Wait_Milli_Seconds
	pop AR2
endmac

?Wait_Milli_Seconds:
	push AR0
	push AR1
L3: mov R1, #45
L2: mov R0, #166
L1: djnz R0, L1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, L2 ; 22.51519us*45=1.013ms
    djnz R2, L3 ; number of millisecons to wait passed in R2
    pop AR1
    pop AR0
    ret
	
;---------------------------------;
; Toggles the 'E' pin in the LCD  ;
;---------------------------------;
LCD_pulse:
	setb LCD_E
	lcall Wait40uSec
	clr LCD_E
    ret

;---------------------------------;
; Writes acc to LCD in 4-bit mode ;
;---------------------------------;
LCD_byte:
	; Write high 4 bits first
	mov c, ACC.7
	mov LCD_D7, c
	mov c, ACC.6
	mov LCD_D6, c
	mov c, ACC.5
	mov LCD_D5, c
	mov c, ACC.4
	mov LCD_D4, c
    lcall LCD_pulse
    lcall Wait40uSec
	; Write low 4 bits next
	mov c, ACC.3
	mov LCD_D7, c
	mov c, ACC.2
	mov LCD_D6, c
	mov c, ACC.1
	mov LCD_D5, c
	mov c, ACC.0
	mov LCD_D4, c
    lcall LCD_pulse
	ret

;---------------------------------;
; Write data to LCD               ;
;---------------------------------;
WriteData mac
	mov a, %0
	lcall ?WriteData
endmac
	
?WriteData:
	setb LCD_RS
	ljmp LCD_byte

;---------------------------------;
; Write command to LCD            ;
;---------------------------------;
WriteCommand mac
	mov a, %0
	lcall ?WriteCommand
endmac

?WriteCommand:
	clr LCD_RS
	ljmp LCD_byte

;---------------------------------;
; Configure LCD in 4-bit mode     ;
;---------------------------------;
LCD_4BIT:
	clr LCD_E   ; Resting state of LCD's enable pin is zero
	clr LCD_RW  ; We are only writing to the LCD in this program
	
	; After power on, let the LCD start up before initializing
	; NOTE: the preprogrammed power-on delay of 16 ms on the AT89LP52
	; seems to be enough.  That is why this line is commented out.
	; Wait_Milli_Seconds(#40)
	
	; First make sure the LCD is in 8-bit mode and then change to 4-bit mode
	WriteCommand(#0x33)
	WriteCommand(#0x33)
	WriteCommand(#0x32) ; change to 4-bit mode

	; Configure the LCD
	WriteCommand(#0x28)
	WriteCommand(#0x0c)
	WriteCommand(#0x01) ;  Clear screen command (takes some time)

    ;Wait for the clear screen command to finish.
	Wait_Milli_Seconds(#2)
    ret

;---------------------------------;
; Send a constant string to LCD   ;
;---------------------------------;
Send_Constant_String mac
	push dph
	push dpl
	push acc
	mov dptr, %0
	lcall ?Send_Constant_String
	pop acc
	pop dpl
	pop dph
endmac

?Send_Constant_String:
    clr a
    movc a, @a+dptr
    jz ?Send_Constant_String_Done
    lcall ?WriteData
    inc dptr
    sjmp ?Send_Constant_String
?Send_Constant_String_Done:
    ret	

;---------------------------------;
; Set LCD cursor at row, column   ;
;---------------------------------;
Set_Cursor mac
	push acc
	mov a, #%1
	dec a
	lcall ?Set_Cursor_%0 ; Select column and row
	pop acc
endmac

?Set_Cursor_2:
	orl a, #01000000B
?Set_Cursor_1:
	orl a, #10000000B
	ljmp ?WriteCommand ; Select column and row

;---------------------------------;
; Display a BCD number in the LCD ;
;---------------------------------;
Display_BCD mac
	push ar0
	mov r0, %0
	lcall ?Display_BCD
	pop ar0
endmac

?Display_BCD:
	push acc
	; Write most significant digit
	mov a, r0
	swap a
	anl a, #0fh
	orl a, #30h
	lcall ?WriteData
	; write least significant digit
	mov a, r0
	anl a, #0fh
	orl a, #30h
	lcall ?WriteData
	pop acc
	ret

;------------------------------------;
; Display a char in the LCD          ;
;------------------------------------;
Display_char mac
	push acc
	mov a, %0
	lcall ?WriteData
	pop acc
endmac



;1234567890123456;
;----------------;
;prof1<<  prof3  ;
;prof2	  prof4  ;
;----------------;
Display_page1 mac
	Set_Cursor(1, 1)
	Send_Constant_String(#blank)
	Set_Cursor(2, 1)
	Send_Constant_String(#blank)
	Set_Cursor(1, 1)
	Send_Constant_String(%0)
	Set_Cursor(2, 1)
	Send_Constant_String(%1)
	Set_Cursor(1, 10)
	Send_Constant_String(%2)
	Set_Cursor(2, 10)
	Send_Constant_String(%3)
endmac


;------------------------------------------------------;
; Display arrow at position (%0, %1, #arrow) on page 1 ;
; arrow:	db '<<', 0						   		   ;
;------------------------------------------------------;
Display_arrow mac
	Set_Cursor(%0, %1)
	Send_Constant_String(#arrow)
endmac


;------------------------------------------------------;
; Clears arrow at position (%0, %1, #arrow) on page 1 ;
; arrow:	db '<<', 0						   		   ;
;------------------------------------------------------;
Clear_arrow mac
	Set_Cursor(%0, %1)
	Send_Constant_String(#clr_arrow)
endmac

;-------------------------;
;clears screen			  ;
;-------------------------;
Clear_screen mac
	Set_Cursor(1, 1)
	Send_Constant_String(#blank)
	Set_Cursor(2, 1)
	Send_Constant_String(#blank)
endmac


;------------------------------------------------;
; Display prof_n at position (x, y)  on page 1   ;
; and checks for click							 ;
; Display prof_n (x, y, prof)		 			 ;
;------------------------------------------------;
Check_page1_prof_n mac
	jnb click, click_%2?
	jb down, loop_main_%2
	Wait_Milli_Seconds(#50)
	jb down, loop_main_%2
	Set_Cursor(%0, %1)		; clear arrow before going to loop_main_prof2
	Send_Constant_String(#clr_arrow)
endmac




;1234567890123456;
;----------------;
;Profile n       ;
;Edit<<  Reflow  ;
;----------------;
;Display_page2(n);
;----------------;
Display_page2 mac
	Set_Cursor(1, 1)
	Send_Constant_String(#blank)
	Set_Cursor(2, 1)
	Send_Constant_String(#blank)
	Set_Cursor(1, 1)		
	Send_Constant_String(#Profile_%0)
	Set_Cursor(2, 1)
	Send_Constant_String(#Edit)
	Set_Cursor(2, 9)
	Send_Constant_String(#Reflow)
endmac


;--------------------------;
;Profile_n_Edit( n ) 	   ;
;n = profile number		   ;
;--------------------------;
Check_Profile_n_Edit mac
	jnb click, click_Edit_%0?
	jb down, profile_%0_Edit?
	Wait_Milli_Seconds(#50)
	jb down, profile_%0_Edit?
	Clear_arrow(2, 5)
	Display_arrow(2, 15)
	Wait_Milli_Seconds(#250)
endmac


;--------------------------;
;Profile_n_Reflow( n ) 	   ;
;n = profile number		   ;
;--------------------------;
Check_Profile_n_Reflow mac
	jnb click, click_Reflow_%0?
	jb down, profile_%0_Reflow?
	Wait_Milli_Seconds(#50)
	jb down, profile_%0_Reflow?
	Clear_arrow(2, 15)
	Display_arrow(2, 5)
	Wait_Milli_Seconds(#250)
	ljmp profile_%0_Edit?
endmac

;-------------------------;
;Func_page2_profile_n( n );
;n = profile number		  ;
;-------------------------;
Func_page2_profile_n mac

	jnb back, page2_profile_%0
	Wait_Milli_Seconds(#50)
	jnb back, page2_profile_%0
	jnb click, page2_profile_%0
	Wait_Milli_Seconds(#50)
	jnb click, page2_profile_%0
	Display_page2(%0)
	Display_arrow(2, 5)
	
profile_%0_Edit?:
	jnb click, jmp_click_Edit_%0?
profile_%0_back?:
	jb back, profile_%0_Edit?_cont
	Wait_Milli_Seconds(#50)
	jnb back, jmp_page1_select_profile_%0
	sjmp profile_%0_Edit?_cont
jmp_page1_select_profile_%0:
	ljmp page1_select_profile
jmp_click_Edit_%0?:
	lcall click_Edit_%0?
profile_%0_Edit?_cont:
	jb down, profile_%0_Edit?
	Wait_Milli_Seconds(#50)
	jb down, profile_%0_Edit?
	Clear_arrow(2, 5)
	Display_arrow(2, 15)
	Wait_Milli_Seconds(#250)
profile_%0_Reflow?:
	jnb click, click_Reflow_%0?
	jb down, profile_%0_Reflow?
	Wait_Milli_Seconds(#50)
	jb down, profile_%0_Reflow?
	Clear_arrow(2, 15)
	Display_arrow(2, 5)
	Wait_Milli_Seconds(#250)
	ljmp profile_%0_Edit?
click_Edit_%0?:
	Wait_Milli_Seconds(#50)
	jb click, jmp_profile_%0_Edit?
	lcall page3_Edit_Profile_%0
jmp_profile_%0_Edit?:
	lcall profile_%0_Edit?
click_Reflow_%0?:
	Wait_Milli_Seconds(#50)
	jb click, profile_%0_Reflow?
	lcall page4_start_Reflow_Profile_%0
endmac



;-------------------------------------;
;Edit_Property_Temp_n( Property, n )  ;
;Property = PreheatTemp/PeakTemp	  ;
;n = profile #                        ;
;-------------------------------------;
Edit_Property_Temp_n mac

	jnb click, edit_%0_%1
	Clear_screen()
	Set_Cursor(1, 1)
	Display_char(#'1')
	Set_Cursor(1, 3)
	Send_Constant_String(#%0)
	Set_Cursor(2, 8)
	Send_Constant_String(#tempUnit)
	
	Set_Cursor(2, 3)
	mov x+0, %0_%1+0
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
	mov y+1, #0
	mov y+2, #0
	mov y+3, #0
change_%0_%1:
	Set_Cursor(2, 3)
	lcall hex2bcd
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)

	jnb click, enter_%0_%1?
	jnb back, back_%0_%1?
	jb down, change_%0_%1
	Wait_Milli_Seconds(#50)
	jb down, change_%0_%1
	sjmp release_%0_%1
enter_%0_%1?:
	Wait_Milli_Seconds(#50)
	jnb click, release_enter_%0_%1
	sjmp change_%0_%1
release_enter_%0_%1:
	jnb click, release_enter_%0_%1
enter_%0_%1:
	ljmp write_%0_%1
back_%0_%1?:
	Wait_Milli_Seconds(#50)
	jnb back, release_back_%0_%1
	sjmp change_%0_%1
release_back_%0_%1:
	jnb back, release_back_%0_%1
	ljmp edit_%0_%1
release_%0_%1:
	mov y+0, #5
	jnb down, release_%0_%1
	lcall add32
	sjmp change_%0_%1
write_%0_%1:
	lcall bcd2hex
	mov %0_%1+0, x+0
	ljmp page3_Edit_Profile_%1
endmac



;-------------------------------------;
;Edit_Property_Time_n( Property, n )  ;
;Property = SoakTime/PeakTime		  ;
;n = profile #                        ;
;-------------------------------------;
Edit_Property_Time_n mac

	jnb click, edit_%0_%1
	Clear_screen()
	Set_Cursor(1, 1)
	Display_char(#'1')
	Set_Cursor(1, 3)
	Send_Constant_String(#%0)
	Set_Cursor(2, 8)
	Send_Constant_String(#timeUnit)
	
	Set_Cursor(2, 3)
	mov x+0, %0_%1+0
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
	mov y+1, #0
	mov y+2, #0
	mov y+3, #0
change_%0_%1:
	Set_Cursor(2, 3)
	lcall hex2bcd
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)

	jnb click, enter_%0_%1?
	jnb back, back_%0_%1?
	jb down, change_%0_%1
	Wait_Milli_Seconds(#50)
	jb down, change_%0_%1
	sjmp release_%0_%1
enter_%0_%1?:
	Wait_Milli_Seconds(#50)
	jnb click, release_enter_%0_%1
	sjmp change_%0_%1
release_enter_%0_%1:
	jnb click, release_enter_%0_%1
enter_%0_%1:
	ljmp write_%0_%1
back_%0_%1?:
	Wait_Milli_Seconds(#50)
	jnb back, release_back_%0_%1
	sjmp change_%0_%1
release_back_%0_%1:
	jnb back, release_back_%0_%1
	ljmp edit_%0_%1
release_%0_%1:
	mov y+0, #1
	jnb down, release_%0_%1
	lcall add32
	sjmp change_%0_%1
write_%0_%1:
	lcall bcd2hex
	mov %0_%1+0, x+0
	ljmp page3_Edit_Profile_%1
endmac





;-------------------------------------------------------;
;Preload_Property_n( Property, n, val )  				;
;Property = PreheatTemp/Time	                        ;
;n = profile #                                          ;
;-------------------------------------------------------;
Preload_Property_n mac
	mov %0_%1+0, #%2
endmac


;-------------------------------------;
;Display_Edit_Profile_n( n )         ;
;n = profile #                        ;
;-------------------------------------;
Display_Edit_Profile_n mac
	jnb click, page3_Edit_Profile_%0
	Wait_Milli_Seconds(#50)
	jnb click, page3_Edit_Profile_%0
	
	Clear_screen()
	Set_Cursor(1, 1)
	Send_Constant_String(#PreheatTemp)
	Set_Cursor(2, 1)
	Send_Constant_String(#SoakTime)
	Display_arrow(1, 14)
	Wait_Milli_Seconds(#250)
sel_PreheatTemp_%0:
	jb back, sel_PreheatTemp_%0_cont
	Wait_Milli_Seconds(#50)
	jb back, sel_PreheatTemp_%0_cont
	ljmp page2_profile_%0
sel_PreheatTemp_%0_cont:
	jnb click, click_PreheatTemp_%0?
	jb down, sel_PreheatTemp_%0
	Wait_Milli_Seconds(#50)
	jb down, sel_PreheatTemp_%0
	
	Clear_arrow(1, 14)
	Display_arrow(2, 14)
	Wait_Milli_Seconds(#250)
	sjmp sel_SoakTime_%0
click_PreheatTemp_%0?:
	Wait_Milli_Seconds(#50)
	jb click, sel_PreheatTemp_%0
jmp_edit_PreheatTemp_%0:
	ljmp edit_PreheatTemp_%0
	
click_SoakTime_%0?:
	Wait_Milli_Seconds(#50)
	jb click, sel_SoakTime_%0
jmp_edit_soakTime_%0:
	ljmp edit_SoakTime_%0
sel_SoakTime_%0:
	jnb click, click_SoakTime_%0?
	jb down, sel_SoakTime_%0
	Wait_Milli_Seconds(#50)
	jb down, sel_SoakTime_%0
	
	Clear_screen()
	Set_Cursor(1, 1)
	Send_Constant_String(#PeakTemp)
	Set_Cursor(2, 1)
	Send_Constant_String(#PeakTime)
	Wait_Milli_Seconds(#250)
	Display_arrow(1,14)
	sjmp sel_PeakTemp_%0
	
click_PeakTemp_%0?:
	Wait_Milli_Seconds(#50)
	jb click, sel_PeakTemp_%0
jmp_edit_sPeakTemp_%0:
	ljmp edit_PeakTemp_%0
sel_PeakTemp_%0:
	jnb click, click_PeakTemp_%0?
	jb down, sel_PeakTemp_%0
	Wait_Milli_Seconds(#50)
	jb down, sel_PeakTemp_%0
	Clear_arrow(1, 14)
	Display_arrow(2, 14)
	Wait_Milli_Seconds(#250)
	sjmp sel_PeakTime_%0
	
click_PeakTime_%0?:
	Wait_Milli_Seconds(#50)
	jb click, sel_PeakTime_%0
jmp_edit_PeakTime_%0:
	ljmp edit_PeakTime_%0	
sel_PeakTime_%0:
	jnb click, click_PeakTime_%0?
	jb down, sel_PeakTime_%0
	Wait_Milli_Seconds(#50)
	jb down, sel_PeakTime_%0
	
	Clear_screen()
	Set_Cursor(1, 1)
	Send_Constant_String(#LiquidTemp)
	Set_Cursor(2, 1)
	Send_Constant_String(#Confirm_symbol)
	Wait_Milli_Seconds(#250)
	Display_arrow(1,14)
	sjmp sel_LiquidTemp_%0
	
click_LiquidTemp_%0?:
	Wait_Milli_Seconds(#50)
	jb click, sel_LiquidTemp_%0
jmp_edit_LiquidTemp_%0:
	ljmp edit_LiquidTemp_%0
sel_LiquidTemp_%0:
	jnb click, click_LiquidTemp_%0?
	jb down, sel_LiquidTemp_%0
	Wait_Milli_Seconds(#50)
	jb down, sel_LiquidTemp_%0
	Clear_arrow(1, 14)
	Display_arrow(2, 14)
	Wait_Milli_Seconds(#250)
	sjmp sel_Confirm_%0
	
click_Confirm_%0?:
	Wait_Milli_Seconds(#50)
	jb click, sel_Confirm_%0
jmp_Confirm_%0:
	ljmp page2_profile_%0
sel_Confirm_%0:
	jnb click, click_Confirm_%0?
	jb down, sel_Confirm_%0
	Wait_Milli_Seconds(#50)
	jb down, sel_Confirm_%0
	lcall page3_Edit_Profile_%0
endmac



;---------------------;
;Start_reflow_n( n )  ;
;n = profile number   ;
;---------------------;
Start_reflow_n mac
	jnb click, page4_start_Reflow_Profile_%0

	
	Clear_screen()
	Set_Cursor(1, 1)
	Send_Constant_String(#Reflowing_p%0)
	Set_Cursor(1, 4)
	Send_Constant_String(#Time_sym)
	Set_Cursor(1, 11)
	Send_Constant_String(#Temp_sym)
	Set_Cursor(2, 9)
	Send_Constant_String(#timeUnit_sym)
	Set_Cursor(2, 16)
	Send_Constant_String(#tempUnit_sym)
	
	mov ramptosoaktemp+0, PreheatTemp_%0+0	; = preheat temp
	
	mov preheattime+0, SoakTime_%0+0		; = soakTime
	
	mov ramptopeaktemp+0, LiquidTemp_%0+0	; = liquid temp
	
	mov reflowheattime+0, PeakTime_%0+0		; = peak time
	
	mov peak_temp+0, PeakTemp_%0+0			; = max temp before burn
	
	setb reflowon

Update_Reflow_%0:
	Set_Cursor(2, 4)
	mov x+0, reflowtimesec+0
	mov x+1, reflowtimesec+1
	mov x+2, #0
	mov x+3, #0
	lcall hex2bcd
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	
	Set_Cursor(2, 11)
	mov x+0, currtemp+0
	mov x+1, currtemp+1
	mov x+2, #0
	mov x+3, #0
	lcall hex2bcd
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	
	Set_Cursor(1, 9)
state_%0_0:
	jnb ramptosoak, state_%0_1
	Display_char(#'0')
	sjmp after_%0_display_state
state_%0_1:
	jnb preheat, state_%0_2
	Display_char(#'1')
	sjmp after_%0_display_state
state_%0_2:
	jnb ramptopeak, state_%0_3
	Display_char(#'2')
	sjmp after_%0_display_state
state_%0_3:
	jnb reflow_flag, state_%0_4
	Display_char(#'3')
	sjmp after_%0_display_state
state_%0_4:
	; in cooling
	Display_char(#'4')
	
after_%0_display_state:

	jnb back, emerg_stop_%0?
	jb	reflow_suc, reflow_success_%0?
	jb	temp_err, jmp_temp_error_%0?
Update_Reflow_%0_cont:
	ljmp Update_Reflow_%0
jmp_temp_error_%0?:
	ljmp temp_error_%0?
	
emerg_stop_%0?:
	Wait_Milli_Seconds(#50)
	jb back, Update_Reflow_%0_cont
	Clear_screen()
	ljmp emerg_stop_%0
reflow_success_%0?:
	Wait_Milli_Seconds(#50)
	jnb reflow_suc, Update_Reflow_%0_cont
	Clear_screen()
	sjmp reflow_success_%0
temp_error_%0?:
	Wait_Milli_Seconds(#50)
	jnb temp_err, jmp_Update_Reflow_%0_cont
	Clear_screen()
	sjmp temp_error_%0
jmp_Update_Reflow_%0_cont:
	ljmp Update_Reflow_%0_cont
	
emerg_stop_%0:
	clr reflowon
	Set_Cursor(1, 1)
	Send_Constant_String(#emerg_stop)
	jb click, emerg_stop_%0
	sjmp emerg_return_page1_%0
reflow_success_%0:
	clr reflowon
	Set_Cursor(1, 1)
	Send_Constant_String(#reflow_suc_sym)
	jb click, reflow_success_%0
	sjmp succ_return_page1_%0
temp_error_%0:
	clr reflowon
	Set_Cursor(1, 1)
	Send_Constant_String(#temp_err_sym)
	Set_Cursor(2, 1)
	Send_Constant_String(#check_thermo)
	jb click, reflow_success_%0
	sjmp err_return_page1_%0
	
jmp_emerg_stop_%0:
	ljmp emerg_stop_%0
emerg_return_page1_%0:
	Wait_Milli_Seconds(#50)
	jb click, jmp_emerg_stop_%0
	ljmp page1_select_profile
succ_return_page1_%0:
	Wait_Milli_Seconds(#50)
	jb click, reflow_success_%0
	ljmp page1_select_profile
err_return_page1_%0:
	Wait_Milli_Seconds(#50)
	jb click, temp_error_%0
	ljmp page1_select_profile
endmac


;---------------------;
;Start_reflow_py( n ) ;
;n = profile number   ;
;---------------------;
Start_reflow_py mac
	
	Clear_screen()
	Set_Cursor(1, 1)
	Send_Constant_String(#Reflowing_p%0)
	Set_Cursor(1, 4)
	Send_Constant_String(#Time_sym)
	Set_Cursor(1, 11)
	Send_Constant_String(#Temp_sym)
	Set_Cursor(2, 9)
	Send_Constant_String(#timeUnit_sym)
	Set_Cursor(2, 16)
	Send_Constant_String(#tempUnit_sym)
	
	mov ramptosoaktemp+0, PreheatTemp_%0+0	; = preheat temp
	
	mov preheattime+0, SoakTime_%0+0		; = soakTime
	
	mov ramptopeaktemp+0, LiquidTemp_%0+0	; = liquid temp
	
	mov reflowheattime+0, PeakTime_%0+0		; = peak time
	
	mov peak_temp+0, PeakTemp_%0+0			; = max temp before burn
	
	setb reflowon
	
	ljmp Update_Reflow_%0
endmac



;---------------------------------------;
init_all_var mac
clr ramptosoak
clr preheat
clr ramptopeak
clr reflow_flag
clr cooling
clr reflowon
clr reflow_suc
clr temp_err
clr transition
clr open
clr cool
clr transition_on
clr open_on
clr cool_on
clr beeper_on
clr skip_beeper
clr six_beeps_flag

mov a, #0
mov Count1ms+0, a
mov Count1ms+1, a
mov Count250ms, a
mov BCD_counter, a
mov reflowtime+0, a
mov reflowtime+1, a
mov state, a
mov ktypetemp+0, a
mov ktypetemp+1, a
mov coldjtemp+0, a
mov coldjtemp+1, a

mov voltage_return+0, a
mov voltage_return+1, a
mov voltage_return_ktype+0, a
mov voltage_return_ktype+1, a	
mov counter, a
mov multiple_of_200, a

mov x+0, a
mov x+1, a
mov x+2, a
mov x+3, a

mov y+0, a
mov y+1, a
mov y+2, a
mov y+3, a

mov bcd+0, a
mov bcd+1, a
mov bcd+2, a
mov bcd+3, a
mov bcd+4, a

mov reflowtimesec+0, a
mov reflowtimesec+1, a

mov currtemp+0, a
mov currtemp+1, a
endmac



