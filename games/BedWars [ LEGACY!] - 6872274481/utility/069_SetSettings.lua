
run(function()
	local SetSettings
	local old = bedwars.SettingsController.settings or {}
	local options = {}
	
	SetSettings = vape.Categories.Utility:CreateModule({
		Name = 'SetSettings',
		Function = function(callback)
			if callback then
				for i in old do
					local module = options[i]
					if module then
						bedwars.SettingsController:setSetting(i, module.Value)
					end
				end
			end
		end,
		Tooltip = 'Adds bedwars settings options to cat vape (also carries the settings with your cv config).'
	})
	for i, v in old do
		if bedwars.SettingsMeta[i] and bedwars.SettingsMeta[i].tab == 'Mobile' then
			continue
		end
		local create = typeof(v) == 'boolean' and 'Toggle' or typeof(v) == 'number' and 'Slider' or nil
		if create and bedwars.SettingsMeta[i] then
			options[i] = SetSettings["Create".. create](SetSettings, {
				Name = bedwars.SettingsMeta[i].name,
				Default = v,
				Min = 1,
				Max = 360,
				Decimal = 5,
				Function = function(val)
					if SetSettings.Enabled then
						bedwars.SettingsController:setSetting(i, val)
					end
				end
			})
		elseif shared.VapeDeveloper then
			notif('Vape', 'Unknown bedwars setting detected ('.. i.. ')', 20, 'alert')
		end
	end
end)
