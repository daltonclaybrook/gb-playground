# How Pokemon Red/Blue Draws Maps

## Components

* **Tilesets**: The tile image data itself.
  * Each Tileset file represents a block of pixels to be loaded into the Tileset VRAM.
  * From what I can tell, this data is always loaded into `$9000` - `$97FF`
    * $8000 - $8FFF seems to be reserved for sprite tiles
  * In the Pokemon project, running `make` will take all Tileset `.png` files and run them through `rgbgfx` to create `.2bpp` files for use in the Gameboy.
  * These may be 1-1 associated with a Blockset, but not sure
    * e.g. "overworld.2bpp" <-> "overworld.bst"
* **Blocksets**: A binary list of "blocks" which are sets of 4x4 tiles
  * Each Block takes up 16 bytes; each byte points to a tile in a Tileset
    * The byte is an offset from $9000 in VRAM, e.g. $2C -> $902C
  * Blocks in a Blockset have incremental "IDs" ($01, $02, $03, etc)
    * A block ID * $10 equals the blocks starting location in the Blockset file
  * Blocksets are generic like Tilesets and can be used in many different locations throughout the game
* **Block Maps**: A binary list of "Block IDs" which refer to locations in a Blockset
  * These are specific areas in the game, such as "Pallet Town"
  * A Block map != a BG Map in VRAM.
    * BG Maps in VRAM are 32 x 32 tiles
    * Block Maps have a dynamic size which is specified in a corresponding "Map Header"
* **Map Headers**: `.asm` files which specify metadata about a Block Map
  * Pointer to Tileset (or Blockset?)
  * Width and height in blocks
  * Pointer to Block Map file
  * Other info unrelated to drawing the map, such as text, connections, and sprites

## Procedure for loading a Map

Still a bit fuzzy on how the data finally ends up in VRAM, but it seems like it goes:

### Map metadata is loaded into RAM

* `[wCurMap]` is added to `MapHeaderPointers` to get location to correct map header
* The first 10 bytes of the header are loaded into WRAM sequentially (The WRAM layout is important here).
  * Starts with `[wCurMapTileset]`
  * `[wCurMapHeight]`
  * `[wCurMapWidth]`
  * `[wMapDataPtr]` - The "Block Map" file which points to blocks
  * `[wMapTextPtr]` - Not using this right now
  * `[wMapScriptPtr]` - Not using this right now
  * `[wMapConnections]` - bitmask of N/S/E/W map connections. Currently unused.

### Block Map is loaded into WRAM

* Space has been predefined at `wOverworldMap` for the Map block IDs (1300 bytes)
* All 1300 ($0514) bytes are filled with a background tile at  `[wMapBackgroundTile]`
* `[hMapWidth]` is loaded from `[wCurMapWidth]` (not sure why this needs to be put in HRAM...)
* `[hMapStride]` is put in VRAM as the map width + `MAP_BORDER` * 2
* A pointer is created at `wOverworldMap` + `[hMapStride]` * `MAP_BORDER` + `MAP_BORDER`. This will be the location of the first tile block on the upper west side of the map accounting for border.
* Each row of block ID bytes stored at `[wMapDataPtr]` is copied to the incrementing pointer location, then the pointer is incremented by `[hMapStride]` to account for the border
* Connections are setup (Don't really care about this at the moment).

### Tileset "header" is loaded into WRAM

* A pointer is created to `Tilesets` + `[wCurMapTileset]` * 12 because a Tileset "header" is 12 bytes
* This header is loaded sequentially into WRAM, which is layed out such that the following refs are populated.
  * `[wTilesetBank]` - the ROM bank number where the Tileset is stored
  * `[wTilesetBlocksPtr]` - Pointer to the Blockset file for the Tileset
  * `[wTilesGfxPtr]` - Pointer to the Tileset GFX file (e.g. overworld.2bpp)
  * `[wTilesetCollisionPtr]` - Pointer to a collision file (I'm not using this at the moment)
  * Additional metadata that I'm not using

### Tileset GFX is loaded into VRAM

* Pointer is created to `[wTilesetGfxPtr]` which was assigned when the tileset header was loaded.
* Pointer is created to `$9000`, the first address in tileset VRAM we want to write to
* Count down register is set to a constant `$600` which is 6 rows of tiles and the full size of the Gfx file
* Tiles are loaded into VRAM sequentially

### Block map is loaded into WRAM

* Switch to the ROM bank in `[wTilesetBank]`
* Pointer is created to `[wCurrentTileBlockMapViewPointer]`. I am manually setting this variable in `world.asm` to match the value I observed when debugging the full Pokemon game. This pointer value is `[wOverworldMap]` + an offset determined at runtime based on the player's location in the map. The value I set (`[wOverworldMap] + $43`) is right in front of Ash's house.
* Pointer is created to the destination address `[wTileMapBackup]`
* A row of six tile blocks are copied to the destination. (The screen can display 20 tiles by 18 tiles, so this is just enough to fill the screen and then some)
  * Blocks are made up of 4x4 tiles
  * In the `DrawTileBlock` procedure, each row of tiles for a specific block is copied. After a row has been drawn, the destination pointer is incremented by `$15` which equals `$04 * $06 - $03` (the width of a row in tiles minus the three times the destination pointer has already been incremented)
  * The other three rows in the block are copied this same way
* After a row is drawn, the original source pointer (`pop de`) is incremented by `[wCurMapWidth] + MAP_BORDER * 2`. (I'm not sure why it's not just incremented by `[hMapStride]`. Maybe I'll try this.)
* The original destination pointer is moved to the next row. (incremented by `$60`, 4 rows of `$18` tiles)
* Each additional row is written to the destination this way.
* A pointer is created to `[wTileMapBackup]` which is where we just copied all the tiles
* This pointer is adjusted for the player's X/Y position within the block
  * incremented by `$30` if `[wYBlockCoord]` is not zero (2 rows down)
  * incremented by `$02` if `[wXBlockCoord]` is not zero (2 rows to the right)
* Data from the pointer is copied to `[wTileMap]`, which is where the screen is drawn from. This section is 20x18 tiles, whereas [wTileMapBackup] is 24 * 20 tiles.
  * A row is copied by counting down from `SCREEN_WIDTH`
  * the source pointer is incremented by 4 because the destination rows are 4 fewer tiles than the source
  * Repeated for each row
* The original rom bank is restored


















* Loop through Map and load each tile of each block into WRAM. If the map is 10x10 blocks, that means 1600 bytes are loaded into WRAM (40x40 tiles)
* Tiles are loaded into BG Map VRAM. Since the BG map is 32x32 tiles, but the Map can be any size, new tiles are loaded into VRAM as the user walks and the map is scrolled.
