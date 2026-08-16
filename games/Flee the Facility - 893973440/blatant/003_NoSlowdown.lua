
for _, v in {'AimAssist', 'Reach', 'SilentAim', 'TriggerBot', 'AntiFall', 'Invisible', 'Jesus', 'Killaura', 'AntiRagdoll', 'Disabler', 'MurderMystery'} do
	vape:Remove(v)
end

run(function()
	local NoSlowdown
	local old
	
	NoSlowdown = vape.Categories.Blatant:CreateModule({
		Name = 'NoSlowdown',
		Function = function(callback)
			if callback then
				repeat
					for _, v in getconnections(inputService.JumpRequest) do
						if v.Function and debug.info(v.Function, 's'):find('PowersLocalScript') then
							old = v
							v:Disable()
						end
					end
	
					task.wait(0.1)
				until not NoSlowdown.Enabled
			else
				if old then
					old:Enable()
					old = nil
				end
			end
		end,
		Tooltip = 'Prevent slowing down when jumping as the beast'
	})
end)
