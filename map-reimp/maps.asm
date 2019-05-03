include "macros.asm"

    const_def
    const OVERWORLD_TILESET ; $00

    const_def
    const PALLET_TOWN_MAP ; $00

TilesetHeaders::
    tileset OverworldBlocks, OverworldGFX

MapHeaders::
    map OVERWORLD_TILESET, 9, 10, PalletTownBlockMap

section "Binaries", rom0

OverworldGFX::
    incbin "assets/overworld.2bpp"

OverworldBlocks::
    incbin "assets/overworld.bst"

PalletTownBlockMap::
    incbin "assets/PalletTown.blk"
