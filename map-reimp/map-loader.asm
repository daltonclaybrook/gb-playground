section "Map Loader", rom0

; Loads and displays the current map
;
; [wCurMap] is used as input
; Function assumes the display has already been disabled
LoadMap::
    call ResetMapViewVRAMPointer
    call ConfigureLCDForTileset
    call ConfigureBGPalette
    call LoadMapMetadata
    call LoadMapBlocks
    call LoadTilesetMetadata
    call LoadTilesetGFX
    call ConfigureBlockMapViewPtrFromPlayerCoords
    call LoadAndCopyMapTiles
    call CopyTilesToVRAM
    ret

ConfigureBlockMapViewPtrFromPlayerCoords::
    ld a, [wPlayerY]
    ld d, a
    and $01 ; only preserve low bit
    ld [wPlayerBlockY], a
    ld a, d
    srl a
    add MAP_BORDER - 2 ; 2 is magic number to get y value right
    ld b, a
    ld a, [wCurMapStride]
    ld c, a
    call Multiply ; hl == y * map stride

    ld a, [wPlayerX]
    ld d, a
    and $01
    ld [wPlayerBlockX], a
    ld a, d
    srl a
    add MAP_BORDER - 2 ; 2 is magic number to get x value right
    ld b, 0
    ld c, a
    add hl, bc ; combine x with y

    ld bc, wCurBlockMap
    add hl, bc
    ld a, l
    ld [wCurBlockMapViewPtr], a
    ld a, h
    ld [wCurBlockMapViewPtr + 1], a
    ret

; convenience function for loading map tiles from a block map
; then copying them to the screen buffer
LoadAndCopyMapTiles::
    call LoadMapTiles
    call CopyMapTilesToScreenBuffer
    ret

; We're loading a new map, so it will start drawing from `$9800` in VRAM
ResetMapViewVRAMPointer::
    ld a, $98
    ld [wMapViewVRAMPointer + 1], a
    xor a
    ld [wMapViewVRAMPointer], a
    ret

; Sets the LCD controller to use the correct tileset address in VRAM
ConfigureLCDForTileset::
    ld a, [rLCDC]
    res rLCDC_TILE_SELECT, a ; select tileset $8800-$97ff in VRAM
    ld [rLCDC], a
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
    ld hl, wCurBlockMap
    ld bc, 1300 ; count of bytes in background buffer
.backgroundLoop
    ld a, d
    ld [hli], a ; fill the whole map block buffer with the background block ID
    dec bc
    ld a, b
    or c
    jr nz, .backgroundLoop

    ld hl, wCurBlockMap ; hl = pointer to first map block
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
    ld a, [wCurBlockMapPtr]
    ld e, a
    ld a, [wCurBlockMapPtr + 1]
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
    ld c, 6 ; multiply by 6, the size of the tileset header struct
    call Multiply
    ld bc, TilesetHeaders
    add hl, bc
    ld d, h
    ld e, l
    ld hl, wCurTilesetBlocksPtr
    ld bc, 6 ; load three pointers worth of data into WRAM
    call CopyData
    ret

; Load Tileset tiles into VRAM
LoadTilesetGFX::
    ld hl, $9000 ; destination in VRAM for the tileset
    ld a, [wCurTilesetGfxPtr]
    ld e, a
    ld a, [wCurTilesetGfxPtr + 1]
    ld d, a ; de = pointer to current tileset GFX
    ld bc, $600 ; counter equals 6 rows of $10 tiles, each with 8x8 pixels
    call CopyData
    ret

; Load tiles from the block map into WRAM
;
; This area of memory ([wTileMapBackup]) is 6x5 blocks
; It uses [wCurBlockMapViewPtr] as a pointer to the upper left corner
; IDs from the block map reference strings of 16 tiles in the blockset
LoadMapTiles::
    ld a, [wCurBlockMapViewPtr]
    ld e, a
    ld a, [wCurBlockMapViewPtr + 1]
    ld d, a

    ld hl, wTileMapBackup    
    ld c, 5 ; 5 rows
