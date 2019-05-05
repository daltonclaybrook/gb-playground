section "Header", rom0[$100]

EntryPoint::
    di ; disable interrupts
    jp Start

    ds $150 - $104 ; initialize this space with zeros. These bytes will be replaced with the Gameboy header information.

; Honestly not all that sure why these need to be included here. 
; Maybe constants need to be declared above where they're used?
include "macros.asm"
include "maps.asm"

section "Game", rom0[$150]

; Game Start
Start::
    ld a, PALLET_TOWN_MAP_2
    ld [wCurMap], a

    ld a, 4
    ld [wMapBackgroundBlockID], a

    ld hl, wCurBlockMap + $33 ; upper left of map without border
    ld a, l
    ld [wCurBlockMapViewPtr], a
    ld a, h
    ld [wCurBlockMapViewPtr + 1], a

    call LoadMap
.gameLoop
    jr .gameLoop

include "hardware.inc"
include "constants.asm"
include "common.asm"
include "wram.asm"
include "map-loader.asm"
