
run(function()
	local InventoryESP
	local Armor
	local Empty
	local Color = {}
	local window, headshot, nametag, grid, armorholder, armordivider
	local slots, armorslots = {}, {}
	
	local SlotCount = 24
	local SlotSize = 32
	local SlotPadding = 4
	local Columns = 6
	local HeaderHeight = 46
	
	local function createSlot(parent)
		local slot = Instance.new('Frame')
		slot.Size = UDim2.fromOffset(SlotSize, SlotSize)
		slot.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		slot.BorderSizePixel = 0
		slot.Visible = false
		slot.Parent = parent
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = slot
		local stroke = Instance.new('UIStroke')
		stroke.Color = color.Light(uipallet.Main, 0.034)
		stroke.Parent = slot
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = UDim2.fromOffset(SlotSize - 8, SlotSize - 8)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Parent = slot
		local amount = Instance.new('TextLabel')
		amount.Name = 'Amount'
		amount.Size = UDim2.fromOffset(SlotSize - 4, 11)
		amount.Position = UDim2.fromOffset(0, SlotSize - 13)
		amount.BackgroundTransparency = 1
		amount.Text = ''
		amount.TextXAlignment = Enum.TextXAlignment.Right
		amount.TextSize = 11
		amount.TextColor3 = uipallet.Text
		amount.TextStrokeColor3 = Color3.new()
		amount.TextStrokeTransparency = 0.4
		amount.FontFace = uipallet.Font
		amount.Parent = slot
		return slot
	end
	
	local function buildWindow()
		window = Instance.new('Frame')
		window.Name = 'InventoryESP'
		window.Size = UDim2.fromOffset(240, HeaderHeight)
		window.Position = UDim2.fromOffset(12, 260)
		window.BackgroundColor3 = uipallet.Main
		window.BackgroundTransparency = 1 - (Color.Opacity or 0.5)
		window.Visible = false
		window.Parent = vape.gui.ScaledGui
		addBlur(window)
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = window
	
		headshot = Instance.new('ImageLabel')
		headshot.Name = 'Headshot'
		headshot.Size = UDim2.fromOffset(26, 26)
		headshot.Position = UDim2.fromOffset(14, 11)
		headshot.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		headshot.Image = ''
		headshot.Parent = window
		local headcorner = Instance.new('UICorner')
		headcorner.CornerRadius = UDim.new(0, 4)
		headcorner.Parent = headshot
	
		nametag = Instance.new('TextLabel')
		nametag.Name = 'Name'
		nametag.Size = UDim2.new(1, -60, 0, 26)
		nametag.Position = UDim2.fromOffset(48, 11)
		nametag.BackgroundTransparency = 1
		nametag.Text = ''
		nametag.TextXAlignment = Enum.TextXAlignment.Left
		nametag.TextSize = 13
		nametag.TextColor3 = uipallet.Text
		nametag.TextTruncate = Enum.TextTruncate.AtEnd
		nametag.FontFace = uipallet.Font
		nametag.Parent = window
	
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.fromOffset(0, HeaderHeight - 1)
		divider.BackgroundColor3 = color.Light(uipallet.Main, 0.04)
		divider.BorderSizePixel = 0
		divider.Parent = window
	
		grid = Instance.new('Frame')
		grid.Name = 'Items'
		grid.Size = UDim2.new(1, -28, 0, 0)
		grid.Position = UDim2.fromOffset(14, HeaderHeight + 10)
		grid.BackgroundTransparency = 1
		grid.Parent = window
		local layout = Instance.new('UIGridLayout')
		layout.CellSize = UDim2.fromOffset(SlotSize, SlotSize)
		layout.CellPadding = UDim2.fromOffset(SlotPadding, SlotPadding)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = grid
	
		for i = 1, SlotCount do
			local slot = createSlot(grid)
			slot.LayoutOrder = i
			slots[i] = slot
		end
	
		armordivider = Instance.new('Frame')
		armordivider.Name = 'ArmorDivider'
		armordivider.Size = UDim2.new(1, 0, 0, 1)
		armordivider.BackgroundColor3 = color.Light(uipallet.Main, 0.04)
		armordivider.BorderSizePixel = 0
		armordivider.Parent = window
	
		armorholder = Instance.new('Frame')
		armorholder.Name = 'Armor'
		armorholder.Size = UDim2.fromOffset(240, SlotSize)
		armorholder.BackgroundTransparency = 1
		armorholder.Parent = window
		local armorlayout = Instance.new('UIListLayout')
		armorlayout.FillDirection = Enum.FillDirection.Horizontal
		armorlayout.Padding = UDim.new(0, SlotPadding)
		armorlayout.Parent = armorholder
	
		for i = 1, 4 do
			local slot = createSlot(armorholder)
			slot.LayoutOrder = i
			armorslots[i] = slot
		end
	end
	
	local function setSlot(slot, item, highlight)
		if not item or not item.itemType then
			slot.Visible = false
			return
		end
	
		slot.Visible = true
		slot.Icon.Image = bedwars.getIcon(item, true)
		slot.Amount.Text = (item.amount or 1) > 1 and tostring(item.amount) or ''
		slot.UIStroke.Color = highlight and Color3.fromHSV(Color.Hue, Color.Sat, Color.Value) or color.Light(uipallet.Main, 0.034)
	end
	
	local function getTarget()
		local best, highest = nil, tick()
		for ent, expiry in targetinfo.Targets do
			if expiry < tick() then
				targetinfo.Targets[ent] = nil
				continue
			end
			if expiry > highest then
				best, highest = ent, expiry
			end
		end
		return best
	end
	
	local function refresh()
		local ent = getTarget()
		local player = ent and ent.Player or nil
		local inventory = player and store.inventories[player] or nil
	
		if not ent or (not inventory and not Empty.Enabled) then
			window.Visible = false
			return
		end
	
		window.Visible = true
		nametag.Text = player and player.DisplayName or (ent.Character and ent.Character.Name) or ''
		headshot.Image = 'rbxthumb://type=AvatarHeadShot&id='..(player and player.UserId or 1)..'&w=420&h=420'
	
		inventory = inventory or {items = {}, armor = {}}
		local hand = inventory.hand
		local shown = 0
	
		for i, slot in slots do
			local item = inventory.items[i]
			setSlot(slot, item, item and hand and item.tool == hand.tool)
			if slot.Visible then
				shown = i
			end
		end
	
		local rows = math.max(math.ceil(shown / Columns), 1)
		local gridheight = (rows * SlotSize) + ((rows - 1) * SlotPadding)
		grid.Size = UDim2.new(1, -28, 0, gridheight)
	
		local height = HeaderHeight + 10 + gridheight + 10
		if Armor.Enabled then
			armordivider.Visible = true
			armorholder.Visible = true
			armordivider.Position = UDim2.fromOffset(0, height - 1)
	
			local armorcount = 0
			for i = 1, 3 do
				local item = inventory.armor[i + 3]
				setSlot(armorslots[i], item)
				if armorslots[i].Visible then
					armorcount += 1
				end
			end
			setSlot(armorslots[4], hand, true)
	
			armorholder.Position = UDim2.fromOffset(14, height + 9)
			height += SlotSize + 19
		else
			armordivider.Visible = false
			armorholder.Visible = false
		end
	
		window.Size = UDim2.fromOffset(240, height)
	end
	
	InventoryESP = vape.Categories.Render:CreateModule({
		Name = 'InventoryESP',
		Function = function(callback)
			if callback then
				if not window then
					buildWindow()
				end
	
				repeat
	
					refresh()
					task.wait(0.1)
				until not InventoryESP.Enabled
	
				window.Visible = false
			elseif window then
				window.Visible = false
			end
		end,
		Tooltip = 'Shows the inventory of whoever you are currently targeting'
	})
	Armor = InventoryESP:CreateToggle({
		Name = 'Show armor',
		Function = function()
			if InventoryESP.Enabled then
				refresh()
			end
		end,
		Default = true
	})
	Empty = InventoryESP:CreateToggle({
		Name = 'Show without data',
		Tooltip = 'Keeps the panel up when the server has not shared their inventory yet'
	})
	Color = InventoryESP:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			if window then
				window.BackgroundColor3 = uipallet.Main
				window.BackgroundTransparency = 1 - opacity
			end
		end
	})
end)
