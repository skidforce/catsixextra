
run(function()
	local AutoSteal
	local Range
	local Delay
	local GUI
	local Stash = {}
	
	local function getInventoryRemote(name)
		return bedwars.Client:GetNamespace('Inventory'):Get(name)
	end
	
	local function stealCrate(crate)
		local value = crate:FindFirstChild('ChestFolderValue')
		local folder = value and value.Value or nil
		if not folder then return end
	
		local items = {}
		for _, v in folder:GetChildren() do
			if v:IsA('Accessory') then
				table.insert(items, v)
			end
		end
		if #items == 0 then return end
	
		getInventoryRemote('SetObservedChest'):SendToServer(folder)
	
		for _, v in items do
			local itemType = v.Name
			task.spawn(function()
				local suc, res = pcall(function()
					return getInventoryRemote('ChestGetItem'):CallServer(folder, v)
				end)
	
				if suc and res then
					table.insert(Stash, {Type = itemType, Expire = tick() + 5})
				end
			end)
		end
	
		getInventoryRemote('SetObservedChest'):SendToServer(nil)
	end
	
	local function depositStash()
		local inventory = replicatedStorage:FindFirstChild('Inventories')
		inventory = inventory and inventory:FindFirstChild(`{lplr.Name}_personal`) or nil
		if not inventory then return end
	
		local pending = table.clone(Stash)
		table.clear(Stash)
	
		for _, v in pending do
			local item = getItem(v.Type)
			if item then
				task.spawn(function()
					local suc, res = pcall(function()
						return getInventoryRemote('ChestGiveItem'):CallServer(inventory, item.tool)
					end)
	
					if not (suc and res) and tick() < v.Expire then
						table.insert(Stash, v)
					end
				end)
			elseif tick() < v.Expire then
				table.insert(Stash, v)
			end
		end
	end
	
	AutoSteal = vape.Categories.Inventory:CreateModule({
		Name = 'AutoSteal',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.matchState ~= 0 or (not AutoSteal.Enabled)
				if not AutoSteal.Enabled then return end
	
				local crates = collection('team-crate', AutoSteal)
				local chests = collection('personal-chest', AutoSteal)
				local nextSteal = 0
	
				repeat
					if entitylib.isAlive and tick() > nextSteal and (not GUI.Enabled or bedwars.AppController:isAppOpen('ChestApp')) then
						nextSteal = tick() + Delay.Value
						local localPosition = entitylib.character.RootPart.Position
						local team = lplr:GetAttribute('Team')
	
						for _, v in crates do
							if v:GetAttribute('Team') ~= team and (localPosition - v.Position).Magnitude <= Range.Value then
								stealCrate(v)
							end
						end
	
						if #Stash > 0 then
							for _, v in chests do
								if (localPosition - v.Position).Magnitude <= Range.Value then
									depositStash()
									break
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoSteal.Enabled
			end
	
			table.clear(Stash)
		end,
		Tooltip = 'Automatically steals loot from the enemy team\'s crate and banks it in your personal chest'
	})
	Range = AutoSteal:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 18,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Delay = AutoSteal:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Suffix = 'seconds',
		Default = 0
	})
	GUI = AutoSteal:CreateToggle({Name = 'GUI Check'})
end)