.rowLoop
    push de ; store the pointer to the first block ID on the current row
    push bc ; store pointer to the row countdown
    ld c, 6 ; 6 blocks per row
.blockLoopInRow
    ld a, [de]
    inc de
    push bc
    push de
    push hl
    ld c, a
    call DrawTileBlock
    pop hl
    pop de
    ld bc, 4
    add hl, bc ; move four spaces to the right
    pop bc
    dec c
    jr nz, .blockLoopInRow
    ld bc, $48 ; move hl down 3 rows (hl has already wrapped one row)
    add hl, bc
    pop bc ; row countdown
    pop de ; pointer to first block ID on current row
    ld a, [wCurMapStride]
    add e
    ld e, a
    jr nc, .noCarry
    inc d
.noCarry ; de = pointer to the first block ID on the next row
    dec c
    jr nz, .rowLoop
    ret

; Tiles are copied from [wTileMapBackup] to the screen buffer [wTileMap]
;
; While the backup is 24x20 tiles (6x5 blocks), the screen buffer is
; 20x18 tiles, which is the size of the screen. This leaves room for
; adjustment based on the values of [wPlayerBlockX] and [wPlayerBlockY]
CopyMapTilesToScreenBuffer::
    ld hl, wTileMapBackup
    ld a, [wPlayerBlockY]
    and a
    jr z, .checkPlayerBlockX
    ld bc, $30 ; 6 blocks * 4 tiles * 2 rows
    add hl, bc
.checkPlayerBlockX::
    ld a, [wPlayerBlockX]
    and a
    jr z, .copyTiles
    ld bc, $02 ; move pointer over two tiles
    add hl, bc
.copyTiles::
    ld d, h
    ld e, l
    ld hl, wTileMap
    ld bc, SCREEN_HEIGHT
.rowLoop
    push bc
    ld bc, SCREEN_WIDTH
    call CopyData
    ld a, 4 ; incrememnt de by 4 because `wTileMapBackup` has 4 more tiles per row than `wTileMap`
    add e
    ld e, a
    jr nc, .noCarry
    inc d
.noCarry
    pop bc
    dec bc
    ld a, c
    or b
    jr nz, .rowLoop
    ret    

; Copy the visible portion of the map into VRAM
CopyTilesToVRAM::
    ld hl, _SCRN0 ; ($9800) Location of BG Map 1 in VRAM
    ld de, wTileMap
    ld bc, SCREEN_HEIGHT
.rowLoop
    push bc
    ld bc, SCREEN_WIDTH
    call CopyData
    ld bc, 32 - SCREEN_WIDTH ; BG Map has 32 width, but our tile map is only SCREEN_WIDTH 
    add hl, bc
    pop bc
    dec bc
    ld a, c
    or b
    jr nz, .rowLoop
    ret

; **********************
; Helper Functions
; **********************

; Copy an 8x8 block of tiles to the tile map in WRAM
;
; Input:
; c = block ID
; hl = address to start drawing block
DrawTileBlock::
    push hl
    ld a, c ; Multiply block id by $10
	swap a
	ld b, a
	and $f0
	ld c, a
	ld a, b
	and $0f
	ld b, a ; bc = tile block ID * $10
    ld a, [wCurTilesetBlocksPtr]
    ld l, a
    ld a, [wCurTilesetBlocksPtr + 1]
    ld h, a ; hl = pointer to first tileset block
    add hl, bc
    ld d, h
    ld e, l ; de = pointer to block to draw
    pop hl ; hl = address to start drawing block

    ld c, 4 ; c = row countdown
.rowLoop
    push bc
    ld a, [de] ; copy four tiles
    ld [hli], a
    inc de
    ld a, [de]
    ld [hli], a
    inc de
    ld a, [de]
    ld [hli], a
    inc de
    ld a, [de]
    ld [hl], a
    inc de
    ld bc, $15 ; move to next row: 4 tiles * 6 blocks - 3 (hl has already been incremented 3 times)
    add hl, bc
    pop bc
    dec c
    jr nz, .rowLoop
    ret

include "palette.asm"
