
run(function()
	local InteractExtender
	local Distance
	local Sight
	local modified = setmetatable({}, {__mode = 'k'})
	
	local function extendPrompt(prompt)
		if not prompt:IsA('ProximityPrompt') then return end
	
		if not modified[prompt] then
			modified[prompt] = {Distance = prompt.MaxActivationDistance, Sight = prompt.RequiresLineOfSight}
		end
	
		prompt.MaxActivationDistance = Distance.Value
		prompt.RequiresLineOfSight = not Sight.Enabled
	end
	
	InteractExtender = vape.Categories.World:CreateModule({
		Name = 'InteractExtender',
		Function = function(callback)
			if callback then
				InteractExtender:Clean(workspace.DescendantAdded:Connect(extendPrompt))
				for _, v in workspace:GetDescendants() do
					extendPrompt(v)
				end
			else
				for i, v in modified do
					i.MaxActivationDistance = v.Distance
					i.RequiresLineOfSight = v.Sight
				end
	
				table.clear(modified)
			end
		end,
		Tooltip = 'Lets you use proximity prompts from further away'
	})
	Distance = InteractExtender:CreateSlider({
		Name = 'Distance',
		Min = 1,
		Max = 500,
		Default = 50,
		Suffix = function(val)
			return val > 1 and 'studs' or 'stud'
		end,
		Function = function(val)
			for i in modified do
				i.MaxActivationDistance = val
			end
		end
	})
	Sight = InteractExtender:CreateToggle({
		Name = 'Through walls',
		Function = function(callback)
			for i in modified do
				i.RequiresLineOfSight = not callback
			end
		end,
		Tooltip = 'Also removes the line of sight requirement'
	})
end)
