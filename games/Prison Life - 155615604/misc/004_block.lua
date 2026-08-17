entitylib.start()

run(function()
	pl = {
		GunTracers = require(replicatedStorage.SharedModules.GunTracers)
	}

	local gui = lplr.PlayerGui:WaitForChild('Home', 10)
	gui = gui and gui.hud.ActionArea
	if vape.Loaded == nil then
		return
	end

	local function getShootFunction()
		for _, v in getconnections(gui.InputBegan) do
			if v.Function then
				pl.Shoot = debug.getupvalue(v.Function, 2)
				pl.Reload = debug.getupvalue(pl.Shoot, 2)
				pl.Bullet = debug.getupvalue(pl.Shoot, 16)
				pl.PlaySound = debug.getupvalue(pl.Reload, 3)
				break
			end
		end

		for _, v in getconnections(lplr.CharacterAdded) do
			if v.Function and debug.info(v.Function, 's'):find('GunController') then
				pl.Equip = debug.getupvalue(v.Function, 3)
				break
			end
		end

		for _, v in getconnections(lplr:GetAttributeChangedSignal('BackpackEnabled')) do
			pl.SwitchUpdate = debug.getupvalue(debug.getupvalue(v.Function, 10), 5)
			pl.SwitchTable = debug.getupvalue(debug.getupvalue(v.Function, 8), 2)
			break
		end
	end

	getShootFunction()
	if not (pl.Bullet and pl.SwitchTable) then
		repeat
			getShootFunction()
			task.wait()
		until pl.Bullet and pl.SwitchTable or vape.Loaded == nil

		if vape.Loaded == nil then
			table.clear(pl)
		end
	end

	local kills = sessioninfo:AddItem('Kills')
	local deaths = sessioninfo:AddItem('Deaths')
	local arrests = sessioninfo:AddItem('Arrests')
	local cheaterkicked = sessioninfo:AddItem('Cheaters Kicked')
	local cheaters = sessioninfo:AddItem('Cheater List', '', function()
		local text = ''
		for _, plr in playersService:GetPlayers() do
			if CheatFlags.Flagged[plr.UserId] then
				text = text..'\n'..(plr.DisplayName ~= plr.Name and plr.DisplayName..' ('..plr.Name..')' or plr.Name)
			end
		end

		return text
	end, false)

	vape:Clean(replicatedStorage.Killfeed.ChildAdded:Connect(function(obj)
		local names = {}

		-- killer
		local start = obj.Name:find('@')
		local endchar = obj.Name:find(')')
		table.insert(names, obj.Name:sub(start + 1, endchar - 1))

		-- victim
		start = obj.Name:find('killed ') + 7
		endchar = obj.Name:find(' ', start)
		table.insert(names, obj.Name:sub(start, endchar - 1))

		vapeEvents.PlayerKill:Fire(unpack(names))
		if names[1] == lplr.Name then
			kills:Increment()
		elseif names[2] == lplr.Name then
			deaths:Increment()
		end
	end))

	vape:Clean(vapeEvents.Arrested.Event:Connect(function()
		arrests:Increment()
	end))

	vape:Clean(replicatedStorage.Remotes.MessageReceived.OnClientEvent:Connect(function(msg)
		if msg:find('kicked') then
			cheaterkicked:Increment()

			task.defer(function()
				vapeEvents.CheaterKicked:Fire(msg:sub(1, msg:find(' ')))
			end)
		end
	end))

	vape:Clean(entitylib.Events.EntityUpdated:Connect(function(ent)
		if ent.Player and ent.Player.Team == teams.Inmates then
			vape.Categories.Friends.ColorUpdate:Fire()
		end
	end))

	table.insert(whitelist.tagcallback, function(plr, plrtag, rich)
		if plr then
			local ent = entitylib.getEntity(plr)
			if ent then
				if CheatFlags.Flagged[plr.UserId] then
					table.insert(plrtag, {text = rich and '!' or 'Cheater'})
				end

				if plr.Team == teams.Inmates then
					if ent.Character:GetAttribute('Hostile') then
						table.insert(plrtag, {text = rich and '!!' or 'Hostile'})
					elseif ent.Character:GetAttribute('Trespassing') then
						table.insert(plrtag, {text = rich and '#' or 'Trespassing'})
					end
				elseif plr.Team == teams.Guards then
					local count = plr:GetAttribute('InnocentKills') or 0
					if count > 0 then
						table.insert(plrtag, {
							text = tostring(count),
							color = Color3.fromHSV(math.clamp(1 - (count / 2), 0, 1) / 2.5, 0.89, 0.75)
						})
					end
				end
			end
		end
	end)

	task.spawn(function()
		gamepasses = {
			['Riot Police'] = marketplaceService:UserOwnsGamePassAsync(lplr.UserId, 643697197),
			Mafia = marketplaceService:UserOwnsGamePassAsync(lplr.UserId, 1443271),
			Sniper = marketplaceService:UserOwnsGamePassAsync(lplr.UserId, 699360089)
		}
	end)

	OriginScanner:UpdateIgnore()
	for _, v in {'EntityAdded', 'LocalAdded'} do
		vape:Clean(entitylib.Events[v]:Connect(function()
			OriginScanner:UpdateIgnore()
		end))
	end

	vape:Clean(runService.RenderStepped:Connect(function()
		table.clear(OriginScanner.Cache)
	end))

	vape:Clean(function()
		table.clear(pl)
	end)
end)
