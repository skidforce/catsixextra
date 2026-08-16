
run(function()
	local AutoHephaestus
	local lastRepair = 0
	
	AutoHephaestus = vape.Categories.Minigames:CreateModule({
		Name = 'AutoHephaestus',
		Function = function(callback)
			if callback then
				AutoHephaestus:Clean(runService.Heartbeat:Connect(function()
					if tick() >= lastRepair and store.equippedKit == 'tinker' and bedwars.TinkerKitController.mounted and bedwars.AbilityController:canUseAbility('tinker_self_repair', {disableBlockedAbilityAlert = true}) and (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 1 then
						lastRepair = tick() + 0.5
						bedwars.AbilityController:useAbility('tinker_self_repair')
					end
				end))
			end
		end,
		Tooltip = 'Automatically repairs your Tinker machine whenever the self repair ability is available'
	})
end)
