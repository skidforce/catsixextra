
run(function()
	local FastPlace
	local CPS
	
	FastPlace = vape.Categories.World:CreateModule({
		Name = 'FastPlace',
		Function = function(callback)
			bedwars.SharedConstants.BLOCK_PLACE_CPS = callback and CPS.Value or 12
		end,
		Tooltip = 'Changes the block place delay'
	})
	CPS = FastPlace:CreateSlider({
		Name = 'Cps',
		Min = 1,
		Max = 100,
		Function = function(val)
			if FastPlace.Enabled then
				bedwars.SharedConstants.BLOCK_PLACE_CPS = val
			end
		end,
		Default = 13
	})
	FastPlace:CreateButton({
		Name = 'Reset to bedwars cps',
		Function = function()
			CPS:SetValue(12)
		end
	})
end)
