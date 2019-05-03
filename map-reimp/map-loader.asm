include "common.asm"
include "maps.asm"
include "wram.asm"

section "Map Loader", rom0[$200]

; Loads and displays the current map
;
; [wCurMap] is used as input
LoadMap::
    call DisableLCD
    call LoadMapMetadata
    call LoadMapBlocks
    call LoadTilesetMetadata
    call LoadTilesetGFX
    call LoadMapTiles
    call CopyTilesToVRAM
    call EnableLCD
    ret

; Load map info into WRAM
LoadMapMetadata::
    ld a, [wCurMap]
    ld b, a
    ld c, 0
    ld hl, MapHeaders
    add hl, bc
    ld d, h
    ld e, l
    ld hl, wCurMapTileset
    ld bc, $05 ; load all 5 bytes of the map header
    call CopyData
    ret

; Load block IDs from a map block file into WRAM
LoadMapBlocks::
    ret

; Load tileset info into WRAM
LoadTilesetMetadata::
    ret

; Load Tileset tiles into VRAM
LoadTilesetGFX::
    ret

; Load tiles for the current map into WRAM by referencing the map blocks file and the blocket
LoadMapTiles::
    ret

; Copy the visible portion of the map into VRAM
CopyTilesToVRAM::
    ret
