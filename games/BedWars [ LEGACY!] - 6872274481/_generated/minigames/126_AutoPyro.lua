
run(function()
	local AutoPyro
	
	local list = {'Range', 'Heat', 'Power'}
	
	AutoPyro = vape.Categories.Minigames:CreateModule({
		Name = 'AutoPyro',
		Function = function(callback)
			if callback then
				repeat
					local flamethrower = getItem('flamethrower')
					if flamethrower then
						for _, v in list do
							local upgrade = v:lower()
							local value = flamethrower.tool:GetAttribute(upgrade) or -1
							local nextUpgrade = AutoPyro.Options[`Buy {v}`].Enabled and value < 3 and bedwars.PyroUpgradeMeta[upgrade].tiers[value + 2]
	
							if nextUpgrade then
								local currency = getItem(nextUpgrade.currency)
								if currency and currency.amount >= nextUpgrade.price then
									bedwars.Handler:Get('UpgradeFlamethrower'):Fire('CallServer', upgrade)
									task.wait(0.1)
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoPyro.Enabled
			end
		end,
		Tooltip = 'Automatically upgrades flamethrower'
	})
	for _, v in list do
		AutoPyro:CreateToggle({
			Name = `Buy {v}`,
			Default = true
		})
	end
end)
