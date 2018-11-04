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
t0_data         equ 65535-921               ; interuption every 1ms
                                            ; 1 MC = 12/11.0592MHz = 1.0850694 uSec
                                            ; 1000 uSec / 1.0850694 uSec = 921.6
                                            ; 1000 uSec = 1 mSec = 921.6 –> ~922
                                            ; 65535-921 = 64614 = 0xFC66
csds			equ	0ff30h			        ; selection indicator buffer
csdb			equ	0ff38h			        ; data buffer
    
t_4ms_buf       equ	16                      ; buffer for counting down 4ms
t_100ms_buf     equ	17                      ; buffer for counting down 100ms
t_1000ms_buf    equ	18                      ; buffer for counting down 1s
    
offset_sec  	equ	19				        ; numbers array offset for seconds
offset_min	    equ	20				        ; numbers array offset for minutes
offset_hur	    equ	21				        ; numbers array offset for hours
    
displays_buf	equ	25			            ; RAM memory allocation for displays buffer
offset_dis		equ	31				        ; display array offset
    
heap            equ	100                     ; heap start address
    
; ------------------------------------- 
; RAM bit map (32)  
; ------------------------------------- 
t0_flag         bit	02h                     ; flag - set to 1 by t0 counter interuption
t_4ms_flag      bit	03h                     ; flag - set to 1 when t_4ms_buf eq 0
t_100ms_flag    bit	04h                     ; flag - set to 1 when t_100ms_buf eq 0
t_1000ms_flag   bit	05h                     ; flag - set to 1 when t_1000ms_buf eq 0

; ==========================================================================
; Start
; --------------------------------------------------------------------------
    org	00h
initialization:
    ljmp    start                           ; jump to start
; ------------------------------------- 
; t0 interruption   
; ------------------------------------- 
    org	0bh 
t0_int: 
    orl     tl0, #t0_data mod 256           ; set up t0 counter
    mov	    th0, #t0_data / 256 
    setb    t0_flag                         ; set up flag (every 1ms)
    reti    
; ------------------------------------- 
; settings  
; ------------------------------------- 
    org	0100h   
start:  
    mov	    a, #255 
    mov	    p1, a                           ; set up P1 port
    mov	    sp, #heap                       ; set up heap start address
; ------------------------------------- 
; timer 
; ------------------------------------- 
    mov     tmod, #00100001b                ; t0 in 1st mode ; t1 in 2nd mode
    mov     tcon, #00000000b                ; no interuptions from INT_0 & INT_1
    mov     tl0, #t0_data mod 256           ; set up t0 counter
    mov     th0, #t0_data / 256 
; ------------------------------------- 
; flags and buffers 
; ------------------------------------- 
    clr     t0_flag                         ; set t0_flag to 0

    clr     t_4ms_flag                      ; set t_4ms_flag to 0
    mov     t_4ms_buf, #4                   ; set t_4ms_buf to 4

    clr     t_100ms_flag                    ; set t_100ms_flag to 0
    mov     t_100ms_buf, #25                ; set t_100ms_buf to 100

    clr     t_1000ms_flag                   ; set t_1000ms_flag to 0
    mov     t_1000ms_buf, #10               ; set t_1000ms_buf to 10

    mov	    offset_dis, #0                  ; offset_dis to 0

; ------------------------------------- 
; set time to 23:59:55  
; ------------------------------------- 
    mov	displays_buf, #01101101b            ; dispaly 5
    mov	displays_buf+1, #01101101b		    ; dispaly 5
    mov	offset_sec, #01010101b	            ; 0101 - 5, 0101 - 5

    mov	displays_buf+2, #01101111b		    ; dispaly 9
    mov	displays_buf+3, #01101101b		    ; dispaly 5
    mov	offset_min, #01011001b	            ; 0101 - 5, 1001 - 9

    mov	displays_buf+4, #01001111b		    ; dispaly 3
    mov	displays_buf+5, #01011011b		    ; dispaly 2
    mov	offset_hur, #00100011b	            ; 0010 - 2, 0011 - 3

; ------------------------------------- 
; interuptions bits 
; ------------------------------------- 
    setb    et0                             ; enable interuptions for t0
    setb    ea                              ; enable interuptions
    setb    tr0                             ; enable t0 counter

; ==========================================================================
; Main loop
; --------------------------------------------------------------------------
loop:		
    jnb     t0_flag, loop_4ms               ; jump to loop_100ms if t0_flag is 0
    clr     t0_flag                         ; set t0_flag to 0
    lcall   t0_handler                      ; handle t0 interuption

loop_4ms:   
    jnb     t_4ms_flag, loop_100ms          ; jump to loop_100ms if t_4ms_flag is 0
    clr     t_4ms_flag                      ; set t_4ms_flag to 0
    lcall   display_handler                 ; lit 7-segment dispaly

