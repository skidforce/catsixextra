
run(function()
	local SkinChanger
	local Options = {}
	local skins, families, groups, order = {}, {}, {}, {}
	local added = setmetatable({}, {__mode = 'k'})
	local watching
	local tiers = {leather = true, chainmail = true, wood = true, stone = true, gold = true, iron = true, diamond = true, emerald = true}
	
	local function prettify(text)
		return (text:gsub('_', ' '):gsub('%a+', function(word)
			return `{word:sub(1, 1):upper()}{word:sub(2)}`
		end))
	end
	
	local function getLabel(itemType, skin)
		local label = `_{skin}_`
		for word in itemType:gmatch('[^_]+') do
			label = label:gsub(`_{word}_`, '_')
		end
		label = label:gsub('^_+', ''):gsub('_+$', '')
		return label ~= '' and prettify(label) or prettify(skin)
	end
	
	local function getFamily(itemType)
		local family = itemType:gsub('_%d+$', '')
		local tier, base = family:match('^([^_]+)_(.+)$')
		return tier and tiers[tier] and base or family
	end
	
	local function getName(family)
		local members = groups[family]
		return prettify(#members > 1 and family or members[1])
	end
	
	for _, skin in bedwars.ItemSkinType do
		local meta = bedwars.getItemSkinMeta(skin)
		local item = meta and meta.itemType and bedwars.ItemMeta[meta.itemType]
		if item and not item.block then
			skins[meta.itemType] = skins[meta.itemType] or {}
			skins[meta.itemType][getLabel(meta.itemType, skin)] = skin
		end
	end
	
	for itemType in skins do
		local family = getFamily(itemType)
		if not groups[family] then
			groups[family] = {}
			table.insert(order, family)
		end
		families[itemType] = family
		table.insert(groups[family], itemType)
	end
	
	table.sort(order, function(a, b)
		return getName(a) < getName(b)
	end)
	
	local function getSkin(itemType)
		local family = SkinChanger.Enabled and families[itemType]
		local option = family and Options[family]
		return option and skins[itemType][option.Value] or nil
	end
	
	local function applyModel(accessory)
		local handle = accessory:FindFirstChild('Handle')
		local template = replicatedStorage.Items:FindFirstChild(getSkin(accessory.Name) or '')
		if not handle or not template or added[accessory] then return end
	
		local grip = handle:FindFirstChild('RightGripAttachment')
		local templategrip = template.Handle:FindFirstChild('RightGripAttachment')
		local record = {
			Parts = {},
			Size = handle.Size,
			Grip = grip and grip.CFrame or nil
		}
		added[accessory] = record
	
		handle:ApplyMesh(template.Handle)
		handle.Size = template.Handle.Size
		if grip and templategrip then
			grip.CFrame = templategrip.CFrame
		end
	
		for _, v in template.Handle:GetChildren() do
			if v:IsA('BasePart') then
				local part = v:Clone()
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.Massless = true
				part.CFrame = handle.CFrame * (template.Handle.CFrame:Inverse() * v.CFrame)
				part.Parent = handle
	
				local weld = Instance.new('WeldConstraint')
				weld.Part0 = handle
				weld.Part1 = part
				weld.Parent = part
				table.insert(record.Parts, part)
			end
		end
	end
	
	local function restoreModel(accessory)
		local handle = accessory:FindFirstChild('Handle')
		local template = replicatedStorage.Items:FindFirstChild(accessory.Name)
		local record = added[accessory]
		if not record then return end
	
		for _, v in record.Parts do
			v:Destroy()
		end
		added[accessory] = nil
	
		if handle then
			if template then
				handle:ApplyMesh(template.Handle)
			end
			handle.Size = record.Size
	
			local grip = handle:FindFirstChild('RightGripAttachment')
			if grip and record.Grip then
				grip.CFrame = record.Grip
			end
		end
	end
	
	local function applySkins()
		local inventory = store.inventory.inventory
		for _, item in inventory.items do
			item.itemSkin = getSkin(item.itemType)
		end
		if inventory.hand then
			inventory.hand.itemSkin = getSkin(inventory.hand.itemType)
		end
		bedwars.InventoryViewmodelController:handleStore(bedwars.Store:getState())
	
		if lplr.Character then
			for _, v in lplr.Character:GetChildren() do
				if v:IsA('Accessory') then
					restoreModel(v)
					applyModel(v)
				end
			end
		end
	end
	
	local function watchCharacter(char)
		if watching then
			watching:Disconnect()
		end
	
		watching = char.ChildAdded:Connect(function(v)
			if v:IsA('Accessory') and v:WaitForChild('Handle', 3) and SkinChanger.Enabled then
				applyModel(v)
			end
		end)
	end
	
	SkinChanger = vape.Categories.Render:CreateModule({
		Name = 'SkinChanger',
		Function = function(callback)
			if callback then
				SkinChanger:Clean(vapeEvents.InventoryChanged.Event:Connect(applySkins))
				SkinChanger:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(applySkins))
				SkinChanger:Clean(lplr.CharacterAdded:Connect(function(char)
					watchCharacter(char)
					task.spawn(function()
						for _ = 1, 10 do
							task.wait(0.4)
							if not SkinChanger.Enabled then return end
							applySkins()
						end
					end)
				end))
	
				if lplr.Character then
					watchCharacter(lplr.Character)
				end
			elseif watching then
				watching:Disconnect()
				watching = nil
			end
			applySkins()
		end,
		Tooltip = 'Reskins the items you hold with their sounds, only you can see it'
	})
	for _, family in order do
		local list, seen = {}, {}
		for _, itemType in groups[family] do
			for label in skins[itemType] do
				if not seen[label] then
					seen[label] = true
					table.insert(list, label)
				end
			end
		end
		table.sort(list)
		table.insert(list, 1, 'None')
	
		Options[family] = SkinChanger:CreateDropdown({
			Name = getName(family),
			List = list,
			Function = function()
				if SkinChanger.Enabled then
					applySkins()
				end
			end
		})
	end
end)
