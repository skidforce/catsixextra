
run(function()
	local PhaseMine
	
	local old = {}
	
	local function setIgnored(part)
		if part:IsA('BasePart') then
			table.insert(old, part)
			bedwars.QueryUtil:setQueryIgnored(part, true)
		end
	end
	
	local function Added(char)
		for _, v in char:QueryDescendants('BasePart') do
			setIgnored(v)
		end
		PhaseMine:Clean(char.ChildAdded:Connect(setIgnored))
	end
	
	PhaseMine = vape.Categories.Minigames:CreateModule({
		Name = 'PhaseMine',
		Function = function(callback)
			if callback then
				PhaseMine:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
					if ent.Player then
						task.delay(1, Added, ent.Character)
					end
				end))
	
				for _, ent in entitylib.List do
					if ent.Player and ent.Player ~= lplr and ent.Character then
						Added(ent.Character)
					end
				end
			else
				for _, v in old do
					if v.Parent then
						bedwars.QueryUtil:setQueryIgnored(v, false)
					end
				end
				table.clear(old)
			end
		end,
		Tooltip = 'Allows you to mine through opponents'
	})
end)
