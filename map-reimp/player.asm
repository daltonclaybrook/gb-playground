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
    call DrawPlayer
    ret

; Sets the LCD controller to use the correct tileset address in VRAM
ConfigureLCDForSprites::
    ld a, [rLCDC]
    set rLCDC_SPRITE_ENABLE, a ; enable sprites
    ld [rLCDC], a
    ret

; draw the player standing still
DrawPlayer::
    ld hl, wOAMBuffer
    call ConfigurePlayerSpriteParams
    call SetAllPlayerFlags
    ld e, c ; e is now the modifer
    ld c, 64 + 8 ; y position
    ; draw upper half
    push bc
    call DrawTileToBuffer
    ld a, e
    add b ; add the modifier to x
    ld b, a
    call DrawTileToBuffer
    pop bc
    ld a, 8
    add c
    ld c, a ; add 8 to y position
    ; draw lower half
    call DrawTileToBuffer
    ld a, e
    add b ; add the modifier to x
    ld b, a
    call DrawTileToBuffer
    ret

; Configure the params for drawing the player
;
; returns:
; b = x position
; c = x modifier (8 or -8)
; d = tile number
; e = flags
; set d to correct tile number for [wPlayerFacingDirection]
ConfigurePlayerSpriteParams::
    ld e, 0 ; most have no flags
    ld b, 64 + 8 ; most have 64 x-offset
    ld c, 8; most use a modifier of 8

    ld a, [wPlayerFacingDirection]
    cp DIRECTION_NORTH
    jr nz, .checkSouth
    ld d, 4 ; tile number for north
.checkSouth
    cp DIRECTION_SOUTH
    jr nz, .checkEast
    ld d, 0 ; tile number for south
.checkEast
    cp DIRECTION_EAST
    jr nz, .checkWest
    ld d, 8 ; tile number for east (flipped from west)
    set OAM_X_FLIP, e ; flip the x axis
    ld b, 72 + 8
    ld c, -8
.checkWest
    cp DIRECTION_WEST
    jr nz, .finish
    ld d, 8 ; tile number for west
.finish
    ret

; Set all flags
;
; e = flags
SetAllPlayerFlags::
    push bc
    push hl
    ld bc, 3 ; flags byte is offset by 3
    add hl, bc
    ld b, 4 ; add to hl
    ld c, 4 ; 4 tile count down
.loop
    ld a, e
    ld [hl], a
    ld a, l
    add b ; add 4
    ld l, a
    jr nc, .noCarry
    inc h
.noCarry
    dec c
    jr nz, .loop
    pop hl
    pop bc
    ret

; Draw one tile to the OAM buffer
; b = x
; c = y
; hl = tile destination
; d = tile number
DrawTileToBuffer::
    ld a, c ; y position
    ld [hli], a
    ld a, b ; x position
    ld [hli], a
    ld a, d ; tile number
    inc d
    ld [hli], a
    inc hl ; flags have already been written
    ret

PlayerGFX::
    incbin "assets/red.2bpp"
