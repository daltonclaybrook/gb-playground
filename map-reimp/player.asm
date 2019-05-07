section "Player", rom0

; Advance the players position
AdvancePlayer::
    call UpdatePlayerDeltas
    ld a, [wPlayerDeltaY]
    ld b, a
    ld a, [wPlayerDeltaX]
    ld c, a
    or b
    ret z ; return if deltas are zero; don't decrement counter or update screen scroll
    ld hl, wWalkCounter
    dec [hl]
    jr nz, .afterUpdateMapCoords
    ld a, [wPlayerY]
    add b
    ld [wPlayerY], a
    ld a, [wPlayerX]
    add c
    ld [wPlayerX], a
    xor a
    ld [wPlayerDeltaY], a
    ld [wPlayerDeltaX], a
.afterUpdateMapCoords
    ld a, [hSCY]
    add b
    ld [hSCY], a
    ld a, [hSCX]
    add c
    ld [hSCX], a
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
