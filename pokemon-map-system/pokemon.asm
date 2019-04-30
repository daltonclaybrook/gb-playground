include "hardware.inc"
include "asm_macros.asm"
include "common.asm"
include "map_constants.asm"
include "copy.asm"
include "wram.asm"
include "vram.asm"
include "tileset_header.asm"

include "predef.asm"
include "predefs.asm"

section "bank6", romx

include "PalletTown.asm"
include "PalletTownObjects.asm"
PalletTown_Blocks: INCBIN "map/PalletTown.blk"

section "Pokemon", rom0

MapHeaderPointers::
    dw PalletTown_h

; see also MapHeaderPointers
MapHeaderBanks:
	db BANK(PalletTown_h)

; function to load map data
LoadMapData::
    ; new code
    ld a, $00
    ld [wCurMap], a
    ld [wCurMapTileset], a
    ; end new code

	ld a, [H_LOADEDROMBANK]
	push af
	call DisableLCD
	ld a, $98
	ld [wMapViewVRAMPointer + 1], a
	xor a
	ld [wMapViewVRAMPointer], a
	ld [hSCY], a
	ld [hSCX], a
	call LoadMapHeader
	call LoadTileBlockMap
	call LoadTilesetTilePatternData
	call LoadCurrentMapView
; copy current map view to VRAM
	coord hl, 0, 0
	ld de, vBGMap0
	ld b, 18
.vramCopyLoop
	ld c, 20
.vramCopyInnerLoop
	ld a, [hli]
	ld [de], a
	inc e
	dec c
	jr nz, .vramCopyInnerLoop
	ld a, 32 - 20
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	dec b
	jr nz, .vramCopyLoop
	ld a, $01
	ld [wUpdateSpritesEnabled], a
	call EnableLCD
	; ld b, SET_PAL_OVERWORLD
	; call RunPaletteCommand
	; call LoadPlayerSpriteGraphics
	ld a, [wd732]
	and 1 << 4 | 1 << 3 ; fly warp or dungeon warp
	jr nz, .restoreRomBank
	ld a, [wFlags_D733]
	bit 1, a
	jr nz, .restoreRomBank
	; call UpdateMusic6Times
	; call PlayDefaultMusicFadeOutCurrent
.restoreRomBank
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

; this loads the current maps complete tile map (which references blocks, not individual tiles) to C6E8
; it can also load partial tile maps of connected maps into a border of length 3 around the current map
LoadTileBlockMap::
; fill C6E8-CBFB with the background tile
	ld hl, wOverworldMap
	ld a, [wMapBackgroundTile]
	ld d, a
	ld bc, $0514
.backgroundTileLoop
	ld a, d
	ld [hli], a
	dec bc
	ld a, c
	or b
	jr nz, .backgroundTileLoop
; load tile map of current map (made of tile block IDs)
; a 3-byte border at the edges of the map is kept so that there is space for map connections
	ld hl, wOverworldMap
	ld a, [wCurMapWidth]
	ld [hMapWidth], a
	add MAP_BORDER * 2 ; east and west
	ld [hMapStride], a ; map width + border
	ld b, 0
	ld c, a
; make space for north border (next 3 lines)
	add hl, bc
	add hl, bc
	add hl, bc
	ld c, MAP_BORDER
	add hl, bc ; this puts us past the (west) border
	ld a, [wMapDataPtr] ; tile map pointer
	ld e, a
	ld a, [wMapDataPtr + 1]
	ld d, a ; de = tile map pointer
	ld a, [wCurMapHeight]
	ld b, a
.rowLoop ; copy one row each iteration
	push hl
	ld a, [hMapWidth] ; map width (without border)
	ld c, a
.rowInnerLoop
	ld a, [de]
	inc de
	ld [hli], a
	dec c
	jr nz, .rowInnerLoop
; add the map width plus the border to the base address of the current row to get the next row's address
	pop hl
	ld a, [hMapStride] ; map width + border
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	dec b
	jr nz, .rowLoop
.northConnection
	ld a, [wMapConn1Ptr]
	cp $ff
	jr z, .southConnection
	call SwitchToMapRomBank
	ld a, [wNorthConnectionStripSrc]
	ld l, a
	ld a, [wNorthConnectionStripSrc + 1]
	ld h, a
	ld a, [wNorthConnectionStripDest]
	ld e, a
	ld a, [wNorthConnectionStripDest + 1]
	ld d, a
	ld a, [wNorthConnectionStripWidth]
	ld [hNorthSouthConnectionStripWidth], a
	ld a, [wNorthConnectedMapWidth]
	ld [hNorthSouthConnectedMapWidth], a
	call LoadNorthSouthConnectionsTileMap
