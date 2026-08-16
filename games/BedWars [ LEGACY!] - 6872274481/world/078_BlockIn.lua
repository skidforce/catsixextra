
run(function()
	local BlockIn
	local Mode
	local Priority
	local Return
	local Switch
	local Wool
	local Blacklist
	
	local scan = 30
	local dirs = {
		Vector3.new(1, 0, 0),
		Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, 1),
		Vector3.new(0, 0, -1)
	}
	local priorities = {
		['Lowest cost'] = function(a, b)
			return a[2] < b[2]
		end,
		['Hardest'] = function(a, b)
			return a[2] > b[2]
		end
	}
	
	local function round(p)
		return Vector3.new(
			math.floor(p.X / 3 + 0.5) * 3,
			math.floor(p.Y / 3 + 0.5) * 3,
			math.floor(p.Z / 3 + 0.5) * 3
		)
	end
	
	local function getOrigin()
		local pos = entitylib.character.RootPart.Position
		local ray = entitylib.Raycast(pos, Vector3.new(0, -scan, 0), store.airRay)
		return roundPos(ray and Vector3.new(pos.X, ray.Position.Y + 1.5, pos.Z) or pos)
	end
	
	local function isDefended(bed)
		local handler = bedwars.BlockController:getHandlerRegistry():getHandler(bed.Name)
		local cells = handler and handler:getContainedPositions(bed) or {bed.Position / 3}
		local occupied = {}
		for _, v in cells do
			occupied[v * 3] = true
		end
		for _, v in cells do
			for _, side in sides do
				local pos = (v * 3) + side
				if not occupied[pos] and not getPlacedBlock(pos) then
					return false
				end
			end
		end
		return true
	end
	
	local function getBedNear()
		local localPosition = entitylib.character.RootPart.Position
		for _, v in collectionService:GetTagged('bed') do
			if (localPosition - v.Position).Magnitude < 14 and not v:GetAttribute(`Team{lplr:GetAttribute('Team') or -1}NoBreak`) and isDefended(v) then
				return v
			end
		end
		return nil
	end
	
	local function find(getBlock, col, topY)
		local y = topY
		local bot = topY - scan
		while y >= bot do
			local pos = Vector3.new(col.X, y, col.Z)
			if getBlock(round(pos)) then
				return y
			end
			y -= 3
		end
		return nil
	end
	
	local function buildCol(getBlock, root, dir, height)
		local out = {}
		local col = root + dir * 3
		local topY = root.Y + 2 * 3
		local sup = find(getBlock, col, topY)
		local sy
		if sup then
			sy = sup + 3
		else
			sy = topY - (height - 1) * 3
		end
		local y = sy
		while y <= topY do
			table.insert(out, Vector3.new(dir.X * 3, y - root.Y, dir.Z * 3))
			y += 3
		end
		return out
	end
	
	local function getPattern(root, getBlock)
		local pattern = {}
		local cols = {}
		for _, dir in ipairs(dirs) do
			local out = buildCol(getBlock, root, dir, 2)
			table.insert(cols, {dir = dir, out = out, cost = #out})
		end
		table.sort(cols, function(a, b)
			return a.cost < b.cost
		end)
		cols[1].out = buildCol(getBlock, root, cols[1].dir, 2)
		cols[1].cost = #cols[1].out
		local capY = 0
		for _, c in ipairs(cols) do
			if #c.out > 0 then
				local top = c.out[#c.out]
				if top.Y > capY then
					capY = top.Y
				end
			end
		end
		for _, o in ipairs(cols[1].out) do
			table.insert(pattern, o)
		end
		table.insert(pattern, Vector3.new(0, capY, 0))
		for i = 2, #cols do
			for _, o in ipairs(cols[i].out) do
				if o.Y ~= capY then
					table.insert(pattern, o)
				end
			end
		end
		return pattern
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
			table.sort(blocks, priorities[Priority.Value])
		end
		return blocks
	end
	
	local function placePattern(origin, patterns, limit)
		local hotbar = store.hand.tool and getHotbar(store.hand.tool) or 0
		local placed = 0
		for _, v in getBlocks() do
			if placed >= limit then break end
			local block = getHotbar(v[3])
			if not block and Switch.Enabled then
				continue
			end
	
			if Switch.Enabled then
				hotbarSwitch(block)
			end
			for _, pos in patterns do
				if placed >= limit or not entitylib.isAlive then break end
				if getPlacedBlock(origin + pos) then continue end
				repeat task.wait() until not entitylib.isAlive or (workspace:GetServerTimeNow() - bedwars.BlockCpsController.lastPlaceTimestamp) >= (1 / 12)
				if not entitylib.isAlive then break end
	
				local root = entitylib.character.RootPart
				if math.abs(root.Position.X - origin.X) > 0.5 or math.abs(root.Position.Z - origin.Z) > 0.5 then
					root.CFrame = CFrame.new(origin.X, root.Position.Y, origin.Z) * (root.CFrame - root.Position)
				end
				bedwars.placeBlock(origin + pos, v[1], true)
				placed += 1
			end
		end
		if Return.Enabled and Switch.Enabled and hotbar then
			hotbarSwitch(hotbar)
		end
	end
	
	BlockIn = vape.Categories.World:CreateModule({
		Name = 'Block-In',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive and (Mode.Value == 'On bind' or getBedNear()) then
						local early = false
						repeat
							task.wait()
							if entitylib.isAlive and not early then
								local origin = getOrigin()
								local drop = entitylib.character.RootPart.Position.Y - origin.Y
								early = drop >= 6 and drop <= 24
								if early then
									placePattern(origin, getPattern(origin, getPlacedBlock), 3)
								end
							end
						until not BlockIn.Enabled or not entitylib.isAlive or entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air
	
						if entitylib.isAlive then
							local origin = getOrigin()
							placePattern(origin, getPattern(origin, getPlacedBlock), math.huge)
						end
					end
	
					if Mode.Value == 'On bind' then
						BlockIn:Toggle()
						break
					end
					task.wait(0.5)
				until not BlockIn.Enabled
			end
		end,
		Tooltip = 'Automatically blocks you in by building walls around you'
	})
	Mode = BlockIn:CreateDropdown({
		Name = 'Mode',
		List = {'On bind', 'When near'},
		Default = 'On bind',
		Tooltip = 'On bind blocks you in once per keypress, When near keeps you blocked in while you are on an enemy bed'
	})
	Priority = BlockIn:CreateDropdown({
		Name = 'Block priority',
		List = {'Lowest cost', 'Hardest'},
		Default = 'Lowest cost'
	})
	Switch = BlockIn:CreateToggle({Name = 'Switch', Default = true})
	Return = BlockIn:CreateToggle({Name = 'Return to last slot', Default = true})
	Wool = BlockIn:CreateToggle({Name = 'Wool only'})
	Blacklist = BlockIn:CreateTextList({
		Name = 'Blacklist',
		Default = {'cannon', 'siege_tnt', 'tnt'}
	})
end)
