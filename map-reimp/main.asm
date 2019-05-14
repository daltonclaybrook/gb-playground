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
    call DisableLCD
	call PerformInitialSetup
    call SetupSampleMapValues
    call LoadMap
    call LoadPlayerTileset
    call EnableLCD

    ld a, IEF_VBLANK | IEF_TIMER | IEF_SERIAL
    ld [rIE], a
    ei

.gameLoop
    call DelayFrame
    call DelayFrame
    call UpdateJoypadState
    call UpdatePlayer
    jr .gameLoop

PerformInitialSetup::
    call WriteDMACodeToHRAM
    xor a
	ld [rIF], a
	ld [rIE], a
    ld [hSCX], a
    ld [hSCY], a
    ret

SetupSampleMapValues::
    ld a, PALLET_TOWN_MAP_2
    ld [wCurMap], a

    ld a, $0b
    ld [wMapBackgroundBlockID], a

    ld a, 3
    ld [wPlayerX], a
    ld a, 6
    ld [wPlayerY], a

    call SetBlockMapViewPtrAndBlockCoords
    ret

; Use the player's current position to set the block map
; pointer and block coordinates
SetBlockMapViewPtrAndBlockCoords::
    ld a, [wPlayerY]
    ld d, a
    and $01 ; only preserve low bit
    ld [wPlayerBlockY], a
    ld a, d
    srl a
    add MAP_BORDER - 2 ; 2 is magic number to get y value right
    swap a ; high nibble is y
    ld b, a
    ld a, [wPlayerX]
    ld d, a
    and $01
    ld [wPlayerBlockX], a
    ld a, d
    srl a
    add MAP_BORDER - 2 ; 2 is magic number to get x value right
    or b ; combine with high nibble

    ld c, a
    ld b, 0
    ld hl, wCurBlockMap
    add hl, bc
    ld a, l
    ld [wCurBlockMapViewPtr], a
    ld a, h
    ld [wCurBlockMapViewPtr + 1], a
    ret

include "common.asm"
include "wram.asm"
include "map-loader.asm"
include "joypad.asm"
include "vblank.asm"
include "player.asm"
include "player-movement.asm"
include "oam-dma.asm"
