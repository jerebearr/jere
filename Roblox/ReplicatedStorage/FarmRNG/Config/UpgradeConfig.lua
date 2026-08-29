local UpgradeConfig = {}

UpgradeConfig.ReelPrices = {
	[2] = 1e5,
	[3] = 1.7e7,
	[4] = 2.9e9,
	[5] = 5e11,
}

UpgradeConfig.MaxGameplayReels = 5
UpgradeConfig.MaxTotalReelsWithPass = 8

UpgradeConfig.CarryCapacityPrices = {
	[10] = 5e3,
	[15] = 5e4,
	[20] = 5e5,
	[25] = 5e6,
	[30] = 5e7,
	[35] = 5e8,
	[40] = 5e9,
	[45] = 5e10,
	[50] = 5e11,
}

UpgradeConfig.SellIntervalUpgrades = {
	{interval = 60, price = 0},
	{interval = 45, price = 5e4},
	{interval = 30, price = 5e6},
	{interval = 20, price = 5e8},
	{interval = 15, price = 5e10},
	{interval = 10, price = 5e12},
	{interval = 5, price = 5e14},
	{interval = 2, price = 5e16},
	{interval = 1, price = 5e18},
}

return UpgradeConfig
