
run(function()
	local AutoCounter
	local Range
	local Limit
	local AutoSwitch = {}
	
	local function getAttackData()
		if Limit.Enabled then
			local tool = store.hand.tool
			return tool and tool.Name == 'tnt' and tool or nil
		end
		local item = getItem('tnt')
		return item and item.tool or nil
	end
	
	AutoCounter = vape.Categories.Utility:CreateModule({
		Name = 'AutoCounterTNT',
		Function = function(callback)
			if callback then
				local tnts, placed = {}, {}
				AutoCounter:Clean(workspace.ChildAdded:Connect(function(v)
					if v.Name == 'tnt' then
						table.insert(tnts, v)
						v.Destroying:Once(function()
							local index = table.find(tnts, v)
							if index then
								table.remove(tnts, index)
							end
						end)
					end
				end))
				repeat
					for pos, expiry in placed do
						if expiry <= tick() then
							placed[pos] = nil
						end
					end
					if entitylib.isAlive then
						local item = getAttackData()
						if item then
							local localPosition = entitylib.character.RootPart.Position
							for _, v in tnts do
								local roundedPos = Vector3.new(math.round(v.Position.X), math.round(v.Position.Y), math.round(v.Position.Z))
								if v.Velocity.Y >= 0 and not placed[roundedPos] and (localPosition - v.Position).Magnitude <= Range.Value then
									if not Limit.Enabled and AutoSwitch.Enabled then
										local hotbar = getHotbar(item)
										switchItem(item)
										if hotbar then
											hotbarSwitch(hotbar)
										end
									end
									placed[roundedPos] = tick() + 3
									task.spawn(bedwars.placeBlock, v.Position, item.Name)
									task.wait(0.12)
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoCounter.Enabled
			end
		end,
		Tooltip = 'Automatically places tnt on opponent\'s tnt'
	})
	AutoCounter:CreateDropdown({
		Name = 'Mode',
		List = {'Toggle', 'On key'},
		Default = 'Toggle'
	})
	Range = AutoCounter:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 60,
		Default = 30
	})
	Limit = AutoCounter:CreateToggle({
		Name = 'Limit to item',
		Function = function(callback)
			if AutoSwitch.Object then
				AutoSwitch.Object.Visible = not callback
			end
		end
	})
	AutoSwitch = AutoCounter:CreateToggle({
		Name = 'Auto Switch',
		Function = function(callback)
			Limit.Object.Visible = not callback
		end,
		Default = true
	})
end)
