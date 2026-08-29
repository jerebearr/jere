local WeightedRandom = {}

function WeightedRandom.Pick(entries, rng)
	rng = rng or Random.new()

	local totalWeight = 0
	for _, entry in ipairs(entries) do
		local weight = entry.weight or entry.chance or 0
		if weight > 0 then
			totalWeight += weight
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = rng:NextNumber(0, totalWeight)
	local running = 0

	for _, entry in ipairs(entries) do
		local weight = entry.weight or entry.chance or 0
		if weight > 0 then
			running += weight
			if roll <= running then
				return entry
			end
		end
	end

	return entries[#entries]
end

return WeightedRandom
