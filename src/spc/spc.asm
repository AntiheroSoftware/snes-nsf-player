.org $400

;========================================
;       NES Registers
;----------------------------------------
sq4000          = $40   ; $4000
sq4001          = $41   ; $4001
sq4002          = $42   ; $4002
sq4003          = $43   ; $4003
sq4004          = $44   ; $4004
sq4005          = $45   ; $4005
sq4006          = $46   ; $4006
sq4007          = $47   ; $4007
tr4008          = $48   ; $4008
tr4009          = $49   ; $4009
tr400A          = $4A   ; $400A
tr400B          = $4b   ; $400B
no400C          = $4C   ; $400C
no400D          = $4D   ; $400D
no400E          = $4E   ; $400E
no400F          = $4F   ; $400F
pcm_freq        = $50   ; $4010
pcm_raw         = $51   ; $4011
pcm_addr        = $52   ; $4012
pcm_length      = $53   ; $4013

sound_ctrl      = $55   ; $4015
no4016	        = $56   ; $4016

;========================================
;       SPC Memory
;----------------------------------------

pulse0duty          = $60
pulse0dutyold       = $61
pulse1duty          = $62
pulse1dutyold       = $63
puls0_sample        = $64
puls1_sample        = $65
puls0_sample_old    = $66
puls1_sample_old    = $67
temp1               = $68
temp2               = $69
temp3               = $6A
temp4               = $6B
temp5               = $6C
temp6               = $6D
temp7               = $6E
temp8               = $6F
old4003             = $70

sweeptemp1          = $78
sweeptemp2          = $79
sweep_freq_lo       = $7A
sweep_freq_hi       = $7B

linear_count_lo     = $7D
linear_count_hi     = $7E
timer3count_lo      = $7F
timer3count_hi      = $80
sweep1              = $81
sweep2              = $82
sweep_freq_lo2      = $83
sweep_freq_hi2      = $84
timer3val           = $85
decay1volume        = $86
decay1rate          = $87
decay_status        = $88
decay2volume        = $89
decay2rate          = $8A
decay3volume        = $8B
decay3rate          = $8C
add_temp            = $8D

;========================================


start:
        clrp                    ; clear direct page flag (DP = $0000-$00FF)
        mov x,#$F0
        mov SP,x

        mov a,#00110000b
        mov $F1,a               ; clear all ports, disable timers

        call !reset_dsp         ; clear DSP registers
        call !set_directory     ; set sample directory

        mov $F2,#$5D            ; directory offset
        mov $F3,#$02            ; $200

        mov $F2,#$05            ; ADSR off, GAIN enabled
        mov $F3,#0
        mov $F2,#$15            ; ADSR off, GAIN enabled
        mov $F3,#0
        mov $F2,#$25
        mov $F3,#0
        mov $F2,#$35
        mov $F3,#0

        mov $F2,#$07            ; infinite gain
        mov $F3,#$1F
        mov $F2,#$17            ; infinite gain
        mov $F3,#$1F
        mov $F2,#$27
        mov $F3,#$1F
        mov $F2,#$37
        mov $F3,#$1F


        mov $F2,#$24            ; sample # for triangle
        mov $F3,#$04

        mov $F2,#$34
        mov $F3,#$00            ; sample # for noise


        mov $F2,#$4C            ; key on
        mov $F3,#00001111b

        mov $F2,#$0C            ; main vol L
        mov $F3,#$7F
        mov $F2,#$1C            ; main vol R
        mov $F3,#$7F

        mov $F2,#$6C
        mov $F3,#00100000b      ; soft reset, mute, and echo disabled

        mov $F2,#$3D            ; noise on voice 3
        mov $F3,#00001000b

        call !enable_timer3

next_xfer:
        mov $F4,#$7D            ; move $7D to port 0 (SPC ready)
wait:
        call !check_timer3
        call !check_timers
        call !check_timers2
        mov a,$F4               ; wait for port 0 to be $D7 (CPU ready)
        cmp a,#$D7
        bne wait
        mov $F4,a               ; reply to CPU with $D7 (begin transfer)

        mov x,#0
xfer:
        cmp x,$F4               ; wait for port 0 to have current byte #
        bne xfer

        mov a,$F5               ; load data on port 1
        mov $40+x,a             ; store data at $40 - $55
        mov $F4,x               ; reply to CPU on port 0

        inc x
        cmp x,#$17
        bne xfer

;=====================================


;-------------------------------------
square0:

        mov a,sound_ctrl
        and a,#00000001b
        bne sq0_enabled
silence:
        mov $F2,#0
        mov $F3,#0
        mov $F2,#1
        mov $F3,#0
        jmp !square1

sq0_enabled:

