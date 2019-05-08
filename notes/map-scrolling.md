# How maps are scrolled and redrawn in Pokemon

This is a oversimplified and possible inaccurate description.

* User presses a direction on the joypad
* In the `OverworldLoop`...
  * if `[wWalkCounter]` does not equal zero, don't update move variables
  * Joypad state is checked and sprite delta is updated
    * `[wSpriteStateData1 + 3]` is delta Y, -1 for up, 1 for down
    * `[wSpriteStateData1 + 5]` is delta X, -1 for left, 1 for right
    * both are reset to 0 if not moving
  * calls `AdvancePlayerSprite`

### AdvancePlayerSprite

* Load delta Y and X, which has just been set elsewhere
* Load and decrement `[wWalkCounter]`. `AdvancePlayerSprite` is only called while the walk counter is non-zero, so no fear of rolling this over.
* If walk counter equals zero, deltas are added to `[wYCoord]` and `[wXCoord]`, which represent the player's current block coordinate.
* If the counter equals 7, this is our first iteration of `AdvancePlayerSprite` and the process is started for drawing the edge of the map.
* `[wMapViewVRAMPointer]` is updated based on the deltas:
  * If moving east/west, add/subtract 2 and do bit math to keep the pointer on the same row of the BG map
  * If moving north/sout, add/subtract `$40` (2 rows of `$10`) and do bit math to keep the high byte in the `$98` - `$9b` range.

Notes:

* Lot of bit math going on when the VRAM pointer is updated:
  * East/West bit math makes sure the new value stays on the same row (e.g. $9800 - $981f)
  * North/South bit math makes sure a carry doesn't move the high byte out of the range ($98 - $9b)
* `_AdvancePlayerSprite` is only called while the player is moving, so after the walk counter has been set to 8
