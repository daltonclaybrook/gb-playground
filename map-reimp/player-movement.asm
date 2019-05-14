section "Player", rom0

UpdatePlayer::
    call UpdatePlayerDeltas
    ld a, [wPlayerDeltaY]
    ld b, a
    ld a, [wPlayerDeltaX]
    ld c, a
    or b
    call nz, AdvancePlayer ; advance player if deltas are not zero
    call DrawPlayer
    ret

; Advance the players position
AdvancePlayer::
    call UpdatePlayerColliding
    ld hl, wWalkCounter
    dec [hl]
    jr nz, .checkForWalkStart
    ld a, [wPlayerY]
    add b
    ld [wPlayerY], a
    ld a, [wPlayerX]
    add c
    ld [wPlayerX], a
    xor a
    ld [wPlayerDeltaY], a
    ld [wPlayerDeltaX], a
.checkForWalkStart
    ld a, 7
    cp [hl] ; check if we're on the first iteration of AdvancePlayer
    push bc
    call z, PrepareToDrawMapEdge
    pop bc
    ld a, [hSCY]
    sla b
    add b
    ld [hSCY], a
    ld a, [hSCX]
    sla c
    add c
    ld [hSCX], a
    ret

; Update the collision state variable
;
; b = delta y
; c = delta x
;
; Proc:
; - get x & y of block the player is moving to (add delta, then divide by 2)
; - get ptr offset in block map file (y * [wCurMapWidth] + x)
; - get block ID at ptr offset
; - create pointer to block id in block set file (multiply by $10)
; - offset pointer by [wPlayerBlockY] (ptr + y * 8) and [wPlayerBlockX] (ptr + x * 4)
; - get tile number at pointer
; - search through collision file for tile number
; - if tile number is not found, a collision occurrs
UpdatePlayerColliding::
    push bc
    ld a, [wPlayerBlockY]
    add b
    and $01
    ld d, a
    ld a, [wPlayerBlockX]
    add c
    and $01
    ld e, a
    push de ; de == block y and x adjusted for the deltas
    ld a, [wPlayerY]
    add b
    srl a ; divide by 2
    add MAP_BORDER
    ld d, a
    ld a, [wPlayerX]
    add c
    srl a ; divide by 2
    add MAP_BORDER
    ld e, a ; d & e are y & x of the block in the block map + border
    ld b, d ; factor 1 = y
    ld a, [wCurMapStride]
    ld c, a ; factor 2 = map stride
    call Multiply ; hl = y * map stride
    jr .breakpoint0
.breakpoint0
    ld d, 0
    add hl, de ; add x to hl. hl == ptr offset in block map
    ld bc, wCurBlockMap
    add hl, bc ; hl == ptr to block
    ld a, [hl] ; a = block ID
    jr .breakpoint1
.breakpoint1
    swap a
    ld l, a
    and $0f
    ld h, a
    ld a, l
    and $f0
    ld l, a ; hl == block ID * $10
    jr .breakpoint2
.breakpoint2
    pop de ; originally pushed de, which contains the adjusted block y & x values
    sla d
    sla d
    sla d ; `sla d` 3 times to multiply y by 8
    ld b, 0
    ld c, d
    jr .breakpoint3
.breakpoint3
    add hl, bc ; hl is now offset by block y
    sla e ; `sla e` 1 time to multiply x by 2
    ld c, e
    add hl, bc ; hl is now offset by block x and y
    jr .breakpoint4
.breakpoint4
    ld a, [wCurTilesetBlocksPtr]
    ld e, a
    ld a, [wCurTilesetBlocksPtr + 1]
    ld d, a
    jr .breakpoint5
.breakpoint5
    add hl, de ; hl == ptr to tile that we're walking towards
    ld a, [hl] 
    ld d, a ; d == tile that we're walking towards
    ld a, [wCurTilesetCollPtr]
    ld l, a
    ld a, [wCurTilesetCollPtr + 1]
    ld h, a ; hl = start of collision data
    pop bc ; return bc to origin delta x and y
.loop
    ld a, [hli]
    cp a, d ; check if collision tile equals the one we're walking towards (d)
    jr z, .passable
    cp a, $ff
    jr z, .collision
    jr .loop
.passable
    xor a
    ld [wPlayerIsColliding], a
    ret
.collision
    ld a, 1
    ld [wPlayerIsColliding], a
    ret

