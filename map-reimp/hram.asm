; these values are copied to SCX, SCY, and WY during V-blank
hSCX EQU $FFAE
hSCY EQU $FFAF

hJoyInput EQU $FFF5

hJoyLast EQU $FFB1
hJoyReleased EQU $FFB2
hJoyPressed EQU $FFB3
hJoyHeld EQU $FFB4

H_VBLANKOCCURRED EQU $FFD6

; controls whether a row or column of 2x2 tile blocks is redrawn in V-blank
; 00 = no redraw
; 01 = redraw column
; 02 = redraw row
hRedrawRowOrColumnMode EQU $FFD0

; the starting location to redraw column/row tiles. generated from `[wCurBlockMapViewPtr]`
hRedrawRowOrColumnDest EQU $FFD1

; Location where the DMA Transfer procedure will live
hDMATransferProc EQU $FF80
