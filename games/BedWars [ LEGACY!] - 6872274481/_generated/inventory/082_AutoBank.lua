
run(function()
	local AutoBank
	local Mode
	local Whitelist
	local UIToggle
	local Chests
	local UI
	local Reference, Blacklist = {}, {}
	local Items = {}
	
	local function getShopNPC()
		local shop, items, upgrades, newid = nil, false, false, nil
		if entitylib.isAlive then
			local localPosition = entitylib.character.RootPart.Position
			for _, v in store.shop do
				if v.RootPart and v.RootPart.Parent and (v.RootPart.Position - localPosition).Magnitude <= 30 and not entitylib.EntityPosition({
					Origin = v.RootPart.Position,
					Range = 40,
					Part = 'RootPart',
					Players = true
				}) then
					shop = v.Upgrades or v.Shop or nil
					upgrades = upgrades or v.Upgrades
					items = items or v.Shop
					newid = v.Shop and v.Id or newid
				end
			end
		end
		return shop, items, upgrades, newid
	end
	local function Added(itemType)
		local item = Instance.new('ImageLabel')
		item.Image = bedwars.getIcon({itemType = itemType}, true)
		item.Size = UDim2.fromOffset(32, 32)
		item.Name = itemType
		item.BackgroundTransparency = 1
		item.LayoutOrder = #UI:GetChildren()
		item.Parent = UI
		local itemtext = Instance.new('TextLabel')
		itemtext.Name = 'Amount'
		itemtext.Size = UDim2.fromScale(1, 1)
		itemtext.BackgroundTransparency = 1
		itemtext.Text = ''
		itemtext.TextColor3 = Color3.new(1, 1, 1)
		itemtext.TextSize = 16
		itemtext.TextStrokeTransparency = 0.3
		itemtext.Font = Enum.Font.Arial
		itemtext.Parent = item
		Items[itemType] = {Amount = 0, Object = itemtext}
	end
	local function Removed(part)
		local index = table.find(Reference, part)
		if index then 
			table.remove(Reference, index) 
		end
	end
	AutoBank = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBank',
		Function = function(callback)
			if callback then
				UI = Instance.new('Frame')
				UI.Size = UDim2.new(1, 0, 0, 32)
				UI.AnchorPoint = Vector2.new(0.5, 0)
				UI.Position = UDim2.new(0.5, 0, 0 -240)
				UI.BackgroundTransparency = 1
				UI.Visible = UIToggle.Enabled
				UI.Parent = vape.gui
				AutoBank:Clean(UI)
				local Sort = Instance.new('UIListLayout')
				Sort.FillDirection = Enum.FillDirection.Horizontal
				Sort.HorizontalAlignment = Enum.HorizontalAlignment.Center
				Sort.SortOrder = Enum.SortOrder.LayoutOrder
				Sort.Parent = UI
				for _, v in Whitelist.ListEnabled do
					Added(v)
				end
	
				Chests = collection('personal-chest', AutoBank)
				local near = false
				local base, rows = CFrame.new(1e3, 1e5, 1e3), Random.new():NextInteger(0, 20000)
				AutoBank:Clean(runService.PreRender:Connect(function()
					if entitylib.isAlive then
						pos = entitylib.character.RootPart.CFrame - Vector3.new(0, 100, 0)
					end
					local new = {}
					for i, v in Reference do
						if v and v.Parent and v.Parent == workspace.ItemDrops then
							new[v.Name] = (new[v.Name] or 0) + (v:GetAttribute('Amount') or 0)
							v.Velocity = Vector3.zero
							v.CFrame = near and entitylib.character.Head.CFrame or base + Vector3.new((i % rows) * 1200, 0, math.floor(i / rows) * 1200)
						elseif v and v.Parent then
							Removed(v)
						end
					end
					for i, v in Items do
						v.Amount = new[i] or 0
						v.Object.Text = tostring(v.Amount)
					end
				end))
				repeat
					local hotbar = lplr.PlayerGui:FindFirstChild('hotbar')
					local hotbarFrame = hotbar and hotbar:FindFirstChild('1')
					hotbar = hotbarFrame and hotbarFrame:FindFirstChild('HotbarHealthbarContainer')
					if hotbar then
						UI.Position = UDim2.new(0.5, 0, 0, (hotbar.AbsolutePosition.Y + guiService:GetGuiInset().Y) - 60)
					end
	
					if entitylib.isAlive and not getShopNPC() then
						near = false
						for _, v in store.inventory.inventory.items do
							local name = v.tool and v.tool.Name or nil
							if name and table.find(Whitelist.ListEnabled, name) and (Blacklist[name] or 0) < tick() then
								task.spawn(function()
									local part = bedwars.Handler:Get('DropItem'):Fire('CallServer', {
										item = v.tool,
										amount = v.amount
									})
									if AutoBank.Enabled and part and part.Parent and not table.find(Reference, part) then
										table.insert(Reference, part)
										part:ClearAllChildren()
										part.AncestryChanged:Once(function()
											Removed(part)
										end)
									elseif AutoBank.Enabled then
										Blacklist[name] = tick() + 5
									end
								end)
							end
						end
					elseif entitylib.isAlive then
						near = true
						for _, v in Reference do
							v.Velocity = Vector3.zero
							v.CFrame = entitylib.character.Head.CFrame
							task.spawn(function()
								bedwars.Handler:Get('PickupItemDrop'):Fire('CallServerAsync', {
									itemDrop = v
								}):andThen(function(suc)
									if suc then
										Removed(v)
									end
								end)
							end)
						end
					end
					task.wait(0.1)
				until not AutoBank.Enabled
			else
				repeat
					for _, v in Reference do
						v.Velocity = Vector3.zero
						v.CFrame = entitylib.character.Head.CFrame
						task.spawn(function()
							bedwars.Handler:Get('PickupItemDrop'):Fire('CallServerAsync', {
								itemDrop = v
							}):andThen(function(suc)
								if suc then
									Removed(v)
								end
							end)
						end)
					end
					task.wait()
				until AutoBank.Enabled
			end
		end,
		Tooltip = 'Stores resources to somewhere safe'
	})
	Whitelist = AutoBank:CreateTextList({
		Name = 'Whitelist',
		Default = {'emerald', 'diamond', 'iron'},
		Function = function()
			if AutoBank.Enabled then
				AutoBank:Toggle()
				AutoBank:Toggle()
			end
		end
	})
	UIToggle = AutoBank:CreateToggle({Name = 'Display resources', Default = true})
end)
