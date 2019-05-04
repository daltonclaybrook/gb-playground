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
wCurMapBlockData::
    ds 2

; block ID used to fill the border of the map
;
; this seems to be un-set in Pokemon, so it stays $00 (blank)
wMapBackgroundBlockID::
    ds 1

; All block IDs for the current map plus the border
wMapBlocks::
    ds 1300

; [wCurMapWidth] + MAP_BORDER * 2
wCurMapStride::
    ds 1
