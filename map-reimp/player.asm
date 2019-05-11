section "Player", rom0

UpdatePlayer::
    call UpdatePlayerDeltas
    ld a, [wPlayerDeltaY]
    ld b, a
    ld a, [wPlayerDeltaX]
    ld c, a
    or b
    call nz, AdvancePlayer ; advance player if deltas are not zero
    ret

; Advance the players position
AdvancePlayer::
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
    call z, PrepareToDrawMapEdge
    ld a, [hSCY]
    sla b
    add b
    ld [hSCY], a
    ld a, [hSCX]
    sla c
    add c
    ld [hSCX], a
    ret

PrepareToDrawMapEdge::
    ld a, b
    cp -1 ; check moving north
    jr nz, .checkMovingSouth
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
    jr nz, .finish
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
    ld hl, wYBlockCoord
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
    xor a
    ld [hl], a
    call MoveTileBlockMapPointerNorth
    jr .updateMapView
.adjustXCoordWithinBlock::
    ld hl, wXBlockCoord
    ld a, [hl]
    add c, ; add delta x
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
    xor a
    ld [hl], a
    call MoveTileBlockMapPointerWest
    jr .updateMapView
.updateMapView::

.finish::
    ret

MoveTileBlockMapPointerNorth::
    ret
MoveTileBlockMapPointerSouth::
    ret
MoveTileBlockMapPointerEast::
    ret
MoveTileBlockMapPointerWest::
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
