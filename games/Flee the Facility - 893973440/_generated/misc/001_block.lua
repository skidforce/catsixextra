run(function()
	lstats = lplr:FindFirstChild('TempPlayerStatsModule')
	if not lstats then
		repeat
			lstats = lplr:FindFirstChild('TempPlayerStatsModule')
			task.wait()
		until lstats or vape.Loaded == nil

		if vape.Loaded == nil then
			return
		end
	end

	local mapval = replicatedStorage.CurrentMap
	local function updateMap()
		if mapval.Value then
			mapobj = mapval.Value
			vapeEvents.MapAdded:Fire(mapobj)
		elseif mapboj then
			vapeEvents.MapRemoved:Fire(mapboj)
			mapobj = nil
		end
	end

	vape:Clean(mapval:GetPropertyChangedSignal('Value'):Connect(updateMap))
	if mapval.Value then
		updateMap()
	end
end)
