section "Palette", rom0[$2000]

MainBGPalette::
    RGB 31, 31, 31
	RGB 28, 26, 9
	RGB 28, 12, 11
	RGB 9, 6, 8

; fade palettes
FadeBGPalette1::
    RGB 23, 23, 23
	RGB 21, 20, 7
	RGB 21, 9, 8
	RGB 7, 5, 6

FadeBGPalette2::
    RGB 16, 16, 16
	RGB 14, 13, 5
	RGB 14, 6, 6
	RGB 5, 3, 4

FadeBGPalette3::
    RGB 8, 8, 8
	RGB 7, 7, 2
	RGB 7, 3, 3
	RGB 2, 2, 2

FadeBGPalette4::
    RGB 0, 0, 0
	RGB 0, 0, 0
	RGB 0, 0, 0
	RGB 0, 0, 0

PlayerPalette::
    RGB 31, 31, 31
    RGB 28, 23, 23
    RGB 23, 6, 9
    RGB 6, 5, 7

ConfigureMainBGPalette::
    ld hl, MainBGPalette
    jp ConfigureSelectedBGPalette

; hl = address of first byte of BG palette to load into BG Palette #0
ConfigureSelectedBGPalette::
    ld a, %10000000 ; auto-increment starting at index 0
    ld [rBCPS], a ; object palette specification
    ld de, rBCPD
    ld c, 8 ; 8 bytes in a color palette
.loop
    ld a, [hli]
    ld [de], a
    dec c
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

FadeOutBackground::
    ld hl, FadeBGPalette1
    ld b, 4 ; b = 4 rounds of dimming
.loop
    call DelayFrame
    call ConfigureSelectedBGPalette
    call DelayFrame
    call DelayFrame
    call DelayFrame
    dec b
    jr nz, .loop
    ret

FadeInBackground::
    ld hl, FadeBGPalette4
    ld b, 5 ; b = rounds of fading
.loop
    call DelayFrame
    call ConfigureSelectedBGPalette
    call DelayFrame
    call DelayFrame
    call DelayFrame
    ld a, l
    ld l, 16 ; subtract 16, 2 palettes worth of bytes
    sub l
    ld l, a
    jr nc, .noCarry
    dec h
.noCarry
    dec b
    jr nz, .loop
    ret
