
run(function()
	local TriggerBot
	local Targets
	local Range
	local Angle
	local CPS
	local Limit
	local Region
	local Mouse
	local GUI
	local BoxColor
	local BoxTween
	local BoxSpeed
	
	local box
	local rayParams = RaycastParams.new()
	
	local function getTarget(localPosition, attackRange, angle)
		if angle > 0 then
			local ent = entitylib.EntityMouse({
				Part = 'RootPart',
				Range = angle,
				MouseOrigin = gameCamera.ViewportSize / 2,
				Players = Targets.Players.Enabled,
				NPCs = Targets.NPCs.Enabled,
				Wallcheck = Targets.Walls.Enabled,
				Origin = localPosition
			})
			if not ent or (localPosition - ent.RootPart.Position).Magnitude > attackRange then return nil end
	
			return ent
		end
	
		local unit = lplr:GetMouse().UnitRay
		rayParams.FilterDescendantsInstances = {lplr.Character}
		local ray = bedwars.QueryUtil:raycast(unit.Origin, unit.Direction * 200, rayParams)
		if not ray then return nil end
	
		for _, ent in entitylib.List do
			if ent.Targetable and ray.Instance:IsDescendantOf(ent.Character) and (localPosition - ent.RootPart.Position).Magnitude <= attackRange then
				if Targets.Players.Enabled and ent.Player or Targets.NPCs.Enabled and not ent.Player then
					if not Targets.Walls.Enabled or not entitylib.Wallcheck(localPosition, ent.RootPart.Position, true, ent) then
						return ent
					end
				end
			end
		end
	
		return nil
	end
	
	TriggerBot = vape.Categories.Combat:CreateModule({
		Name = 'TriggerBot',
		Function = function(callback)
			if callback then
				repeat
					local ent, doAttack
					if entitylib.isAlive and (not GUI.Enabled or not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN)) and (not Mouse.Enabled or inputService:IsMouseButtonPressed(0)) then
						if (not Limit.Enabled or store.hand.toolType == 'sword') and bedwars.DaoController.chargingMaid == nil then
							local attackRange = math.clamp(Range.Value, 0, getReach(store.hand.tool) * 2)
							ent = getTarget(entitylib.character.RootPart.Position, attackRange, Angle.Value)
							doAttack = ent ~= nil
							if not doAttack and Region.Enabled then
								doAttack = bedwars.SwordController:getTargetInRegion(attackRange, 0) ~= nil
							end
	
							if ent then
								targetinfo.Targets[ent] = tick() + 1
							end
	
							if doAttack and canSwing() then
								bedwars.SwordController:swingSwordAtMouse()
							end
						end
					end
	
					if box then
						box.Adornee = ent and ent.RootPart or nil
						tweenService:Create(box, TweenInfo.new(BoxSpeed.Value, Enum.EasingStyle[BoxTween.Value]), {
							Size = ent and Vector3.new(4, 6, 4) or Vector3.zero
						}):Play()
						if ent then
							box.Color3 = Color3.fromHSV(BoxColor.Hue, BoxColor.Sat, BoxColor.Value)
							box.Transparency = 1 - BoxColor.Opacity
						end
					end
	
					task.wait(doAttack and 1 / CPS.GetRandomValue() or 0.016)
				until not TriggerBot.Enabled
			end
		end,
		Tooltip = 'Automatically swings when hovering over a entity'
	})
	
	Targets = TriggerBot:CreateTargets({
		Players = true,
		NPCs = true,
		Walls = true
	})
	Range = TriggerBot:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 18,
		Default = 18,
		Decimal = 10,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end,
		Tooltip = 'Clamped by the reach of whatever you are holding'
	})
	Angle = TriggerBot:CreateSlider({
		Name = 'Angle',
		Min = 0,
		Max = 1000,
		Default = 0,
		Tooltip = 'Swings at entities near the middle of your screen instead of only the one under your cursor'
	})
	CPS = TriggerBot:CreateTwoSlider({
		Name = 'CPS',
		Min = 1,
		Max = 9,
		DefaultMin = 7,
		DefaultMax = 7
	})
	Limit = TriggerBot:CreateToggle({
		Name = 'Limit to items',
		Default = true,
		Tooltip = 'Only swings when the sword is held'
	})
	Region = TriggerBot:CreateToggle({
		Name = 'Region check',
		Default = true,
		Tooltip = 'Also swings when the game reports anything inside your sword region'
	})
	Mouse = TriggerBot:CreateToggle({Name = 'Require mouse down'})
	GUI = TriggerBot:CreateToggle({Name = 'GUI check'})
	TriggerBot:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxColor.Object.Visible = callback
			BoxTween.Object.Visible = callback
			BoxSpeed.Object.Visible = callback
			if callback then
				box = Instance.new('BoxHandleAdornment')
				box.Adornee = nil
				box.AlwaysOnTop = true
				box.Size = Vector3.zero
				box.CFrame = CFrame.new(0, -0.5, 0)
				box.ZIndex = 0
				box.Parent = vape.gui
			elseif box then
				box:Destroy()
				box = nil
			end
		end
	})
	local animlist = {'Bounce'}
	for _, v in Enum.EasingStyle:GetEnumItems() do
		if not table.find(animlist, v.Name) then
			table.insert(animlist, v.Name)
		end
	end
	BoxTween = TriggerBot:CreateDropdown({
		Name = 'Box Animation',
		List = animlist,
		Darker = true,
		Visible = false
	})
	BoxSpeed = TriggerBot:CreateSlider({
		Name = 'Animation Speed',
		Min = 0,
		Max = 10,
		Default = 0.9,
		Decimal = 30,
		Darker = true,
		Visible = false
	})
	BoxColor = TriggerBot:CreateColorSlider({
		Name = 'Target Color',
		Darker = true,
		DefaultHue = 0.6,
		DefaultOpacity = 0.5,
		Visible = false
	})
end)