.southConnection
	ld a, [wMapConn2Ptr]
	cp $ff
	jr z, .westConnection
	call SwitchToMapRomBank
	ld a, [wSouthConnectionStripSrc]
	ld l, a
	ld a, [wSouthConnectionStripSrc + 1]
	ld h, a
	ld a, [wSouthConnectionStripDest]
	ld e, a
	ld a, [wSouthConnectionStripDest + 1]
	ld d, a
	ld a, [wSouthConnectionStripWidth]
	ld [hNorthSouthConnectionStripWidth], a
	ld a, [wSouthConnectedMapWidth]
	ld [hNorthSouthConnectedMapWidth], a
	call LoadNorthSouthConnectionsTileMap
.westConnection
	ld a, [wMapConn3Ptr]
	cp $ff
	jr z, .eastConnection
	call SwitchToMapRomBank
	ld a, [wWestConnectionStripSrc]
	ld l, a
	ld a, [wWestConnectionStripSrc + 1]
	ld h, a
	ld a, [wWestConnectionStripDest]
	ld e, a
	ld a, [wWestConnectionStripDest + 1]
	ld d, a
	ld a, [wWestConnectionStripHeight]
	ld b, a
	ld a, [wWestConnectedMapWidth]
	ld [hEastWestConnectedMapWidth], a
	call LoadEastWestConnectionsTileMap
.eastConnection
	ld a, [wMapConn4Ptr]
	cp $ff
	jr z, .done
	call SwitchToMapRomBank
	ld a, [wEastConnectionStripSrc]
	ld l, a
	ld a, [wEastConnectionStripSrc + 1]
	ld h, a
	ld a, [wEastConnectionStripDest]
	ld e, a
	ld a, [wEastConnectionStripDest + 1]
	ld d, a
	ld a, [wEastConnectionStripHeight]
	ld b, a
	ld a, [wEastConnectedMapWidth]
	ld [hEastWestConnectedMapWidth], a
	call LoadEastWestConnectionsTileMap
.done
	ret

; load the tile pattern data of the current tileset into VRAM
LoadTilesetTilePatternData::
	ld a, [wTilesetGfxPtr]
	ld l, a
	ld a, [wTilesetGfxPtr + 1]
	ld h, a
	ld de, vTileset
	ld bc, $600
	ld a, [wTilesetBank]
	jp FarCopyData2

; this builds a tile map from the tile block map based on the current X/Y coordinates of the player's character
LoadCurrentMapView::
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, [wTilesetBank] ; tile data ROM bank
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a ; switch to ROM bank that contains tile data
	ld a, [wCurrentTileBlockMapViewPointer] ; address of upper left corner of current map view
	ld e, a
	ld a, [wCurrentTileBlockMapViewPointer + 1]
	ld d, a
	ld hl, wTileMapBackup
	ld b, $05
.rowLoop ; each loop iteration fills in one row of tile blocks
	push hl
	push de
	ld c, $06
.rowInnerLoop ; loop to draw each tile block of the current row
	push bc
	push de
	push hl
	ld a, [de]
	ld c, a ; tile block number
	call DrawTileBlock
	pop hl
	pop de
	pop bc
	inc hl
	inc hl
	inc hl
	inc hl
	inc de
	dec c
	jr nz, .rowInnerLoop
; update tile block map pointer to next row's address
	pop de
	ld a, [wCurMapWidth]
	add MAP_BORDER * 2
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
; update tile map pointer to next row's address
	pop hl
	ld a, $60
	add l
	ld l, a
	jr nc, .noCarry2
	inc h
.noCarry2
	dec b
	jr nz, .rowLoop
	ld hl, wTileMapBackup
	ld bc, $0000
.adjustForYCoordWithinTileBlock
	ld a, [wYBlockCoord]
	and a
	jr z, .adjustForXCoordWithinTileBlock
	ld bc, $0030
	add hl, bc
.adjustForXCoordWithinTileBlock
	ld a, [wXBlockCoord]
	and a
	jr z, .copyToVisibleAreaBuffer
	ld bc, $0002
	add hl, bc
.copyToVisibleAreaBuffer
	coord de, 0, 0 ; base address for the tiles that are directly transferred to VRAM during V-blank
	ld b, SCREEN_HEIGHT
.rowLoop2
	ld c, SCREEN_WIDTH
.rowInnerLoop2
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .rowInnerLoop2
	ld a, $04
	add l
	ld l, a
	jr nc, .noCarry3
	inc h
.noCarry3
	dec b
	jr nz, .rowLoop2
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a ; restore previous ROM bank
	ret

; function to write the tiles that make up a tile block to memory
; Input: c = tile block ID, hl = destination address
DrawTileBlock::
	push hl
	ld a, [wTilesetBlocksPtr] ; pointer to tiles
	ld l, a
	ld a, [wTilesetBlocksPtr + 1]
	ld h, a
	ld a, c
	swap a
	ld b, a
	and $f0
	ld c, a
	ld a, b
	and $0f
	ld b, a ; bc = tile block ID * 0x10
	add hl, bc
	ld d, h
	ld e, l ; de = address of the tile block's tiles
	pop hl
	ld c, $04 ; 4 loop iterations
