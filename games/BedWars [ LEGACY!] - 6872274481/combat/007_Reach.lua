
run(function()
	local BlockReach
	local BlockRange
	local BreakReach
	local BreakRange
	local SwordReach
	local SwordRange
	
	local old
	local swingConnection
	local lastExtendedSwing = 0
	
	local function extendedSwordHit()
		if not entitylib.isAlive then return end
	
		local sword = getSword()
		if not sword or (tick() - lastExtendedSwing) < getSwordSpeed(sword.tool) then return end
	
		local reach = getReach(sword.tool)
		local localPosition = entitylib.character.RootPart.Position
		local target = entitylib.EntityPosition({
			Origin = localPosition,
			Range = SwordRange.Value + 2,
			Part = 'RootPart',
			Players = true,
			NPCs = true,
			Wallcheck = true
		})
		if not target then return end
	
		local delta = target.RootPart.Position - localPosition
		if delta.Magnitude <= reach then return end
	
		local direction = CFrame.lookAt(localPosition, target.RootPart.Position).LookVector
		lastExtendedSwing = tick()
		bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
		bedwars.Handler:Get('SwordHit'):Fire('SendToServer', {
			weapon = sword.tool,
			chargedAttack = {chargeRatio = 0},
			entityInstance = target.Character,
			validate = {
				raycast = {
					cameraPosition = {value = gameCamera.CFrame.Position},
					cursorDirection = {value = direction}
				},
				targetPosition = {value = target.Character:GetPivot().Position},
				selfPosition = {value = localPosition + direction * math.max(delta.Magnitude - (reach - 0.001), 0)}
			}
		})
	end
	
	local function updateExtendedReach()
		if swingConnection then
			swingConnection:Disconnect()
			swingConnection = nil
		end
	
		if canDebug or not Reach.Enabled or not SwordReach.Enabled then return end
	
		swingConnection = inputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	
			extendedSwordHit()
		end)
	end
	
	Reach = vape.Categories.Combat:CreateModule({
		Name = 'Reach',
		Tooltip = 'Allows you to place, attack, and break further',
		Function = function(callback)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = callback and SwordReach.Enabled and SwordRange.Value + 2 or 14.4
			if callback then
				old = bedwars.BlockSelector.getMouseInfo
				bedwars.BlockSelector.getMouseInfo = function(...)
					local Self, Select, Args = ...
					if not Args then
						Args = {}
					end
					if Select == 0 then
						Args.range = BlockReach.Enabled and BlockRange.Value or 24
					elseif Select == 1 then
						Args.range = BreakReach.Enabled and BreakRange.Value or 18
					end
					return old(Self, Select, Args)
				end
			else
				bedwars.BlockSelector.getMouseInfo = old
				old = nil
			end
	
			updateExtendedReach()
		end,
	})
	SwordReach = Reach:CreateToggle({
		Name = 'Sword Reach',
		Function = function(callback)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and callback and SwordRange.Value + 2 or 14.4
			pcall(function()
				SwordRange.Object.Visible = callback
			end)
			updateExtendedReach()
		end,
		Default = true
	})
	SwordRange = Reach:CreateSlider({
		Name = 'Sword Range',
		Min = 1,
		Max = 18,
		Default = 18,
		Decimal = 5,
		Darker = true,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end,
		Function = function(val)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and SwordReach.Enabled and val or 14.4
		end
	})
	BlockReach = Reach:CreateToggle({
		Name = 'Placement Reach',
		Function = function(callback)
			BlockRange.Object.Visible = callback
		end
	})
	BlockRange = Reach:CreateSlider({
		Name = 'Placement Range',
		Min = 1,
		Max = 60,
		Default = 18,
		Darker = true,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end,
		Visible = false
	})
	BreakReach = Reach:CreateToggle({
		Name = 'Break Reach',
		Function = function(callback)
			BreakRange.Object.Visible = callback
		end
	})
	BreakRange = Reach:CreateSlider({
		Name = 'Break Range',
		Min = 1,
		Max = 30,
		Default = 30,
		Decimal = 5,
		Darker = true,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end,
		Visible = false
	})
	Reach:CreateButton({
		Name = 'Reset to default reach',
		Tooltip = 'Resets every range back to default',
		Function = function()
			BreakRange:SetValue(18)
			BlockRange:SetValue(24)
			SwordRange:SetValue(12.4)
		end
	})
end)
