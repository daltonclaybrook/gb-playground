section "VBlank", rom0

VBlank::
    push af
	push bc
	push de
	push hl

    ld a, [hSCX]
	ld [rSCX], a
	ld a, [hSCY]
	ld [rSCY], a

    call ReadJoypad

    ld a, [H_VBLANKOCCURRED]
	and a
	jr z, .skipZeroing
	xor a
	ld [H_VBLANKOCCURRED], a
.skipZeroing

    pop hl
	pop de
	pop bc
	pop af
	reti

DelayFrame::
; Wait for the next vblank interrupt.
; As a bonus, this saves battery.

NOT_VBLANKED EQU 1

	ld a, NOT_VBLANKED
	ld [H_VBLANKOCCURRED], a
.wait
	halt
	ld a, [H_VBLANKOCCURRED]
	and a
	jr nz, .wait
	ret
