local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmRNG = ReplicatedStorage:WaitForChild("FarmRNG")
local WeightedRandom = require(FarmRNG.Shared.WeightedRandom)

local LandConfig = {}

LandConfig.RerollBasePrice = 250
LandConfig.RerollMultiplier = 2.15
LandConfig.MatchingLandMultiplier = 1.40
LandConfig.SecondaryLandMultiplier = 1.15
LandConfig.MythicLandMultiplier = 1.45

LandConfig.Lands = {
	{
		id = "BasicMeadow",
		name = "Basic Meadow",
		weight = 38.75,
		rank = 1,
		families = {"Grain", "Ranch", "FlowerHoney"},
	},
	{
		id = "RichSoil",
		name = "Rich Soil",
		weight = 24,
		rank = 2,
		families = {"Vegetable", "Fruit"},
	},
	{
		id = "Forest",
		name = "Forest",
		weight = 14,
		rank = 3,
		families = {"Fruit", "Fungi"},
	},
	{
		id = "Wetland",
		name = "Wetland",
		weight = 9,
		rank = 3,
		families = {"Wetland"},
	},
	{
		id = "Tropical",
		name = "Tropical",
		weight = 6,
		rank = 4,
		families = {"Tropical", "Fruit"},
	},
	{
		id = "Desert",
		name = "Desert",
		weight = 4,
		rank = 4,
		families = {"Vegetable", "Tropical"},
	},
	{
		id = "Frozen",
		name = "Frozen",
		weight = 2.5,
		rank = 5,
		families = {"Fruit", "Magical"},
	},
	{
		id = "Volcanic",
		name = "Volcanic",
		weight = 1.5,
		rank = 5,
		families = {"Tropical", "Magical"},
	},
	{
		id = "MythicLand",
		name = "Mythic Land",
		weight = 0.25,
		rank = 6,
		families = {"Grain", "Vegetable", "Fruit", "FlowerHoney", "Fungi", "Wetland", "Tropical", "Ranch", "Magical"},
	},
}

local byId = {}
for _, land in ipairs(LandConfig.Lands) do
	byId[land.id] = land
end

LandConfig.ById = byId

LandConfig.PityMilestones = {
	[5] = 2,
	[10] = 3,
	[20] = 4,
	[35] = 5,
}

function LandConfig.GetRerollPrice(rollNumber)
	rollNumber = math.max(2, rollNumber)
	return math.floor(
		LandConfig.RerollBasePrice * math.pow(LandConfig.RerollMultiplier, rollNumber - 2) + 0.5
	)
end

function LandConfig.RollLand(rng, rollNumber)
	rng = rng or Random.new()
	rollNumber = rollNumber or 1

	if rollNumber >= 50 then
		return byId.MythicLand
	end

	local minRank = LandConfig.PityMilestones[rollNumber] or 1
	local candidates = {}

	for _, land in ipairs(LandConfig.Lands) do
		if land.rank >= minRank then
			table.insert(candidates, {
				id = land.id,
				land = land,
				weight = land.weight,
			})
		end
	end

	local picked = WeightedRandom.Pick(candidates, rng)
	return picked and picked.land or byId.BasicMeadow
end

function LandConfig.GetLandName(landId)
	local land = byId[landId]
	return land and land.name or tostring(landId)
end

function LandConfig.GetLandMultiplier(landId, farm)
	if landId == "MythicLand" then
		return LandConfig.MythicLandMultiplier
	end

	if farm.primaryLand == landId then
		return LandConfig.MatchingLandMultiplier
	end

	if farm.secondaryLands then
		for _, secondaryLandId in ipairs(farm.secondaryLands) do
			if secondaryLandId == landId then
				return LandConfig.SecondaryLandMultiplier
			end
		end
	end

	return 1
end

return LandConfig
