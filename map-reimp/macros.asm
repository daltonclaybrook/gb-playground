; Define a tileset
;
; - Param 1: Blockset address
; - Param 2: GFX address
; - Param 3: Tile collision address
tileset: MACRO
    dw \1, \2, \3 ; Blockset, GFX, Tilecoll
ENDM

; Define a Block Map
;
; - Param 1: Tileset index
; - Param 2: Width in blocks
; - Param 3: Height in blocks
; - Param 4: Block map address
map: MACRO
    db \1 ; Tileset index
    db \2, \3 ; Width and Height of blocks in map
    dw \4 ; Block Map
ENDM

; Start defining constants
const_def: MACRO
const_value = 0
ENDM

; Define a constant
const: MACRO
\1 EQU const_value
const_value = const_value + 1
ENDM

; Define a two-byte RGB color
;
; color value intensities range from 0 - 31
; e.g. RGB 31, 31, 31 is white
RGB: MACRO
    dw (\3 << 10 | \2 << 5 | \1)
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
coord: MACRO
	validateCoords \2, \3
	ld \1, wTileMap + SCREEN_WIDTH * \3 + \2
ENDM
