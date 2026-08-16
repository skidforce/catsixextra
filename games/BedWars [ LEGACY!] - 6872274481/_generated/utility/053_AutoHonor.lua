
run(function()
	local AutoHonor
	local Delay
	
	local Honored = {}
	local function honor()
		if #Honored > 1 then return end
		local list, team = table.clone(entitylib.List), lplr:GetAttribute('Team')
		table.sort(list, function(a, b)
			return a.Player:GetAttribute('Team') == team and b.Player:GetAttribute('Team') ~= team
		end)
		for _, v in list do
			if #Honored > 1 then break end
			if not table.find(Honored, v.Player) then
				bedwars.HonorController:honorPlayer(v.Player.UserId)
				table.insert(Honored, v.Player)
				task.wait(Delay.Value)
			end
		end
	end
	
	AutoHonor = vape.Categories.Utility:CreateModule({
		Name = 'AutoHonor',
		Function = function(callback)
			if callback then
				AutoHonor:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill and deathTable.entityInstance == lplr.Character and #bedwars.Store:getState().Party.members <= 0 and store.matchState ~= 2 then
						honor()
					end
				end))
				AutoHonor:Clean(vapeEvents.MatchEndEvent.Event:Connect(honor))
			end
		end,
		Tooltip = 'Automatically honor your teammates'
	})
	Delay = AutoHonor:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 2,
		Decimal = 100,
		Suffix = 'seconds',
		Default = 0.1
	})
end)
