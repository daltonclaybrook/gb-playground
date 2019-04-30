section "Tileset header", rom0

LoadTilesetHeader:
	; call GetPredefRegisters
	push hl
	ld d, 0
	ld a, [wCurMapTileset]
	add a
	add a
	ld b, a
	add a
	add b ; a = tileset * 12
	jr nc, .noCarry
	inc d
.noCarry
	ld e, a
	ld hl, Tilesets
	add hl, de
	ld de, wTilesetBank
	ld c, $b
.copyTilesetHeaderLoop
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copyTilesetHeaderLoop
	ld a, [hl]
	ld [hTilesetType], a
	xor a
	ld [$ffd8], a
	pop hl
	ld a, [wCurMapTileset]
	push hl
	push de
	ld hl, DungeonTilesets
	ld de, $1
	call IsInArray
	pop de
	pop hl
	jr c, .asm_c797
	ld a, [wCurMapTileset]
	ld b, a
	ld a, [hPreviousTileset]
	cp b
	jr z, .done
.asm_c797
	ld a, [wDestinationWarpID]
	cp $ff
	jr z, .done
	call LoadDestinationWarpPosition
	ld a, [wYCoord]
	and $1
	ld [wYBlockCoord], a
	ld a, [wXCoord]
	and $1
	ld [wXBlockCoord], a
.done
	ret

IsInArray::
; Search an array at hl for the value in a.
; Entry size is de bytes.
; Return count b and carry if found.
	ld b, 0

IsInRestOfArray::
	ld c, a
.loop
	ld a, [hl]
	cp -1
	jr z, .notfound
	cp c
	jr z, .found
	inc b
	add hl, de
	jr .loop

.notfound
	and a
	ret

.found
	scf
	ret

; function to load position data for destination warp when switching maps
; INPUT:
; a = ID of destination warp within destination map
LoadDestinationWarpPosition::
	ld b, a
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, [wPredefParentBank]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ld a, b
	add a
	add a
	ld c, a
	ld b, 0
	add hl, bc
	ld bc, 4
	ld de, wCurrentTileBlockMapViewPointer
	call CopyData
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ret

const_value = 0

	const OVERWORLD    ; 0
	const REDS_HOUSE_1 ; 1
	const MART         ; 2
	const FOREST       ; 3
	const REDS_HOUSE_2 ; 4
	const DOJO         ; 5
	const POKECENTER   ; 6
	const GYM          ; 7
	const HOUSE        ; 8
	const FOREST_GATE  ; 9
	const MUSEUM       ; 10
	const UNDERGROUND  ; 11
	const GATE         ; 12
	const SHIP         ; 13
	const SHIP_PORT    ; 14
	const CEMETERY     ; 15
	const INTERIOR     ; 16
	const CAVERN       ; 17
	const LOBBY        ; 18
	const MANSION      ; 19
	const LAB          ; 20
	const CLUB         ; 21
	const FACILITY     ; 22
	const PLATEAU      ; 23

DungeonTilesets:
	db FOREST, MUSEUM, SHIP, CAVERN, LOBBY, MANSION, GATE, LAB, FACILITY, CEMETERY, GYM, $FF
Tilesets::
	tileset Overworld_Block,   Overworld_GFX,   Overworld_Coll,   $FF,$FF,$FF, $52, OUTDOOR

SECTION "bank19", ROMX
Overworld_GFX:     INCBIN "map/overworld.2bpp"
Overworld_Block:   INCBIN "map/overworld.bst"
Overworld_Coll::    INCBIN  "map/overworld.tilecoll"
