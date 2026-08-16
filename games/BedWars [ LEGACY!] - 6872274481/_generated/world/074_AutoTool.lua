
run(function()
	local AutoTool
	local old, event
	
	local function getToolSlot(block)
		if not block or block:GetAttribute('NoBreak') or block:GetAttribute('Team'..(lplr:GetAttribute('Team') or 0)..'NoBreak') then return end
	
		local meta = bedwars.ItemMeta[block.Name]
		local tool = meta and meta.block and store.tools[meta.block.breakType]
		if not tool or (store.hand and store.hand.tool == tool.tool) then return end
	
		for i, v in store.inventory.hotbar do
			if v.item and v.item.itemType == tool.itemType then
				return i - 1
			end
		end
		return
	end
	
	AutoTool = vape.Categories.World:CreateModule({
		Name = 'AutoTool',
		Function = function(callback)
			if callback then
				event = Instance.new('BindableEvent')
				AutoTool:Clean(event)
				AutoTool:Clean(event.Event:Connect(function()
					contextActionService:CallFunction('block-break', Enum.UserInputState.Begin, newproxy(true))
				end))
				old = bedwars.BlockBreaker.hitBlock
				bedwars.BlockBreaker.hitBlock = function(self, maid, raycastparams, ...)
					local info = self.clientManager:getBlockSelector():getMouseInfo(1, {ray = raycastparams})
					local slot = getToolSlot(info and info.target and info.target.blockInstance or nil)
	
					if slot then
						task.spawn(function()
							if hotbarSwitch(slot) and inputService:IsMouseButtonPressed(0) then
								event:Fire()
							end
						end)
					end
					return old(self, maid, raycastparams, ...)
				end
			else
				bedwars.BlockBreaker.hitBlock = old
				old = nil
			end
		end,
		Tooltip = 'Automatically selects the correct tool'
	})
end)