loop_100ms: 
    jnb     t_100ms_flag, loop_1000ms       ; jump to loop_1000ms if t_100ms_flag is 0
    clr     t_100ms_flag                    ; set t_100ms_flag to 0

loop_1000ms:    
    jnb     t_1000ms_flag, loop_end         ; jump to loop_end if t_1000ms_flag is 0
    clr     t_1000ms_flag                   ; set t_1000ms_flag to 0
    lcall   clock                           ; clock

loop_end:   
    ljmp    loop    

; ------------------------------------- 
; handle t0 interuption (every 1 ms)    
; ------------------------------------- 
t0_handler: 
    dec     t_4ms_buf                       ; decrement t_100ms_buf
    mov     a, t_4ms_buf                    ; move t_100ms_buf to accumulator
    jz      t0_4                            ; jump to t0_100 if accumulator is eq 0
    ret 

t0_4:   
    setb    t_4ms_flag                      ; set t_100ms_flag to 1
    mov     t_4ms_buf, #4                   ; restore t_100ms_buf buffer to 100
    
    dec     t_100ms_buf                     ; decrement t_1000ms_buf
    mov     a, t_100ms_buf                  ; move t_1000ms_buf to accumulator
    jz      t0_100                          ; jump to t0_1000 if accumulator is eq 0
    ret 

t0_100: 
    setb    t_100ms_flag                    ; set t_100ms_flag to 1
    mov     t_100ms_buf, #25                ; restore t_100ms_buf buffer to 100
    
    dec     t_1000ms_buf                    ; decrement t_1000ms_buf
    mov     a, t_1000ms_buf                 ; move t_1000ms_buf to accumulator
    jz      t0_1000                         ; jump to t0_1000 if accumulator is eq 0
    ret 

t0_1000:    
    setb    t_1000ms_flag                   ; set t_1000ms_flag to 1
    mov     t_1000ms_buf, #10               ; restore t_1000ms_buf buffer to 10
    ret

; ==========================================================================
; Clock
; --------------------------------------------------------------------------
; desc: real time clock
; --------------------------------------------------------------------------
clock:
    mov	    a, offset_sec			        ; copy offset_sec to accumulator
    add	    a, #00000001b			        ; increment accumulator
    da	    a					            ; decimal adjust
    mov	    offset_sec, a		            ; copy accumulator to offset_sec
    mov	    a, offset_sec		            ; copy offset_sec to accumulator
    cjne    a, #01100000b, display_seconds  ; if a is not equal 01100000b (60) jump to display_seconds
    mov	    a, #00000000b                   ; assing 0 to a
    mov     offset_sec, a			        ; assing 0 to offset_sec


    mov	    a, offset_min			        ; copy offset_min to accumulator
    add	    a, #00000001b			        ; increment accumulator
    da	    a					            ; decimal adjust
    mov	    offset_min, a			        ; copy accumulator to offset_min
    mov	    a, offset_min			        ; copy offset_min to accumulator
    cjne	a, #01100000b, display_minutes  ; if a is not equal 01100000b (60) jump to display_minutes
    mov	    a, #00000000b			        ; assing 0 to a
    mov	    offset_min, a			        ; assing 0 to offset_min


    mov	    a, offset_hur			        ; copy offset_hur to accumulator
    add	    a, #00000001b			        ; increment accumulator
    da	    a					            ; decimal adjust
    mov	    offset_hur, a			        ; copy accumulator to offset_hur
    mov	    a, offset_hur			        ; copy offset_hur to accumulator
    cjne	a, #00100100b, display_hours	; if a is not equal 00100100b (24) jump to display_hours
                                            

    mov	    displays_buf, #00111111b		; dispaly 0
    mov	    displays_buf+1, #00111111b		; dispaly 0
    mov	    offset_sec, #00000000b	        ; 0000 - 0, 0000 - 0

    mov	    displays_buf+2, #00111111b		; dispaly 0
    mov	    displays_buf+3, #00111111b		; dispaly 0
    mov	    offset_min, #00000000b	        ; 0000 - 0, 0000 - 0

    mov	    displays_buf+4, #00111111b		; dispaly 0
    mov	    displays_buf+5, #00111111b		; dispaly 0
    mov	    offset_hur, #00000000b	        ; 0000 - 0, 0000 - 0			

    ret

; -------------------------------------
; seconds
; -------------------------------------
display_seconds:
    mov	    dptr, #numbers	                ; set dptr as a pointer to 1st element of the array
    lcall	get_right
    movc	a, @a+dptr			            ; assign accumulator value from numbers array of index accumulator+1
    mov	    displays_buf, a			        ; assign display_but value to accumulator
			

    mov	    dptr, #numbers	                ; set dptr as a pointer to 1st element of the array
    mov	    a, offset_sec
    lcall   get_left	
    movc	a, @a+dptr			            ; assign accumulator value from numbers array of index accumulator+1
    mov	    displays_buf+1, a		        ; assign display_but+1 value to accumulator
    ret

