
run(function()
	local AutoMiner
	local Delay
	local Animation
	local Range
	
	local Legit = getFunctionRange(bedwars.MinerController.setupMinerPrompts) or 0
	
	AutoMiner = vape.Categories.Minigames:CreateModule({
		Name = 'AutoMiner',
		Function = function(callback)
			if callback then
				local petrified = collection('petrified-player', AutoMiner)
				local cooldown = 0
	
				repeat
					if entitylib.isAlive and tick() - cooldown >= math.max(Delay.Value, 0.25) then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in petrified do
							local root = v:IsA('Model') and v.PrimaryPart or v
							local petrifyId = v:GetAttribute('PetrifyId')
							if root and petrifyId and (localPosition - root.Position).Magnitude <= Range.Value then
								if Animation.Enabled then
									bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.MINER_MINE_STONE)
								end
	
								task.delay(Delay.Value, function()
									if AutoMiner.Enabled and v.Parent then
										bedwars.Handler:Get('DestroyPetrifiedPlayer'):Fire('SendToServer', {
											petrifyId = petrifyId
										})
									end
								end)
								cooldown = tick()
								break
							end
						end
					end
					task.wait(0.1)
				until not AutoMiner.Enabled
			end
		end,
		Tooltip = 'Automatically mines petrified players within range'
	})
	Range = AutoMiner:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 12,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	AutoMiner:CreateButton({
		Name = 'Sync to legit range',
		Function = function()
			Range:SetValue(Legit)
		end
	})
	Delay = AutoMiner:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 2,
		Default = 0.1,
		Decimal = 10,
		Suffix = 'seconds'
	})
	Animation = AutoMiner:CreateToggle({
		Name = 'Animation',
		Default = true
	})
end)
