
run(function()
	local AutoMelody
	local Range
	local SelfHeal
	local TeammateHeal
	
	AutoMelody = vape.Categories.Minigames:CreateModule({
		Name = 'AutoMelody',
		Function = function(callback)
			if callback then
				repeat
					local mag, hp, ent = Range.Value, math.huge, nil
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in entitylib.List do
							if v.Player and (SelfHeal.Enabled or v.Player ~= lplr) and (TeammateHeal.Enabled and v.Player:GetAttribute('Team') == lplr:GetAttribute('Team') or not TeammateHeal.Enabled and SelfHeal.Enabled and v.Player == lplr) then
								local newmag = (localPosition - v.RootPart.Position).Magnitude
								if newmag <= mag and v.Health < hp and v.Health < v.MaxHealth then
									mag, hp, ent = newmag, v.Health, v
								end
							end
						end
					end
	
					if ent and getItem('guitar') then
						bedwars.Handler:Get('GuitarHeal'):Fire('SendToServer', {
							healTarget = ent.Character
						})
					end
					task.wait(0.1)
				until not AutoMelody.Enabled
			end
		end,
		Tooltip = 'Automatically uses the guitar to heal ur teammates/urself'
	})
	SelfHeal = AutoMelody:CreateToggle({
		Name = 'Self Heal',
		Default = true
	})
	TeammateHeal = AutoMelody:CreateToggle({
		Name = 'Teammate Heal',
		Default = true
	})
	Range = AutoMelody:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 30,
		Decimal = 4
	})
end)
