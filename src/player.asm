	XREF __initSoundCPU
	XDEF __spc_sound_init
	XDEF __spc_nsf_init
	XDEF __spc_nsf_play
	XDEF __spc_sound_stop

	XREF nsf_data

;######################################################
;### RAM
;######################################################

;######################################################
;### Equates
;######################################################

init_lo EQU $7F1013
init_hi EQU $7F1014
play_lo EQU $7F1015
play_hi EQU $7F1016

stack_lo EQU $7F1017
stack_hi EQU $7F1018

noise_length    EQU $7F101B
triangle_length EQU $7F101C
square0_length  EQU $7F101D
square1_length  EQU $7F101E

;######################################################
;### Code
;######################################################

;######################################################
;### __spc_sound_init
;### init and copy SPC.bin in SPC is ok
;######################################################

__spc_sound_init:
	sei					; disable interrupts
	rep #$30
    sep #$20
    LONGA OFF
    LONGI ON
    jsr __initSoundCPU
    phk
    plb
    lda #$20
    sta $7F4116
    cli					; enable interrupts
    rep     #$30		; set back like it was TODO (way to do it more generic) ???
	LONGA	ON
	LONGI	ON
    rts

;######################################################
;### __spc_nsf_init
;######################################################

__spc_nsf_init:
	sei				; disable interrupts
	LONGA OFF
    LONGI ON
	rep #$30
    sep #$20

    ; restore params passed by C
    tsc
	sec
	sbc	#L32
	tcs
	phd
	tcd

    lda <L32+3		; functions params : a is songNumber
    ldx #$0000		; offset in nsf song table

    pha
    txa
    asl
    asl
    pha

    jsr clear_nes_sound
    jsr update_dsp

    ; copy nes code into ram
    ldx #$0000
?1
    lda >nescode,x
    sta $7F5000,x
    inx
    cpx #$0100
    bne ?1

    ;copy nsf_data into ram
    ldx #$0000
?2
	lda >nsf_data,x
    sta $7FDA00,x	; TODO change cause it's related to spartanX.nsf
    inx
    cpx #$2600		; TODO size of nsf data
    bne ?2

    lda #1
    sta >square0_length
    sta >square1_length
    sta >triangle_length
    sta >noise_length

    pla
    tax

	; This part of code was patched to use directly
	; the nsf data reading the right offset
    ldx #$000a
    lda >nsf_data,x
    sta >init_lo
    lda >nsf_data+1,x
    sta >init_hi
    lda >nsf_data+2,x
    sta >play_lo
    lda >nsf_data+3,x
    sta >play_hi

    pla
    jsl $7F5002				; nes_init
    phk
    plb

    pld
    tsc
    clc
    adc #$0001
    tsc

    cli						; enable interrupts
    rep     #$30			; set back like it was TODO (way to do it more generic) ???
	LONGA	ON
	LONGI	ON

L32	equ	0

    rts

;######################################################
;### __spc_nsf_play
;###
;######################################################

__spc_nsf_play:
	sei					; disable interrupts
	rep #$30
    sep #$20
    LONGA OFF
    LONGI ON
    lda #%00000001
    sta $4200
    jsl $7F5000     	; NSF play a.k.a nesplay
    phk
    plb
    lda #%10000001
    sta $4200
    jsr detect_changes
    jsr emulate_length_counter
    jsr backup_regs
    jsr update_dsp
    lda $7F4116
    and #$20
    sta $7F4116
    cli					; enable interrupts
    rep     #$30		; set back like it was TODO (way to do it more generic) ???
	LONGA	ON
	LONGI	ON
    rts

;######################################################
;### __spc_sound_stop
;###
;######################################################

__spc_sound_stop:
	rep #$30
    sep #$20
    LONGA OFF
    LONGI ON
    jsr clear_nes_sound
    jsr update_dsp
    rts

;=============================================

