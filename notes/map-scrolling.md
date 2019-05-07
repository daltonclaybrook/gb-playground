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
* If `[wWalkCounter]` has reached zero, add deltas to `[wYCoord]` and `[wXCoord]`. (These are the player's current block coordinate, I think)
