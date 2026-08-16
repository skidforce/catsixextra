
run(function()
	local OverlayEditor
	local FillColor
	local OutlineColor
	local Thickness
	local Animate
	local Speed
	local overlay, overlayBox, overlayTween
	local activePart
	
	local isOverlayPart = function(part)
		return part:IsA('BasePart') and part.Anchored and part.Transparency == 1 and part:FindFirstChildOfClass('SelectionBox') ~= nil
	end
	
	local function hideOverlay()
		if overlayTween then
			overlayTween:Cancel()
			overlayTween = nil
		end
		if overlay then
			overlay.Parent = nil
		end
	end
	
	local moveOverlay = function(part)
		if not overlay then return end
	
		if overlayTween then
			overlayTween:Cancel()
			overlayTween = nil
		end
	
		if Animate.Enabled and overlay.Parent == gameCamera then
			overlayTween = tweenService:Create(overlay, TweenInfo.new(Speed.Value, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = part.CFrame, Size = part.Size})
			overlayTween:Play()
		else
			overlay.CFrame = part.CFrame
			overlay.Size = part.Size
			overlay.Parent = gameCamera
		end
	end
	
	local bindPart = function(part)
		if not OverlayEditor.Enabled or not isOverlayPart(part) then return end
	
		part:FindFirstChildOfClass('SelectionBox').Visible = false
		activePart = part
		moveOverlay(part)
	end
	
	OverlayEditor = vape.Categories.Render:CreateModule({
		Name = 'OverlayEditor',
		Function = function(callback)
			if callback then
				overlay = Instance.new('Part')
				overlay.Size = Vector3.one * 3
				overlay.Anchored = true
				overlay.CanCollide = false
				overlay.CanQuery = false
				overlay.CanTouch = false
				overlay.CastShadow = false
				overlay.Transparency = 1
				overlayBox = Instance.new('SelectionBox')
				overlayBox.Adornee = overlay
				overlayBox.LineThickness = Thickness.Value
				overlayBox.Color3 = Color3.fromHSV(OutlineColor.Hue, OutlineColor.Sat, OutlineColor.Value)
				overlayBox.Transparency = 1 - OutlineColor.Opacity
				overlayBox.SurfaceColor3 = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
				overlayBox.SurfaceTransparency = 1 - FillColor.Opacity
				overlayBox.Parent = overlay
				bedwars.QueryUtil:setQueryIgnored(overlay, true)
	
				for _, child in workspace:GetChildren() do
					bindPart(child)
				end
	
				OverlayEditor:Clean(workspace.ChildAdded:Connect(function(child)
					task.defer(bindPart, child)
				end))
				OverlayEditor:Clean(workspace.ChildRemoved:Connect(function(child)
					if child ~= activePart then return end
	
					activePart = nil
					task.delay(0.06, function()
						if not activePart and OverlayEditor.Enabled then
							hideOverlay()
						end
					end)
				end))
			else
				if activePart then
					local box = activePart:FindFirstChildOfClass('SelectionBox')
					if box then
						box.Visible = true
					end
					activePart = nil
				end
	
				hideOverlay()
				if overlay then
					overlay:Destroy()
					overlay, overlayBox = nil, nil
				end
			end
		end,
		Tooltip = 'Restyles the outline on the block you are aiming at'
	})
	FillColor = OverlayEditor:CreateColorSlider({
		Name = 'Fill Color',
		DefaultSat = 0,
		DefaultOpacity = 0.25,
		Darker = true,
		Function = function(hue, sat, val, opacity)
			if overlayBox then
				overlayBox.SurfaceColor3 = Color3.fromHSV(hue, sat, val)
				overlayBox.SurfaceTransparency = 1 - opacity
			end
		end
	})
	OutlineColor = OverlayEditor:CreateColorSlider({
		Name = 'Outline Color',
		DefaultSat = 0,
		Darker = true,
		Function = function(hue, sat, val, opacity)
			if overlayBox then
				overlayBox.Color3 = Color3.fromHSV(hue, sat, val)
				overlayBox.Transparency = 1 - opacity
			end
		end
	})
	Thickness = OverlayEditor:CreateSlider({
		Name = 'Thickness',
		Min = 0.01,
		Max = 0.2,
		Default = 0.04,
		Decimal = 100,
		Function = function(value)
			if overlayBox then
				overlayBox.LineThickness = value
			end
		end
	})
	Animate = OverlayEditor:CreateToggle({
		Name = 'Animate',
		Default = true,
		Tooltip = 'Glides the overlay onto the next block instead of snapping to it'
	})
	Speed = OverlayEditor:CreateSlider({
		Name = 'Animation time',
		Min = 0.01,
		Max = 0.5,
		Default = 0.08,
		Decimal = 100,
		Suffix = 's'
	})
end)
