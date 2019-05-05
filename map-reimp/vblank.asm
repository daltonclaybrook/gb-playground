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

    pop hl
	pop de
	pop bc
	pop af
	reti
