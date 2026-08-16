
run(function()
	local KitDisplay
	
	local function waitForChild(start, ...)
		local parent = start
		for _, v in {...} do
			local deadline = tick() + 10
			local child
			repeat
				child = parent and parent:FindFirstChild(v)
				if not child then task.wait(0.1) end
			until child or not KitDisplay.Enabled or tick() >= deadline
			parent = child
			if not parent then
				break
			end
		end
		return parent
	end
	
	local function getPlayerDraft(name) 
		for _, v in playersService:GetPlayers() do
			if name and (v.Name == name or v.DisplayName == name or v:GetAttribute('DisguiseDisplayName') == name) then
				return v
			end
	
			local displayName = bedwars.StreamerModeController and bedwars.StreamerModeController:getDisplayName(v)
			if name and displayName == name then
				return v
			end
		end
		return nil
	end
	
	local function tweenKit(roact, image)
		roact.Image = image
		roact.Position = UDim2.fromScale(1.05, 0)
		tweenService:Create(roact, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(1.05, 0.5)
		}):Play()
	end
	
	local function renderKit(v)
		task.wait(0.3)
		if not KitDisplay.Enabled or not v.Parent then return end
		local name = v:FindFirstChild('PlayerName', true)
		if name then
			local player = getPlayerDraft(name.Text)
			if player then
				local frame = v:FindFirstChild('1')
				local card = frame and frame:FindFirstChild('MatchDraftPlayerCard')
				if not card then return end
				local roact, image = card:FindFirstChild('KitImage'), bedwars.BedwarsKitMeta[player:GetAttribute('PlayingAsKits')] or bedwars.BedwarsKitMeta.none
				if not roact then
					roact = Instance.new('ImageLabel')
					roact.BackgroundTransparency = 1
					roact.AnchorPoint = Vector2.new(1, 0.5)
					roact.Position = UDim2.fromScale(1.05, 0)
					roact.Name = 'KitImage'
					roact.Size = UDim2.fromScale(1.5, 1.5)
					roact.ZIndex = 1
					roact.ImageTransparency = 0.4
					roact.SliceCenter = Rect.new(0, 0, 0, 0)
					roact.SliceScale = 1
					roact.ScaleType = Enum.ScaleType.Crop
					roact.Parent = card
	
					KitDisplay:Clean(roact)
	
					local ratio = Instance.new('UIAspectRatioConstraint', roact)
					ratio.Name = '1'
					ratio.AspectRatio = 1
					ratio.AspectType = Enum.AspectType.FitWithinMaxSize
					ratio.DominantAxis = Enum.DominantAxis.Width
				end
	
				tweenKit(roact, image.renderImage)
	
				local connection = player:GetAttributeChangedSignal('PlayingAsKits'):Connect(function()
					if not KitDisplay.Enabled or not roact.Parent then return end
					image = bedwars.BedwarsKitMeta[player:GetAttribute('PlayingAsKits')] or bedwars.BedwarsKitMeta.none
					tweenKit(roact, image.renderImage)
				end)
				KitDisplay:Clean(name:GetPropertyChangedSignal('Text'):Once(function()
					if connection then
						connection:Disconnect()
						connection = nil
					end
					renderKit(v)
				end))
				KitDisplay:Clean(connection)
			end
		end
	end
	
	KitDisplay = vape.Categories.Render:CreateModule({
		Name = 'KitDisplay',
		Function = function(callback)
			if callback then
				local bodyContainer
				repeat
					local app = lplr.PlayerGui:FindFirstChild('MatchDraftApp')
					local background = app and app:FindFirstChild('DraftAppBackground')
					local frame = background and background:FindFirstChild('1')
					bodyContainer = frame and frame:FindFirstChild('BodyContainer')
					if not bodyContainer then task.wait(0.1) end
				until bodyContainer or not KitDisplay.Enabled
				if not KitDisplay.Enabled then return end
				if bodyContainer then
					for i = 1, 2 do
						local column = waitForChild(bodyContainer, 'Team' .. i .. 'Column')
						if column then
							KitDisplay:Clean(column.ChildAdded:Connect(renderKit))
							for _, v in column:GetChildren() do
								task.spawn(renderKit, v)
							end
						end
					end
				end
			end
		end,
		Tooltip = 'Allows you to view opponent\'s kit in match draft.'
	})
end)
