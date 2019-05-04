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

ConfigureBGPalette::
    ; call SelectBGPalette3
    ld a, %10000000
    ld [rBCPS], a
    ld hl, MainBGPalette2
    ld de, rBCPD
    ld c, 8 ; copy 8 bytes
.loop
    ld a, [hli]
    ld [de], a
    dec c
    jr nz, .loop
    ret

SelectBGPalette3::
    ld a, 1
    ld [rVBK], a
    ld hl, _SCRN0
    ld bc, 32 * 32 ; full map of 32 x 32 tiles
.loop
    ld a, 3
    ld [hli], a
    dec bc
    ld a, c
    or b
    jr nz, .loop
    xor a
    ld [rVBK], a
    ret
