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
    and a
    jr z, .updateEastWestVRAMPointer
.updateEastWestVRAMPointer
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
