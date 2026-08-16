
run(function()
	local ItemESP
	local Distance
	local Transparency
	local Scale
	local WhitelistOnly
	local Whitelist = {}
	
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local Reference, Strings, Sizes = {}, {}, {}
	local function Added(ent)
		local Name = bedwars.ItemMeta[ent.Name] and bedwars.ItemMeta[ent.Name].displayName or ent.Name
		if WhitelistOnly.Enabled and not table.find(Whitelist.ListEnabled, Name:lower()) then
			return
		end
	
		Strings[ent] = Name .. '%s'
		if Distance.Enabled then
			Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '.. Strings[ent]
		end
	
		local nametag = Instance.new('TextLabel')
		nametag.TextSize = 14 * Scale.Value
		nametag.Font = Enum.Font.Arial
		local size = getfontsize(removeTags(ent.Name), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
		nametag.Name = ent.Name
		nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
		nametag.AnchorPoint = Vector2.new(0.5, 1)
		nametag.BackgroundColor3 = Color3.new()
		nametag.BackgroundTransparency = 0.5
		nametag.BorderSizePixel = 0
		nametag.Visible = false
		nametag.Text = string.format(Strings[ent], '', ent:GetAttribute('Amount') >= 2 and ' x' .. tostring(ent:GetAttribute('Amount')) or '')
		nametag.TextColor3 = Color3.new(1, 1, 1)
		nametag.RichText = true
		nametag.Parent = Folder
		Reference[ent] = nametag
	end
	local function Updated(ent)
		if Reference[ent] then
			Reference[ent].TextSize = 14 * Scale.Value
			Reference[ent].BackgroundTransparency = Transparency.Value
		end
	end
	local function Removing(ent)
		if Reference[ent] then
			Reference[ent]:Destroy()
			Reference[ent] = nil
		end
	end
	
	ItemESP = vape.Categories.Render:CreateModule({
		Name = 'ItemESP',
		Function = function(call)
			if call then
				ItemESP:Clean(collectionService:GetInstanceAddedSignal('ItemDrop'):Connect(Added))
				ItemESP:Clean(collectionService:GetInstanceRemovedSignal('ItemDrop'):Connect(Removing))
				ItemESP:Clean(runService.PreRender:Connect(function()
					for ent, nametag in Reference do
						local headPos, headVis = gameCamera:WorldToViewportPoint(ent.Position + Vector3.new(0, 1, 0))
						nametag.Visible = headVis
						if not headVis then
							continue
						end
	
						if ent.Position.Y > -200 then
							if Distance.Enabled then
								local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.Position).Magnitude) or 0
								if Sizes[ent] ~= mag then
									nametag.Text = string.format(Strings[ent], mag, ent:GetAttribute('Amount') >= 2 and ' x' .. tostring(ent:GetAttribute('Amount')) or '')
									local size = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
									nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
									Sizes[ent] = mag
								end
							else
								nametag.Text = string.format(Strings[ent], '')
								local size = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
								nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
							end
							nametag.Position = UDim2.fromOffset(headPos.X, headPos.Y)
						else
							nametag.Visible = false
						end
					end
				end))
	
				for _, v in collectionService:GetTagged('ItemDrop') do
					Added(v)
				end
			else
				for i in Reference do
					Removing(i)
				end
			end
		end,
		Tooltip = 'Renders tags dropped items'
	})
	Distance = ItemESP:CreateToggle({
		Name = 'Distance',
		Function = function(callback)
			if ItemESP.Enabled then
				for ent in Reference do
					local Name = bedwars.ItemMeta[ent.Name] and bedwars.ItemMeta[ent.Name].displayName or ent.Name
					Strings[ent] = callback and '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '.. Strings[ent] or Name.. '%s'
				end
			end
		end,
		Tooltip = 'Shows the distance of the item'
	})
	Transparency = ItemESP:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Function = function()
			if ItemESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end,
		Default = 0.5
	})
	Scale = ItemESP:CreateSlider({
		Name = 'Scale',
		Default = 1,
		Min = 0.1,
		Max = 1.5,
		Decimal = 10,
		Function = function()
			if ItemESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end
	})
	WhitelistOnly = ItemESP:CreateToggle({
		Name = 'Whitelist Only',
		Function = function(callback)
			if Whitelist.Object then
				Whitelist.Object.Visible = callback
			end
			if ItemESP.Enabled then
				ItemESP:Toggle()
				ItemESP:Toggle()
			end
		end,
		Tooltip = 'Only renders whitelisted items'
	})
	Whitelist = ItemESP:CreateTextList({
		Name = 'Allowed items',
		Function = function()
			if ItemESP.Enabled then
				ItemESP:Toggle()
				ItemESP:Toggle()
			end
		end,
		Darker = true,
		Visible = false
	})
end)
