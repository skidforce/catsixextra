
run(function()
	local CannonSpeed
	local Value
	
	CannonSpeed = vape.Categories.Blatant:CreateModule({
		Name = 'CannonSpeed',
		Function = function(callback)
			debug.setconstant(bedwars.CannonHandController.launchSelf, 15, callback and Value.Value or 200)
		end,
		Tooltip = 'Makes you go faster with cannon.'
	})
	Value = CannonSpeed:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 400,
		Default = 200,
		Function = function(val)
			if CannonSpeed.Enabled then
				debug.setconstant(bedwars.CannonHandController.launchSelf, 15, val)
			end
		end,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	CannonSpeed:CreateButton({
		Name = 'Sync to legit speed',
		Function = function()
			Value:SetValue(200)
		end
	})
end)
