; sound.asm
;
; Support routines for the SPC700
; (C) 1999 Realtime Simulations and Roleplaying Games
; Grog's worst nightmares come true with this bloody CPU

;######################################################
;### initSoundCPU is totally ported to wdc assembler
;### transfer have been controlled and looks ok
;######################################################

	XDEF __initSoundCPU

__initSoundCPU:
        phk
        plb
        php
        rep #$30
        sep #$20
        LONGA OFF
        LONGI ON

wait_spc_ready_for_transfer:
        ldx $2140
        cpx #$BBAA
		bne wait_spc_ready_for_transfer

        ldx #$0400      ;Target SPC address for program
        stx $2142
        ldx #$0000
        lda #$01
        sta $2141
        lda #$CC
        sta $2140
?1      cmp $2140       ;Wait for SPC to sync
        bne ?1

SoundSendLoop:
        lda >spcprogg,X
        sta $2141       ;Set the address
        txa
        sta $2140       ;Set the data
?1      cmp $2140
        bne ?1          ;Wait for SPC to sync
        inx
        cpx spcend-spcprogg   ;Check for last data byte
        bne SoundSendLoop

        stz $2141       ;Mark end of data
        ldy #$0400      ;Set starting address of SPC code
        sty $2142
        inx
        inx
        txa
        sta $2140       ;Tell SPC to begin executing its program

        plp
        rts				; it's was rtl

SPC_CODE SECTION

	XDEF spcprogg
	XDEF spcend

spcprogg:
	INSERT SPC_ORIG.bin
spcend:
	DB $FF

ENDS