detect_changes:
	lda $7F4000
	and #%00100000
	bne decay_disabled0

	lda $7F4003
	beq ?1
	sta $7F4103
	lda #0
	sta $7F4003

	lda $7F4116
	ora #%00000001
	sta $7F4116
	bra end_square0
?1
	lda $7F4116
	and #%11111110
	sta $7F4116
	bra end_square0

decay_disabled0:
	lda $7F4003
	sta $7F4103

end_square0:

	lda $7F4004
	and #%00100000
	bne decay_disabled1

	lda $7F4007
	beq ?1
	sta $7F4107
	lda #0
	sta $7F4007

	lda $7F4116
	ora #00000010
	sta $7F4116
	bra end_square1
?1
	lda $7F4116
	and #%11111101
	sta $7F4116
	bra end_square1

decay_disabled1:
	lda $7F4007
	sta $7F4107
end_square1:
                        ;       triangle wave
	lda $7F4008
	and #%10000000
	bne disabled3

	lda $7F400B
	beq ?1
	sta $7F410B
	lda #0
	sta $7F400B
	lda $7F4116
	ora #%00000100
	sta $7F4116
	bra end_tri
?1
	lda $7F4116
	and #%11111011
	sta $7F4116
	bra end_tri

disabled3:
	lda $7F400B
	sta $7F410B
end_tri:

	lda $7F400C
	and #%00100000
	bne decay_disabled2

	lda $7F400F
	beq ?1
	sta $7F410F
	lda #0
	sta $7F400F

	lda $7F4116
	ora #%00001000
	sta $7F4116
	bra end_noise
?1
	lda $7F4116
	and #%11110111
	sta $7F4116
	bra end_noise

decay_disabled2:
	lda $7F400F
	sta $7F410F
end_noise:
                        ; check freq for sweeps
	lda $7F4001
	and #%10000000
	beq sqsw1

	lda $7F4001
	and #%00000111
	beq sqsw1x
	lda $7F4002
	beq sqsw1
	sta $7F4102
	lda #0
	sta $7F4002
	lda $7F4116
	ora #%01000000
	sta $7F4116
	bra skip1

sqsw1:
	lda $7F4002
	sta $7F4102
skip1:
	bra nextcheck
sqsw1x:
	lda $7F4116
	and #%10111111
	sta $7F4116
	bra sqsw1

nextcheck:
                        ; check freq for sweeps
	lda $7F4005
	and #%10000000
	beq sqsw12

	lda $7F4005
	and #%00000111
	beq sqsw1x2
	lda $7F4006
	beq sqsw12
	sta $7F4106
	lda #0
	sta $7F4006
	lda $7F4116
	ora #%10000000
	sta $7F4116
	bra skip2
sqsw12:
	lda $7F4006
	sta $7F4106
skip2:
	bra nextcheck2
sqsw1x2:
	lda $7F4116
	and #%01111111
	sta $7F4116
	bra sqsw12

nextcheck2:
	rts

;=============================================

backup_regs:
	lda $7F4000
	sta $7F4100
	lda $7F4001
	sta $7F4101
	;lda $7F4002
	;sta $7F4102
	lda $7F4004
	sta $7F4104
	lda $7F4005
	sta $7F4105
	;lda $7F4006
	;sta $7F4106
	lda $7F4008
	sta $7F4108
	lda $7F4009
	sta $7F4109
	lda $7F400A
	sta $7F410A
	;lda $7F400B
	;sta $7F410B
	lda $7F400C
	sta $7F410C
	lda $7F400D
	sta $7F410D
	lda $7F400E
	sta $7F410E
	;lda $7F4015
	;sta $7F4115
	lda $7F4011
	sta $7F4111

	rts

;=============================================

