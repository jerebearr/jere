local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FarmRNG = ReplicatedStorage:WaitForChild("FarmRNG")
local PlotPriceConfig = require(FarmRNG.Config.PlotPriceConfig)
local LandConfig = require(FarmRNG.Config.LandConfig)
local FarmConfig = require(FarmRNG.Config.FarmConfig)
local LuckConfig = require(FarmRNG.Config.LuckConfig)
local ChipShopConfig = require(FarmRNG.Config.ChipShopConfig)
local UpgradeConfig = require(FarmRNG.Config.UpgradeConfig)
local NumberFormatter = require(FarmRNG.Shared.NumberFormatter)

local remotes = ReplicatedStorage:FindFirstChild("FarmRNGRemotes") or Instance.new("Folder")
remotes.Name = "FarmRNGRemotes"
remotes.Parent = ReplicatedStorage

local function remoteFunction(name)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotes
	end
	return remote
end

local RF = {}
for _, name in ipairs({
	"GetState", "Spin", "BuyOffer", "BuyNextPlot", "RerollLand", "BuyLuck",
	"BuyNextGameplayReel", "BuyNextCarryCapacity", "BuyNextSellInterval",
	"GetChipShop", "BuyChip", "ActivateChip", "TryFuse", "ClaimSuperMartMoney",
	"GiveTestingMoney", "WipeTestingData",
}) do
	RF[name] = remoteFunction(name)
end

local dataByPlayer = {}

local function newData()
	return {
		Money = 0,
		LuckLevel = 0,
		OwnedGameplayReels = 1,
		HasExtraReelsPass = false,
		CarryCapacity = 5,
		SellIntervalIndex = 1,
		Plots = {
			[1] = {unlocked = true, landId = "BasicMeadow", landRollCount = 1, farmKey = nil},
		},
		Inventory = {},
		ActiveOffers = {},
		ChipInventory = {},
		ChipPurchases = {},
		ActiveChip = {chipId = nil, charges = 0},
		LastSpinAt = 0,
		SuperMart = {PendingValue = 0, ClaimableMoney = 0, LastSaleAt = workspace:GetServerTimeNow()},
	}
end

local function getData(player)
	if not dataByPlayer[player] then
		dataByPlayer[player] = newData()
	end
	return dataByPlayer[player]
end

local function countPlots(data)
	local total = 0
	for _, plot in pairs(data.Plots) do
		if plot.unlocked then
			total += 1
		end
	end
	return total
end

