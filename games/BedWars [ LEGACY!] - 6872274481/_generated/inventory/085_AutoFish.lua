
run(function()
	local AutoFish
	local Show
	local Blacklist
	local Minigame
	local CompleteDelay = {}
	local Cast
	local CastDelay = {}
	local rejects = {}
	
	local old
	local function getBait()
		for _, v in workspace:GetChildren() do
			if v.Name == 'fisherman_bobber' and v:GetAttribute('ProjectileShooter') == lplr.UserId then
				return v
			end
		end
		return nil
	end
	
	local function isRejected(pos)
		for _, v in rejects do
			if (v - pos).Magnitude < 4 then
				return true
			end
		end
		return false
	end
	
	local function getCastSpot()
		local localPosition = entitylib.character.RootPart.Position
		local open
	
		for dist = 5, 17, 3 do
			for angle = 0, 330, 30 do
				local spot = localPosition + (CFrame.Angles(0, math.rad(angle), 0).LookVector * dist)
				local ray = entitylib.Raycast(spot + Vector3.new(0, 8, 0), Vector3.new(0, -26, 0), store.airRay)
				if not ray then
					if not open and not isRejected(spot) then
						open = spot
					end
				elseif ray.Material == Enum.Material.Water and not isRejected(ray.Position) then
					return ray.Position
				end
			end
		end
		return open
	end
	
	local function castRod(spot)
		local item = bedwars.FishingRodController:getHandItem()
		if item and not bedwars.FishingRodController.projectileHandler and bedwars.FishingRodController:canLaunch() then
			bedwars.FishingRodController:beginHolding(item, nil, bedwars.FishingRodController.aimingMaid, false)
			task.wait()
			local handler = bedwars.FishingRodController.projectileHandler
			if handler then
				local meta = bedwars.ProjectileMeta.fisherman_bobber
				local origin = (bedwars.ProjectileController:getLaunchPosition(item.tool) or entitylib.character.RootPart.Position) + handler.fromPositionOffset
				handler.targetPoint = prediction.SolveTrajectory(origin, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0) or spot
			end
			bedwars.FishingRodController:releaseChargeInput(bedwars.FishingRodController.aimingMaid, function()
				return true
			end, nil)
		end
	end
	
	AutoFish = vape.Categories.Inventory:CreateModule({
		Name = 'AutoFish',
		Function = function(call)
			if call then
				old = bedwars.FishingMinigameController.startMinigame
				bedwars.FishingMinigameController.startMinigame = function(...)
					if Minigame.Enabled then
						task.wait(CompleteDelay:GetRandomValue())
						return select(3, ...)({win = true})
					end
					return (old or bedwars.FishingMinigameController.startMinigame)(...)
				end
	
				AutoFish:Clean(bedwars.Handler:Get('FishFound').Remote:Connect(function(data)
					local reroll = #Blacklist.ListEnabled > 0
					for _, v in data.dropData.drops do
						local amount = tonumber(v.amount) or 0
						if Show.Enabled then
							local itemDisplay = bedwars.ItemMeta[v.itemType] and bedwars.ItemMeta[v.itemType].displayName or v.itemType
							notif('AutoFish', `You can get {amount} {itemDisplay:lower()}{amount >= 2 and 's' or ''} on ur next fish`, 20, 'info')
						end
						if not table.find(Blacklist.ListEnabled, v.itemType) then
							reroll = false
						end
					end
	
					if reroll and entitylib.isAlive then
						lplr.Character.Humanoid.Jump = true
					end
				end))
				repeat
					if entitylib.isAlive and Cast.Enabled and (store.hand.tool and store.hand.tool.Name == 'fishing_rod') and not getBait() then
						local spot = getCastSpot()
						if not spot and #rejects > 0 then
							table.clear(rejects)
							spot = getCastSpot()
						end
	
						if spot then
							task.wait(CastDelay:GetRandomValue())
							if AutoFish.Enabled then
								castRod(spot)
								task.wait(2.5)
								local bait = getBait()
								if not bait or not bait:GetAttribute('WaitingForFish') then
									table.insert(rejects, spot)
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoFish.Enabled
			else
				table.clear(rejects)
				if old then
					bedwars.FishingMinigameController.startMinigame = old
					old = nil
				end
			end
		end,
		Tooltip = 'Automatically fishes with fishing rod'
	})
	Blacklist = AutoFish:CreateTextList({
		Name = 'Blacklisted loot',
		Default = {'iron'},
		Tooltip = 'Jumps to cancel the catch when every item the fish drops is blacklisted'
	})
	Show = AutoFish:CreateToggle({
		Name = 'Show loot drops',
		Tooltip = 'Notifies ur next lootdrops'
	})
	Minigame = AutoFish:CreateToggle({
		Name = 'Auto Minigame',
		Function = function(callback)
			if CompleteDelay.Object then
				CompleteDelay.Object.Visible = callback
			end
		end,
		Default = true,
		Tooltip = 'Automatically completes the minigame'
	})
	CompleteDelay = AutoFish:CreateTwoSlider({
		Name = 'Complete delay',
		Min = 0,
		Max = 25,
		Decimal = 5,
		DefaultMin = 0.1,
		DefaultMax = 0.9,
		Darker = true
	})
	Cast = AutoFish:CreateToggle({
		Name = 'Auto Cast',
		Function = function(callback)
			if CastDelay.Object then
				CastDelay.Object.Visible = callback
			end
		end,
		Tooltip = 'Finds a spot to fish at and casts there, ignoring where ur camera looks'
	})
	CastDelay = AutoFish:CreateTwoSlider({
		Name = 'Cast delay',
		Min = 0,
		Max = 5,
		Decimal = 5,
		DefaultMin = 0.3,
		DefaultMax = 1.2,
		Darker = true,
		Visible = false
	})
end)
