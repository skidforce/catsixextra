
run(function()
	local AutoEldric
	local Range
	local Allies
	local Health
	local linked
	
	local Link = bedwars.Handler:Get('WarlockLinkTarget')
	
	AutoEldric = vape.Categories.Minigames:CreateModule({
		Name = 'AutoEldric',
		Function = function(callback)
			if callback then
				linked = nil
	
				repeat
					if entitylib.isAlive and store.equippedKit == 'warlock' then
						local origin = entitylib.character.RootPart.Position
						local target = entitylib.EntityPosition({
							Origin = origin,
							Range = Range.Value,
							Part = 'RootPart',
							Players = true,
							Wallcheck = true
						})
	
						if not target and Allies.Enabled then
							for _, v in entitylib.List do
								if not v.Targetable and v.Player and v ~= entitylib.character and (v.RootPart.Position - origin).Magnitude <= Range.Value and (v.Health / v.MaxHealth) <= (Health.Value / 100) then
									target = v
									break
								end
							end
						end
	
						if target and target.Character ~= linked then
							linked = target.Character
							Link:Fire('CallServer', {target = target.Character})
						elseif not target then
							linked = nil
						end
					end
					task.wait(0.1)
				until not AutoEldric.Enabled
			end
		end,
		Tooltip = 'Automatically links the warlock staff to enemies or hurt teammates'
	})
	Range = AutoEldric:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 60,
		Default = 24,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	AutoEldric:CreateButton({
		Name = 'Sync to legit range',
		Function = function()
			Range:SetValue(24)
		end
	})
	Allies = AutoEldric:CreateToggle({
		Name = 'Heal teammates',
		Default = true,
		Tooltip = 'Links a hurt teammate when no enemy is in range'
	})
	Health = AutoEldric:CreateSlider({
		Name = 'Ally health',
		Min = 1,
		Max = 100,
		Default = 70,
		Darker = true,
		Suffix = function()
			return '%'
		end
	})
end)
