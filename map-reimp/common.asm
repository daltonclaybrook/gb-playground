section "LCD Control", rom0

DisableLCD::
	xor a
	ld [rIF], a ; cancel any interrupt requests
	ld a, [rIE]
	ld b, a
	res 0, a ; disable the VBlank interrupt
	ld [rIE], a

.wait
	ld a, [rLY]
	cp LY_VBLANK
	jr nz, .wait

	ld a, [rLCDC]
	res rLCDC_ENABLE, a ; reset the LCD enable bit
	ld [rLCDC], a
	ld a, b
	ld [rIE], a ; reenable any interrupt handlers that were disabled
	ret

EnableLCD::
	ld a, [rLCDC]
	set rLCDC_ENABLE, a
	ld [rLCDC], a
	ret

section "Copy", rom0

; Copy data from one place to another
;
; hl = destination
; de = source
; bc = count
CopyData::
    ld a, [de]
    ld [hli], a
    inc de
    dec bc ; does not set the zero flag, sadly
    ld a, c
	or b
    jr nz, CopyData
    ret

; Multiply two 8-bit numbers
;
; b = factor 1
; c = factor 2
; hl = result
Multiply::
    ld hl, 0
    ld d, 0
    ld e, b
    xor a
    cp c
    jr z, .finish
.loop
    add hl, de
    dec c
    jr nz, .loop
.finish
    ret
