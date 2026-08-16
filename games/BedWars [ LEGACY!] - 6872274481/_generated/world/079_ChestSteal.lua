
run(function()
	local ChestSteal
	local Range
	local Open
	local Skywars
	local Legit
	local Visualize
	local FillColor
	local OutlineColor
	local Animate
	local Speed
	local Delays = {}
	local Boxes = {}
	local Tweens = {}
	local BoxTargets = {}
	
	local function makeBox()
		local part = Instance.new('Part')
		part.Size = Vector3.new(3, 3, 3)
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		local selection = Instance.new('SelectionBox')
		selection.Adornee = part
		selection.LineThickness = 0.04
		selection.Parent = part
		bedwars.QueryUtil:setQueryIgnored(part, true)
		return part
	end
	
	local function updateBoxes(targets)
		for i, part in Boxes do
			local chest = targets and targets[i]
			if chest ~= BoxTargets[i] then
				if Tweens[i] then
					Tweens[i]:Cancel()
					Tweens[i] = nil
				end
	
				if not chest then
					part.Parent = nil
				elseif Animate.Enabled and part.Parent == gameCamera then
					Tweens[i] = tweenService:Create(part, TweenInfo.new(Speed.Value, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = chest.CFrame})
					Tweens[i]:Play()
				else
					part.CFrame = chest.CFrame
					part.Parent = gameCamera
				end
				BoxTargets[i] = chest
			end
	
			if chest then
				part.SelectionBox.Color3 = Color3.fromHSV(OutlineColor.Hue, OutlineColor.Sat, OutlineColor.Value)
				part.SelectionBox.Transparency = 1 - OutlineColor.Opacity
				part.SelectionBox.SurfaceColor3 = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
				part.SelectionBox.SurfaceTransparency = 1 - FillColor.Opacity
			end
		end
	end
	
	local function lootChest(chest)
		chest = chest and chest.Value or nil
		local chestitems = chest and chest:GetChildren() or {}
		if #chestitems > 1 and (Delays[chest] or 0) < tick() then
			Delays[chest] = tick() + 0.2
			bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(chest)
	
			for _, v in chestitems do
				if v:IsA('Accessory') then
					task.spawn(function()
						pcall(function()
							bedwars.Client:GetNamespace('Inventory'):Get('ChestGetItem'):CallServer(chest, v)
						end)
					end)
					if Legit.Enabled then
						task.wait(0.2)
					end
				end
			end
	
			bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(nil)
		end
	end
	
	ChestSteal = vape.Categories.World:CreateModule({
		Name = 'ChestSteal',
		Function = function(callback)
			if callback then
				local chests = collection('chest', ChestSteal)
				repeat task.wait() until store.queueType ~= 'bedwars_test'
				local function getChestPart(folder)
					for _, v in chests do
						local value = v:FindFirstChild('ChestFolderValue')
						if value and value.Value == folder then
							return v
						end
					end
					return nil
				end
	
				if (not Skywars.Enabled) or store.queueType:find('skywars') then
					repeat
						local targets = {}
						if entitylib.isAlive and store.matchState ~= 2 then
							if Open.Enabled then
								if bedwars.AppController:isAppOpen('ChestApp') then
									local observed = lplr.Character:FindFirstChild('ObservedChestFolder')
									lootChest(observed)
									targets[1] = observed and observed.Value and getChestPart(observed.Value) or nil
								end
							else
								local localPosition = entitylib.character.RootPart.Position
								local closest = math.huge
								for _, v in chests do
									local magnitude = (localPosition - v.Position).Magnitude
									if magnitude <= Range.Value then
										lootChest(v:FindFirstChild('ChestFolderValue'))
										if magnitude < closest then
											closest, targets[1] = magnitude, v
										end
									end
								end
							end
						end
	
						updateBoxes(targets)
						task.wait(0.1)
					until not ChestSteal.Enabled
				end
			else
				updateBoxes(nil)
			end
		end,
		Tooltip = 'Grabs items from near chests.'
	})
	Range = ChestSteal:CreateSlider({
		Name = 'Range',
		Min = 0,
		Max = 18,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Visualize = ChestSteal:CreateToggle({
		Name = 'Visualize',
		Function = function(callback)
			FillColor.Object.Visible = callback
			OutlineColor.Object.Visible = callback
			Animate.Object.Visible = callback
			Speed.Object.Visible = callback
			if callback then
				Boxes[1] = makeBox()
			else
				updateBoxes(nil)
				for _, v in Boxes do
					v:Destroy()
				end
				table.clear(Boxes)
				table.clear(Tweens)
				table.clear(BoxTargets)
			end
		end,
		Tooltip = 'Draws a box around the closest chest being looted'
	})
	FillColor = ChestSteal:CreateColorSlider({
		Name = 'Fill Color',
		DefaultSat = 0,
		DefaultOpacity = 0.25,
		Darker = true,
		Visible = false
	})
	OutlineColor = ChestSteal:CreateColorSlider({
		Name = 'Outline Color',
		DefaultSat = 0,
		Darker = true,
		Visible = false
	})
	Animate = ChestSteal:CreateToggle({
		Name = 'Animate',
		Default = true,
		Darker = true,
		Visible = false,
		Tooltip = 'Glides the box onto the next chest instead of snapping to it'
	})
	Speed = ChestSteal:CreateSlider({
		Name = 'Animation time',
		Min = 0.01,
		Max = 0.5,
		Default = 0.08,
		Decimal = 100,
		Suffix = 's',
		Darker = true,
		Visible = false
	})
	Open = ChestSteal:CreateToggle({Name = 'GUI Check'})
	Legit = ChestSteal:CreateToggle(({Name = 'Legit mode'}))
	Skywars = ChestSteal:CreateToggle({
		Name = 'Only Skywars',
		Function = function()
			if ChestSteal.Enabled then
				ChestSteal:Toggle()
				ChestSteal:Toggle()
			end
		end,
		Default = true
	})
end)
