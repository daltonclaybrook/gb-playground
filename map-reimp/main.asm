include "hardware.inc"
include "constants.asm"
include "hram.asm"

; Hardware interrupts
section "vblank", rom0[$40]
	jp VBlank
section "hblank", rom0[$48]
	reti
section "timer", rom0[$50]
	reti
section "serial", rom0[$58]
	reti
section "joypad", rom0[$60]
	reti

section "Header", rom0[$100]

EntryPoint::
    di
    jp Start

    ds $150 - $104 ; initialize this space with zeros. These bytes will be replaced with the Gameboy header information.

; Honestly not all that sure why these need to be included here. 
; Maybe constants need to be declared above where they're used?
include "macros.asm"
include "maps.asm"

section "Game", rom0[$150]

; Game Start
Start::
	xor a
	ld [rIF], a
	ld [rIE], a
    ld [hSCX], a
    ld [hSCY], a

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

    ld a, IEF_VBLANK | IEF_TIMER | IEF_SERIAL
    ld [rIE], a

    ei

.gameLoop
    call DelayFrame
    call DelayFrame
    call UpdateJoypadState
    call UpdatePlayer
    jr .gameLoop

include "common.asm"
include "wram.asm"
include "map-loader.asm"
include "joypad.asm"
include "vblank.asm"
include "player.asm"
