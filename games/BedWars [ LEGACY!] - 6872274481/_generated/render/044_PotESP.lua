
run(function()
	local PotESP
	local Background
	local Color = {}
	
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local Reference = {}
	local Template
	
	local function getTemplate()
		if Template then return Template end
	
		local assets = replicatedStorage:FindFirstChild('Assets')
		local blocks = assets and assets:FindFirstChild('Blocks')
		local model = blocks and blocks:FindFirstChild('desert_pot')
		Template = model and model:FindFirstChildWhichIsA('MeshPart', true)
	
		return Template
	end
	
	local function Added(block)
		if block.Name ~= 'desert_pot' or Reference[block] then return end
	
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = block.Name
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = block
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local viewport = Instance.new('ViewportFrame')
		viewport.Size = UDim2.fromOffset(36, 36)
		viewport.Position = UDim2.fromScale(0.5, 0.5)
		viewport.AnchorPoint = Vector2.new(0.5, 0.5)
		viewport.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		viewport.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		viewport.BorderSizePixel = 0
		viewport.Ambient = Color3.new(1, 1, 1)
		viewport.LightColor = Color3.new(1, 1, 1)
		viewport.Parent = billboard
		local uicorner = Instance.new('UICorner')
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = viewport
	
		local mesh = getTemplate()
		if mesh then
			mesh = mesh:Clone()
			mesh.CFrame = CFrame.Angles(0, math.rad(25), 0)
			mesh.Parent = viewport
			local camera = Instance.new('Camera')
			camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.75, 3.9), Vector3.new(0, 0.05, 0))
			camera.Parent = viewport
			viewport.CurrentCamera = camera
		end
	
		Reference[block] = billboard
	end
	
	local function Removing(block)
		if Reference[block] then
			Reference[block]:Destroy()
			Reference[block] = nil
		end
	end
	
	PotESP = vape.Categories.Render:CreateModule({
		Name = 'PotESP',
		Function = function(callback)
			if callback then
				for _, v in collectionService:GetTagged('block') do
					Added(v)
				end
				PotESP:Clean(collectionService:GetInstanceAddedSignal('block'):Connect(Added))
				PotESP:Clean(collectionService:GetInstanceRemovedSignal('block'):Connect(Removing))
			else
				for i in Reference do
					Removing(i)
				end
			end
		end,
		Tooltip = 'Renders an icon over desert pots'
	})
	Background = PotESP:CreateToggle({
		Name = 'Background',
		Function = function(callback)
			if Color.Object then Color.Object.Visible = callback end
			for _, v in Reference do
				v.ViewportFrame.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end,
		Default = true
	})
	Color = PotESP:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.ViewportFrame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.ViewportFrame.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
end)
