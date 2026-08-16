
run(function()
	local AutoBlockUp
	local LimitItem
	local lastPlace = 0
	
	local function getBlockUpItem()
		if store.hand.toolType == 'block' then
			return store.hand.tool and store.hand.tool.Name
		elseif not LimitItem.Enabled then
			for _, item in store.inventory.inventory.items do
				local meta = bedwars.ItemMeta[item.itemType]
				if meta and meta.block then
					return item.itemType
				end
			end
		end
		return nil
	end
	
	AutoBlockUp = vape.Categories.Utility:CreateModule({
		Name = 'AutoBlockUp',
		Function = function(callback)
			if callback then
				AutoBlockUp:Clean(runService.Heartbeat:Connect(function()
					if entitylib.isAlive and up then
						local item = getBlockUpItem()
						if item then
							local pos = roundPos(entitylib.character.RootPart.Position - Vector3.new(0, entitylib.character.HipHeight + 1.5, 0))
							if tick() >= lastPlace and not getPlacedBlock(pos) then
								lastPlace = tick() + 0.15
								bedwars.placeBlock(pos, item, false)
							end
	
							entitylib.character.RootPart.Velocity = Vector3.new(entitylib.character.RootPart.Velocity.X, 35, entitylib.character.RootPart.Velocity.Z)
						end
					end
				end))
				AutoBlockUp:Clean(inputService.InputBegan:Connect(function(input)
					if not inputService:GetFocusedTextBox() and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA) then
						up = true
					end
				end))
				AutoBlockUp:Clean(inputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
						up = false
						entitylib.character.RootPart.Velocity = Vector3.new(entitylib.character.RootPart.Velocity.X, 0, entitylib.character.RootPart.Velocity.Z)
					end
				end))
	
				local touchGui = inputService.TouchEnabled and lplr.PlayerGui:FindFirstChild('TouchGui')
				local jumpButton = touchGui and touchGui:FindFirstChild('JumpButton', true)
				if jumpButton then
					AutoBlockUp:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
						up = jumpButton.ImageRectOffset.X == 146
					end))
				end
			end
		end,
		Tooltip = 'Places a block beneath you while holding jump so you can tower up instantly'
	})
	LimitItem = AutoBlockUp:CreateToggle({Name = 'Limit to items'})
end)
