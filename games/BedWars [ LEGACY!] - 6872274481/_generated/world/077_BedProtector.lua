
run(function()
	local BedProtector
	local PlaceRange
	local Blacklist
	local Wool
	local Mode
	local Smart
	local Switch
	
	local function getBedNear()
		local localPosition = entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero
		for _, v in collectionService:GetTagged('bed') do
			if (localPosition - v.Position).Magnitude < 14 and v:GetAttribute('Team' .. (lplr:GetAttribute('Team') or -1) .. 'NoBreak') then
				return v
			end
		end
		return nil
	end
	
	local function getBlocks()
		local blocks = {}
		for _, item in store.inventory.inventory.items do
			local block = bedwars.ItemMeta[item.itemType].block
			if block and (Wool.Enabled and item.itemType:find('wool') or not Wool.Enabled and not table.find(Blacklist.ListEnabled, item.itemType:find('wool') and 'wool' or item.itemType)) then
				table.insert(blocks, {item.itemType, block.health, item.tool})
			end
		end
		if #blocks > 1 then
			table.sort(blocks, function(a, b)
				return a[2] > b[2]
			end)
		end
		return blocks
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
	
	BedProtector = vape.Categories.World:CreateModule({
		Name = 'BedProtector',
		Function = function(callback)
			if callback then
				repeat
					local bed = getBedNear()
					if bed then
						for i, block in getBlocks() do
							local switch, old = Switch.Enabled, store.hand and store.hand.tool and getHotbar(store.hand.tool) or nil
							local hotbar = nil
	
							if switch then
								hotbar = getHotbar(block[3])
							end
	
							for _, pos in getPyramid(i, 3) do
								if not BedProtector.Enabled then
									break
								end
								pos = (bed.CFrame * CFrame.new(pos)).Position
								if getPlacedBlock(pos) then
									continue
								end
								if (entitylib.character.RootPart.Position - pos).Magnitude > PlaceRange.Value then
									continue
								end
								if hotbar and hotbarSwitch(hotbar) then
									task.wait()
								end
								task.spawn(bedwars.placeBlock, pos, block[1], false)
								task.wait(0.1)
							end
	
							if switch and old and hotbarSwitch(old) then
								task.wait()
							end
						end
					else
						if Mode.Value == 'On Key' then
							notif('BedProtector', 'Unable to locate bed', 5)
							BedProtector:Toggle()
						end
					end
					task.wait(0.5)
					if Mode.Value == 'On Key' then
						BedProtector:Toggle()
						break
					end
				until not BedProtector.Enabled
			end
		end,
		Tooltip = 'Automatically places strong blocks around the bed.'
	})
	Mode = BedProtector:CreateDropdown({
		Name = 'Mode',
		List = {'Toggle', 'On Key'},
		Default = 'Toggle',
		Function = function(val)
			if Smart then
				Smart.Object.Visible = val == 'Toggle'
			end
		end
	})
	Blacklist = BedProtector:CreateTextList({
		Name = 'Blacklist',
		Default = {'siege_tnt', 'tnt'}
	})
	PlaceRange = BedProtector:CreateSlider({
		Name = 'Place Range',
		Min = 1,
		Max = 30,
		Default = 15
	})
	Wool = BedProtector:CreateToggle({Name = 'Wool only', Tooltip = 'Only uses wools to bed defend.'})
	Switch = BedProtector:CreateToggle({Name = 'Auto Switch'})
	Smart = BedProtector:CreateToggle({Name = 'Smart', Default = true})
end)
