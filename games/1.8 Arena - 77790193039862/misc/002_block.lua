
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

	entitylib.getUpdateConnections = function(ent)
		return {
			ent.Player.HealthValue:GetPropertyChangedSignal('Value')
		}
	end

	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end

		if plr == lplr then
			local hum = {GetState = function() end, Health = 100}
			local humrootpart = gameCamera.CameraSubject

			local entity = {
				Connections = {},
				Character = char,
				Health = 100,
				Head = humrootpart,
				Humanoid = hum,
				HumanoidRootPart = humrootpart,
				HipHeight = 5,
				MaxHealth = 100,
				NPC = plr == nil,
				Player = plr,
				RootPart = humrootpart,
				TeamCheck = teamfunc
			}

			entitylib.character = entity
			entitylib.isAlive = true
			entitylib.Events.LocalAdded:Fire(entity)
			return
		end

		entitylib.EntityThreads[char] = task.spawn(function()
			local hum = waitForChildOfType(char, 'Humanoid', 10)
			local humrootpart = char:WaitForChild('Torso', 10)
			local head = char:WaitForChild('Head', 10) or humrootpart
			local val = plr:WaitForChild('HealthValue', 10)

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = plr.HealthValue.Value,
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					Hitbox = char.PlayerHitbox,
					HipHeight = 3,
					MaxHealth = 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				entity.Targetable = entitylib.targetCheck(entity)
				for _, v in entitylib.getUpdateConnections(entity) do
					table.insert(entity.Connections, v:Connect(function()
						entity.Health = plr.HealthValue.Value
						entitylib.Events.EntityUpdated:Fire(entity)
					end))
				end

				table.insert(entitylib.List, entity)
				entitylib.Events.EntityAdded:Fire(entity)
			end

			entitylib.EntityThreads[char] = nil
		end)
	end

	entitylib.addPlayer = function(plr) end

	local oldstart = entitylib.start
	entitylib.start = function()
		oldstart()
		if entitylib.Running then
			table.insert(entitylib.Connections, gameCamera:GetPropertyChangedSignal('CameraSubject'):Connect(function()
				if gameCamera.CameraSubject then
					entitylib.addEntity(true, lplr)
				end
			end))

			if gameCamera.CameraSubject then
				entitylib.addEntity(true, lplr)
			end

			table.insert(entitylib.Connections, workspace.OtherCharacters.ChildAdded:Connect(function(ent)
				local plr = playersService:FindFirstChild(ent.Name:sub(1, #ent.Name - 14))
				if plr then
					entitylib.refreshEntity(ent, plr)
				end
			end))

			for _, ent in workspace.OtherCharacters:GetChildren() do
				local plr = playersService:FindFirstChild(ent.Name:sub(1, #ent.Name - 14))
				if plr then
					entitylib.refreshEntity(ent, plr)
				end
			end
		end
	end

	entitylib.start()
end)
