# Farm RNG Prototype Source

This is the first coding pass for the Roblox farming RNG game.

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
- Infinite stacked backpack inventory
- Risk fusion and safe fusion logic
- Super Mart sale interval config from 60 seconds down to 1 second
- Basic test UI created by a LocalScript

## Roblox Studio placement

Create these folders/scripts in Roblox Studio:

```text
ReplicatedStorage
  FarmRNG
    Config
      ChipShopConfig
      FarmConfig
      FusionConfig
      LandConfig
      LuckConfig
      MonetizationConfig
      PlotPriceConfig
      UpgradeConfig
    Shared
      NumberFormatter
      WeightedRandom

ServerScriptService
  FarmRNG
    Bootstrap
    Services
      ChipShopService
      CurrencyService
      FarmInventoryService
      FusionService
      HarvestReelService
      LandService
      PlayerDataService
      SuperMartService
      UpgradeService

StarterPlayer
  StarterPlayerScripts
    FarmRNGClient
```

Each `.lua` file in this package should become a `ModuleScript`, except:

- `Bootstrap.server.lua` should be a normal Script named `Bootstrap`
- `FarmRNGClient.client.lua` should be a LocalScript named `FarmRNGClient`

## Important Studio setting

For DataStore testing, turn on:

`Game Settings > Security > Enable Studio Access to API Services`

If you do not enable that, DataStore saves may warn in output. The prototype will still create default data for testing.

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

## Next coding step

The next step is the actual map gameplay:
- 40 physical plot parts
- hand-delivery crate pickup
- placing farms onto plots
- truck buying and dispatching
- Super Mart claim zone
- adjacency/road-bonus calculations
