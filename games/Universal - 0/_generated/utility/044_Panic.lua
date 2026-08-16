
run(function()
	local time = tick()
	local Panic; Panic = vape.Categories.Utility:CreateModule({
		Name = 'Panic',
		Function = function(callback)
			if callback then
				if time > tick() then
					for _, v in vape.Modules do
						if v.Enabled then
							v:Toggle()
						end
					end
				else
					notif('Panic', 'Re-enable panic to confirm', 5, 'info')
					time = tick() + 1
					Panic:Toggle()
				end
			end
		end,
		Tooltip = 'Disables all currently enabled modules'
	})
end)
