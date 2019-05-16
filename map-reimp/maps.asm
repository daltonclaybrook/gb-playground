section "Map Binaries", rom0

    const_def
    const OVERWORLD_TILESET ; $00
    const OVERWORLD_TILESET_2 ; $01

    const_def
    const PALLET_TOWN_MAP ; $00
    const PALLET_TOWN_MAP_2 ; $01
    const SAFFRON_CITY_MAP ; $03
    const CINNABAR_ISLAND ; $04

TilesetHeaders::
    tileset OverworldBlocks, OverworldGFX, OverworldColl
    tileset OverworldBlocks, OverworldGFX, OverworldColl

MapHeaders::
    map OVERWORLD_TILESET, 9, 10, PalletTownBlockMap
    map OVERWORLD_TILESET_2, 9, 10, PalletTownBlockMap
    map OVERWORLD_TILESET, 18, 20, SaffronCityBlockMap
    map OVERWORLD_TILESET, 9, 10, CinnabarIslandBlockMap

OverworldBlocks::
    incbin "assets/overworld.bst"

OverworldGFX::
    incbin "assets/overworld.2bpp"

OverworldColl::
    incbin "assets/overworld.tilecoll"

PalletTownBlockMap::
    incbin "assets/PalletTown.blk"

SaffronCityBlockMap::
    incbin "assets/SaffronCity.blk"

CinnabarIslandBlockMap::
    incbin "assets/CinnabarIsland.blk"
