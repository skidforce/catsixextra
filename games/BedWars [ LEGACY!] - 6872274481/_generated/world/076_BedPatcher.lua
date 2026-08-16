
run(function()
	local BedPatcher
	local PlaceRange
	local Whitelist
	local Mode
	local Switch
	local Limit
	
	local function getBedNear()
		local localPosition = entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero
		for _, v in collectionService:GetTagged('bed') do
			if (localPosition - v.Position).Magnitude < 14 and v:GetAttribute('Team' .. (lplr:GetAttribute('Team') or -1) .. 'NoBreak') then
				return v
			end
		end
		return nil
	end
	
	local function getBlock()
		if Limit.Enabled and store.hand.toolType == 'block' and table.find(Whitelist.ListEnabled, store.hand.tool.Name:find('wool') and 'wool' or store.hand.tool.Name) then
			return {store.hand.tool.Name}
		end
		local blocks = {}
		for _, item in store.inventory.inventory.items do
			local block = bedwars.ItemMeta[item.itemType].block
			if block and table.find(Whitelist.ListEnabled, item.itemType:find('wool') and 'wool' or item.itemType) then
				table.insert(blocks, {item.itemType, block.health, item.tool})
			end
		end
		if #blocks > 1 then
			table.sort(blocks, function(a, b)
				return a[2] > b[2]
			end)
		end
		return blocks[1] or {}
	end
	
	local function getPyramid(size, grid)
		local positions = {}
		for h = size, 0, -1 do
			for w = h, 0, -1 do
				table.insert(positions, Vector3.new(w, (size - h), ((h + 1) - w)) * grid)
				table.insert(positions, Vector3.new(w * -1, (size - h), ((h + 1) - w)) * grid)
				table.insert(positions, Vector3.new(w, (size - h), (h - w) * -1) * grid)
				table.insert(positions, Vector3.new(w * -1, (size - h), (h - w) * -1) * grid)
			end
		end
		return positions
	end
	
	BedPatcher = vape.Categories.World:CreateModule({
		Name = 'BedPatcher',
		Function = function(callback)
			if callback then
				repeat
					local bed = getBedNear()
					if bed then
						for i = 0, 6 do
							local y = Vector3.yAxis * (3 * i)
							if getPlacedBlock(bed.Position + y) or getPlacedBlock(((bed.CFrame + y) * CFrame.new(0, 0, 3)).Position) then
								for _, pos in getPyramid(i, 3) do
									local itemType, _, tool = unpack(getBlock())
									if not itemType then
										break
									end
									pos = (bed.CFrame * CFrame.new(pos)).Position
									if getPlacedBlock(pos) or (entitylib.character.RootPart.Position - pos).Magnitude > PlaceRange.Value then
										continue
									end
									if Switch.Enabled and getHotbar(tool) and hotbarSwitch(getHotbar(tool)) then
										task.wait()
									end
									task.spawn(bedwars.placeBlock, pos, itemType, false)
									task.wait(0.1)
								end
							end
						end
					else
						if Mode.Value == 'On Key' then
							notif('BedPatcher', 'Unable to locate bed', 5)
							BedPatcher:Toggle()
						end
					end
					task.wait(0.5)
					if Mode.Value == 'On Key' then
						BedPatcher:Toggle()
						break
					end
				until not BedPatcher.Enabled
			end
		end,
		Tooltip = 'Automatically replaces missing blocks near bed.'
	})
	Mode = BedPatcher:CreateDropdown({
		Name = 'Mode',
		List = {'Toggle', 'On Key'},
		Default = 'Toggle'
	})
	Whitelist = BedPatcher:CreateTextList({
		Name = 'Whitelist',
		Default = {'wool', 'obsidian'}
	})
	PlaceRange = BedPatcher:CreateSlider({
		Name = 'Place Range',
		Min = 1,
		Max = 60,
		Default = 15
	})
	Wool = BedPatcher:CreateToggle({Name = 'Wool only', Tooltip = 'Only uses wools to patch.'})
	Switch = BedPatcher:CreateToggle({Name = 'Auto Switch'})
	Limit = BedPatcher:CreateToggle({Name = 'Limit to item'})
end)