;-------------------------------------
                                ; emulate duty cycle (select sample #)
                                ; check first the octave sample to be played

        mov a,sq4000            ; emulate duty cycle
        and a,#11000000b
        clrc
        rol a
        rol a
        rol a

        mov puls0_sample,a
        cmp a,puls0_sample_old
        beq sq1_no_change

sq1_sample_change:

        mov $F2,#$04            ; sample # reg
        mov $F3,puls0_sample

        mov $F2,#$4C            ; key on
        mov $F3,#00000001b

sq1_no_change:

        mov puls0_sample_old,puls0_sample

;        mov puls0_sample,#0
;
;        mov y,a
;
;        mov a,sq4003
;        and a,#00000111b
;        mov x,a
;        mov a,y
;;        cmp x,#00000101b
;;        beq pitch0
;        cmp x,#00000110b
;        beq pitch0
;        cmp x,#00000111b
;        beq pitch0
;
;        clrc
;        adc a,#4
;        mov puls0_sample,#1
;
;pitch0:
;        mov $F2,#$04            ; sample #
;        mov $F3,a
;
;        mov $F2,#$4C            ; key on
;        mov $F3,#00000001b
;no_change:
;        mov pulse0dutyold,pulse0duty
;        mov puls0_sample_old,puls0_sample

;-------------------------------------
; freq sweep test

;        mov a,$41
;        and a,#10000000b
;        beq skipsweep0
;        mov a,$41
;
;        mov sweeptemp1,$42
;        mov sweeptemp2,$43
;        and sweeptemp2,#00000111b
;
;        mov a,$41
;        and a,#00000111b
;        beq skipsweep0
;        mov x,a
;
;keepshifting0:
;        clrc
;        ror sweeptemp2
;        ror sweeptemp1
;
;        dec x
;        bne keepshifting0
;
;        and $43,#00000111b
;
;        mov a,sweeptemp1
;        mov y,sweeptemp2
;
;        addw ya,$42
;        mov a,$42
;        mov y,$43
;
;
;        mov a,$42
;        clrc
;        rol a
;        push psw
;        clrc
;        adc a,#freqtable & 255
;        rol temp3
;        mov temp1,a
;        pop psw
;        mov a,$43
;        rol a
;        ror temp3
;        adc a,#freqtable >> 8
;        mov temp2,a
;
;        mov y,#0
;        mov a,[temp1]+y
;        mov $F2,#2
;        mov $F3,a
;
;        inc y
;        mov a,[temp1]+y
;        mov $F2,#3
;        mov $F3,a
;
;        jmp !nextsq0
;
;
;skipsweep0:

;-------------------------------------

                                ; check if sweeps are enabled
        mov a,$41
        and a,#10000000b
        beq skip00
        mov a,$41
        and a,#00000111b
        beq skip00

        call !check_timers
        bra nextsq0

skip00:


        mov a,sq4003            ; check if freq is 0 or too high
        and a,#00000111b
        bne ok1
        mov a,sq4002
        beq silence
        cmp a,#1
        beq silence
        cmp a,#2
        beq silence
        cmp a,#3
        beq silence
        cmp a,#4
        beq silence
        cmp a,#5
        beq silence
        cmp a,#6
        beq silence
ok1:




        and $43,#00000111b

        mov a,$42
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable & 255
        rol temp3
        mov temp1,a
        pop psw
        mov a,$43
        rol a
        ror temp3 & 255
        adc a,#freqtable >> 8
        mov temp2,a

        mov y,#0
        mov a,[temp1]+y
        mov $F2,#2
        mov $F3,a

        inc y
        mov a,[temp1]+y
        mov $F2,#3
        mov $F3,a

;-----------------------------------------------

nextsq0:

        mov a,sq4000            ; check volume decay disable
        and a,#00010000b
        bne decay_disabled

        call !check_timer3

        mov a,$56
        and a,#00000001b
        beq no_reset

;        mov a,sq4000
;        and a,#00001111b
;        mov x,a
;        mov a,!volume_decay_rates+X
;        mov decay1rate,a
        bra no_reset


volume_decay_rates:
        .db 3
        .db 6
        .db 9
        .db 12
        .db 15
        .db 18
        .db 21
        .db 24
        .db 27
        .db 30
        .db 33
        .db 36
        .db 40
        .db 44
        .db 48
        .db 52
        .db 56

;        mov a,sq4000
;        and a,#00001111b
;        mov x,a
;        mov a,!volume_decay_table+X
;        mov $F2,#$07
;        mov $F3,a
;
;        mov $F2,#$08           ; envx
;        mov $F3,#01111000b
;
;
;        mov $F2,#$04
;        mov $F3,puls0_sample
;        mov $F2,#$4C
;        mov $F3,#00000001b
;
;        mov a,#$1F
;        mov $F2,#$08
;        mov $F3,a
;
;        bra write_volume

decay_disabled:
        mov $F2,#$07
        mov $F3,#$1F

        mov a,no4016
        and a,#20h
        beq mono

        mov a,sq4000
        and a,#00001111b
        asl a
        asl a
        asl a
;        asl a

        mov $F2,#0
        mov $F3,a
        mov $F2,#1
        mov $F3,#0
        bra no_reset


mono:
        mov a,sq4000            ; emulate volume, square 0
        and a,#00001111b
        asl a
        asl a
        asl a

write_volume:
        mov $F2,#0              ; write volume
        mov $F3,a
        mov $F2,#1
        mov $F3,a
;        mov $F3,#0

no_reset:



;=====================================

;-------------------------------------
square1:

        mov a,sound_ctrl
        and a,#00000010b
        bne sq1_enabled
silence2:
        mov $F2,#$10
        mov $F3,#0
        mov $F2,#$11
        mov $F3,#0
        jmp !triangle

sq1_enabled:


;-------------------------------------
                                ; emulate duty cycle (select sample #)
                                ; check first the octave sample to be played

        mov a,sq4004            ; emulate duty cycle
        and a,#11000000b
        clrc
        rol a
        rol a
        rol a

        mov puls1_sample,a
        cmp a,puls1_sample_old
        beq sq2_no_change

sq2_sample_change:

        mov $F2,#$14            ; sample # reg
        mov $F3,puls1_sample

        mov $F2,#$4C            ; key on
        mov $F3,#00000010b

sq2_no_change:

        mov puls1_sample_old,puls1_sample





;        mov puls0_sample,#0
;
;        mov y,a
;
;        mov a,sq4003
;        and a,#00000111b
;        mov x,a
;        mov a,y
;;        cmp x,#00000101b
;;        beq pitch0
;        cmp x,#00000110b
;        beq pitch0
;        cmp x,#00000111b
;        beq pitch0
;
;        clrc
;        adc a,#4
;        mov puls0_sample,#1
;
;pitch0:
;        mov $F2,#$04            ; sample #
;        mov $F3,a
;
;        mov $F2,#$4C            ; key on
;        mov $F3,#00000001b
;no_change:
;        mov pulse0dutyold,pulse0duty
;        mov puls0_sample_old,puls0_sample
;-------------------------------------


                                ; check if sweeps are enabled
        mov a,$45
        and a,#10000000b
        beq skip01
        mov a,$45
        and a,#00000111b
        beq skip01

        call !check_timers2
        bra nextsq1

skip01:


        mov a,sq4007            ; check if freq is 0 or too high
        and a,#00000111b
        bne ok2
        mov a,sq4006
        beq silence2
        cmp a,#1
        beq silence2
        cmp a,#2
        beq silence2
        cmp a,#3
        beq silence2
        cmp a,#4
        beq silence2
        cmp a,#5
        beq silence2
        cmp a,#6
        beq silence2
ok2:


        and $47,#00000111b

        mov a,$46
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable & 255
        rol temp3
        mov temp1,a
        pop psw
        mov a,$47
        rol a
        ror temp3
        adc a,#freqtable >> 8
        mov temp2,a

        mov y,#0
        mov a,[temp1]+y
        mov $F2,#$12
        mov $F3,a

        inc y
        mov a,[temp1]+y
        mov $F2,#$13
        mov $F3,a

;--------------------------------------

nextsq1:

        mov a,sq4004            ; check decay disabled
        and a,#00010000b
        bne decay_disabled2

        mov a,$56
        and a,#00000010b
        beq no_reset2
        bra no_reset2

;        mov a,sq4004
;        and a,#00001111b
;        mov x,a
;        mov a,!volume_decay_table+X
;        mov $F2,#$17
;        mov $F3,a
;
;        mov $F2,#$18           ; envx
;        mov $F3,#01111000b
;
;
;        mov $F2,#$14
;        mov $F3,puls0_sample
;        mov $F2,#$4C
;        mov $F3,#00000010b
;
;        mov a,#$1F
;        mov $F2,#$18
;        mov $F3,a
;
;        bra write_volume2

decay_disabled2:
        mov $F2,#$17
        mov $F3,#$1F

        mov a,no4016
        and a,#20h
        beq mono2

        mov a,sq4004
        and a,#00001111b
        asl a
        asl a
        asl a
;        asl a

        mov $F2,#$10
        mov $F3,#0
        mov $F2,#$11
        mov $F3,a
        bra no_reset2


mono2:
        mov a,sq4004            ; emulate volume, square 0
        and a,#00001111b
        asl a
        asl a
        asl a

write_volume2:
        mov $F2,#$10            ; write volume
;        mov $F3,#0
        mov $F3,a
        mov $F2,#$11
        mov $F3,a

no_reset2:



;=====================================

;-------------------------------------
triangle:
        mov a,sound_ctrl
        and a,#00000100b        ; check triangle bit of $4015
        bne tri_enabled

silence3:
        mov $F2,#$20
        mov $F3,#0
        mov $F2,#$21
        mov $F3,#0
        jmp !noise

tri_enabled:

;        mov a,no4016
;        and a,#00000100b
;        beq silence3

        mov a,tr4008
        beq silence3
        and a,#10000000b
        beq tri_length_enabled
        mov a,tr4008
        and a,#01111111b
        beq silence3

        mov a,no4016
        and a,#20h
        beq mono3

        mov a,pcm_raw
        lsr a
        lsr a
        mov add_temp,a
        mov a,#$3F

        setc
        sbc a,add_temp

        mov $F2,#$20
        mov $F3,a
        mov $F2,#$21
        mov $F3,a


;        mov $F2,#$20           ; set volume
;        mov $F3,#$3F
;        mov $F2,#$21
;        mov $F3,#$3F

	  bra notimer
mono3:

        mov $F2,#20h
        mov $F3,#7Fh
        mov $F3,#21h
        mov $F3,#7Fh

        bra notimer

tri_length_enabled:

        mov a,no4016
        and a,#00000100b
        beq notimer
        mov a,tr4008
        and a,#01111111b
        mov y,#3
        mul ya
        mov linear_count_hi,y
        mov linear_count_lo,a

        mov a,$FF                ; clear counter
notimer:

        call !check_timer3



        and $4B,#00000111b

        mov a,$4A
        clrc
        rol a
        push psw
        clrc
        adc a,#tritable & 255
        rol temp3
        mov temp1,a
        pop psw
        mov a,$4B
        rol a
        ror temp3
        adc a,#tritable >> 8
        mov temp2,a

        mov y,#0
        mov a,[temp1]+y
        mov $F2,#$22

        setc
        cmp a,#0
        beq nomess1
        cmp a,#1
        beq nomess1
        sbc a,#2
nomess1:
        mov $F3,a

        inc y
        mov a,[temp1]+y
        mov $F2,#$23
        sbc a,#0
        mov $F3,a


;=====================================

;-------------------------------------
noise:
        mov a,sound_ctrl
        and a,#00001000b
        bne noise_enabled

        mov $F2,#$30
        mov $F3,#0
        mov $F2,#$31
        mov $F3,#0

        bra noise_off

noise_enabled:
        mov a,no400C            ; check decay disable
        and a,#00010000b
        bne decay_disabled3

        bra no_reset3

;        mov a,$56
;        and a,#00001000b
;        beq no_reset3
;
;        mov a,no400C
;        and a,#00001111b
;        mov x,a
;        mov a,!volume_decay_table+X
;        mov $F2,#$37
;        mov $F3,a
;
;        mov $F2,#$38
;        mov $F3,#01111000b
;
;        mov $F2,#$34
;        mov $F3,#0             ; puls0_sample
;        mov $F2,#$4C
;        mov $F3,#00001000b
;
;        mov a,#$08
;        mov $F2,#$38
;        mov $F3,a
;
;        bra write_volume3

decay_disabled3:
        mov $F2,#$37
        mov $F3,#$1F

        mov a,no4016
        and a,#20h
        beq mono4

        mov a,no400C
        and a,#00001111b
        bra write_volume3

mono4:
        mov a,no400C            ; write noise volume
        and a,#00001111b
        asl a
        mov x,a


        mov a,pcm_raw
        lsr a
        lsr a
        mov add_temp,a
        mov a,x
        setc
        sbc a,add_temp
        bcs just_fine
        mov a,#0
just_fine:

;        mov $F2,#$30
;        mov $F3,a
;        mov $F2,#$31
;        mov $F3,a



;        asl a
;        asl a
;        asl a
write_volume3:
        mov $F2,#$30
        mov $F3,a
        mov $F2,#$31
        mov $F3,a

no_reset3:
;---------------------------------------
                                ; write noise frequency
        mov a,no400E
        and a,#00001111b
        mov x,a
        mov a,!noise_freq_table+X

        mov $F2,#$6C
        mov $F3,a


;        mov $F2,#$6C
;        mov a,no400E
;        eor a,#$FF
;        and a,#00001111b
;        asl a
;        or  a,#00100000b       ; set echo disable
;        mov $F3,a              ; write noise frequency

noise_off:

        jmp !next_xfer


;======================================
; timer notes:
;               linear counter
;               267.094 Timer2 units (15.6ms) for 1/240hz
;               267.094 / 3 = 89.031 (timer value)
;               4-bit counter / 3 is number of .25-frames passed
;                       maxmimum time allowed between checks
;                       before 4-bit overflow: 22.2 milliseconds!
;

enable_timer3:
        mov $F1,#0              ; disable timers
        mov $FC,#89				; 89 * 3 = 267
        mov $FB,#22             ; 22.2222 * 3 = 66.66666
        mov $FA,#22
        mov a,$FF               ; clear counters
        mov a,$FE
        mov a,$FD
        mov $F1,#00000111b      ; enable timers
        ret


check_timer3:
        mov a,$FF               ; timer's 4-bit counter
        mov timer3val,a

        mov a,sq4000
        and a,#00010000b
        beq decay1
        jmp !no_decay1
decay1:

        mov a,$56
        and a,#00000001b
        beq no_decay_reset

        mov a,#00001111b        ; reset decay
        mov decay1volume,a
        mov a,#0
        mov decay1rate,a

        mov a,decay_status
        or a,#00000001b
        mov decay_status,a

        bra write_decay_volume

no_decay_reset:

        mov a,decay_status
        and a,#00000001b
        bne no_decay1x
        jmp !no_decay1
no_decay1x:

        mov a,sq4000
        and a,#00001111b
        mov x,a

        mov a,timer3val
        clrc
        adc a,decay1rate
        mov decay1rate,a

        cmp a,!volume_decay_rates+X
        bcc no_decay1

        mov a,#0
        mov decay1rate,a

        mov a,decay1volume
        bne no_decay_end

        mov a,sq4000
        and a,#00100000b        ; decay looping enabled?
        beq decay1_end
        mov a,#00010000b        ; looped, reset volume
        mov decay1volume,a
        bra no_decay1

decay1_end:
        mov a,decay_status      ; disabled!
        and a,#11111110b
        mov decay_status,a
        bra no_decay1

no_decay_end:
        dec decay1volume

write_decay_volume:
        mov a,decay1volume
        asl a
        asl a
        asl a
        mov x,a

        mov a,sound_ctrl
        and a,#00000001b
        beq silenced1

        mov a,sq4001
        and a,#10000000b
        beq okd1y
        mov a,sq4001
        and a,#00000111b
        beq okd1y
        bra ooykd

okd1y:
        mov a,sq4003
        and a,#00000111b
        bne okd1                ; check if freq is 0 or too high
        mov a,sq4002
        beq silenced1
        cmp a,#7
        bcc silenced1
        bra okd1

ooykd:
        mov a,sweep_freq_lo
        and a,#00000111b
        bne okd1                ; check if freq is 0 or too high
        mov a,sweep_freq_hi
        beq silenced1
        cmp a,#7
        bcc silenced1
        bra okd1

silenced1:
        mov x,#0
okd1:
        mov a,no4016
        and a,#20h
        beq monod1

        mov $F2,#0
        mov $F3,x
        mov $F2,#1
        mov $F3,#0
        bra no_decay1

monod1:
        mov $F2,#0              ; write volume
        mov $F3,x
        mov $F2,#1
        mov $F3,x


no_decay1:

        mov a,sq4004
        and a,#00010000b
        beq decay2
        jmp !no_decay2
decay2:

        mov a,$56
        and a,#00000010b
        beq no_decay_reset2

        mov a,#00001111b        ; reset decay
        mov decay2volume,a
        mov a,#0
        mov decay2rate,a

        mov a,decay_status
        or a,#00000010b
        mov decay_status,a

        bra write_decay_volume2

no_decay_reset2:

        mov a,decay_status
        and a,#00000010b
        bne no_decay2x
        jmp !no_decay2
no_decay2x:

        mov a,sq4004
        and a,#00001111b
        mov x,a

        mov a,timer3val
        clrc
        adc a,decay2rate
        mov decay2rate,a

        cmp a,!volume_decay_rates+X
        bcc no_decay2

        mov a,#0
        mov decay2rate,a

        mov a,decay2volume
        bne no_decay_end2

        mov a,sq4004
        and a,#00100000b        ; decay looping enabled?
        beq decay2_end
        mov a,#00010000b        ; looped, reset volume
        mov decay2volume,a
        bra no_decay2

decay2_end:
        mov a,decay_status      ; disabled!
        and a,#11111101b
        mov decay_status,a
        bra no_decay2

no_decay_end2:
        dec decay2volume

write_decay_volume2:
        mov a,decay2volume
        asl a
        asl a
        asl a
        mov x,a

        mov a,sound_ctrl
        and a,#00000010b
        beq silenced2

        mov a,sq4005
        and a,#10000000b
        beq okd2y
        mov a,sq4005
        and a,#00000111b
        beq okd2y
        bra ooykd2

okd2y:
        mov a,sq4007
        and a,#00000111b
        bne okd2                ; check if freq is 0 or too high
        mov a,sq4006
        beq silenced2
        cmp a,#7
        bcc silenced2
        bra okd2

ooykd2:


        mov a,sweep_freq_lo2
        and a,#00000111b
        bne okd2                ; check if freq is 0 or too high
        mov a,sweep_freq_hi2
        beq silenced2
        cmp a,#7
        bcc silenced2
        bra okd2

silenced2:
        mov x,#0
okd2:
        mov a,no4016
        and a,#20h
        beq monod2

        mov $F2,#10h
        mov $F3,#0
        mov $F2,#11h
        mov $F3,x
        bra no_decay2

monod2:
        mov $F2,#$10            ; write volume
        mov $F3,x
        mov $F2,#$11
        mov $F3,x


no_decay2:


        mov a,no400C
        and a,#00010000b
        bne no_decay3


        mov a,sound_ctrl
        and a,#00001000b
        beq no_decay3

        mov a,$56
        and a,#00001000b
        beq no_decay_reset3

        mov a,#00001111b        ; reset decay
        mov decay3volume,a
        mov a,#0
        mov decay3rate,a

        mov a,decay_status
        or a,#00001000b
        mov decay_status,a

        bra write_decay_volume3

no_decay_reset3:

        mov a,decay_status
        and a,#00001000b
        beq no_decay3

        mov a,no400C
        and a,#00001111b
        mov x,a

        mov a,timer3val
        clrc
        adc a,decay3rate
        mov decay3rate,a

        cmp a,!volume_decay_rates+X
        bcc no_decay3

        mov a,#0
        mov decay3rate,a

        mov a,decay3volume
        bne no_decay_end3

        mov a,no400C
        and a,#00100000b        ; decay looping enabled?
        beq decay3_end
        mov a,#00010000b        ; looped, reset volume
        mov decay3volume,a
        bra no_decay3

decay3_end:
        mov a,decay_status      ; disabled!
        and a,#11110111b
        mov decay_status,a
        bra no_decay3

no_decay_end3:
        dec decay3volume

        mov a,sound_ctrl
        and a,#00001000b
        bne write_decay_volume3
        mov x,#0
        bra noise_decayed

write_decay_volume3:
        mov a,decay3volume
        asl a
;        asl a
;        asl a
        mov x,a

noise_decayed:
        mov $F2,#$30            ; write volume
        mov $F3,x
        mov $F2,#$31
        mov $F3,x


no_decay3:


        mov a,sound_ctrl
        and a,#00000100b
        beq timer3_complete

        mov a,linear_count_hi
        bne needed
        mov a,linear_count_lo
        beq not_needed
needed:
        mov a,timer3val

        clrc
        adc a,timer3count_lo
        mov timer3count_lo,a
        mov a,#0
        adc a,timer3count_hi
        mov timer3count_hi,a

        cmp a,linear_count_hi
        bcc timer3_ongoing

        mov a,timer3count_lo
        cmp a,linear_count_lo
        bcs timer3_complete
timer3_ongoing:

        mov $F2,#$20            ; set volume
        mov $F3,#$3F
        mov $F2,#$21
        mov $F3,#$3F

not_needed:
        ret

timer3_complete:
;        mov $F1,#0

        mov $F2,#$20
        mov $F3,#0
        mov $F2,#$21
        mov $F3,#0
        mov linear_count_lo,#0
        mov linear_count_hi,#0

        mov timer3count_lo,#0
        mov timer3count_hi,#0
        ret


        mov a,tr4008
        and a,
        ret


silencex1:
        mov $F2,#0
        mov $F3,#0
        mov $F2,#1
        mov $F3,#0

nonsweep:
        ret

check_timers:
        mov a,sq4001
        and a,#10000000b
        beq nonsweep
        mov a,sq4001
        and a,#00000111b
        beq nonsweep

        mov a,no4016
        and a,#01000000b
        beq nofreqchange

        and no4016,#10111111b   ; disable!
        mov a,$FD               ; clear counter

        mov a,sq4002
        mov sweep_freq_lo,a
        mov a,sq4003
        and a,#00000111b
        mov sweep_freq_hi,a

        bne ok1x                ; check if freq is 0 or too high
        mov a,sweep_freq_lo
        beq silencex1
        cmp a,#7
        bcc silencex1
ok1x:

        mov a,sweep_freq_hi
        and a,#11111000b
        bne silencex1


        mov a,sweep_freq_lo
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable & 255
        rol temp3
        mov temp1,a
        pop psw
        mov a,sweep_freq_hi
        rol a
        ror temp3
        adc a,#freqtable >> 8
        mov temp2,a

        mov y,#0
        mov a,[temp1]+y
        mov $F2,#2
        mov $F3,a

        inc y
        mov a,[temp1]+y
        mov $F2,#3
        mov $F3,a


nofreqchange:

        mov a,sq4001
        and a,#01110000b
        lsr a
        lsr a
        lsr a
        lsr a
        mov x,a

        mov a,$FD
        clrc
        adc a,sweep1
        mov sweep1,a

        cmp a,!sweeptimes+x

        bcc nonsweep

        mov a,#0
        mov sweep1,a

        mov a,sweep_freq_lo
        mov sweeptemp1,a
        mov a,sweep_freq_hi
        mov sweeptemp2,a

        mov a,sq4001
        and a,#00000111b
        bne swcont
        ret

swcont:
        clrc
        ror sweeptemp2
        ror sweeptemp1
        dec a
        bne swcont

        mov a,sweeptemp1        ; decrease by 1 (sweep channel difference)
        setc
        sbc a,#1
        mov sweeptemp1,a
        mov a,sweeptemp2
        sbc a,#0
        mov sweeptemp2,a


        mov a,sweep_freq_hi
        bne ok3x                ; check if freq is 0 or too high
        mov a,sweep_freq_lo
        beq silencex2
        cmp a,#7
        bcc silencex2
ok3x:

        mov a,sweep_freq_hi
        and a,#11111000b
        bne silencex2


        mov a,sq4001
        and a,#00001000b
        bne decrease

        mov a,sweep_freq_lo
        clrc
        adc a,sweeptemp1
        mov sweep_freq_lo,a

        mov a,sweep_freq_hi
        adc a,sweeptemp2
        mov sweep_freq_hi,a
        bra swupdate

decrease:
        mov a,sweep_freq_lo
        setc
        sbc a,sweeptemp1
        mov sweep_freq_lo,a

        mov a,sweep_freq_hi
        sbc a,sweeptemp2
        mov sweep_freq_hi,a


swupdate:
        mov a,sweep_freq_hi
        bne ok2x                ; check if freq is 0 or too high
        mov a,sweep_freq_lo
        beq silencex2
        cmp a,#7
        bcc silencex2
ok2x:

        mov a,sweep_freq_hi
        and a,#11111000b
        bne silencex2


        mov a,sweep_freq_lo
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable & 255
        rol temp3
        mov temp1,a
        pop psw
        mov a,sweep_freq_hi
        rol a
        ror temp3
        adc a,#freqtable >> 8
        mov temp2,a

        mov y,#0
        mov a,[temp1]+y
        mov $F2,#2
        mov $F3,a

        inc y
        mov a,[temp1]+y
        mov $F2,#3
        mov $F3,a

swzero:
        ret


silencex2:
        mov $F2,#0
        mov $F3,#0
        mov $F2,#1
        mov $F3,#0
        ret



sweeptimes:
        .db 3,6,9,12,15,18,21,24


silencex12:
        mov $F2,#$10
        mov $F3,#0
        mov $F2,#$11
        mov $F3,#0

nonsweepx:
        ret



check_timers2:
        mov a,sq4005
        and a,#10000000b
        beq nonsweepx
        mov a,sq4005
        and a,#00000111b
        beq nonsweepx

        mov a,no4016
        and a,#10000000b
        beq nofreqchangex

        and no4016,#01111111b   ; disable!
        mov a,$FE               ; clear counter

        mov a,sq4006
        mov sweep_freq_lo2,a
        mov a,sq4007
        and a,#00000111b
        mov sweep_freq_hi2,a

        bne ok1x2               ; check if freq is 0 or too high
        mov a,sweep_freq_lo2
        beq silencex12
        cmp a,#7
        bcc silencex12
ok1x2:

        mov a,sweep_freq_hi2
        and a,#11111000b
        bne silencex12


        mov a,sweep_freq_lo2
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable & 255
        rol temp3
        mov temp1,a
        pop psw
        mov a,sweep_freq_hi2
        rol a
        ror temp3
        adc a,#freqtable >> 8
        mov temp2,a

        mov y,#0
        mov a,[temp1]+y
        mov $F2,#$12
        mov $F3,a

        inc y
        mov a,[temp1]+y
        mov $F2,#$13
        mov $F3,a


nofreqchangex:

        mov a,sq4005
        and a,#01110000b
        lsr a
        lsr a
        lsr a
        lsr a
        mov x,a

        mov a,$FE
        clrc
        adc a,sweep2
        mov sweep2,a

        cmp a,!sweeptimes+x

        bcc nonsweepx

        mov a,#0
        mov sweep2,a

        mov a,sweep_freq_lo2
        mov sweeptemp1,a
        mov a,sweep_freq_hi2
        mov sweeptemp2,a

        mov a,sq4005
        and a,#00000111b
        beq swzero2

swcont2:
        clrc
        ror sweeptemp2
        ror sweeptemp1
        dec a
        bne swcont2


        mov a,sweep_freq_hi2
        bne ok3x2               ; check if freq is 0 or too high
        mov a,sweep_freq_lo2
        beq silencex22
        cmp a,#7
        bcc silencex22
ok3x2:

        mov a,sweep_freq_hi2
        and a,#11111000b
        bne silencex22


        mov a,sq4005
        and a,#00001000b
        bne decrease2

        mov a,sweep_freq_lo2
        clrc
        adc a,sweeptemp1
        mov sweep_freq_lo2,a

        mov a,sweep_freq_hi2
        adc a,sweeptemp2
        mov sweep_freq_hi2,a
        bra swupdate2

decrease2:
        mov a,sweep_freq_lo2
        setc
        sbc a,sweeptemp1
        mov sweep_freq_lo2,a

        mov a,sweep_freq_hi2
        sbc a,sweeptemp2
        mov sweep_freq_hi2,a


swupdate2:
        mov a,sweep_freq_hi2
        bne ok2x2               ; check if freq is 0 or too high
        mov a,sweep_freq_lo2
        beq silencex22
        cmp a,#7
        bcc silencex22
ok2x2:

        mov a,sweep_freq_hi2
        and a,#11111000b
        bne silencex22


        mov a,sweep_freq_lo2
        clrc
        rol a
        push psw
        clrc
        adc a,#freqtable & 255
        rol temp3
        mov temp1,a
        pop psw
        mov a,sweep_freq_hi2
        rol a
        ror temp3
        adc a,#freqtable >> 8
        mov temp2,a

        mov y,#0
        mov a,[temp1]+y
        mov $F2,#$12
        mov $F3,a

        inc y
        mov a,[temp1]+y
        mov $F2,#$13
        mov $F3,a

swzero2:
        ret


silencex22:
        mov $F2,#$10
        mov $F3,#0
        mov $F2,#$11
        mov $F3,#0
        ret





;======================================
reset_dsp:
        mov y,#0
        mov x,#0
clear:
        mov $F2,x
        mov $F3,y
        inc x
        mov a,x
        and a,#00001111b
        cmp a,#$0A
        bne clear
        mov a,x
        and a,#11110000b
        clrc
        adc a,#$10
        mov x,a
        cmp x,#$80
        bne clear

        mov a,#$0C
clear2:
        mov $F2,a
        mov $F3,y
        clrc
        adc a,#$10
        cmp a,#$8C
        bne clear2

        mov a,#$0D
clear3:
        mov $F2,a
        mov $F3,y
        clrc
        adc a,#$10
        cmp a,#$8D
        bne clear3

        mov a,#$0F
clear4:
        mov $F2,a
        mov $F3,y
        clrc
        adc a,#$10
        cmp a,#$8F
        bne clear4

                                ; clear zero-page
        mov a,#0
        mov x,#$EF
clear5
        mov $00+x,a
        dec x
        bne clear5
        mov $00,a

        ret


;======================================

set_directory:
        mov a,#pulse0 & 255     ; directory for Pulse 0
        mov !$0200,a
        mov !$0202,a
        mov a,#pulse0 >> 8
        mov !$0201,a
        mov !$0203,a

        mov a,#pulse1 & 255     ; directory for Pulse 1
        mov !$0204,a
        mov !$0206,a
        mov a,#pulse1 >> 8
        mov !$0205,a
        mov !$0207,a

        mov a,#pulse2 & 255     ; directory for Pulse 2
        mov !$0208,a
        mov !$020A,a
        mov a,#pulse2 >> 8
        mov !$0209,a
        mov !$020B,a

        mov a,#pulse3 & 255     ; directory for Pulse 3 (same as pulse1)
        mov !$020C,a
        mov !$020E,a
        mov a,#pulse3 >> 8
        mov !$020D,a
        mov !$020F,a

        mov a,#triang & 255     ; directory for Triangle
        mov !$0210,a
        mov !$0212,a
        mov a,#triang >> 8
        mov !$0211,a
        mov !$0213,a

        ret

;======================================================================
;       DSP value            NES reg    NES decay       SPC decay
;----------------------------------------------------------------------
;volume_decay_table:    ( no longer used )
;        .db $8D                 ; $00   240Hz .25 sec   260 msec
;        .db $8A                 ; $01   120Hz .5 sec    510 msec
;        .db $88                 ; $02   80Hz .75 sec    770 msec
;        .db $87                 ; $03   60Hz 1 sec      1 second
;        .db $86                 ; $04   48Hz 1.25 sec   1.3 seconds
;        .db $85                 ; $05   40Hz 1.5 sec    1.5 seconds
;        .db $85                 ; $06   34Hz 1.764 sec  1.5 seconds
;        .db $84                 ; $07   30Hz 2 sec      2.0 seconds
;        .db $83                 ; $08   26Hz 2.307 sec  2.6 seconds
;        .db $83                 ; $09   24Hz 2.5 sec    2.6 seconds
;        .db $83                 ; $0A   21Hz 2.857 sec  2.6 seconds
;        .db $82                 ; $0B   20Hz 3 sec      3.1 seconds
;        .db $82                 ; $0C   18Hz 3.333 sec  3.1 seconds
;        .db $82                 ; $0D   17Hz 3.529 sec  3.1 seconds
;        .db $81                 ; $0E   16Hz 3.75 sec   4.1 seconds
;        .db $81                 ; $0F   15Hz 4 sec      4.1 seconds
;======================================================================
;       DSP value            NES reg    NES noise freq  SPC noise freq
;----------------------------------------------------------------------
noise_freq_table:
        .db 00111111b           ; $0                    32mhz
        .db 00111111b           ; $1                    32mhz
        .db 00111111b           ; $2                    32mhz
        .db 00111111b           ; $3                    32mhz
        .db 00111111b           ; $4                    32mhz
        .db 00111111b           ; $5                    32mhz
        .db 00111110b           ; $6                    16mhz
        .db 00111110b           ; $7                    16mhz
        .db 00111110b           ; $8    16744.04mhz     16mhz
        .db 00111110b           ; $9    14080hz         16mhz
        .db 00111100b           ; $A    9397.28hz       8.0mhz
        .db 00111011b           ; $B    7040hz          6.4mhz
        .db 00111001b           ; $C    4698.64hz       4.0mhz
        .db 00111000b           ; $D    35200hz         3.2mhz
        .db 00110101b           ; $E    17600 hz        1.6mhz
        .db 00110010b           ; $F    880 hz          800hz
;======================================================================

pulse0: .include "pl1a-0.asm"
pulse1: .include "pl1a-1.asm"
pulse2: .include "pl1a-2.asm"
pulse3: .include "pl1a-3.asm"

pulse0b: .include "pl3-0.asm"
pulse1b: .include "pl3-1.asm"
pulse2b: .include "pl3-2.asm"
pulse3b: .include "pl3-3.asm"

pulse0c: .include "pl2-0.asm"
pulse1c: .include "pl2-1.asm"
pulse2c: .include "pl2-2.asm"
pulse3c: .include "pl2-3.asm"

pulse0d: .include "pl1-0.asm"
pulse1d: .include "pl1-1.asm"
pulse2d: .include "pl1-2.asm"
pulse3d: .include "pl1-3.asm"

pulse0e: .include "pl1-0.asm"
pulse1e: .include "pl1-1.asm"
pulse2e: .include "pl1-2.asm"
pulse3e: .include "pl1-3.asm"

freqtable: .include "snestabl.asm"
tritable: .include "tritabl2.asm"

;        .include "sq2.asm"
;        .include "peeko1.asm"
;        .include "puls2y2.asm"

        .include "pl2.asm"

triang: .include "tri5.asm"

.end
