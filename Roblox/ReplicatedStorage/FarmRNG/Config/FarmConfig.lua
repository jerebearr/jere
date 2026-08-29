local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmRNG = ReplicatedStorage:WaitForChild("FarmRNG")
local WeightedRandom = require(FarmRNG.Shared.WeightedRandom)

local FarmConfig = {}

FarmConfig.RarityPaybackMinutes = {
	Common = 100,
	Uncommon = 200,
	Rare = 400,
	Epic = 900,
	Legendary = 1800,
	Mythic = 3600,
}

-- Batch 1: 17 farms. Add the next 17, then the last 16 after the loop is tested.
FarmConfig.Farms = {
	{id = "WheatField", name = "Wheat Field", rarity = "Common", family = "Grain", primaryLand = "BasicMeadow", secondaryLands = {"RichSoil"}, baseCrateValue = 12, productionSeconds = 15, baseStorage = 5, placement = "Gains +8% production for each neighboring Grain farm, max +24%."},
	{id = "CornFarm", name = "Corn Farm", rarity = "Common", family = "Grain", primaryLand = "BasicMeadow", secondaryLands = {"RichSoil"}, baseCrateValue = 14, productionSeconds = 16, baseStorage = 5, placement = "Counts as feed. Ranch neighbors gain +10% value."},
	{id = "CarrotFarm", name = "Carrot Farm", rarity = "Common", family = "Vegetable", primaryLand = "RichSoil", secondaryLands = {"BasicMeadow"}, baseCrateValue = 11, productionSeconds = 13, baseStorage = 5, placement = "Gains +10% value beside another Vegetable farm."},
	{id = "PotatoFarm", name = "Potato Farm", rarity = "Common", family = "Vegetable", primaryLand = "RichSoil", secondaryLands = {"BasicMeadow"}, baseCrateValue = 13, productionSeconds = 18, baseStorage = 6, placement = "Stores +2 extra crates beside any Grain farm."},
	{id = "RicePaddy", name = "Rice Paddy", rarity = "Uncommon", family = "Wetland", primaryLand = "Wetland", secondaryLands = {"RichSoil"}, baseCrateValue = 32, productionSeconds = 18, baseStorage = 7, placement = "Gains +10% production for each neighboring Wetland farm, max +20%."},
	{id = "AppleOrchard", name = "Apple Orchard", rarity = "Uncommon", family = "Fruit", primaryLand = "Forest", secondaryLands = {"BasicMeadow"}, baseCrateValue = 36, productionSeconds = 21, baseStorage = 7, placement = "Adjacent Honey Farms boost this farm's value."},
	{id = "SunflowerFarm", name = "Sunflower Farm", rarity = "Uncommon", family = "FlowerHoney", primaryLand = "BasicMeadow", secondaryLands = {"RichSoil"}, baseCrateValue = 30, productionSeconds = 17, baseStorage = 7, placement = "Boosts one adjacent Honey Farm by +20% production."},
	{id = "HoneyFarm", name = "Honey Farm", rarity = "Uncommon", family = "FlowerHoney", primaryLand = "BasicMeadow", secondaryLands = {"Forest"}, baseCrateValue = 44, productionSeconds = 24, baseStorage = 7, placement = "Adjacent Fruit farms gain +8% value. Adjacent Flower farms gain +12% production."},
	{id = "CoffeePlantation", name = "Coffee Plantation", rarity = "Rare", family = "Tropical", primaryLand = "Tropical", secondaryLands = {"Forest"}, baseCrateValue = 110, productionSeconds = 25, baseStorage = 8, placement = "Gains +20% value beside Cocoa-style Tropical farms added later."},
	{id = "CranberryBog", name = "Cranberry Bog", rarity = "Rare", family = "Wetland", primaryLand = "Wetland", secondaryLands = {"Frozen"}, baseCrateValue = 105, productionSeconds = 24, baseStorage = 8, placement = "Gains +10% value for each different Wetland neighbor."},
	{id = "MushroomFarm", name = "Mushroom Farm", rarity = "Rare", family = "Fungi", primaryLand = "Forest", secondaryLands = {"Wetland"}, baseCrateValue = 95, productionSeconds = 21, baseStorage = 8, placement = "Gains +15% production for each neighboring Orchard or Forest farm, max +30%."},
	{id = "DragonfruitFarm", name = "Dragonfruit Farm", rarity = "Epic", family = "Tropical", primaryLand = "Tropical", secondaryLands = {"Volcanic"}, baseCrateValue = 420, productionSeconds = 30, baseStorage = 10, placement = "Gains +10% production for each different Tropical neighbor, max +30%."},
	{id = "GlowshroomFarm", name = "Glowshroom Farm", rarity = "Epic", family = "Fungi", primaryLand = "Forest", secondaryLands = {"MythicLand"}, baseCrateValue = 390, productionSeconds = 28, baseStorage = 10, placement = "Adjacent Magical farms gain +8% value."},
	{id = "EmberPepperFarm", name = "Ember Pepper Farm", rarity = "Epic", family = "Magical", primaryLand = "Volcanic", secondaryLands = {"Desert"}, baseCrateValue = 460, productionSeconds = 35, baseStorage = 10, placement = "Gains +15% value beside Dragonfruit or other fire-themed farms."},
	{id = "PrismOrchard", name = "Prism Orchard", rarity = "Legendary", family = "Fruit", primaryLand = "MythicLand", secondaryLands = {"Forest", "Tropical"}, baseCrateValue = 1800, productionSeconds = 38, baseStorage = 12, placement = "Gains +5% value for every different Fruit type in its connected group."},
	{id = "ColossalPumpkinFarm", name = "Colossal Pumpkin Farm", rarity = "Legendary", family = "Vegetable", primaryLand = "RichSoil", secondaryLands = {"MythicLand"}, baseCrateValue = 2200, productionSeconds = 45, baseStorage = 12, placement = "Gains +20% value when surrounded by at least two Vegetable farms."},
	{id = "TimeFarm", name = "Time Farm", rarity = "Mythic", family = "Magical", primaryLand = "MythicLand", secondaryLands = {"Frozen", "Volcanic"}, baseCrateValue = 25000, productionSeconds = 60, baseStorage = 15, placement = "Every 45 seconds, advances eligible neighboring farms by 5 seconds. Can reach one aligned plot across a road."},
}

