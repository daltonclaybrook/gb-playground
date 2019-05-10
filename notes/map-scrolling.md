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
* If the counter does not equal 7, jump directly to then end, update the BG scroll position (e.g. `[hSCY]`), and return
* If the counter equals 7, this is our first iteration of `AdvancePlayerSprite` and the process is started for drawing the edge of the map.
* `[wMapViewVRAMPointer]` is updated based on the deltas:
  * If moving east/west, add/subtract 2 and do bit math to keep the pointer on the same row of the BG map
  * If moving north/sout, add/subtract `$40` (2 rows of `$10`) and do bit math to keep the high byte in the `$98` - `$9b` range.
* If the VRAM pointer was updated, try to adjust `[wXBlockCoord]` or `[wYBlockCoord]`.
  * This value represents the player's offset inside a block
  * Since blocks are 4x4 tiles, but a player takes up 2x2 tiles, this value can be 0 or 1.
  * Check each direction (N/S/E/W) individually and update this value
  * If the update underflows or overflows (2) this variable, `[wCurrentTileBlockMapViewPointer]` is updated accordingly (MoveTileBlockMapPointerEast, etc)
* Advance to `.updateMapView` label.
* Build a tile map from block map + view pointer (described in `pokemon-maps.md` under "Block map tiles are loaded into WRAM")
* Check the deltas again and schedule a redraw of a row/column as necessary:
  * When scheduling a redraw, tiles are copied from the edge of `[wTileMap]` to a buffer: `[wRedrawRowOrColumnSrcTiles]`
  * South row example:
    * create a coordinate pointing to the upper left point of the bottom two rows (`coord hl, 0, 16`)
    * Copy tiles from this pointer to `[wRedrawRowOrColumnSrcTiles]`, counting down from `SCREEN_WIDTH * 2` (2 rows of tiles)
  * East column example:
    * Create a coordinate to the upper left point of the right two rows (`coord hl, 18, 0`)
    * Destination pointer is set to `[wRedrawRowOrColumnSrcTiles]`
    * Counter is set to `SCREEN_HEIGHT`
    * Copy two tiles
    * Add `19` to the source pointer (1 row minus 1 tile)
    * loop
  * `[wMapViewVRAMPointer]` is converted and stored in `[hRedrawRowOrColumnDest]`
    * For north and west sides, the pointer stays the same
    * for east side, add `18` to the pointer, then do bit math to make sure the pointer stays on the same row
    * for south side, add `$0200` (`$10` rows of `$20` tiles), then do bit math to make sure high byte stays in the range `$98` - `$9b`
    * set `[hRedrawRowOrColumnMode]` to either `REDRAW_COL` or `REDRAW_ROW`
      * It seems important that this be done last beause the vblank handler uses this value to start redrawing

### RedrawRowOrColumn (called from VBlank handler)

* Check `[hRedrawRowOrColumnMode]` and return if zero
* set it to zero
* jump to draw row or draw column label based on flag
* source pointer is `[wRedrawRowOrColumnSrcTiles]`
* destination pointer is `[hRedrawRowOrColumnDest]`
* loop and copy all tiles to VRAM

### New variables

* `[hRedrawRowOrColumnMode]` - The current redraw mode used from the VBlank handler. Values are `REDRAW_COL`, `REDRAW_ROW`, or zero (don't redraw anything)
* `[wRedrawRowOrColumnSrcTiles]` - A linear list of tiles to redraw in a row or column
* `[hRedrawRowOrColumnDest]` - The starting location to redraw row or column tiles. This is generated from `[wMapViewVRAMPointer]`, and is equal to `[wMapViewVRAMPointer]` when redrawing the north or west side
* `[wYCoord]` and `[wXCoord]` - The player's position in player coordinate space. Since a player takes up 2x2 tiles, divide tile coordinate by 2 to get player coordinate.
* `[wXBlockCoord]` and `[wYBlockCoord]` - The player's offset inside the current block. Can be 0 or 1.

Notes:

* Lot of bit math going on when the VRAM pointer is updated:
  * East/West bit math makes sure the new value stays on the same row (e.g. $9800 - $981f)
  * North/South bit math makes sure a carry doesn't move the high byte out of the range ($98 - $9b)
* `_AdvancePlayerSprite` is only called while the player is moving, so after the walk counter has been set to 8
