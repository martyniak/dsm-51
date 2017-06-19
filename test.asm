;		  set up
;		----------
t0_data			equ	65535-921		; interuption every 1ms
									; 1 MC = 12/11.0592MHz = 1.0850694 uSec
									; 1000 uSec / 1.0850694 uSec = 921.6
 									; 1000 uSec = 1 mSec = 921.6 –> ~922
 									; 65535-921 = 64614 = 0xFC66

timer100_buf	equ	16				; buffer for counting down 100ms
timer10_buf		equ	23				; buffer for counting down 1s

heap			equ	100				; heap start address

;			  ram bit map (32)
;			--------------------------------------------
t0_flag			bit	02h				; flag - set to 1 by t0 counter interuption
timer100_flag	bit	03h				; flag - set to 1 when timer100_buf eq 0
timer10_flag	bit	04h				; flag - set to 1 when timer10_buf eq 0

;		  start
;		---------
			org	00h
initialization:
			ljmp	start				; jump to start

;		  t0 interruption
;		-------------------
			org	0bh
t0_int:
			orl	tl0,#t0_data mod 256	; set up t0 counter
			mov	th0,#t0_data / 256
			setb	t0_flag				; set up flag (every 1ms)
			reti

;		  settings
;		------------
			org	0100h
start:
			mov	a,#255
			mov	p1,a				; set up P1 port
			mov	sp,#heap			; set up heap start address

;			  timer
;			---------
			mov	tmod,#00100001b			; t0 in 1st mode ; t1 in 2nd mode
			mov	tcon,#00000000b			; no interuptions from INT_0 & INT_1
			mov	tl0,#t0_data mod 256	; set up t0 counter
			mov	th0,#t0_data / 256

;			  flags and buffers
;			---------------------
			clr	t0_flag				; set t0_flag to 0

			clr	timer100_flag		; set timer100_flag to 0
			mov	timer100_buf,#100	; set timer100_buf to 100

			clr	timer10_flag		; set timer10_flag to 0
			mov	timer10_buf,#10		; set timer10_buf to 10

;			  interuptions bits
;			---------------------
			setb	et0				; enable interuptions for t0
			setb	ea				; enable interuptions
			setb	tr0				; enable t0 counter

;		  main loop
;		-------------
main:		
			jnb		t0_flag,main_100ms		; jump to main_100ms if t0_flag is 0
			clr		t0_flag					; set t0_flag to 0
			lcall	t0_handler				; handle t0 interuption
main_100ms:
			jnb		timer100_flag,main_1000ms	; jump to main_1000ms if timer100_flag is 0
			clr		timer100_flag				; set timer100_flag to 0
			lcall	test_off					; led and buzzer off
main_1000ms:
			jnb		timer10_flag,main_end	; jump to main_end if timer10_flag is 0
			clr		timer10_flag			; set timer10_flag to 0
			lcall	test_on					; led and buzzer on
main_end:
			ljmp	main

;		  handle t0 interuption (every 1 ms)
;		--------------------------------------
t0_handler:
			dec		timer100_buf	; decrement timer100_buf
			mov		a,timer100_buf 	; move timer10_buf to accumulator
			jz		t0_100			; jump to t0_1000 if accumulator is eq 0
			ret
t0_100:
			setb	timer100_flag		; set timer100_flag to 1
			mov		timer100_buf,#100	; restore timer100_buf buffer to 100
			
			dec		timer10_buf		; decrement timer10_buf
			mov		a,timer10_buf	; move timer10_buf to accumulator
			jz		t0_1000			; jump to t0_1000 if accumulator is eq 0
			ret
t0_1000:
			setb 	timer10_flag	; set timer10_flag to 1
			mov		timer10_buf,#10	; restore timer10_buf buffer to 10
			ret

;		  led test
;		------------
;		desc: 	every 100ms led is switched off
;				every 1s led is switched on
;		---------------------------------------------------------------------------
test_off:
			setb	p1.7	; led on
			setb	p1.5	; buzzer on
			ret

test_on:
			clr		p1.7	; led off
			clr		p1.5	; buzzer off
			ret
end