PrepareToDrawMapEdge::
    call TogglePlayerOddStep
    ld a, b
    cp $ff ; check moving north
    jr nz, .checkMovingSouth
    ld a, DIRECTION_NORTH
    ld [wPlayerFacingDirection], a
    ld a, [wMapViewVRAMPointer]
    sub $40
    ld [wMapViewVRAMPointer], a
    jr nc, .adjustYCoordWithinBlock
    ld a, [wMapViewVRAMPointer + 1]
    dec a
    and $03 ; these two lines keep the high byte in the range of $98 - $9b
    or $98
    ld [wMapViewVRAMPointer + 1], a 
    jr .adjustYCoordWithinBlock
.checkMovingSouth::
    cp 1
    jr nz, .checkMovingEast
    ld a, DIRECTION_SOUTH
    ld [wPlayerFacingDirection], a
    ld a, [wMapViewVRAMPointer]
    add $40
    ld [wMapViewVRAMPointer], a
    jr nc, .adjustYCoordWithinBlock
    ld a, [wMapViewVRAMPointer + 1]
    inc a
    and $03
    or $98
    ld [wMapViewVRAMPointer + 1], a
    jr .adjustYCoordWithinBlock
.checkMovingEast::
    ld a, c
    cp 1
    jr nz, .checkMovingWest
    ld a, DIRECTION_EAST
    ld [wPlayerFacingDirection], a
    ld a, [wMapViewVRAMPointer]
    ld e, a
    and $e0 ; the following lines make sure the add doesn't overflow past $1f in order to keep the pointer on the same row
    ld d, a
    ld a, e    
    add $02
    and $1f
    or d
    ld [wMapViewVRAMPointer], a
    jr .adjustYCoordWithinBlock
.checkMovingWest::
    cp -1
    jr nz, .updateMapView
    ld a, DIRECTION_WEST
    ld [wPlayerFacingDirection], a
    ld a, [wMapViewVRAMPointer]
    ld e, a
    and $e0
    ld d, a
    ld a, e
    sub $02
    and $1f
    or d
    ld [wMapViewVRAMPointer], a
    jr .adjustYCoordWithinBlock
.adjustYCoordWithinBlock::
    ld hl, wPlayerBlockY
    ld a, [hl]
    add b ; add delta y to block coord
    ld [hl], a
    cp $02
    jr nz, .checkYBlockCoordUnderflow
    xor a
    ld [hl], a
    call MoveTileBlockMapPointerSouth
    jr .updateMapView
.checkYBlockCoordUnderflow::
    cp $ff
    jr nz, .adjustXCoordWithinBlock
    ld a, $01
    ld [hl], a
    call MoveTileBlockMapPointerNorth
    jr .updateMapView
.adjustXCoordWithinBlock::
    ld hl, wPlayerBlockX
    ld a, [hl]
    add c ; add delta x
    ld [hl], a
    cp $02
    jr nz, .checkXBlockCoordUnderflow
    xor a
    ld [hl], a
    call MoveTileBlockMapPointerEast
    jr .updateMapView
.checkXBlockCoordUnderflow::
    cp $ff
    jr nz, .updateMapView
    ld a, $01
    ld [hl], a
    call MoveTileBlockMapPointerWest
    jr .updateMapView
.updateMapView::
    call LoadAndCopyMapTiles
    ld a, [wPlayerDeltaY]
    ; check north redraw
    cp $ff
    jr nz, .checkSouthRedraw
    call ScheduleNorthRowRedraw
    jr .finish
.checkSouthRedraw::
    cp $01
    jr nz, .checkEastRedraw
    call ScheduleSouthRowRedraw
    jr .finish
.checkEastRedraw::
    ld a, [wPlayerDeltaX]
    cp $01
    jr nz, .checkWestRedraw
    call ScheduleEastColumnRedraw
    jr .finish
.checkWestRedraw::
    cp $ff
    jr nz, .finish
    call ScheduleWestColumnRedraw
.finish::
    ret

; flip [wPlayerOddStep] between 0 and 1
TogglePlayerOddStep::
    ld a, [wPlayerOddStep]
    cpl
    and $01
    ld [wPlayerOddStep], a
    ret

MoveTileBlockMapPointerNorth::
    ld de, wCurBlockMapViewPtr
    ld a, [wCurMapStride]
    ld b, a
    ld a, [de]
    sub b
    ld [de], a
    ret nc
    inc de
    ld a, [de]
    dec a
    ld [de], a
    ret

