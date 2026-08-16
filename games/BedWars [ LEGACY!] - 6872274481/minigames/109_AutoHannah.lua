
run(function()
	local AutoHannah
	local Range
	
	AutoHannah = vape.Categories.Minigames:CreateModule({
		Name = 'AutoHannah',
		Function = function(callback)
			if callback then
				local attempted = {}
				local objs = collection('HannahExecuteInteraction', AutoHannah, function(list, v)
					attempted[v] = nil
					table.insert(list, v)
				end, function(list, v)
					attempted[v] = nil
					local index = table.find(list, v)
					if index then
						table.remove(list, index)
					end
				end)
	
				repeat
					if entitylib.isAlive and store.equippedKit == 'hannah' then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in objs do
							if not AutoHannah.Enabled then
								break
							end
	
							local part = not v:IsA('Model') and v or v.PrimaryPart
							if part and (part.Position - localPosition).Magnitude <= Range.Value and (not attempted[v] or tick() - attempted[v] >= 1) then
								attempted[v] = tick()
	
								local billboard = bedwars.Handler:Get('HannahPromptTrigger'):Fire('CallServer', {
									user = lplr,
									victimEntity = v
								}) and v:FindFirstChild('Hannah Execution Icon')
	
								if billboard then
									billboard:Destroy()
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoHannah.Enabled
			end
		end,
		Tooltip = 'Automatically executes low health players with Hannah.'
	})
	AutoHannah:CreateTargets({Players = true})
	
	Range = AutoHannah:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 30,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	
	AutoHannah:CreateDropdown({
		Name = 'Target mode',
		List = methods,
		Default = 'Health'
	})
	AutoHannah:CreateToggle({
		Name = 'Only killaura target',
		Tooltip = 'Only executes targets that are being attacked by killaura'
	})
end)
