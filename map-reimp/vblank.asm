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
	call RedrawRowOrColumn

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

RedrawRowOrColumn::
	ld a, [hRedrawRowOrColumnMode]
	and a
	ret z ; return if we're not in redrawing mode
	ld b, a
	xor a
	ld [hRedrawRowOrColumnMode], a ; reset mode to 0
	ld a, b
	cp REDRAW_COL
	jr z, .drawColumn
.drawRow::
	ld hl, wRedrawRowOrColumnSrcTiles
	ld a, [hRedrawRowOrColumnDest]
	ld e, a
	ld a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	push de
	call .drawHalfRow
	pop de
	ld a, BG_MAP_WIDTH
	add e
	ld e, a
.drawHalfRow::
	ld c, SCREEN_WIDTH / 2
.rowLoop::
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ld a, e
	inc a
	; these lines wrap to the left side of the screen if necessary
	and $1f
	ld b, a
	ld a, e
	and $e0
	or b
	ld e, a
	dec c
	jr nz, .rowLoop
	ret
.drawColumn::
	ld hl, wRedrawRowOrColumnSrcTiles
	ld a, [hRedrawRowOrColumnDest]
	ld e, a
	ld a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	ld c, SCREEN_HEIGHT
.columnLoop::
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ld a, BG_MAP_WIDTH - 1 ; move down a row and back one tile
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry::
	ld a, d
	and $03 ; wrap to top if necessary
	or $98
	ld d, a
	dec c
	jr nz, .columnLoop
	ret

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
