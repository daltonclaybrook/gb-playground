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
    ld c, 5 ; multiply index by 5 bytes, which is the size of the map header struct
    call Multiply
    ld bc, MapHeaders
    add hl, bc
    ld d, h
    ld e, l
    ld hl, wCurMapTileset
    ld bc, $05 ; load all 5 bytes of the map header
    call CopyData
    ret

; Load block IDs from a map block file into WRAM
LoadMapBlocks::
    ld a, [wMapBackgroundBlockID]
    ld d, a
    ld hl, wMapBlocks
    ld bc, 1300 ; count of bytes in background buffer
.backgroundLoop
    ld a, d
    ld [hli], a ; fill the whole map block buffer with the background block ID
    dec bc
    ld a, b
    or c
    jr nz, .backgroundLoop

    ld hl, wMapBlocks ; hl = pointer to first map block
    ld a, [wCurMapWidth]
    add MAP_BORDER * 2 ; a = map stride
    ld [wCurMapStride], a
    ld d, 0
    ld e, a ; de = map stride
    ld c, MAP_BORDER ; count down
.topBorderLoop
    add hl, de ; move the hl pointer down `MAP_BORDER` rows
    dec c
    jr nz, .topBorderLoop
    ld e, MAP_BORDER
    add hl, de ; hl is now at the upper left portion of the map accounting for borders
    ld a, [wCurMapBlockDataPtr]
    ld e, a
    ld a, [wCurMapBlockDataPtr + 1]
    ld d, a ; de = pointer to map block data
    ld a, [wCurMapHeight]
    ld c, a ; c = counter for map height
.rowLoop
    push bc
    push hl
    ld a, [wCurMapWidth]
    ld c, a ; c = counter for map width
.innerRowLoop
    ld a, [de]
    ld [hli], a
    inc de
    dec c
    jr nz, .innerRowLoop
    pop hl
    ld a, [wCurMapStride]
    add l
    ld l, a
    jr nc, .noCarry
    inc h
.noCarry
    pop bc
    dec c
    jr nz, .rowLoop
    ret

; Load tileset info into WRAM
LoadTilesetMetadata::
    ld a, [wCurMapTileset] ; get index of current tileset
    ld b, a
    ld c, 4 ; multiply by 4, the size of the tileset header struct
    call Multiply
    ld bc, TilesetHeaders
    add hl, bc
    ld d, h
    ld e, l
    ld hl, wCurTilesetBlocksPtr
    ld bc, 4 ; load two pointers worth of data into WRAM
    call CopyData
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
