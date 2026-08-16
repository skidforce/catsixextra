
run(function()
	local Viewmodel
	local Depth
	local Horizontal
	local Vertical
	local Size
	local NoBob
	local Visuals
	local FillColor
	local OutlineColor
	local Rots = {}
	local Highlights = {}
	local old, oldc1
	
	local function highlightAccessory(accessory)
		local handle = accessory:FindFirstChild('Handle')
		if handle then
			local highlight = Instance.new('Highlight')
			highlight.Name = 'ViewmodelVisuals'
			highlight.FillColor = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
			highlight.FillTransparency = FillColor.Opacity
			highlight.OutlineColor = Color3.fromHSV(OutlineColor.Hue, OutlineColor.Sat, OutlineColor.Value)
			highlight.OutlineTransparency = OutlineColor.Opacity
			highlight.Parent = handle
			Viewmodel:Clean(highlight)
			table.insert(Highlights, highlight)
		end
	end
	
	local function startVisuals()
		local viewmodel
		repeat
			viewmodel = gameCamera:FindFirstChild('Viewmodel')
			if viewmodel or not Viewmodel.Enabled then break end
			task.wait(0.1)
		until false
		if not viewmodel or not Viewmodel.Enabled then return end
	
		for _, v in viewmodel:GetChildren() do
			if v:IsA('Accessory') then
				highlightAccessory(v)
			end
		end
	
		Viewmodel:Clean(viewmodel.ChildAdded:Connect(function(v)
			for i = #Highlights, 1, -1 do
				if not Highlights[i].Parent then
					table.remove(Highlights, i)
				end
			end
			if v:IsA('Accessory') then
				highlightAccessory(v)
			end
		end))
	end
	
	Viewmodel = vape.Legit:CreateModule({
		Name = 'Viewmodel',
		Function = function(callback)
			local viewmodel = gameCamera:FindFirstChild('Viewmodel')
			if callback then
				old = bedwars.ViewmodelController.playAnimation
				oldc1 = viewmodel and viewmodel.RightHand.RightWrist.C1 or CFrame.identity
				if NoBob.Enabled then
					bedwars.ViewmodelController.playAnimation = function(self, animtype, ...)
						if bedwars.AnimationType and animtype == bedwars.AnimationType.FP_WALK then return end
						return old(self, animtype, ...)
					end
				end
	
				bedwars.InventoryViewmodelController:handleStore(bedwars.Store:getState())
				if viewmodel then
					gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(Rots[1].Value), math.rad(Rots[2].Value), math.rad(Rots[3].Value))
					viewmodel:ScaleTo(Size.Value)
					Viewmodel:Clean(viewmodel.ChildAdded:Connect(function(v)
						if v:IsA('Accessory') and Size.Value ~= 1 then
							bedwars.scaleTool(v, Size.Value)
						end
					end))
				end
				Viewmodel:Clean(gameCamera.ChildAdded:Connect(function(v)
					if v.Name == 'Viewmodel' then
						Viewmodel:Toggle()
						Viewmodel:Toggle()
					end
				end))
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', -Depth.Value)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', Horizontal.Value)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', Vertical.Value)
	
				if Visuals.Enabled then
					startVisuals()
				end
			else
				bedwars.ViewmodelController.playAnimation = old
				if viewmodel then
					viewmodel:ScaleTo(1)
					viewmodel.RightHand.RightWrist.C1 = oldc1
				end
	
				bedwars.InventoryViewmodelController:handleStore(bedwars.Store:getState())
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', 0)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', 0)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', 0)
				table.clear(Highlights)
				old = nil
			end
		end,
		Tooltip = 'Changes the viewmodel animations and visuals'
	})
	Depth = Viewmodel:CreateSlider({
		Name = 'Depth',
		Min = 0,
		Max = 2,
		Default = 0.8,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', -val)
			end
		end
	})
	Horizontal = Viewmodel:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 2,
		Default = 0.8,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', val)
			end
		end
	})
	Vertical = Viewmodel:CreateSlider({
		Name = 'Vertical',
		Min = -0.2,
		Max = 2,
		Default = -0.2,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', val)
			end
		end
	})
	Size = Viewmodel:CreateSlider({
		Name = 'Size',
		Min = 0.1,
		Max = 2,
		Default = 1,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled and gameCamera:FindFirstChild('Viewmodel') then
				gameCamera.Viewmodel:ScaleTo(val)
			end
		end
	})
	for _, name in {'Rotation X', 'Rotation Y', 'Rotation Z'} do
		table.insert(Rots, Viewmodel:CreateSlider({
			Name = name,
			Min = 0,
			Max = 360,
			Function = function(val)
				if Viewmodel.Enabled then
					gameCamera.Viewmodel.RightHand.RightWrist.C1 = (oldc1 + oldc1.Position * (Size.Value - 1)) * CFrame.Angles(math.rad(Rots[1].Value), math.rad(Rots[2].Value), math.rad(Rots[3].Value))
				end
			end
		}))
	end
	NoBob = Viewmodel:CreateToggle({
		Name = 'No Bobbing',
		Default = true,
		Function = function()
			if Viewmodel.Enabled then
				Viewmodel:Toggle()
				Viewmodel:Toggle()
			end
		end
	})
	Visuals = Viewmodel:CreateToggle({
		Name = 'Visuals',
		Tooltip = 'Highlights the item held in your viewmodel',
		Function = function(callback)
			FillColor.Object.Visible = callback
			OutlineColor.Object.Visible = callback
			if Viewmodel.Enabled then
				Viewmodel:Toggle()
				Viewmodel:Toggle()
			end
		end
	})
	FillColor = Viewmodel:CreateColorSlider({
		Name = 'Fill Color',
		DefaultSat = 0,
		DefaultOpacity = 0.5,
		Darker = true,
		Visible = false,
		Function = function(hue, sat, val, opacity)
			for _, v in Highlights do
				v.FillColor = Color3.fromHSV(hue, sat, val)
				v.FillTransparency = opacity
			end
		end
	})
	OutlineColor = Viewmodel:CreateColorSlider({
		Name = 'Outline Color',
		DefaultValue = 0,
		DefaultOpacity = 0,
		Darker = true,
		Visible = false,
		Function = function(hue, sat, val, opacity)
			for _, v in Highlights do
				v.OutlineColor = Color3.fromHSV(hue, sat, val)
				v.OutlineTransparency = opacity
			end
		end
	})
end)