.loop ; each loop iteration, write 4 tile numbers
	push bc
	ld a, [de]
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
	ld bc, $0015
	add hl, bc
	pop bc
	dec c
	jr nz, .loop
	ret

; function to load data from the map header
LoadMapHeader::
	; callba MarkTownVisitedAndLoadMissableObjects
	ld a, [wCurMapTileset]
	ld [wUnusedD119], a
	ld a, [wCurMap]
	call SwitchToMapRomBank
	ld a, [wCurMapTileset]
	ld b, a
	res 7, a ; resetting 7th bit to zero. why?
	ld [wCurMapTileset], a
	ld [hPreviousTileset], a
	bit 7, b ; setting 7th bit high. why?
	ret nz
	ld hl, MapHeaderPointers
	ld a, [wCurMap]
	sla a
	jr nc, .noCarry1
	inc h
.noCarry1
	add l
	ld l, a
	jr nc, .noCarry2
	inc h
.noCarry2
	ld a, [hli]
	ld h, [hl]
	ld l, a ; hl = base of map header
; copy the first 10 bytes (the fixed area) of the map data to D367-D370
	ld de, wCurMapTileset
	ld c, $0a
.copyFixedHeaderLoop
	ld a, [hli]
	ld [de], a ; setting overworld as the current tileset [wCurMapTileset]
	inc de
	dec c
	jr nz, .copyFixedHeaderLoop
; initialize all the connected maps to disabled at first, before loading the actual values
	ld a, $ff
	ld [wMapConn1Ptr], a
	ld [wMapConn2Ptr], a
	ld [wMapConn3Ptr], a
	ld [wMapConn4Ptr], a
.getObjectDataPointer
	ld a, [hli]
	ld [wObjectDataPointerTemp], a
	ld a, [hli]
	ld [wObjectDataPointerTemp + 1], a
	push hl
	predef LoadTilesetHeader
	; callab LoadWildData
	pop hl ; restore hl from before going to the warp/sign/sprite data (this value was saved for seemingly no purpose)
	ld a, [wCurMapHeight] ; map height in 4x4 tile blocks
	add a ; double it
	ld [wCurrentMapHeight2], a ; store map height in 2x2 tile blocks
	ld a, [wCurMapWidth] ; map width in 4x4 tile blocks
	add a ; double it
	ld [wCurrentMapWidth2], a ; map width in 2x2 tile blocks
	ld a, [wCurMap]
	ld c, a
	ld b, $00
	ld a, [H_LOADEDROMBANK]
	ld [MBC1RomBank], a
	ret

; function to switch to the ROM bank that a map is stored in
; Input: a = map number
SwitchToMapRomBank::
	push hl
	push bc
	ld c, a
	ld b, $00
	ld a, Bank(MapHeaderBanks)
	call BankswitchHome ; switch to ROM bank 3
	ld hl, MapHeaderBanks
	add hl, bc
	ld a, [hl]
	ld [$ffe8], a ; save map ROM bank
	call BankswitchBack
	ld a, [$ffe8]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a ; switch to map ROM bank
	pop bc
	pop hl
	ret

BankswitchHome::
; switches to bank # in a
; Only use this when in the home bank!
	ld [wBankswitchHomeTemp], a
	ld a, [H_LOADEDROMBANK]
	ld [wBankswitchHomeSavedROMBank], a
	ld a, [wBankswitchHomeTemp]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

BankswitchBack::
; returns from BankswitchHome
	ld a, [wBankswitchHomeSavedROMBank]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

; function to copy map connection data from ROM to WRAM
; Input: hl = source, de = destination
CopyMapConnectionHeader::
	ld c, $0b
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	ret

LoadNorthSouthConnectionsTileMap::
	ld c, MAP_BORDER
.loop
	push de
	push hl
	ld a, [hNorthSouthConnectionStripWidth]
	ld b, a
.innerLoop
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .innerLoop
	pop hl
	pop de
	ld a, [hNorthSouthConnectedMapWidth]
	add l
	ld l, a
	jr nc, .noCarry1
	inc h
.noCarry1
	ld a, [wCurMapWidth]
	add MAP_BORDER * 2
	add e
	ld e, a
	jr nc, .noCarry2
	inc d
.noCarry2
	dec c
	jr nz, .loop
	ret

LoadEastWestConnectionsTileMap::
	push hl
	push de
	ld c, MAP_BORDER
.innerLoop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .innerLoop
	pop de
	pop hl
	ld a, [hEastWestConnectedMapWidth]
	add l
	ld l, a
	jr nc, .noCarry1
	inc h
.noCarry1
	ld a, [wCurMapWidth]
	add MAP_BORDER * 2
	add e
	ld e, a
	jr nc, .noCarry2
	inc d
.noCarry2
	dec b
	jr nz, LoadEastWestConnectionsTileMap
	ret
