local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("FarmRNGRemotes")

local function remote(name)
	return remotes:WaitForChild(name)
end

local gui = Instance.new("ScreenGui")
gui.Name = "FarmRNGPrototypeGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(520, 620)
frame.Position = UDim2.fromOffset(20, 20)
frame.BackgroundTransparency = 0.15
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 34)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Text = "Farm RNG Prototype"
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 92)
status.Position = UDim2.fromOffset(10, 44)
status.BackgroundTransparency = 1
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextWrapped = true
status.Text = "Loading..."
status.Parent = frame

local function makeButton(text, x, y, w, h)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(w or 155, h or 34)
	button.Position = UDim2.fromOffset(x, y)
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.Parent = frame
	return button
end

local spinButton = makeButton("Spin Harvest Reel", 10, 145)
local moneyButton = makeButton("+ Testing Money", 180, 145)
local luckButton = makeButton("Buy Luck", 350, 145)
local plotButton = makeButton("Buy Next Plot", 10, 185)
local reelButton = makeButton("Buy Next Reel", 180, 185)
local carryButton = makeButton("Buy Carry Slot", 350, 185)
local shopButton = makeButton("Refresh Chip Shop", 10, 225)
local buyChip1Button = makeButton("Buy Chip 1", 180, 225)
local buyChip2Button = makeButton("Buy Chip 2", 350, 225)
local buyChip3Button = makeButton("Buy Chip 3", 10, 265)
local sellButton = makeButton("Buy Mart Speed", 180, 265)
local wipeButton = makeButton("Wipe Test Data", 350, 265)

local offersLabel = Instance.new("TextLabel")
offersLabel.Size = UDim2.new(1, -20, 0, 165)
offersLabel.Position = UDim2.fromOffset(10, 310)
offersLabel.BackgroundTransparency = 1
offersLabel.TextXAlignment = Enum.TextXAlignment.Left
offersLabel.TextYAlignment = Enum.TextYAlignment.Top
offersLabel.Font = Enum.Font.Code
offersLabel.TextSize = 13
offersLabel.TextWrapped = true
offersLabel.Text = "Offers will appear here."
offersLabel.Parent = frame

local buyOfferButtons = {}
for i = 1, 8 do
	local row = math.floor((i - 1) / 4)
	local col = (i - 1) % 4
	local button = makeButton("Buy " .. i, 10 + col * 125, 485 + row * 42, 115, 34)
	buyOfferButtons[i] = button
end

local function summarize(state)
	if not state or not state.ok then
		status.Text = state and state.message or "No state."
		return
	end

	local mythicChance = state.luckChances and state.luckChances.Mythic or 0
	status.Text =
		"Money: $" .. tostring(state.moneyText) ..
		"\nLuck: " .. tostring(state.luckLevel) .. "/50 | Mythic/reel: " .. string.format("%.6f", mythicChance) .. "%" ..
		"\nReels: " .. tostring(state.totalReels) .. " | Next reel: $" .. tostring(state.nextReelPriceText) ..
		"\nPlots: " .. tostring(state.plotsOwned) .. "/" .. tostring(state.maxPlots) .. " | Next plot: $" .. tostring(state.nextPlotPriceText) ..
		"\nCarry: " .. tostring(state.carryCapacity) .. " | Mart interval: " .. tostring(state.sellInterval) .. "s" ..
		"\nActive Chip: " .. tostring(state.activeChip and state.activeChip.chipId or "None") .. " (" .. tostring(state.activeChip and state.activeChip.charges or 0) .. " spins left)"

	local lines = {"Current offers:"}
	if not state.activeOffers or #state.activeOffers == 0 then
		table.insert(lines, "No offers. Press Spin.")
	else
		for _, offer in ipairs(state.activeOffers) do
			table.insert(lines, string.format("[%d] %s | %s | $%s%s", offer.reelIndex, offer.name, offer.rarity, tostring(offer.price), offer.locked and " | LOCKED" or ""))
		end
	end

	table.insert(lines, "")
	table.insert(lines, "Chip shop:")
	if state.chipShop and state.chipShop.offers then
		for _, chip in ipairs(state.chipShop.offers) do
			table.insert(lines, string.format("Slot %d: %s | $%s%s", chip.slotIndex, chip.name, tostring(chip.price), chip.purchased and " | bought" or ""))
		end
	end
	offersLabel.Text = table.concat(lines, "\n")
end

local function invoke(name, ...)
	local ok, result = pcall(function(...)
		return remote(name):InvokeServer(...)
	end, ...)

	if not ok then
		status.Text = "Remote failed: " .. tostring(result)
		return nil
	end

	if result and result.state then
		summarize(result.state)
	elseif result and result.ok then
		status.Text = result.message or "Done."
	end

	if result and result.message then
		print("[FarmRNG]", result.message)
	end

	return result
end

spinButton.MouseButton1Click:Connect(function()
	status.Text = "Spinning for 5 seconds..."
	local result = invoke("Spin")
	if result and result.ok then
		task.wait(result.result.spinSeconds or 5)
		summarize(result.state)
	end
end)

moneyButton.MouseButton1Click:Connect(function() invoke("GiveTestingMoney", 1e9) end)
luckButton.MouseButton1Click:Connect(function() invoke("BuyLuck") end)
plotButton.MouseButton1Click:Connect(function() invoke("BuyNextPlot") end)
reelButton.MouseButton1Click:Connect(function() invoke("BuyNextGameplayReel") end)
carryButton.MouseButton1Click:Connect(function() invoke("BuyNextCarryCapacity") end)
shopButton.MouseButton1Click:Connect(function() invoke("GetChipShop") end)
buyChip1Button.MouseButton1Click:Connect(function() invoke("BuyChip", 1) end)
buyChip2Button.MouseButton1Click:Connect(function() invoke("BuyChip", 2) end)
buyChip3Button.MouseButton1Click:Connect(function() invoke("BuyChip", 3) end)
sellButton.MouseButton1Click:Connect(function() invoke("BuyNextSellInterval") end)
wipeButton.MouseButton1Click:Connect(function() invoke("WipeTestingData") end)

for reelIndex, button in ipairs(buyOfferButtons) do
	button.MouseButton1Click:Connect(function()
		invoke("BuyOffer", reelIndex)
	end)
end

task.wait(1)
local initial = invoke("GetState")
if initial and initial.ok then
	summarize(initial)
elseif initial and initial.state then
	summarize(initial.state)
end
