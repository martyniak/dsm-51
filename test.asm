; ==========================================================================
; DSM-51 microcontroller (INTEL 8051) - P1 & P3 ports pins assignment
; --------------------------------------------------------------------------
; p1.0	-	(out)	COM2 output
; p1.1	-	(out)	external interrupt
; p1.2	-	(out)	isolated output O1
; p1.3	-	(out)	isolated output O2
; p1.4	-	(out)	watchdog
; p1.5	-	(out)	buzzer	
; p1.6	-	(out)	7-segment display
; p1.7	-	(out)	TEST led
; p3.0	-	(in)	rxd		- receive data for serial port (COM1 input)
; p3.1	-	(out)	txd 	- transmit data for serial port (COM1 output)
; p3.2	-	(in)	int0 	- external interrupt 0 (COM2 input)
; p3.3	-	(in)	int1 	- external interrupt 1
; p3.4	-	(in)	t0 		- timer 0 external input (isolated input I1)
; p3.5	-	(in)	t1 		- timer 1 external input (keyboard)
; p3.6	-	(out)	wr		- external data memory write strobe
; p3.7	-	(out)	rd		- external data memory read strobe

; ==========================================================================
; Set up
; --------------------------------------------------------------------------
t0_data         equ 65535-921           ; interuption every 1ms
                                        ; 1 MC = 12/11.0592MHz = 1.0850694 uSec
                                        ; 1000 uSec / 1.0850694 uSec = 921.6
                                        ; 1000 uSec = 1 mSec = 921.6 –> ~922
                                        ; 65535-921 = 64614 = 0xFC66
t_100ms_buf     equ	16                  ; buffer for counting down 100ms
t_1000ms_buf    equ	23                  ; buffer for counting down 1s

heap            equ	100                 ; heap start address

; -------------------------------------
; RAM bit map (32)
; -------------------------------------
t0_flag         bit	02h                 ; flag - set to 1 by t0 counter interuption
t_100ms_flag    bit	03h                 ; flag - set to 1 when t_100ms_buf eq 0
t_1000ms_flag   bit	04h                 ; flag - set to 1 when t_1000ms_buf eq 0

; ==========================================================================
; Start
; --------------------------------------------------------------------------
    org	00h
initialization:
    ljmp    start                       ; jump to start
; -------------------------------------
; t0 interruption
; -------------------------------------
    org	0bh
t0_int:
    orl     tl0, #t0_data mod 256       ; set up t0 counter
    mov	    th0, #t0_data / 256
    setb    t0_flag                     ; set up flag (every 1ms)
    reti
; -------------------------------------
; settings
; -------------------------------------
    org	0100h
start:
    mov	    a, #255
    mov	    p1, a                       ; set up P1 port
    mov	    sp, #heap                   ; set up heap start address
; -------------------------------------
; timer
; -------------------------------------
    mov     tmod, #00100001b            ; t0 in 1st mode ; t1 in 2nd mode
    mov     tcon, #00000000b            ; no interuptions from INT_0 & INT_1
    mov     tl0, #t0_data mod 256       ; set up t0 counter
    mov     th0, #t0_data / 256
; -------------------------------------
; flags and buffers
; -------------------------------------
    clr     t0_flag                     ; set t0_flag to 0

    clr     t_100ms_flag                ; set t_100ms_flag to 0
    mov     t_100ms_buf, #100           ; set t_100ms_buf to 100

    clr     t_1000ms_flag               ; set t_1000ms_flag to 0
    mov     t_1000ms_buf, #10           ; set t_1000ms_buf to 10
; -------------------------------------
; interuptions bits
; -------------------------------------
    setb    et0                         ; enable interuptions for t0
    setb    ea                          ; enable interuptions
    setb    tr0                         ; enable t0 counter

; ==========================================================================
; Main loop
; --------------------------------------------------------------------------
loop:		
    jnb     t0_flag, loop_100ms         ; jump to loop_100ms if t0_flag is 0
    clr     t0_flag                     ; set t0_flag to 0
    lcall   t0_handler                  ; handle t0 interuption

loop_100ms:
    jnb     t_100ms_flag, loop_1000ms   ; jump to loop_1000ms if t_100ms_flag is 0
    clr     t_100ms_flag                ; set t_100ms_flag to 0
    lcall   test_off                    ; led and buzzer off

loop_1000ms:
    jnb     t_1000ms_flag, loop_end     ; jump to loop_end if t_1000ms_flag is 0
    clr     t_1000ms_flag               ; set t_1000ms_flag to 0
    lcall   test_on                     ; led and buzzer on

loop_end:
    ljmp    loop

; -------------------------------------
; handle t0 interuption (every 1 ms)
; -------------------------------------
t0_handler:
    dec     t_100ms_buf                 ; decrement t_100ms_buf
    mov     a, t_100ms_buf              ; move t_100ms_buf to accumulator
    jz      t0_100                      ; jump to t0_100 if accumulator is eq 0
    ret

t0_100:
    setb    t_100ms_flag                ; set t_100ms_flag to 1
    mov     t_100ms_buf, #100           ; restore t_100ms_buf buffer to 100
			
    dec     t_1000ms_buf                ; decrement t_1000ms_buf
    mov     a, t_1000ms_buf             ; move t_1000ms_buf to accumulator
    jz      t0_1000                     ; jump to t0_1000 if accumulator is eq 0
    ret

t0_1000:
    setb    t_1000ms_flag               ; set t_1000ms_flag to 1
    mov     t_1000ms_buf, #10           ; restore t_1000ms_buf buffer to 10
    ret

; ==========================================================================
; TEST led
; --------------------------------------------------------------------------
; desc: every 100ms led is switched off
;       every 1s led is switched on
; --------------------------------------------------------------------------
test_off:
    setb    p1.7                        ; led off
    setb    p1.5                        ; buzzer off
    ret

test_on:
    clr     p1.7                        ; led on
    clr     p1.5                        ; buzzer on
    ret

end
; ==========================================================================