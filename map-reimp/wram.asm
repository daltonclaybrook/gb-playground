section "WRAM", wram0

; index of the current map
wCurMap::
    ds 1

; index of the current map's tileset
wCurMapTileset::
    ds 1

; height of the current map in blocks
wCurMapHeight::
    ds 1

; width of the current map in blocks
wCurMapWidth::
    ds 1

; memory address of block map file
wCurMapBlockDataPtr::
    ds 2

; block ID used to fill the border of the map
;
; this seems to be un-set in Pokemon, so it stays $00 (blank)
wMapBackgroundBlockID::
    ds 1

; All block IDs for the current map plus the border
wCurBlockMap::
    ds 1300

; [wCurMapWidth] + MAP_BORDER * 2
wCurMapStride::
    ds 1

; pointer to the tileset blocks data
wCurTilesetBlocksPtr::
    ds 2

; pointer to the tileset gfx data
wCurTilesetGfxPtr::
    ds 2

; an offset from [wCurBlockMap] to draw to the upper left corner of the screen
;
; [wCurBlockMapViewPtr] = y * [wCurMapStride] + x + [wCurBlockMap] 
wCurBlockMapViewPtr::
    ds 2

section "Player Data", wram0

; player's current Y movement direction
wPlayerDeltaY::
    ds 1

; player's current X movement direction
wPlayerDeltaX::
    ds 1

; player's current Y coord in player coordinate space
;
; the player sprite is 2x2 tiles, so Player Y of 1 == Tile Y of 2
wPlayerY::
    ds 1

; player's current X coord
wPlayerX::
    ds 1

; player's Y location within the current block
wPlayerBlockY::
    ds 1

; player's X location within the current block
wPlayerBlockX::
    ds 1

; player walk counter
wWalkCounter::
    ds 1

; The direction the player is facing
;
; DIRECTION_SOUTH, DIRECTION_NORTH, DIRECTION_EAST, DIRECTION_WEST
wPlayerFacingDirection::
    ds 1

; Whether or not the player is on an odd step
;
; causes the animation to flip on the x axis if walking north or south
wPlayerOddStep::
    ds 1

section "Tile Map Data", wram0

; buffer for temporarily saving and restoring current screen's tiles
;
; (e.g. if menus are drawn on top)
wTileMapBackup::
	ds 24 * 20 ; 6 x 5 blocks of 4x4 tiles

wTileMap::
    ds 20 * 18 ; width * height of screen

; the tiles of the row or column to be redrawn by RedrawRowOrColumn
wRedrawRowOrColumnSrcTiles::
	ds SCREEN_WIDTH * 2

; the address of the upper left corner of the visible portion of the BG tile map in VRAM
wMapViewVRAMPointer::
	ds 2

section "OAM Buffer", wram0[$ca00]

; buffer for OAM data. Copied to OAM by DMA
;
; It's important that this buffer start at a multiple of $100, which is why $ca00 is hard-coded
wOAMBuffer:: ; $ca00
	ds 4 * 40
