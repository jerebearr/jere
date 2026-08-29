# Farm RNG Prototype Source

This branch contains the first code pass for the Roblox farming RNG game.

It includes:
- 40-plot price curve: Plot 2 = $250, Plot 40 = $2Qi
- Land rerolls with per-plot pity and guaranteed Mythic Land on land roll 50
- Harvest Reel with 5-second spin cooldown
- 1-5 gameplay reels, with placeholders for the 6-8 Robux reel pass
- Free spins and paid known-result farm purchases
- 17 Batch-1 farms, including Time Farm
- Permanent Luck levels 0-50
- Luck 50 Mythic chance = 1 in 250 per reel
- World-synced Soil Chip shop restocking every 5 minutes
- Every chip guaranteed at least once per UTC day
- Soil Chips lasting 5 full machine presses
- Infinite stacked backpack inventory data
- Fusion config values for the later fusion UI
- Super Mart sale interval config from 60 seconds down to 1 second
- Basic temporary test UI created by a LocalScript

## Current prototype structure

```text
Roblox/
  default.project.json
  ReplicatedStorage/
    FarmRNG/
      Config/
        ChipShopConfig.lua
        FarmConfig.lua
        FusionConfig.lua
        LandConfig.lua
        LuckConfig.lua
        MonetizationConfig.lua
        PlotPriceConfig.lua
        UpgradeConfig.lua
      Shared/
        NumberFormatter.lua
        WeightedRandom.lua
  ServerScriptService/
    FarmRNG/
      Bootstrap.server.lua
  StarterPlayer/
    StarterPlayerScripts/
      FarmRNGClient.client.lua
```

`Bootstrap.server.lua` is currently a single prototype server script. Later, as the game gets bigger, we can split it into service ModuleScripts such as `HarvestReelService`, `LandService`, `TruckService`, and `SuperMartService`.

## Rojo use

The `default.project.json` file is included for Rojo-style syncing/building. If you are manually placing scripts in Roblox Studio, use this mapping:

- `ReplicatedStorage/FarmRNG/Config/*.lua` -> ModuleScripts under `ReplicatedStorage > FarmRNG > Config`
- `ReplicatedStorage/FarmRNG/Shared/*.lua` -> ModuleScripts under `ReplicatedStorage > FarmRNG > Shared`
- `ServerScriptService/FarmRNG/Bootstrap.server.lua` -> normal Script named `Bootstrap`
- `StarterPlayer/StarterPlayerScripts/FarmRNGClient.client.lua` -> LocalScript named `FarmRNGClient`

## First test flow

1. Press Play in Studio.
2. Use `+ Testing Money` to add temporary cash.
3. Press `Spin Harvest Reel`.
4. Wait 5 seconds.
5. Buy a revealed farm.
6. Buy Luck, plots, reels, carry slots, and Mart speed upgrades to test the systems.

Remove or secure these RemoteFunctions before publishing:
- `GiveTestingMoney`
- `WipeTestingData`

## Not finished yet

The prototype does not yet include the real map systems:
- 40 physical plot parts
- hand-delivery crate pickup
- placing farms onto plots
- truck buying and dispatching
- Super Mart claim zone
- adjacency/road-bonus calculations
- real DataStore saving
- Robux product/gamepass wiring
