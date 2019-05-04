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

section "Tile Map Data", wram0[$c528] ; making this a round number for testing purposes

; buffer for temporarily saving and restoring current screen's tiles
;
; (e.g. if menus are drawn on top)
wTileMapBackup::
	ds 24 * 20 ; 6 x 5 blocks of 4x4 tiles

wTileMap::
    ds 20 * 18 ; width * height of screen
