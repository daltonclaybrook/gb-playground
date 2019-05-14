section "Palette", rom0[$2000]

MainBGPalette1::
    RGB 31, 31, 31
    RGB 31, 0, 0
    RGB 0, 31, 0
    RGB 0, 0, 31

MainBGPalette2::
    RGB 31, 31, 31
    RGB 29, 26, 14
    RGB 11, 21, 20
    RGB 27, 12, 9

MainBGPalette3::
    RGB 31, 31, 31
    RGB 21, 21, 21
    RGB 10, 10, 10
    RGB 0, 0, 0

EveryBGPalette::
    RGB 31, 31, 31
	RGB 28, 26, 9
	RGB 28, 12, 11
	RGB 9, 6, 8

	RGB 31, 31, 31
    RGB 29, 26, 14
    RGB 11, 21, 20
    RGB 27, 12, 9
	
    RGB 4, 18, 22
	RGB 22, 7, 28
	RGB 8, 15, 4
	RGB 24, 20, 24
	
    RGB 19, 18, 25
	RGB 1, 10, 26
	RGB 29, 4, 25
	RGB 29, 13, 21
	
    RGB 16, 26, 17
	RGB 23, 9, 10
	RGB 21, 22, 11
	RGB 28, 12, 11
	
    RGB 9, 6, 8
	RGB 0, 21, 26
	RGB 28, 26, 9
	RGB 13, 29, 17
	
    RGB 10, 7, 15
	RGB 26, 27, 4
	RGB 28, 31, 19
	RGB 8, 9, 1
	
    RGB 4, 20, 5
	RGB 19, 0, 20
	RGB 0, 3, 12
	RGB 23, 23, 18
EveryBGPaletteEnd::

PlayerPalette::
    RGB 31, 31, 31
    RGB 28, 23, 23
    RGB 23, 6, 9
    RGB 6, 5, 7

ConfigureBGPalette::
    ; call SelectRandomBGPalettes
    ld d, 0
    call SelectBGPaletteAtIndex
    ld a, %10000000
    ld [rBCPS], a
    ld hl, EveryBGPalette
    ld de, rBCPD
    ld bc, EveryBGPaletteEnd - EveryBGPalette
.loop
    ld a, [hli]
    ld [de], a
    dec bc
    ld a, c
    or b
    jr nz, .loop
    ret

ConfigureSpritePalette::
    ld a, %10000000 ; auto-increment starting at index 0
    ld [rOCPS], a ; object palette specification
    ld hl, PlayerPalette
    ld de, rOCPD
    ld c, 8 ; 8 bytes in a color palette
.loop
    ld a, [hli]
    ld [de], a
    dec c
    jr nz, .loop
    ret

; Select a specific background palette
;
; d = index
SelectBGPaletteAtIndex::
    ld a, 1
    ld [rVBK], a
    ld hl, _SCRN0
    ld bc, 32 * 32 ; full map of 32 x 32 tiles
.loop
    ld a, d
    ld [hli], a
    dec bc
    ld a, c
    or b
    jr nz, .loop
    xor a
    ld [rVBK], a
    ret

RandomPalettes::
    db 6, 3, 0, 5, 6, 5, 1, 0, 2, 1, 3, 6, 0, 1, 0, 7, 3, 2, 4, 7
RandomPalettesEnd::

SelectRandomBGPalettes::
    ld a, 1
    ld [rVBK], a
    ld hl, _SCRN0
    ld bc, 32 * 32 ; full map of 32 x 32 tiles
    ld de, 0
.loop
    push de
    push hl
    ld hl, RandomPalettes
    add hl, de
    ld d, h
    ld e, l
    pop hl ; hl = next VRAM destination. de = random palette address

    ld a, [de]
    ld [hli], a
    pop de ; de = random palette index
    inc de
    ld a, e
    sub 17 ; count of random palette indexes
    jr nz, .continue
    ld de, 0
.continue
    dec bc
    ld a, c
    or b
    jr nz, .loop
    xor a
    ld [rVBK], a
    ret
