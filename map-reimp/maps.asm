include "macros.asm"

section "Binaries", rom0[$1000]

    const_def
    const OVERWORLD_TILESET ; $00
    const OVERWORLD_TILESET_2 ; $01

    const_def
    const PALLET_TOWN_MAP ; $00
    const PALLET_TOWN_MAP_2 ; $01

TilesetHeaders::
    tileset OverworldBlocks, OverworldGFX
    tileset OverworldBlocks, OverworldGFX

MapHeaders::
    map OVERWORLD_TILESET, 9, 10, PalletTownBlockMap
    map OVERWORLD_TILESET_2, 9, 10, PalletTownBlockMap

OverworldBlocks::
    incbin "assets/overworld.bst"

OverworldGFX::
    incbin "assets/overworld.2bpp"

PalletTownBlockMap::
    incbin "assets/PalletTown.blk"
