lb: MACRO ; r, hi, lo
	ld \1, ((\2) & $ff) << 8 + ((\3) & $ff)
ENDM

homecall: MACRO
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, BANK(\1)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call \1
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
ENDM

farcall EQUS "callba"

callba: MACRO
	ld b, BANK(\1)
	ld hl, \1
	call Bankswitch
ENDM

callab: MACRO
	ld hl, \1
	ld b, BANK(\1)
	call Bankswitch
ENDM

jpba: MACRO
	ld b, BANK(\1)
	ld hl, \1
	jp Bankswitch
ENDM

jpab: MACRO
	ld hl, \1
	ld b, BANK(\1)
	jp Bankswitch
ENDM

validateCoords: MACRO
	IF \1 >= SCREEN_WIDTH
		fail "x coord out of range"
	ENDC
	IF \2 >= SCREEN_HEIGHT
		fail "y coord out of range"
	ENDC
ENDM

;\1 = r
;\2 = X
;\3 = Y
;\4 = which tilemap (optional)
coord: MACRO
	validateCoords \2, \3
	IF _NARG >= 4
		ld \1, \4 + SCREEN_WIDTH * \3 + \2
	ELSE
		ld \1, wTileMap + SCREEN_WIDTH * \3 + \2
	ENDC
ENDM

;\1 = X
;\2 = Y
;\3 = which tilemap (optional)
aCoord: MACRO
	validateCoords \1, \2
	IF _NARG >= 3
		ld a, [\3 + SCREEN_WIDTH * \2 + \1]
	ELSE
		ld a, [wTileMap + SCREEN_WIDTH * \2 + \1]
	ENDC
ENDM

;\1 = X
;\2 = Y
;\3 = which tilemap (optional)
Coorda: MACRO
	validateCoords \1, \2
	IF _NARG >= 3
		ld [\3 + SCREEN_WIDTH * \2 + \1], a
	ELSE
		ld [wTileMap + SCREEN_WIDTH * \2 + \1], a
	ENDC
ENDM

;\1 = X
;\2 = Y
;\3 = which tilemap (optional)
dwCoord: MACRO
	validateCoords \1, \2
	IF _NARG >= 3
		dw \3 + SCREEN_WIDTH * \2 + \1
	ELSE
		dw wTileMap + SCREEN_WIDTH * \2 + \1
	ENDC
ENDM

;\1 = r
;\2 = X
;\3 = Y
;\4 = map width
overworldMapCoord: MACRO
	ld \1, wOverworldMap + ((\2) + 3) + (((\3) + 3) * ((\4) + (3 * 2)))
ENDM

; macro for two nibbles
dn: MACRO
	db (\1 << 4 | \2)
ENDM

; macro for putting a byte then a word
dbw: MACRO
	db \1
	dw \2
ENDM

dba: MACRO
	dbw BANK(\1), \1
ENDM

dwb: MACRO
	dw \1
	db \2
ENDM

dab: MACRO
	dwb \1, BANK(\1)
ENDM

dbbw: MACRO
	db \1, \2
	dw \3
ENDM

; Predef macro.
predef_const: MACRO
	const \1PredefID
ENDM

add_predef: MACRO
\1Predef::
	db BANK(\1)
	dw \1
ENDM

predef_id: MACRO
	ld a, (\1Predef - PredefPointers) / 3
ENDM

predef: MACRO
	predef_id \1
	call Predef
ENDM

predef_jump: MACRO
	predef_id \1
	jp Predef
ENDM

tx_pre_const: MACRO
	const \1_id
ENDM

add_tx_pre: MACRO
\1_id:: dw \1
ENDM

db_tx_pre: MACRO
	db (\1_id - TextPredefs) / 2 + 1
ENDM

tx_pre_id: MACRO
	ld a, (\1_id - TextPredefs) / 2 + 1
ENDM

tx_pre: MACRO
	tx_pre_id \1
	call PrintPredefTextID
ENDM

tx_pre_jump: MACRO
	tx_pre_id \1
	jp PrintPredefTextID
ENDM

ldPal: MACRO
	ld \1, \2 << 6 | \3 << 4 | \4 << 2 | \5
ENDM

; tilesets' headers macro
tileset: MACRO
	db BANK(\2)   ; BANK(GFX)
	dw \1, \2, \3 ; Block, GFX, Coll
	db \4, \5, \6 ; counter tiles
	db \7         ; grass tile
	db \8         ; permission (indoor, cave, outdoor)
ENDM

INDOOR  EQU 0
CAVE    EQU 1
OUTDOOR EQU 2

PAL_SET: MACRO
	db ($a << 3) + 1
	dw \1, \2, \3, \4
	ds 7
ENDM

;\1 (byte) = current map id
;\2 (byte) = connected map id
;\3 (byte) = x movement of connection strip
;\4 (byte) = connection strip offset
;\5 (word) = connected map blocks pointer
NORTH_MAP_CONNECTION: MACRO
	db \2 ; map id
	dw \5 + (\2_WIDTH * (\2_HEIGHT - 3)) + \4; "Connection Strip" location
	dw wOverworldMap + 3 + \3 ; current map position
	IF (\1_WIDTH < \2_WIDTH)
		db \1_WIDTH - \3 + 3 ; width of connection strip
	ELSE
		db \2_WIDTH - \4 ; width of connection strip
	ENDC
	db \2_WIDTH ; map width
	db (\2_HEIGHT * 2) - 1 ; y alignment (y coordinate of player when entering map)
	db (\3 - \4) * -2 ; x alignment (x coordinate of player when entering map)
	dw wOverworldMap + 1 + (\2_HEIGHT * (\2_WIDTH + 6)) ; window (position of the upper left block after entering the map)
