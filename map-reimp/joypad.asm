section "Joypad", rom0

ReadJoypad::
    ld a, 1 << 5 ; directional keys
    ld [rP1], a ; select directional keys
    ld a, [rP1]
    ld a, [rP1] ; do this twice because hardware is weird
    cpl ; low-bit means pressed, so invert them
	and %1111 ; mask off bits that aren't directions
    swap a
    ld b, a

    ld a, 1 << 4 ; select button keys
    ld [rP1], a
    rept 6 ; what the fresh hell is this all about? Hardware is weird.
	ld a, [rP1]
	endr
    cpl
	and %1111
	or b ; a = high nibble is directional pad, low nibble is start/select/B/A

    ld [hJoyInput], a
    
    ld a, 1 << 4 | 1 << 5 ; deselect keys
    ld [rP1], a
    ret

; hJoyReleased: (hJoyLast ^ hJoyInput) & hJoyLast
; hJoyPressed:  (hJoyLast ^ hJoyInput) & hJoyInput
UpdateJoypadState::
    ld a, [hJoyInput]
    ld b, a
    ld a, [hJoyLast]
    ld e, a
    xor b
    ld d, a
    and e
    ld [hJoyReleased], a
    ld a, d
    and b
    ld [hJoyPressed], a
    ld a, b
    ld [hJoyLast], a
    ld [hJoyHeld], a
    ret
