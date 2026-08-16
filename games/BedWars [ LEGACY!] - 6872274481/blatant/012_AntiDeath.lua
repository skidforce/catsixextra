
run(function()
	local AntiDeath
	local StopThreshold
	local Threshold
	local Notify
	local Delay
	local Mode
	
	local oldroot, clone, hip = nil, nil, 2.7
	
	local function createClone()
		if store.rootpart then return false end
		if entitylib.isAlive and entitylib.character.Humanoid.Health > 0 and (not oldroot or not oldroot.Parent) then
			hip = entitylib.character.Humanoid.HipHeight
			oldroot = entitylib.character.HumanoidRootPart
			if not lplr.Character.Parent then return false end
			lplr.Character.Parent = replicatedStorage
			clone = oldroot:Clone()
			clone.Parent = lplr.Character
			oldroot.Transparency = 1
			oldroot.Parent = workspace
			store.rootpart = oldroot
			lplr.Character.PrimaryPart = clone
			lplr.Character.Parent = workspace
			bedwars.QueryUtil:setQueryIgnored(clone, true)
			bedwars.QueryUtil:setQueryIgnored(oldroot, true)
			return true
		end
		return false
	end
	
	local function destroyClone()
		local char = lplr.Character
		if oldroot and oldroot.Parent and char then 
			char.Parent = replicatedStorage
			oldroot.Parent = char
			if clone then
				clone:Destroy()
				clone = nil
			end
			char.PrimaryPart = oldroot
			char.Parent = workspace
			oldroot.CanCollide = true
			local humanoid = char:FindFirstChildOfClass('Humanoid')
			if humanoid then
				humanoid.HipHeight = hip or 2.6
			end
			oldroot.Transparency = 1
			oldroot = nil
			store.rootpart = nil
			return true
		end
		if clone then
			clone:Destroy()
			clone = nil
		end
		oldroot = nil
		store.rootpart = nil
		return false
	end
	
	local Paused, Activated = 0, 0
	
	AntiDeath = vape.Categories.Blatant:CreateModule({
		Name = 'AntiDeath',
		Function = function(call)
			if call then
				local FloatTime = tick();
	
				AntiDeath:Clean(runService.PreSimulation:Connect(function()
					if oldroot and oldroot.Parent then
						if (tick() - entitylib.character.AirTime) > 1.7 then
							FloatTime = tick() + 0.2
						end
						oldroot.Velocity = Vector3.new(0, 1, 0)
						oldroot.CFrame = clone.CFrame - (tick() > FloatTime and Vector3.new(0, 200, 0) or Vector3.zero)
					end
				end))
	
				repeat
					if tick() > Paused and entitylib.isAlive and (entitylib.character.Humanoid.Health <= Threshold.Value) then
						if (tick() - Activated) >= Delay.Value then
							Activated = tick()
	
							if Notify.Enabled then
								notif('AntiDeath', `Health below {Threshold.Value}%`, 12, 'warning')
							end
	
							if Mode.Value == 'Teleport' then
								lplr.Character.PrimaryPart.CFrame += Vector3.new(0, 100, 0)
								Paused = tick() + 5
							elseif Mode.Value == 'Invincibility' then
								if createClone() then
									Paused = tick() + 5
									task.delay(0, function()
										repeat task.wait() until not AntiDeath.Enabled or not entitylib.isAlive or (entitylib.character.Humanoid.Health >= StopThreshold.Value)
										local old = clone and clone.CFrame or nil
										if destroyClone() and old then
											entitylib.character.RootPart.CFrame = old
										end
										Paused = tick() + 5
	
										if AntiDeath.Enabled and Notify.Enabled then
											notif('AntiDeath', 'You are visible again', 12, 'info')
										end
									end)
								end
							end
						end
					end
					task.wait()
				until not AntiDeath.Enabled
			else
				destroyClone()
			end
		end,
		Tooltip = 'Uses selected mode when on a threshold'
	})
	Mode = AntiDeath:CreateDropdown({
		Name = 'Mode',
		List = {'Teleport', 'Invincibility'},
		Default = 'Invincibility',
		Tooltip = 'Teleport - Teleports you high up\nInvincibility - Makes you unhittable'
	})
	StopThreshold = AntiDeath:CreateSlider({
		Name = 'Stop Threshold',
		Min = 1,
		Max = 100,
		Default = 30,
		Suffix = function()
			return '%'
		end,
		Tooltip = 'Health percentage to untrigger at'
	})
	Threshold = AntiDeath:CreateSlider({
		Name = 'Threshold',
		Min = 1,
		Max = 100,
		Default = 30,
		Suffix = function()
			return '%'
		end,
		Tooltip = 'Health percentage to trigger at'
	})
	Delay = AntiDeath:CreateSlider({
		Name = 'Delay',
		Min = 1,
		Max = 20,
		Default = 5,
		Suffix = function(val)
			return val <= 1 and 'sec' or 'secs'
		end,
		Tooltip = 'Delay between triggers'
	})
	Notify = AntiDeath:CreateToggle({
		Name = 'Notify on trigger',
		Default = true
	})
end)
