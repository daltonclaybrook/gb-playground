section "Player", rom0

; load player tileset into VRAM
;
; Player tileset is layed out in a grid of 2x12 tiles
LoadPlayerTileset::
    call ConfigureLCDForSprites
    call ConfigureSpritePalette
    ld hl, $8000 ; first tile in VRAM
    ld de, PlayerGFX
    ld bc, 2 * 12 * 16 ; 2 columns * 12 rows * 16 bytes per tile
    call CopyData
    call DrawStanding
    ret

; Sets the LCD controller to use the correct tileset address in VRAM
ConfigureLCDForSprites::
    ld a, [rLCDC]
    set rLCDC_SPRITE_ENABLE, a ; enable sprites
    ld [rLCDC], a
    ret

; draw the player standing still
DrawStanding::
    ld hl, wOAMBuffer
    ld d, 0 ; tile number
    ld e, 2 ; lines to draw
    ld b, 60 + 16 ; starting y position
    ld c, 64 + 8 ; starting x position
.loop
    push bc
    call DrawTileToBuffer
    ld a, 8
    add c
    ld c, a
    call DrawTileToBuffer
    pop bc
    ld a, 8
    add b
    ld b, a
    dec e
    jr nz, .loop
    ret

; Draw one tile to the OAM buffer
; b = y
; c = x
; hl = tile destination
; d = tile number
DrawTileToBuffer::
    ld a, b ; y position
    ld [hli], a
    ld a, c ; x position
    ld [hli], a
    ld a, d ; tile number
    inc d
    ld [hli], a
    xor a ; flags
    ld [hli], a
    ret

PlayerGFX::
    incbin "assets/red.2bpp"