MoveTileBlockMapPointerSouth::
    ld de, wCurBlockMapViewPtr
    ld a, [wCurMapStride]
    ld b, a
    ld a, [de]
    add b
    ld [de], a
    ret nc
    inc de
    ld a, [de]
    inc a
    ld [de], a
    ret

MoveTileBlockMapPointerEast::
    ld de, wCurBlockMapViewPtr
    ld a, [de]
    inc a
    ld [de], a
    ret nc
    inc de
    ld a, [de]
    inc a
    ld [de], a
    ret

MoveTileBlockMapPointerWest::
    ld de, wCurBlockMapViewPtr
    ld a, [de]
    dec a
    ld [de], a
    ret nc
    inc de
    ld a, [de]
    dec a
    ld [de], a
    ret

ScheduleNorthRowRedraw::
    coord de, 0, 0
    ld hl, wRedrawRowOrColumnSrcTiles
    ld bc, SCREEN_WIDTH * 2
    call CopyData
    ld a, [wMapViewVRAMPointer]
    ld [hRedrawRowOrColumnDest], a
    ld a, [wMapViewVRAMPointer + 1]
    ld [hRedrawRowOrColumnDest + 1], a
    ld a, REDRAW_ROW
    ld [hRedrawRowOrColumnMode], a
    ret

ScheduleSouthRowRedraw::
    coord de, 0, 16 ; copy bottom two rows (screen has 18 rows)
    ld hl, wRedrawRowOrColumnSrcTiles
    ld bc, SCREEN_WIDTH * 2
    call CopyData
    ld a, [wMapViewVRAMPointer]
    ld l, a
    ld a, [wMapViewVRAMPointer + 1]
    ld h, a
    ld bc, $200 ; 16 rows of 32 tiles
    add hl, bc
    ld a, h
    and $03 ; keep the high byte in the range $98-$9b
    or $98
    ld [hRedrawRowOrColumnDest + 1], a
    ld a, l
    ld [hRedrawRowOrColumnDest], a
    ld a, REDRAW_ROW
    ld [hRedrawRowOrColumnMode], a
    ret

ScheduleEastColumnRedraw::
    coord de, 18, 0
    call ColumnRedrawHelper
    ld a, [wMapViewVRAMPointer]
    ld c, a
    and $e0
    ld b, a
    ld a, c
    add 18
    and $1f
    or b
    ld [hRedrawRowOrColumnDest], a
    ld a, [wMapViewVRAMPointer + 1]
    ld [hRedrawRowOrColumnDest + 1], a
    ld a, REDRAW_COL
    ld [hRedrawRowOrColumnMode], a
    ret

ScheduleWestColumnRedraw::
    coord de, 0, 0
    call ColumnRedrawHelper
    ld a, [wMapViewVRAMPointer]
    ld [hRedrawRowOrColumnDest], a
    ld a, [wMapViewVRAMPointer + 1]
    ld [hRedrawRowOrColumnDest + 1], a
    ld a, REDRAW_COL
    ld [hRedrawRowOrColumnMode], a
    ret

ColumnRedrawHelper::
    ld hl, wRedrawRowOrColumnSrcTiles
    ld c, SCREEN_HEIGHT
.loop::
    ld a, [de]
    ld [hli], a
    inc de
    ld a, [de]
    ld [hli], a
    ld a, 19 ; 1 row minus 1 tile
    add e
    ld e, a
    jr nc, .noCarry
    inc d
.noCarry::
    dec c
    jr nz, .loop
    ret

; read from Joypad and update player deltas if necessary
UpdatePlayerDeltas::
    ld hl, wWalkCounter
    ld a, [hl]
    and a
    ret nz
    ld a, [hJoyHeld]
    bit JOYPAD_UP_BIT, a
    jr z, .checkDownButton
    ld a, -1
    ld [wPlayerDeltaY], a
    jr .handleDirectionPressed
.checkDownButton
    bit JOYPAD_DOWN_BIT, a
    jr z, .checkRightButton
    ld a, 1
    ld [wPlayerDeltaY], a
    jr .handleDirectionPressed
.checkRightButton
    bit JOYPAD_RIGHT_BIT, a
    jr z, .checkLeftButton
    ld a, 1
    ld [wPlayerDeltaX], a
    jr .handleDirectionPressed
.checkLeftButton
    bit JOYPAD_LEFT_BIT, a
    jr z, .finish
    ld a, -1
    ld [wPlayerDeltaX], a
.handleDirectionPressed
    ld [hl], PLAYER_WALK_COUNT ; reset countdown
.finish
    ret