local byId = {}
local byRarity = {}

for _, farm in ipairs(FarmConfig.Farms) do
	byId[farm.id] = farm
	byRarity[farm.rarity] = byRarity[farm.rarity] or {}
	table.insert(byRarity[farm.rarity], farm)
end

FarmConfig.ById = byId
FarmConfig.ByRarity = byRarity

function FarmConfig.GetFarm(farmId)
	return byId[farmId]
end

function FarmConfig.GetBaseCoinsPerMinute(farmId)
	local farm = byId[farmId]
	if not farm then
		return 0
	end

	return (60 / farm.productionSeconds) * farm.baseCrateValue
end

function FarmConfig.GetFarmPurchasePrice(farmId)
	local farm = byId[farmId]
	if not farm then
		return math.huge
	end

	local payback = FarmConfig.RarityPaybackMinutes[farm.rarity] or 100
	return math.floor(FarmConfig.GetBaseCoinsPerMinute(farmId) * payback + 0.5)
end

function FarmConfig.GetLevelMultipliers(level)
	level = math.clamp(level or 1, 1, 50)
	local t = (level - 1) / 49

	return {
		production = 1 + 7 * math.pow(t, 1.25),
		value = 1 + 24 * math.pow(t, 1.75),
		storage = math.floor(5 + 95 * t + 0.5),
	}
end

local function listContains(list, value)
	if not list then
		return false
	end

	for _, item in ipairs(list) do
		if item == value then
			return true
		end
	end

	return false
end

function FarmConfig.RollFarmByRarity(rng, rarity, activeChip)
	rng = rng or Random.new()
	local farms = byRarity[rarity]

	if not farms or #farms == 0 then
		farms = byRarity.Common
	end

	local entries = {}

	for _, farm in ipairs(farms) do
		local weight = 1

		if activeChip and activeChip.landId then
			if farm.primaryLand == activeChip.landId then
				weight = 20
			elseif listContains(farm.secondaryLands, activeChip.landId) then
				weight = 5
			end
		end

		if activeChip and activeChip.id == "MythicMagicalChip" and farm.family == "Magical" then
			weight *= 10
		end

		table.insert(entries, {
			farm = farm,
			weight = weight,
		})
	end

	local picked = WeightedRandom.Pick(entries, rng)
	return picked and picked.farm or farms[1]
end

return FarmConfig
