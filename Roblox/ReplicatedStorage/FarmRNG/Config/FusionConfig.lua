local FusionConfig = {}

FusionConfig.TierOrder = {
	"Normal",
	"Gold",
	"Diamond",
	"Emerald",
	"Rainbow",
	"Celestial",
}

FusionConfig.NextTier = {
	Normal = "Gold",
	Gold = "Diamond",
	Diamond = "Emerald",
	Emerald = "Rainbow",
	Rainbow = "Celestial",
}

FusionConfig.Required = {
	Gold = 5,
	Diamond = 5,
	Emerald = 3,
	Rainbow = 3,
	Celestial = 2,
}

FusionConfig.ValueMultipliers = {
	Normal = 1,
	Gold = 6,
	Diamond = 36,
	Emerald = 120,
	Rainbow = 420,
	Celestial = 950,
}

function FusionConfig.GetNextTier(fromTier)
	return FusionConfig.NextTier[fromTier]
end

function FusionConfig.GetRequiredForTarget(targetTier)
	return FusionConfig.Required[targetTier]
end

function FusionConfig.GetSuccessChance(targetTier, insertedCount)
	local required = FusionConfig.Required[targetTier]
	if not required then
		return 0
	end

	return math.clamp((insertedCount / required) * 100, 0, 100)
end

return FusionConfig