local function updateLeaderstats(player)
	local data = getData(player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = leaderstats:FindFirstChild("Money") or Instance.new("NumberValue")
	money.Name = "Money"
	money.Value = data.Money
	money.Parent = leaderstats

	local luck = leaderstats:FindFirstChild("Luck") or Instance.new("IntValue")
	luck.Name = "Luck"
	luck.Value = data.LuckLevel
	luck.Parent = leaderstats

	local plots = leaderstats:FindFirstChild("Plots") or Instance.new("IntValue")
	plots.Name = "Plots"
	plots.Value = countPlots(data)
	plots.Parent = leaderstats
end

local function spend(player, amount)
	local data = getData(player)
	if data.Money < amount then
		return false, "Not enough money."
	end
	data.Money -= amount
	updateLeaderstats(player)
	return true
end

local function addMoney(player, amount)
	local data = getData(player)
	data.Money += amount
	updateLeaderstats(player)
end

local function getTotalReels(data)
	if data.HasExtraReelsPass then
		return UpgradeConfig.MaxTotalReelsWithPass
	end
	return math.clamp(data.OwnedGameplayReels or 1, 1, UpgradeConfig.MaxGameplayReels)
end

local function makeInvKey(farmId, tier, level)
	return farmId .. "|" .. (tier or "Normal") .. "|" .. tostring(level or 1)
end

local function addFarmToInventory(data, farmId, tier, level, amount)
	local key = makeInvKey(farmId, tier, level)
	data.Inventory[key] = (data.Inventory[key] or 0) + (amount or 1)
	return key
end

local function removeFarmFromInventory(data, farmId, tier, level, amount)
	local key = makeInvKey(farmId, tier, level)
	local current = data.Inventory[key] or 0
	if current < amount then
		return false
	end
	current -= amount
	data.Inventory[key] = current > 0 and current or nil
	return true
end

local function currentChip(data)
	if data.ActiveChip and data.ActiveChip.chipId and data.ActiveChip.charges > 0 then
		return ChipShopConfig.ById[data.ActiveChip.chipId]
	end
	return nil
end

local function chipPurchaseKey(shop, slotIndex)
	return tostring(shop.dayIndex) .. ":" .. tostring(shop.rotationIndex) .. ":" .. tostring(slotIndex)
end

local function getShopForPlayer(player)
	local data = getData(player)
	local shop = ChipShopConfig.GetShopForTime(workspace:GetServerTimeNow())
	for _, offer in ipairs(shop.offers) do
		offer.purchased = data.ChipPurchases[chipPurchaseKey(shop, offer.slotIndex)] == true
	end
	shop.secondsUntilRestock = math.max(0, shop.nextRestockTime - workspace:GetServerTimeNow())
	return shop
end

local function buildInventoryList(data)
	local list = {}
	for key, count in pairs(data.Inventory) do
		local farmId, tier, levelString = string.match(key, "([^|]+)|([^|]+)|([^|]+)")
		local farm = FarmConfig.GetFarm(farmId)
		table.insert(list, {
			key = key,
			farmId = farmId,
			name = farm and farm.name or farmId,
			rarity = farm and farm.rarity or "?",
			tier = tier,
			level = tonumber(levelString) or 1,
			count = count,
		})
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

local function processSuperMart(data)
	local upgrade = UpgradeConfig.SellIntervalUpgrades[data.SellIntervalIndex or 1]
	local interval = upgrade and upgrade.interval or 60
	local now = workspace:GetServerTimeNow()
	if now - data.SuperMart.LastSaleAt >= interval then
		data.SuperMart.ClaimableMoney += data.SuperMart.PendingValue
		data.SuperMart.PendingValue = 0
		data.SuperMart.LastSaleAt = now
	end
	return interval
end

local function buildState(player)
	local data = getData(player)
	local plotCount = countPlots(data)
	local nextPlot = plotCount + 1
	local nextLuckPrice = data.LuckLevel < LuckConfig.MaxLuckLevel and LuckConfig.GetLuckUpgradePrice(data.LuckLevel + 1) or nil
	local nextReel = data.OwnedGameplayReels + 1
	local nextCarry = data.CarryCapacity + 5
	local nextSell = UpgradeConfig.SellIntervalUpgrades[(data.SellIntervalIndex or 1) + 1]
	local sellInterval = processSuperMart(data)

	local plots = {}
	for plotNumber, plot in pairs(data.Plots) do
		local land = LandConfig.ById[plot.landId]
		table.insert(plots, {plotNumber = plotNumber, landId = plot.landId, landName = land and land.name or plot.landId, landRollCount = plot.landRollCount})
	end
	table.sort(plots, function(a, b) return a.plotNumber < b.plotNumber end)

	local offers = {}
	for _, offer in pairs(data.ActiveOffers) do
		table.insert(offers, offer)
	end
	table.sort(offers, function(a, b) return a.reelIndex < b.reelIndex end)

	return {
		ok = true,
		money = data.Money,
		moneyText = NumberFormatter.Format(data.Money),
		luckLevel = data.LuckLevel,
		luckChances = LuckConfig.GetRarityChances(data.LuckLevel),
		nextLuckPrice = nextLuckPrice,
		nextLuckPriceText = nextLuckPrice and NumberFormatter.Format(nextLuckPrice) or "MAX",
		ownedGameplayReels = data.OwnedGameplayReels,
		totalReels = getTotalReels(data),
		nextReelPrice = UpgradeConfig.ReelPrices[nextReel],
		nextReelPriceText = UpgradeConfig.ReelPrices[nextReel] and NumberFormatter.Format(UpgradeConfig.ReelPrices[nextReel]) or "Robux pass for 6-8",
		carryCapacity = data.CarryCapacity,
		nextCarryPrice = UpgradeConfig.CarryCapacityPrices[nextCarry],
		nextCarryPriceText = UpgradeConfig.CarryCapacityPrices[nextCarry] and NumberFormatter.Format(UpgradeConfig.CarryCapacityPrices[nextCarry]) or "MAX",
		sellInterval = sellInterval,
		nextSellPrice = nextSell and nextSell.price or nil,
		nextSellPriceText = nextSell and NumberFormatter.Format(nextSell.price) or "MAX",
		plotsOwned = plotCount,
		maxPlots = PlotPriceConfig.MaxPlots,
		nextPlotPrice = PlotPriceConfig.GetPlotPrice(nextPlot),
		nextPlotPriceText = PlotPriceConfig.GetPlotPrice(nextPlot) and NumberFormatter.Format(PlotPriceConfig.GetPlotPrice(nextPlot)) or "MAX",
		plots = plots,
		activeOffers = offers,
		inventory = buildInventoryList(data),
		chipInventory = data.ChipInventory,
		activeChip = data.ActiveChip,
		chipShop = getShopForPlayer(player),
		superMart = data.SuperMart,
	}
end

Players.PlayerAdded:Connect(function(player)
	getData(player)
	updateLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	dataByPlayer[player] = nil
end)

RF.GetState.OnServerInvoke = function(player)
	return buildState(player)
end

RF.Spin.OnServerInvoke = function(player)
	local data = getData(player)
	local now = os.clock()
	local remaining = LuckConfig.SpinSeconds - (now - (data.LastSpinAt or 0))
	if remaining > 0 then
		return {ok = false, message = string.format("Wait %.1fs before spinning again.", remaining), state = buildState(player)}
	end
	data.LastSpinAt = now

	local activeChip = currentChip(data)
	local rng = Random.new(math.floor(os.clock() * 1000000) + player.UserId)
	local reels = getTotalReels(data)
	for reelIndex = 1, reels do
		local existing = data.ActiveOffers[tostring(reelIndex)]
		if not (existing and existing.locked) then
			local rarity = LuckConfig.RollRarity(rng, data.LuckLevel, {mythicChipActive = activeChip and activeChip.mythicBoost == true})
			local farm = FarmConfig.RollFarmByRarity(rng, rarity, activeChip)
			data.ActiveOffers[tostring(reelIndex)] = {
				reelIndex = reelIndex,
				farmId = farm.id,
				name = farm.name,
				rarity = farm.rarity,
				family = farm.family,
				primaryLand = farm.primaryLand,
				price = FarmConfig.GetFarmPurchasePrice(farm.id),
				locked = false,
				createdAt = workspace:GetServerTimeNow(),
			}
		end
	end
	if activeChip then
		data.ActiveChip.charges -= 1
		if data.ActiveChip.charges <= 0 then
			data.ActiveChip = {chipId = nil, charges = 0}
		end
	end
	return {ok = true, message = "Spin complete.", result = {spinSeconds = LuckConfig.SpinSeconds}, state = buildState(player)}
end

RF.BuyOffer.OnServerInvoke = function(player, reelIndex)
	local data = getData(player)
	local offer = data.ActiveOffers[tostring(tonumber(reelIndex))]
	if not offer then
		return {ok = false, message = "No farm offer in that reel.", state = buildState(player)}
	end
	local ok, err = spend(player, offer.price)
	if not ok then
		return {ok = false, message = err, state = buildState(player)}
	end
	addFarmToInventory(data, offer.farmId, "Normal", 1, 1)
	data.ActiveOffers[tostring(tonumber(reelIndex))] = nil
	return {ok = true, message = "Farm purchased.", state = buildState(player)}
end

RF.BuyNextPlot.OnServerInvoke = function(player)
	local data = getData(player)
	local nextPlot = countPlots(data) + 1
	local price = PlotPriceConfig.GetPlotPrice(nextPlot)
	if not price then return {ok = false, message = "All plots are owned.", state = buildState(player)} end
	local ok, err = spend(player, price)
	if not ok then return {ok = false, message = err, state = buildState(player)} end
	local land = LandConfig.RollLand(Random.new(os.clock() * 1000000 + player.UserId), 1)
	data.Plots[nextPlot] = {unlocked = true, landId = land.id, landRollCount = 1, farmKey = nil}
	updateLeaderstats(player)
	return {ok = true, message = "Plot purchased.", state = buildState(player)}
end

RF.RerollLand.OnServerInvoke = function(player, plotNumber)
	local data = getData(player)
	local plot = data.Plots[tonumber(plotNumber)]
	if not plot then return {ok = false, message = "Plot is not owned.", state = buildState(player)} end
	local nextRoll = (plot.landRollCount or 1) + 1
	local price = LandConfig.GetRerollPrice(nextRoll)
	local ok, err = spend(player, price)
	if not ok then return {ok = false, message = err, state = buildState(player)} end
	local land = LandConfig.RollLand(Random.new(os.clock() * 1000000 + player.UserId + nextRoll), nextRoll)
	plot.landId = land.id
	plot.landRollCount = land.id == "MythicLand" and 1 or nextRoll
	return {ok = true, message = "Land rerolled.", state = buildState(player)}
end

RF.BuyLuck.OnServerInvoke = function(player)
	local data = getData(player)
	if data.LuckLevel >= LuckConfig.MaxLuckLevel then return {ok = false, message = "Luck is maxed.", state = buildState(player)} end
	local price = LuckConfig.GetLuckUpgradePrice(data.LuckLevel + 1)
	local ok, err = spend(player, price)
	if not ok then return {ok = false, message = err, state = buildState(player)} end
	data.LuckLevel += 1
	updateLeaderstats(player)
	return {ok = true, message = "Luck upgraded.", state = buildState(player)}
end

RF.BuyNextGameplayReel.OnServerInvoke = function(player)
	local data = getData(player)
	local nextReel = data.OwnedGameplayReels + 1
	local price = UpgradeConfig.ReelPrices[nextReel]
	if not price then return {ok = false, message = "Gameplay reels are maxed.", state = buildState(player)} end
	local ok, err = spend(player, price)
	if not ok then return {ok = false, message = err, state = buildState(player)} end
	data.OwnedGameplayReels = nextReel
	return {ok = true, message = "Reel unlocked.", state = buildState(player)}
end

RF.BuyNextCarryCapacity.OnServerInvoke = function(player)
	local data = getData(player)
	local nextCarry = data.CarryCapacity + 5
	local price = UpgradeConfig.CarryCapacityPrices[nextCarry]
	if not price then return {ok = false, message = "Carry capacity is maxed.", state = buildState(player)} end
	local ok, err = spend(player, price)
	if not ok then return {ok = false, message = err, state = buildState(player)} end
	data.CarryCapacity = nextCarry
	return {ok = true, message = "Carry capacity upgraded.", state = buildState(player)}
end

RF.BuyNextSellInterval.OnServerInvoke = function(player)
	local data = getData(player)
	local nextUpgrade = UpgradeConfig.SellIntervalUpgrades[(data.SellIntervalIndex or 1) + 1]
	if not nextUpgrade then return {ok = false, message = "Mart interval is maxed.", state = buildState(player)} end
	local ok, err = spend(player, nextUpgrade.price)
	if not ok then return {ok = false, message = err, state = buildState(player)} end
	data.SellIntervalIndex += 1
	return {ok = true, message = "Super Mart speed upgraded.", state = buildState(player)}
end

RF.GetChipShop.OnServerInvoke = function(player)
	return {ok = true, shop = getShopForPlayer(player), state = buildState(player)}
end

RF.BuyChip.OnServerInvoke = function(player, slotIndex)
	local data = getData(player)
	local shop = getShopForPlayer(player)
	local offer = shop.offers[tonumber(slotIndex)]
	if not offer then return {ok = false, message = "Invalid chip slot.", state = buildState(player)} end
	local key = chipPurchaseKey(shop, tonumber(slotIndex))
	if data.ChipPurchases[key] then return {ok = false, message = "Already bought this chip this restock.", state = buildState(player)} end
	local ok, err = spend(player, offer.price)
	if not ok then return {ok = false, message = err, state = buildState(player)} end
	data.ChipPurchases[key] = true
	data.ChipInventory[offer.id] = (data.ChipInventory[offer.id] or 0) + 1
	return {ok = true, message = "Chip purchased.", state = buildState(player)}
end

RF.ActivateChip.OnServerInvoke = function(player, chipId)
	local data = getData(player)
	if data.ActiveChip and data.ActiveChip.charges > 0 then return {ok = false, message = "A chip is already active.", state = buildState(player)} end
	if (data.ChipInventory[chipId] or 0) <= 0 then return {ok = false, message = "You do not own that chip.", state = buildState(player)} end
	data.ChipInventory[chipId] -= 1
	if data.ChipInventory[chipId] <= 0 then data.ChipInventory[chipId] = nil end
	data.ActiveChip = {chipId = chipId, charges = ChipShopConfig.ChargesPerChip}
	return {ok = true, message = "Chip activated for 5 full spins.", state = buildState(player)}
end

RF.TryFuse.OnServerInvoke = function(player, farmId, fromTier, level, insertedCount)
	return {ok = false, message = "Fusion UI is not wired in this first prototype yet.", state = buildState(player)}
end

RF.ClaimSuperMartMoney.OnServerInvoke = function(player)
	local data = getData(player)
	processSuperMart(data)
	local amount = data.SuperMart.ClaimableMoney
	if amount <= 0 then return {ok = false, message = "No money waiting at Super Mart.", state = buildState(player)} end
	data.SuperMart.ClaimableMoney = 0
	addMoney(player, amount)
	return {ok = true, message = "Claimed Super Mart money.", state = buildState(player)}
end

RF.GiveTestingMoney.OnServerInvoke = function(player, amount)
	addMoney(player, tonumber(amount) or 1e9)
	return {ok = true, message = "Testing money added.", state = buildState(player)}
end

RF.WipeTestingData.OnServerInvoke = function(player)
	dataByPlayer[player] = newData()
	updateLeaderstats(player)
	return {ok = true, message = "Testing data wiped.", state = buildState(player)}
end

print("[FarmRNG] Prototype server loaded.")
