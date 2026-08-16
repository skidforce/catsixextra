
run(function()
	local AutoXurot
	local Range
	local Delay
	local dragonForm = false
	local nextBreath = 0
	
	local Breath = bedwars.Handler:Get('DragonBreath')
	
	local function isLocal(data)
		if type(data) ~= 'table' then return true end
		return data.player == nil or data.player == lplr
	end
	
	AutoXurot = vape.Categories.Minigames:CreateModule({
		Name = 'AutoXurot',
		Function = function(callback)
			if callback then
				dragonForm, nextBreath = false, 0
	
				local action = bedwars.Handler:Get('VoidDragonAction')
				if action.Remote then
					AutoXurot:Clean(action.Remote:Connect(function(data)
						if isLocal(data) then
							if data.action == 'transform' then
								dragonForm = true
							elseif data.action == 'dragon_deactive' then
								dragonForm = false
							end
						end
					end))
				end
	
				local deactive = bedwars.Handler:Get('VoidDragonDeactive')
				if deactive.Remote then
					AutoXurot:Clean(deactive.Remote:Connect(function(data)
						if isLocal(data) then
							dragonForm = false
						end
					end))
				end
	
				AutoXurot:Clean(lplr.CharacterAdded:Connect(function()
					dragonForm = false
				end))
	
				repeat
					if dragonForm and entitylib.isAlive and store.equippedKit == 'void_dragon' and tick() >= nextBreath then
						local target = entitylib.EntityPosition({
							Origin = entitylib.character.RootPart.Position,
							Range = Range.Value,
							Part = 'RootPart',
							Players = true,
							Wallcheck = true
						})
	
						if target then
							nextBreath = tick() + Delay.Value
							Breath:Fire('SendToServer', {player = lplr, targetPoint = target.RootPart.Position})
						end
					end
					task.wait(0.05)
				until not AutoXurot.Enabled
			end
		end,
		Tooltip = 'Automatically breathes on enemies while you are in dragon form'
	})
	Range = AutoXurot:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 200,
		Default = 120,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	Delay = AutoXurot:CreateSlider({
		Name = 'Delay',
		Min = 0.1,
		Max = 3,
		Default = 0.5,
		Decimal = 10,
		Suffix = function(val)
			return val <= 1 and 'sec' or 'secs'
		end
	})
end)
