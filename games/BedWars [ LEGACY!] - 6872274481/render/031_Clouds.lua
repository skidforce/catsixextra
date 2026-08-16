
run(function()
	local Clouds
	local Scale
	local CloudColor
	local folder, folderConnection
	local reference = setmetatable({}, {__mode = 'k'})
	
	local function remember(part)
		if not reference[part] then
			reference[part] = {part.Size, part.Color, part.Transparency}
		end
		return reference[part]
	end
	
	local applyPart = function(part)
		if not Clouds.Enabled or not part:IsA('BasePart') then return end
		local original = remember(part)
		part.Size = original[1] * (Scale.Value / 100)
		part.Color = Color3.fromHSV(CloudColor.Hue, CloudColor.Sat, CloudColor.Value)
		part.Transparency = 1 - CloudColor.Opacity
	end
	
	local function restore()
		for part, original in reference do
			if part.Parent then
				part.Size = original[1]
				part.Color = original[2]
				part.Transparency = original[3]
			end
		end
		table.clear(reference)
	end
	
	local function applyAll()
		if not Clouds.Enabled or not folder then return end
		for _, part in folder:GetChildren() do
			applyPart(part)
		end
	end
	
	local function bindFolder(new)
		if folderConnection then
			folderConnection:Disconnect()
			folderConnection = nil
		end
	
		folder = new
		if not folder then return end
	
		folderConnection = folder.ChildAdded:Connect(function(part)
			task.defer(applyPart, part)
		end)
		applyAll()
	end
	
	Clouds = vape.Categories.Render:CreateModule({
		Name = 'Clouds',
		Function = function(callback)
			if callback then
				Clouds:Clean(workspace.ChildAdded:Connect(function(child)
					if child.Name == 'Clouds' then
						bindFolder(child)
					end
				end))
				bindFolder(workspace:FindFirstChild('Clouds'))
			else
				bindFolder(nil)
				restore()
			end
		end,
		Tooltip = 'Restyles the clouds around the map'
	})
	Scale = Clouds:CreateSlider({
		Name = 'Size',
		Min = 5,
		Max = 300,
		Default = 100,
		Function = applyAll,
		Suffix = function()
			return '%'
		end
	})
	CloudColor = Clouds:CreateColorSlider({
		Name = 'Color',
		DefaultSat = 0,
		Darker = true,
		Function = applyAll
	})
end)
