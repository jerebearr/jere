local PlotPriceConfig = {}

PlotPriceConfig.MaxPlots = 40
PlotPriceConfig.Plot2Price = 250
PlotPriceConfig.FinalPlotPrice = 2e18 -- 2 Qi
PlotPriceConfig.Multiplier = math.pow(
	PlotPriceConfig.FinalPlotPrice / PlotPriceConfig.Plot2Price,
	1 / (PlotPriceConfig.MaxPlots - 2)
)

function PlotPriceConfig.GetPlotPrice(plotNumber)
	if plotNumber <= 1 then
		return 0
	end

	if plotNumber > PlotPriceConfig.MaxPlots then
		return nil
	end

	return math.floor(
		PlotPriceConfig.Plot2Price * math.pow(PlotPriceConfig.Multiplier, plotNumber - 2) + 0.5
	)
end

function PlotPriceConfig.GetTotalCostToPlot(plotNumber)
	local total = 0

	for n = 2, math.min(plotNumber, PlotPriceConfig.MaxPlots) do
		total += PlotPriceConfig.GetPlotPrice(n)
	end

	return total
end

return PlotPriceConfig
