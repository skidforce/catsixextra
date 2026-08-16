
run(function()
	local CropESP
	local Color
	local Transparency
	local Scale
	
	local Folder = Instance.new('Folder')
	if vape.ThreadFix then
		setthreadidentity(8)
	end
	Folder.Parent = vape.gui
	
	local Reference = {}
	
	local function Added(ent)
		local nametag = Instance.new('TextLabel')
		nametag.TextSize = 14 * Scale.Value
		nametag.Font = Enum.Font.Arial
		nametag.Text = bedwars.ItemMeta[ent.Name] and bedwars.ItemMeta[ent.Name].displayName or 'Crop'
		local size = getfontsize(nametag.Text, nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
		nametag.Name = ent.Name
		nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
		nametag.AnchorPoint = Vector2.new(0.5, 1)
		nametag.BackgroundColor3 = Color3.new()
		nametag.BackgroundTransparency = Transparency.Value
		nametag.BorderSizePixel = 0
		nametag.Visible = false
		nametag.TextColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		nametag.RichText = true
		nametag.Parent = Folder
		Reference[ent] = nametag
	end
	
	local function Updated(ent)
		if Reference[ent] then
			Reference[ent].TextSize = 14 * Scale.Value
			Reference[ent].TextColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			Reference[ent].BackgroundTransparency = Transparency.Value
		end
	end
	
	local function Removing(ent)
		if Reference[ent] then
			Reference[ent]:Destroy()
			Reference[ent] = nil
		end
	end
	
	CropESP = vape.Categories.Render:CreateModule({
		Name = 'CropESP',
		Function = function(callback)
			if callback then
				for _, v in collectionService:GetTagged('HarvestableCrop') do
					Added(v)
				end
				CropESP:Clean(collectionService:GetInstanceAddedSignal('HarvestableCrop'):Connect(Added))
				CropESP:Clean(collectionService:GetInstanceRemovedSignal('HarvestableCrop'):Connect(Removing))
				CropESP:Clean(runService.PreRender:Connect(function()
					for ent, nametag in Reference do
						if not ent.Parent then
							Removing(ent)
							continue
						end
	
						local screenPos, visible = gameCamera:WorldToViewportPoint(ent:IsA('Model') and ent:GetPivot().Position + Vector3.new(0, 1, 0) or ent.Position + Vector3.new(0, 1, 0))
						nametag.Visible = visible
						if visible then
							nametag.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
						end
					end
				end))
			else
				for i in Reference do
					Removing(i)
				end
			end
		end,
		Tooltip = 'Renders crops that are ready to harvest'
	})
	Color = CropESP:CreateColorSlider({
		Name = 'Text Color',
		Function = function()
			if CropESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end
	})
	Transparency = CropESP:CreateSlider({
		Name = 'Transparency',
		Function = function()
			if CropESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end,
		Default = 0.5,
		Min = 0,
		Max = 1,
		Decimal = 100
	})
	Scale = CropESP:CreateSlider({
		Name = 'Scale',
		Function = function()
			if CropESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end,
		Min = 0.1,
		Max = 1.5,
		Decimal = 10,
		Default = 1
	})
end)
