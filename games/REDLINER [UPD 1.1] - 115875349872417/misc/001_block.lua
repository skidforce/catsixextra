run(function()
	local function waitForChildOfType(obj, name, timeout, prop)
		local checktick = tick() + timeout
		local returned
		repeat
			returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
			if returned or checktick < tick() then break end
			task.wait()
		until false
		return returned
	end

	entitylib.addEntity = function(char, plr, teamfunc, spawntime)
		if not char then return end
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum = waitForChildOfType(char, 'Humanoid', 10)
			local humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
			local head = char:WaitForChild('Head', 10) or humrootpart
			local hitbox = char:FindFirstChild('Head_Hurtbox', true)

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = hum.Health,
					Head = head,
					Hitbox = hitbox or humrootpart,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					MaxHealth = hum.MaxHealth,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					SpawnTime = spawntime or 0,
					TeamCheck = teamfunc
				}

				if plr == lplr then
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
				else
					entity.Targetable = entitylib.targetCheck(entity)

					for _, v in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, v:Connect(function()
							entitylib.Events.EntityUpdated:Fire(entity)
						end))
					end

					table.insert(entitylib.List, entity)
					entitylib.Events.EntityAdded:Fire(entity)
				end
			end

			entitylib.EntityThreads[char] = nil
		end)
	end

	if game.PlaceId == 126691165749976 then
		entitylib.targetCheck = function(entity)
			if entity.NPC then return true end
			if isFriend(entity.Player) then return false end
			if not select(2, whitelist:get(entity.Player)) then return false end
			if vape.Categories.Main.Options['Teams by server'].Enabled then
				if not redline.Teams[tostring(lplr.UserId)] then return true end
				return redline.Teams[tostring(entity.Player.UserId)] ~= redline.Teams[tostring(lplr.UserId)]
			end

			return true
		end

		local function updatePlayer(plr)
			plr = playersService:GetPlayerByUserId(tonumber(plr.Name))

			if plr and entitylib.Running then
				if plr == lplr then
					local cloned = table.clone(entitylib.List)
					for _, entity in cloned do
						if entity.Targetable ~= entitylib.targetCheck(entity) then
							entitylib.refreshEntity(entity.Character, entity.Player)
						end
					end
					table.clear(cloned)
				else
					local entity = entitylib.getEntity(plr)
					if entity and entity.Targetable ~= entitylib.targetCheck(entity) then
						entitylib.refreshEntity(entity.Character, plr)
					end
				end
			end
		end

		local function processPlayer(plr)
			if tonumber(plr.Name) then
				redline.Teams[plr.Name] = plr:GetAttribute('team_id')
				task.spawn(updatePlayer, plr)

				vape:Clean(plr:GetAttributeChangedSignal('team_id'):Connect(function()
					redline.Teams[plr.Name] = plr:GetAttribute('team_id')
					task.spawn(updatePlayer, plr)
				end))
			end
		end

		local function processMatch(match)
			if match and match.Name == 'Match' then
				vape:Clean(match.DescendantAdded:Connect(processPlayer))
				for _, v in match:GetDescendants() do
					processPlayer(v)
				end
			end
		end

		vape:Clean(replicatedStorage.ReadOnly.ChildAdded:Connect(processMatch))
		task.spawn(processMatch, replicatedStorage.ReadOnly:FindFirstChild('Match'))
	end
end)
