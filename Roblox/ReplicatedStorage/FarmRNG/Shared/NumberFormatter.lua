local NumberFormatter = {}

local SUFFIXES = {
	{1e21, "Sx"},
	{1e18, "Qi"},
	{1e15, "Qa"},
	{1e12, "T"},
	{1e9, "B"},
	{1e6, "M"},
	{1e3, "K"},
}

function NumberFormatter.Format(value)
	value = tonumber(value) or 0

	if math.abs(value) < 1000 then
		return tostring(math.floor(value + 0.5))
	end

	for _, suffixData in ipairs(SUFFIXES) do
		local amount = suffixData[1]
		local suffix = suffixData[2]

		if math.abs(value) >= amount then
			local short = value / amount

			if short >= 100 then
				return string.format("%.0f%s", short, suffix)
			elseif short >= 10 then
				return string.format("%.1f%s", short, suffix)
			else
				return string.format("%.2f%s", short, suffix)
			end
		end
	end

	return tostring(value)
end

return NumberFormatter
