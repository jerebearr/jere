local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmRNG = ReplicatedStorage:WaitForChild("FarmRNG")
local WeightedRandom = require(FarmRNG.Shared.WeightedRandom)

local LuckConfig = {}

LuckConfig.MaxLuckLevel = 50
LuckConfig.SpinSeconds = 5

LuckConfig.RarityOrder = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
}

LuckConfig.BaseChances = {
	Common = 89.48995190476,
	Uncommon = 10,
	Rare = 0.5,
	Epic = 0.01,
	Legendary = 0.000047619,
	Mythic = 0.000000476190476,
}

LuckConfig.MaxChances = {
	Common = 40,
	Uncommon = 30,
	Rare = 18,
	Epic = 8,
	Legendary = 3.6,
	Mythic = 0.4,
}

LuckConfig.MythicChipMaxChances = {
	Common = 39.4,
	Uncommon = 30,
	Rare = 18,
	Epic = 8,
	Legendary = 3.6,
	Mythic = 1,
}

function LuckConfig.GetLuckUpgradePrice(nextLuckLevel)
	nextLuckLevel = math.clamp(nextLuckLevel, 1, LuckConfig.MaxLuckLevel)
	return math.floor(500 * math.pow(2.25, nextLuckLevel - 1) + 0.5)
end

local function normalize(chances)
	local total = 0
	for _, rarity in ipairs(LuckConfig.RarityOrder) do
		total += chances[rarity] or 0
	end

	if total <= 0 then
		return table.clone(LuckConfig.BaseChances)
	end

	local normalized = {}
	for _, rarity in ipairs(LuckConfig.RarityOrder) do
		normalized[rarity] = (chances[rarity] or 0) / total * 100
	end

	return normalized
end

function LuckConfig.GetRarityChances(luckLevel, options)
	options = options or {}
	luckLevel = math.clamp(luckLevel or 0, 0, LuckConfig.MaxLuckLevel)

	local t = luckLevel / LuckConfig.MaxLuckLevel
	local target = options.mythicChipActive and LuckConfig.MythicChipMaxChances or LuckConfig.MaxChances

	local raw = {}

	for _, rarity in ipairs(LuckConfig.RarityOrder) do
		local base = LuckConfig.BaseChances[rarity]
		local max = target[rarity]

		raw[rarity] = math.pow(base, 1 - t) * math.pow(max, t)
	end

	return normalize(raw)
end

function LuckConfig.RollRarity(rng, luckLevel, options)
	rng = rng or Random.new()
	local chances = LuckConfig.GetRarityChances(luckLevel, options)
	local entries = {}

	for _, rarity in ipairs(LuckConfig.RarityOrder) do
		table.insert(entries, {
			rarity = rarity,
			weight = chances[rarity],
		})
	end

	local picked = WeightedRandom.Pick(entries, rng)
	return picked and picked.rarity or "Common"
end

return LuckConfig
