
run(function()
	local AutoMartin
	local Targets
	local Range
	
	AutoMartin = vape.Categories.Minigames:CreateModule({
		Name = 'AutoMartin',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.EntityPosition({
						Range = Range.Value,
						Part = 'RootPart',
						Wallcheck = Targets.Walls.Enabled,
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Sort = sortmethods.Distance
					}) and bedwars.AbilityController:canUseAbility('cactus_fire', {disableBlockedAbilityAlert = true}) then
						bedwars.AbilityController:useAbility('cactus_fire')
					end
					task.wait(0.1)
				until not AutoMartin.Enabled
			end
		end,
		Tooltip = 'Automatically uses "Wild growth" ability when within range.'
	})
	Targets = AutoMartin:CreateTargets({
		Players = true,
		Walls = true
	})
	Range = AutoMartin:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 22,
		Default = 22,
		Suffix = function(val)
			return val <= 0 and 'stud' or 'studs'
		end
	})
end)