ENDM

;\1 (byte) = current map id
;\2 (byte) = connected map id
;\3 (byte) = x movement of connection strip
;\4 (byte) = connection strip offset
;\5 (word) = connected map blocks pointer
;\6 (flag) = add 3 to width of connection strip (why?)
SOUTH_MAP_CONNECTION: MACRO
	db \2 ; map id
	dw \5 + \4 ; "Connection Strip" location
	dw wOverworldMap + 3 + (\1_HEIGHT + 3) * (\1_WIDTH + 6) + \3 ; current map position
	IF (\1_WIDTH < \2_WIDTH)
		IF (_NARG > 5)
			db \1_WIDTH - \3 + 3 ; width of connection strip
		ELSE
			db \1_WIDTH - \3 ; width of connection strip
		ENDC
	ELSE
		db \2_WIDTH - \4 ; width of connection strip
	ENDC
	db \2_WIDTH ; map width
	db 0  ; y alignment (y coordinate of player when entering map)
	db (\3 - \4) * -2 ; x alignment (x coordinate of player when entering map)
	dw wOverworldMap + 7 + \2_WIDTH ; window (position of the upper left block after entering the map)
ENDM

;\1 (byte) = current map id
;\2 (byte) = connected map id
;\3 (byte) = y movement of connection strip
;\4 (byte) = connection strip offset
;\5 (word) = connected map blocks pointer
WEST_MAP_CONNECTION: MACRO
	db \2 ; map id
	dw \5 + (\2_WIDTH * \4) + \2_WIDTH - 3 ; "Connection Strip" location
	dw wOverworldMap + (\1_WIDTH + 6) * (\3 + 3) ; current map position
	IF (\1_HEIGHT < \2_HEIGHT)
		db \1_HEIGHT - \3 + 3 ; height of connection strip
	ELSE
		db \2_HEIGHT - \4 ; height of connection strip
	ENDC
	db \2_WIDTH ; map width
	db (\3 - \4) * -2 ; y alignment
	db (\2_WIDTH * 2) - 1 ; x alignment
	dw wOverworldMap + 6 + (2 * \2_WIDTH) ; window (position of the upper left block after entering the map)
ENDM

;\1 (byte) = current map id
;\2 (byte) = connected map id
;\3 (byte) = y movement of connection strip
;\4 (byte) = connection strip offset
;\5 (word) = connected map blocks pointer
;\6 (flag) = add 3 to height of connection strip (why?)
EAST_MAP_CONNECTION: MACRO
	db \2 ; map id
	dw \5 + (\2_WIDTH * \4) ; "Connection Strip" location
	dw wOverworldMap - 3 + (\1_WIDTH + 6) * (\3 + 4) ; current map position
	IF (\1_HEIGHT < \2_HEIGHT)
		IF (_NARG > 5)
			db \1_HEIGHT - \3 + 3 ; height of connection strip
		ELSE
			db \1_HEIGHT - \3 ; height of connection strip
		ENDC
	ELSE
		db \2_HEIGHT - \4 ; height of connection strip
	ENDC
	db \2_WIDTH ; map width
	db (\3 - \4) * -2 ; y alignment
	db 0 ; x alignment
	dw wOverworldMap + 7 + \2_WIDTH ; window (position of the upper left block after entering the map)
ENDM

; Constant enumeration is useful for monsters, items, moves, etc.
const_def: MACRO
const_value = 0
ENDM

const: MACRO
\1 EQU const_value
const_value = const_value + 1
ENDM

;\1 sprite id
;\2 x position
;\3 y position
;\4 movement (WALK/STAY)
;\5 range or direction
;\6 text id
;\7 items only: item id
;\7 trainers only: trainer class/pokemon id
;\8 trainers only: trainer number/pokemon level
object: MACRO
	db \1
	db \3 + 4
	db \2 + 4
	db \4
	db \5
	IF (_NARG > 7)
		db TRAINER | \6
		db \7
		db \8
	ELSE
		IF (_NARG > 6)
			db ITEM | \6
			db \7
		ELSE
			db \6
		ENDC
	ENDC
ENDM

;\1 x position
;\2 y position
;\3 destination warp id
;\4 destination map (-1 = wLastMap)
warp: MACRO
	db \2, \1, \3, \4
ENDM

;\1 x position
;\2 y position
;\3 sign id
sign: MACRO
	db \2, \1, \3
ENDM

;\1 x position
;\2 y position
;\3 map width
warp_to: MACRO
	EVENT_DISP \3, \2, \1
ENDM

;\1 = Map Width
;\2 = Rows above (Y-blocks)
;\3 = X movement (X-blocks)
EVENT_DISP: MACRO
	dw (wOverworldMap + 7 + (\1) + ((\1) + 6) * ((\2) >> 1) + ((\3) >> 1)) ; Ev.Disp
	db \2,\3 ;Y,X
ENDM
