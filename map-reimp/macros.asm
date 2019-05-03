; Define a tileset
;
; - Param 1: Blockset address
; - Param 2: GFX address
tileset: MACRO
    dw \1, \2 ; Blockset, GFX
ENDM

; Define a Block Map
;
; - Param 1: Tileset index
; - Param 2: Height in blocks
; - Param 3: Width in blocks
; - Param 4: Block map address
map: MACRO
    db \1 ; Tileset index
    db \2, \3 ; Height and Width of blocks in map
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