emulate_length_counter:
	lda #0
	sta $7F4115
	                        ; square 0
	lda $7F4116
	and #%00000001
	beq sq0_not_changed

	lda $7F4103
	pha
	and #%00001000
	beq sq0_d3_0

	pla
	lsr a
	lsr a
	lsr a
	lsr a

	xba
	lda #0
	xba

	tax
	lda >length_d3_1,x
	sta >square0_length
	bra sq0_load_end

sq0_d3_0:
	pla
	lsr a
	lsr a
	lsr a
	lsr a

	tax
	lda >length_d3_0,x
	sta >square0_length

sq0_load_end:
;	lda #0
;	sta $7F4003

sq0_not_changed:
	lda $7F4115
	ora #%00000001
	sta $7F4115
	lda $7F4000
	and #%00100000
	bne sq0_counter_disabled

	lda >square0_length
	beq blahsq
	dec
	sta >square0_length
	bra sq0_counter_disabled

blahsq:
	lda $7F4115
	and #%11111110
	sta $7F4115

sq0_counter_disabled:
	                        ; square 1
	lda $7F4116
	and #%00000010
	beq sq1_not_changed

	lda $7F4107
	pha
	and #%00001000
	beq sq1_d3_0

	pla
	lsr a
	lsr a
	lsr a
	lsr a

	xba
	lda #0
	xba

	tax
	lda >length_d3_1,x
	sta >square1_length
	bra sq1_load_end

sq1_d3_0:
	pla
	lsr a
	lsr a
	lsr a
	lsr a

	tax
	lda >length_d3_0,x
	sta >square1_length

sq1_load_end:
;	lda #0
;	sta $7F4007

sq1_not_changed:
	lda $7F4115
	ora #%00000010
	sta $7F4115

	lda $7F4004
	and #%00100000
	bne sq1_counter_disabled

	lda >square1_length
	beq sqblah
	dec
	sta >square1_length
	bra sq1_counter_disabled

sqblah:
	lda $7F4115
	and #%11111101
	sta $7F4115

sq1_counter_disabled:
	                        ; triangle channel
	lda $7F4116
	and #%00000100
	beq tri_not_changed

	lda $7F410B
	pha
	and #%00001000
	beq tri_d3_0

	pla
	lsr a
	lsr a
	lsr a
	lsr a

	xba
	lda #0
	xba

	tax
	lda >length_d3_1,x
	sta >triangle_length
	bra tri_load_end

tri_d3_0:
	pla
	lsr a
	lsr a
	lsr a
	lsr a

	tax
	lda >length_d3_0,x
	sta >triangle_length

tri_load_end:
;	lda #0
;	sta $7F400B

tri_not_changed:
	lda $7F4115
	ora #%00000100
	sta $7F4115

	lda $7F4008
	and #%10000000
	bne tri_counter_disabled

	lda >triangle_length
	beq blah
	dec
	sta >triangle_length
	bra tri_counter_disabled

blah:
	lda $7F4115
	and #%11111011
	sta $7F4115

tri_counter_disabled:
	                        ; noise channel
	lda $7F4116
	and #%00001000          ; get length value (0 if unchanged)
	beq unchanged

	lda $7F410F
	pha
	and #%00001000
	beq d3_0

	pla
	lsr a
	lsr a
	lsr a
	lsr a

	xba
	lda #0
	xba

	tax
	lda >length_d3_1,x
	sta >noise_length

	bra load_end

d3_0:
	pla
	lsr a
	lsr a
	lsr a
	lsr a

	tax
	lda >length_d3_0,x
	sta >noise_length

load_end:
;	lda #0
;	sta $7F400F

unchanged:
	lda $7F4115
	ora #%00001000
	sta $7F4115

	lda $7F400C
	and #%00100000
	bne noise_counter_disabled

	lda >noise_length
	beq pleh

	dec
	sta >noise_length
	bra noise_counter_disabled

pleh:
	lda $7F4115
	and #%11110111
	sta $7F4115

noise_counter_disabled:
	lda $7F4115
	and $7F4015
	sta $7F4115

	rts

