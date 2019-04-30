include "pokemon.asm"

; entrypoint of the game
section "Header", rom0[$100]

EntryPoint::
    di ; disable interrupts
    jp Start

; this range of the header is used by the Gameboy to validate the cartridge is
; legit. Writing zeros here because the rgbfix tool will overwrite them with
; correct info, such as the Nintendo logo.
    dbr 0, $150 - $104

section "Game", rom0[$150]

Start::
    ; call WaitVBlank ; wait until VBlank period

    ; xor a ; ld a, 0
    ; ld [rLCDC], a ; turn off LCD. (Reminder: ask in discord when to do this vs simply writing during VBlank)

; problems solved tonight:
; - the correct tileset was not enabled on rLCDC
; - no palette was set (all white; looked blank)
; - wCurrentTileBlockMapViewPointer was not set

rLCDC_DEFAULT EQU %11100011

    ld a, rLCDC_ENABLE_MASK
	ld [rLCDC], a

    ld hl, wOverworldMap + $43
    ld a, l
    ld [wCurrentTileBlockMapViewPointer], a
    ld a, h
    ld [wCurrentTileBlockMapViewPointer + 1], a

    call LoadMapData

    ld a, %11100100
    ld [rBGP], a ; background palette

    ld a, %10000001
    ld [rLCDC], a ; turn on LCD

.gameLoop
    halt
    nop
    jr .gameLoop
