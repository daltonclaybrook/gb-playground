include "hardware.inc"
include "constants.asm"

section "Common", rom0

; Wait until the display has finished drawing the last line, but has not yet begun
; drawing the first line again. This period is known has VBlank.
WaitVBlank::
    ld a, [rLY]
    cp SCRN_Y ; LCD is in VBlank if [rLY] >= SCRN_Y (144)
    jr c, WaitVBlank
    ret

DisableLCD::
	xor a
	ld [rIF], a
	ld a, [rIE]
	ld b, a
	res 0, a
	ld [rIE], a

.wait
	ld a, [rLY]
	cp LY_VBLANK
	jr nz, .wait

	ld a, [rLCDC]
	and $ff ^ rLCDC_ENABLE_MASK
	ld [rLCDC], a
	ld a, b
	ld [rIE], a
	ret

EnableLCD::
	ld a, [rLCDC]
	set rLCDC_ENABLE, a
	ld [rLCDC], a
	ret

; dbr value, nb_times
; Writes nb_times consecutive bytes with value.
dbr: MACRO
    REPT \2
        db \1
    ENDR
ENDM

; dwr value, nb_times
; Writes nb_times consecutive words with value.
dwr: MACRO
    REPT \2
        dw \1
    ENDR
ENDM