length_d3_0:
	.db $06,$0B,$15,$29,$51,$1F,$08,$0F
	.db $07,$0D,$19,$31,$61,$25,$09,$11

length_d3_1:
	.db $80,$02,$03,$04,$05,$06,$07,$08
	.db $09,$0A,$0B,$0C,$0D,$0E,$0F,$10

;=============================================

;######################################################
;### update_dsp is totally ported to wdc assembler
;### transfer have been controlled and looks ok
;######################################################

	XDEF update_dsp

update_dsp:
    php
	LONGI OFF
    sep #$10
?1
    lda $2140
    cmp #$7D                ; wait for SPC ready
    bne ?1

    lda #$D7
    sta $2140               ; tell SPC that CPU is ready
?2
    cmp $2140               ; wait for reply
    bne ?2

    ldx #$00
    stx $2140               ; clear port 0
xfer:
    lda $7F4100,x
    sta $2141               ; send data to port 1
?1
    cpx $2140               ; wait for reply on port 0
    bne ?1

    inx
    cpx #$17
    beq ?2
    stx $2140
    bra xfer
?2
	LONGI ON
    plp
    rts

;------------------------------------------------------------

clear_nes_sound:
	LONGA OFF
	LONGI ON
    lda #$00
    sta $7F4100             ; optimized for speeeeeed
    sta $7F4101
    sta $7F4102
    sta $7F4103
    sta $7F4104
    sta $7F4105
    sta $7F4106
    sta $7F4107
    sta $7F4108
    sta $7F4109
    sta $7F410A
    sta $7F410B
    sta $7F410C
    sta $7F410D
    sta $7F410E
    sta $7F410F
    sta $7F4114
    sta $7F4000
    sta $7F4001
    sta $7F4002
    sta $7F4003
    sta $7F4004
    sta $7F4005
    sta $7F4006
    sta $7F4007
    sta $7F4008
    sta $7F4009
    sta $7F400A
    sta $7F400B
    sta $7F400C
    sta $7F400D
    sta $7F400E
    sta $7F400F
    sta $7F4014
    rts

    XDEF nescode
    XDEF nesinit
    XDEF nesplay

NES_CODE SECTION

; This code need to be in RAM at 7F5000
; It is copied then executed directly from address

nescode:

nesrun:
        bra nesplay
        bra nesinit
nesinit:
		php
		phd
        phk
        plb
        pha
	LONGA ON
        rep #$20
        lda #$0000
        tcd
    LONGA OFF
    LONGI OFF
        sep #$30        ; mem and index to 8-bit
        pla
    LONGA ON
    LONGI ON
		rep #$30
		tsx
		stx $7F1017
	LONGA OFF
    LONGI OFF
		sep #$30
        sec
        xce             ; 6502 mode
        ldx #0
        txy
        jsr ($1013,x)
        clc
        xce             ; native mode
	LONGA	ON
	LONGI	ON
		rep	#$30
		ldx $7F1017
		txs
        lda #$1000
        tcd
	LONGA OFF
        sep #$20

        lda #$0F
        sta $7F4015

		pld
        plp
        rtl

nesplay:
        php
        phd
        phk
        plb

	LONGA ON
        rep #$20
        lda #$0000
        tcd
	LONGA OFF
	LONGI OFF
        sep #$30
    LONGA ON
    LONGI ON
		rep #$30
		tsx
		stx $7F1017
	LONGA OFF
    LONGI OFF
		sep #$30
        sec
        xce             ; 6502 mode
        ldx #0
        txy
        jsr ($1015,x)
        clc
        xce             ; native mode
    LONGA	ON
	LONGI	ON
		rep	#$30
		ldx $7F1017
		txs
	LONGA ON
        rep #$20
        lda #$1000
        tcd
    LONGA OFF
    LONGI ON
    rep #$30
    sep #$20
    	pld
        plp
        rtl
ENDS
