
run(function()
	local Headless
	local Hats
	
	local hidden = setmetatable({}, {__mode = 'k'})
	
	local function setHidden(character, hide)
		local head = character:FindFirstChild('Head')
		if not head then return end
	
		head.LocalTransparencyModifier = hide and 1 or 0
		for _, v in head:GetChildren() do
			if v:IsA('Decal') then
				if hide and not hidden[v] then
					hidden[v] = v.Transparency
				end
				v.Transparency = hide and 1 or (hidden[v] or 0)
			end
		end
	
		for _, v in character:GetChildren() do
			if v:IsA('Accessory') and v.Handle and v.Handle:FindFirstChild('HatAttachment') then
				v.Handle.LocalTransparencyModifier = hide and Hats.Enabled and 1 or 0
			end
		end
	end
	
	Headless = vape.Categories.Render:CreateModule({
		Name = 'Headless',
		Function = function(callback)
			if callback then
				Headless:Clean(runService.PreRender:Connect(function()
					if entitylib.isAlive then
						setHidden(lplr.Character, true)
					end
				end))
			elseif entitylib.isAlive then
				setHidden(lplr.Character, false)
			end
		end,
		Tooltip = 'Hides your own head'
	})
	Hats = Headless:CreateToggle({
		Name = 'Hide hats',
		Default = true,
		Tooltip = 'Hides anything worn on your head too'
	})
end)
