
run(function()
	local NoTextures
	local Materials = {}
	local Decals = {}
	local Meshes = {}
	local reference = {}
	
	local function remember(obj, property)
		local props = reference[obj]
		if not props then
			props = {}
			reference[obj] = props
		end
	
		if props[property] == nil then
			props[property] = obj[property]
		end
	end
	
	local function stripObject(obj)
		if Decals.Enabled and obj:IsA('Decal') then
			remember(obj, 'Transparency')
			obj.Transparency = 1
			return
		end
	
		if Decals.Enabled and obj:IsA('SurfaceAppearance') then
			remember(obj, 'Parent')
			obj.Parent = nil
			return
		end
	
		if Meshes.Enabled and obj:IsA('SpecialMesh') then
			remember(obj, 'TextureId')
			obj.TextureId = ''
			return
		end
	
		if obj:IsA('BasePart') then
			if Meshes.Enabled and obj:IsA('MeshPart') then
				remember(obj, 'TextureID')
				obj.TextureID = ''
			end
	
			if Materials.Enabled then
				remember(obj, 'Material')
				obj.Material = Enum.Material.SmoothPlastic
			end
		end
	end
	
	local function restore()
		for i, v in reference do
			pcall(function()
				for property, value in v do
					i[property] = value
				end
			end)
		end
		table.clear(reference)
	end
	
	local function scan()
		local descendants = store.map:GetDescendants()
	
		for i, v in descendants do
			if not NoTextures.Enabled then return end
			stripObject(v)
	
			if i % 500 == 0 then
				task.wait()
			end
		end
	end
	
	local function refresh()
		if not NoTextures.Enabled then return end
		restore()
		scan()
	end
	
	NoTextures = vape.Categories.Render:CreateModule({
		Name = 'NoTextures',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.map or not NoTextures.Enabled
				if not NoTextures.Enabled then return end
	
				NoTextures:Clean(store.map.DescendantAdded:Connect(function(obj)
					task.defer(stripObject, obj)
				end))
				scan()
			else
				restore()
			end
		end,
		Tooltip = 'Removes textures and materials from the map'
	})
	Materials = NoTextures:CreateToggle({
		Name = 'Materials',
		Default = true,
		Function = refresh,
		Tooltip = 'Flattens every part to smooth plastic'
	})
	Decals = NoTextures:CreateToggle({
		Name = 'Decals',
		Default = true,
		Function = refresh,
		Tooltip = 'Hides decals, textures and PBR surfaces'
	})
	Meshes = NoTextures:CreateToggle({
		Name = 'Meshes',
		Default = true,
		Function = refresh,
		Tooltip = 'Clears textures off meshes'
	})
end)