; -------------------------------------
; minutes
; -------------------------------------
display_minutes:
    mov	    displays_buf, #00111111b
    mov	    displays_buf+1, #00111111b

    mov	    dptr, #numbers	                ; set dptr as a pointer to 1st element of the array
    lcall	get_right
    movc	a, @a+dptr			            ; assign accumulator value from numbers array of index accumulator+1
    mov	    displays_buf+2, a		        ; assign display_but+2 value to accumulator
			
    mov	    dptr, #numbers	                ; set dptr as a pointer to 1st element of the array
    mov	    a, offset_min
    lcall   get_left
    movc	a, @a+dptr			            ; assign accumulator value from numbers array of index accumulator+1
    mov	    displays_buf+3, a		        ; assign display_but+3 value to accumulator
    ret

; -------------------------------------
; hours
; -------------------------------------
display_hours:
    mov	    displays_buf, #00111111b
    mov	    displays_buf+1, #00111111b
    mov	    displays_buf+2, #00111111b
    mov	    displays_buf+3, #00111111b
			
    mov	    dptr, #numbers	                ; set dptr as a pointer to 1st element of the array
    lcall	get_right
    movc	a, @a+dptr			            ; assign accumulator value from numbers array of index accumulator+1
    mov	    displays_buf+4, a		        ; assign display_but+4 value to accumulator
			
    mov	    dptr, #numbers	                ; set dptr as a pointer to 1st element of the array
    mov	    a, offset_hur
    lcall   get_left
    movc	a, @a+dptr			            ; assign accumulator value from numbers array of index accumulator+1
    mov	    displays_buf+5, a		        ; assign display_but+5 value to accumulator
    ret

; ==========================================================================
; Display handler
; --------------------------------------------------------------------------
display_handler:
    setb	p1.6					        ; display on

    mov	    dptr, #displays			        ; set dptr as a pointer to 1st element of the array
    mov	    a, offset_dis			        ; assign offser to accumulator
    movc	a, @a+dptr				        ; assign accumulator value from displays array of index accumulator+1
    mov	    dptr, #csds				        ; set dptr as a pointer to dispaly
    movx	@dptr, a				        ; lit proper segment

    mov 	a, #displays_buf		        ; copy displays_buf do accumulator
    add	    a, offset_dis			        ; add offset_dis and accumulator
    mov	    r0, a					        ; copy accumulator to r0
    mov	    a, @r0					        ; copy r0 to accumulator
    mov	    dptr, #csdb				        ; copy csdb to dptr pointer
    movx	@dptr, a				        ; lit proper segment
    
    clr	    p1.6					        ; display off 
    
    inc	    offset_dis				        ; increment offset_dis
    mov	    a, offset_dis			        ; copy offset_dis to accumulator
    cjne	a, #6, display_handler_end      ; if accumulator is not equal 6  jump to display_handler_end

    mov	    offset_dis, #00000000b

display_handler_end:
	ret

; ==========================================================================
; Bit shift
; --------------------------------------------------------------------------
; 01000101 (45)	-> 	00000100 (4)
; -------------------------------------
get_left:
	clr	c			
    rrc	a
    clr	c
    rrc	a
    clr	c
    rrc	a
    clr	c
    rrc	a
	ret

; -------------------------------------
; 01000101 (45)	-> 	00000101 (5)
; -------------------------------------
get_right:
    clr	c
    rlc	a
    clr	c
    rlc	a
    clr	c
    rlc	a
    clr	c
    rlc	a
    clr	c
    rrc	a
    clr	c
    rrc	a
    clr	c
    rrc	a
    clr	c
    rrc	a
    ret

; ==========================================================================
; Arrays
; --------------------------------------------------------------------------
numbers:
;       hgfedcba
    db	00111111b			; 0			<_-_-_a-_-_->
    db	00000110b			; 1			|           |
    db	01011011b			; 2			f           b
    db	01001111b			; 3			|           |
    db	01100110b			; 4			<_-_-_g-_-_->
    db	01101101b			; 5			|           |
    db	01111101b			; 6			e           c
    db	00000111b			; 7			|           |	<_-_-_>
    db	01111111b			; 8			<_-_-_d-_-_->	|  h  |
    db	01101111b			; 9	                        <_-_-_>

displays:
    db	00000001b
    db	00000010b
    db	00000100b
    db	00001000b
    db	00010000b
    db	00100000b

end
; ==========================================================================