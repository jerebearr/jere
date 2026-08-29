local ChipShopConfig = {}

ChipShopConfig.RestockSeconds = 300 -- 5 minutes
ChipShopConfig.Slots = 3
ChipShopConfig.RotationsPerDay = 86400 / ChipShopConfig.RestockSeconds
ChipShopConfig.ChargesPerChip = 5

ChipShopConfig.Chips = {
	{
		id = "MeadowChip",
		name = "Meadow Chip",
		landId = "BasicMeadow",
		weight = 36,
		price = 5e10,
	},
	{
		id = "RichSoilChip",
		name = "Rich Soil Chip",
		landId = "RichSoil",
		weight = 25,
		price = 5e10,
	},
	{
		id = "ForestChip",
		name = "Forest Chip",
		landId = "Forest",
		weight = 15,
		price = 5e11,
	},
	{
		id = "WetlandChip",
		name = "Wetland Chip",
		landId = "Wetland",
		weight = 9,
		price = 5e11,
	},
	{
		id = "TropicalChip",
		name = "Tropical Chip",
		landId = "Tropical",
		weight = 6,
		price = 5e12,
	},
	{
		id = "DesertChip",
		name = "Desert Chip",
		landId = "Desert",
		weight = 4,
		price = 5e12,
	},
	{
		id = "FrozenChip",
		name = "Frozen Chip",
		landId = "Frozen",
		weight = 3,
		price = 5e13,
	},
	{
		id = "VolcanicChip",
		name = "Volcanic Chip",
		landId = "Volcanic",
		weight = 1.9,
		price = 5e13,
	},
	{
		id = "MythicMagicalChip",
		name = "Mythic/Magical Chip",
		landId = "MythicLand",
		weight = 0.1,
		price = 5e15,
		mythicBoost = true,
	},
}

local byId = {}
for _, chip in ipairs(ChipShopConfig.Chips) do
	byId[chip.id] = chip
end
ChipShopConfig.ById = byId

local function getDayIndex(serverTime)
	return math.floor(serverTime / 86400)
end

local function getRotationIndex(serverTime)
	local secondsInDay = serverTime % 86400
	return math.floor(secondsInDay / ChipShopConfig.RestockSeconds) + 1
end

local function getNextRestockTime(serverTime)
	return math.floor(serverTime / ChipShopConfig.RestockSeconds + 1) * ChipShopConfig.RestockSeconds
end

ChipShopConfig.GetDayIndex = getDayIndex
ChipShopConfig.GetRotationIndex = getRotationIndex
ChipShopConfig.GetNextRestockTime = getNextRestockTime

local function pickWeightedChip(rng, usedIds)
	local total = 0

	for _, chip in ipairs(ChipShopConfig.Chips) do
		if not usedIds[chip.id] then
			total += chip.weight
		end
	end

	local roll = rng:NextNumber(0, total)
	local running = 0

	for _, chip in ipairs(ChipShopConfig.Chips) do
		if not usedIds[chip.id] then
			running += chip.weight
			if roll <= running then
				return chip
			end
		end
	end

	for _, chip in ipairs(ChipShopConfig.Chips) do
		if not usedIds[chip.id] then
			return chip
		end
	end

	return ChipShopConfig.Chips[1]
end

function ChipShopConfig.GenerateDailySchedule(dayIndex)
	-- Deterministic schedule: same dayIndex produces same shop in every server.
	-- Server code should never send the full day schedule to clients.
	local rng = Random.new((dayIndex + 1729) * 7919)
	local schedule = {}

	for rotation = 1, ChipShopConfig.RotationsPerDay do
		schedule[rotation] = {}
	end

	-- Guarantee every chip appears at least once per day.
	for _, chip in ipairs(ChipShopConfig.Chips) do
		local placed = false

		while not placed do
			local rotation = rng:NextInteger(1, ChipShopConfig.RotationsPerDay)
			if #schedule[rotation] < ChipShopConfig.Slots then
				local duplicate = false
				for _, existing in ipairs(schedule[rotation]) do
					if existing == chip.id then
						duplicate = true
						break
					end
				end

				if not duplicate then
					table.insert(schedule[rotation], chip.id)
					placed = true
				end
			end
		end
	end

	-- Fill every shop rotation. No duplicate chip inside the same restock.
	for rotation = 1, ChipShopConfig.RotationsPerDay do
		local usedIds = {}

		for _, chipId in ipairs(schedule[rotation]) do
			usedIds[chipId] = true
		end

		while #schedule[rotation] < ChipShopConfig.Slots do
			local chip = pickWeightedChip(rng, usedIds)
			table.insert(schedule[rotation], chip.id)
			usedIds[chip.id] = true
		end
	end

	return schedule
end

function ChipShopConfig.GetShopForTime(serverTime)
	local dayIndex = getDayIndex(serverTime)
	local rotationIndex = getRotationIndex(serverTime)
	local schedule = ChipShopConfig.GenerateDailySchedule(dayIndex)
	local slotChipIds = schedule[rotationIndex]
	local offers = {}

	for slotIndex, chipId in ipairs(slotChipIds) do
		local chip = byId[chipId]
		table.insert(offers, {
			slotIndex = slotIndex,
			id = chip.id,
			name = chip.name,
			landId = chip.landId,
			price = chip.price,
			mythicBoost = chip.mythicBoost or false,
		})
	end

	return {
		dayIndex = dayIndex,
		rotationIndex = rotationIndex,
		nextRestockTime = getNextRestockTime(serverTime),
		offers = offers,
	}
end

return ChipShopConfig
