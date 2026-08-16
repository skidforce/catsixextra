
run(function()
	local AutoLasso
	local Targets
	local Range
	local FireRate
	local SwitchDelay
	local nextFire = 0
	
	local function throwLasso()
		local item = getItem('lasso')
		local source = item and bedwars.ItemMeta.lasso.projectileSource or nil
		local target = source and getFacingEntity({
			Part = 'RootPart',
			Range = Range.Value,
			Players = Targets.Players.Enabled,
			NPCs = Targets.NPCs.Enabled,
			Wallcheck = Targets.Walls.Enabled,
			Limit = 10
		}) or nil
		if not target then return end
	
		local hotbar = store.hand.tool and getHotbar(store.hand.tool) or nil
		if hotbarSwitch(getHotbar(item.tool)) then
			task.wait(store.ping.total or 0)
			if fireProjectile(item, 'lasso', source.projectileType('lasso'), target) then
				nextFire = tick() + source.fireDelaySec + FireRate:GetRandomValue()
				task.wait(SwitchDelay.Value)
			end
			hotbarSwitch(hotbar)
		end
	end
	
	AutoLasso = vape.Categories.Minigames:CreateModule({
		Name = 'AutoLasso',
		Function = function(callback)
			if callback then
				nextFire = 0
	
				repeat
					if entitylib.isAlive and store.equippedKit == 'cowgirl' and store.hand.toolType == 'sword' and (tick() - bedwars.SwordController.lastSwing) < 0.2 and tick() >= nextFire then
						throwLasso()
					end
					task.wait(0.1)
				until not AutoLasso.Enabled
			end
		end,
		Tooltip = 'Automatically throws Lassy\'s lasso at whoever you\'re meleeing'
	})
	Targets = AutoLasso:CreateTargets({
		Players = true,
		NPCs = false
	})
	Range = AutoLasso:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 60,
		Default = 22,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	FireRate = AutoLasso:CreateTwoSlider({
		Name = 'Fire Rate',
		Min = 0,
		Max = 1,
		DefaultMin = 0.05,
		DefaultMax = 0.12,
		Decimal = 100
	})
	SwitchDelay = AutoLasso:CreateSlider({
		Name = 'Switch Delay',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Suffix = 'seconds',
		Default = 0.02
	})
end)
