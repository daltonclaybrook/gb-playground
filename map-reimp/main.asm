include "map-loader.asm"

section "Header", rom0[$100]

EntryPoint::
    di ; disable interrupts
    jp Start

    ds $150 - $104 ; initialize this space with zeros. These bytes will be replaced with the Gameboy header information.

section "Game", rom0[$150]

; Game Start
Start::
    ld a, PALLET_TOWN_MAP
    ld [wCurMap], a
    call LoadMap
.gameLoop
    jr .gameLoop
