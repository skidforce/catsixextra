entitylib.start()

run(function()
	local root

	for i = 1, 3 do
		local doBreak
		for _, v in getloadedmodules() do
			if v:GetFullName() == 'Start.Client.ClientRoot' then
				doBreak = true
				break
			end
		end

		if doBreak then
			break
		end

		task.wait(0.5)
	end

	for _, v in getloadedmodules() do
		if v:GetFullName() == 'Start.Client.ClientRoot' then
			if getscripthash(v) ~= latestHash then
				warningRoutine(getscripthash(v))

				if vape.Loaded == nil then
					return
				end
			end

			root = require(v)
			if not rawget(root, 'loaded') then
				repeat
					task.wait()
				until rawget(root, 'loaded') or vape.Loaded == nil
			end

			if vape.Loaded == nil then
				return
			end
		end
	end

	if not root then
		lplr:Kick('Failed to find root class, please contact 7GrandDad on discord.')
		return
	end

	local classList = rawget(root, 'Classes') or {}
	redline = setmetatable({
		CEnum = require(replicatedStorage.Assets.ModuleScripts.CEnum),
		Packets = require(replicatedStorage.Assets.ModuleScripts.Packets),
		Packet = debug.getupvalue(getrawmetatable(require(replicatedStorage.Assets.ModuleScripts.Packets.Packet)).__call, 3),
		Util = require(replicatedStorage.Assets.SharedClasses.Util),
		Teams = redline.Teams
	}, {
		__index = function(self, ind)
			return rawget(classList, ind)
		end
	})

	local dumplist = {
		Constants = {
			ShootFunction = function(constants, func, inst)
				for _, const in constants do
					if const == 'ViewportPointToRay' and debug.info(func, 'n'):sub(1, 1) == '_' then
						redline.ShootFunction = require(inst)[debug.info(func, 'n')]
						break
					end
				end
			end,
			ActionController = function(constants, func, inst)
				for _, const in constants do
					if const == 'getAction FAILED FOR : ' and debug.info(func, 'n'):sub(1, 1) == '_' then
						redline.ActionController = inst.Name
						redline.ActionFunction = require(inst)[debug.info(func, 'n')]
						break
					end
				end
			end,
			IndicatorController = function(constants, func, inst)
				for _, const in constants do
					if const == 'INVALID crosshair_name : ' then
						redline.IndicatorController = inst.Name
						break
					end
				end
			end,
			ActionEventPacket = function(constants, func, inst)
				local found
				for _, const in constants do
					if const == 'OnClientEvent' then
						found = true
					elseif const == 'onKill' and found then
						redline.ActionEventPacket = searchForPacket(func, true)
						if redline.ActionEventPacket then
							redline.ActionEventPacket = redline.Packets.unreliablePackets[redline.ActionEventPacket]
						end

						break
					end
				end
			end,
			LaunchpadFunction = function(constants, func, inst)
				local found
				for _, const in constants do
					if const == -0.007 then
						found = true
					elseif const == 'augment' and found then
						local dumpList = {}
						for _, const in constants do
							if tostring(const):sub(1, 2) == '_x' then
								table.insert(dumpList, const)
							end
						end

						redline.LaunchpadFunction = dumpList[9]
						break
					end
				end
			end
		},
		Protos = {
			AttackPacket = function(protos, func, inst)
				for _, proto in protos do
					if debug.info(proto, 'n') == 'redlinerMelee' then
						redline.AttackPacket = searchForPacket(proto)
						if redline.AttackPacket then
							redline.AttackPacket = redline.Packets[redline.AttackPacket].Name
						end

						break
					end
				end
			end,
			IndicatorTable = function(protos, func, inst)
				for _, proto in protos do
					if debug.info(proto, 'n') == 'removeShotIndicator' then
						for _, const in debug.getconstants(proto) do
							if tostring(const):sub(1, 1) == '_' then
								redline.IndicatorTable = const
								break
							end
						end

						break
					end
				end
			end,
			DashVariables = function(protos, func, inst)
				for _, proto in protos do
					local doBreak = false
					local found = false
					for _, const in debug.getconstants(proto) do
						if const == 'onDeath' then
							found = true
						elseif const == 'Fire' and found then
							doBreak = true
						end
					end

					if doBreak then
						local dumpList = {}
						for _, const in debug.getconstants(proto) do
							if tostring(const):sub(1, 2) == '_x' then
								table.insert(dumpList, const)
							end
						end

						redline.MoveController = dumpList[3]
						redline.DashRecoverVariable = dumpList[4]
						redline.DashVariable = dumpList[5]
						break
					end
				end
			end
		}
	}

	for _, v in getscripts() do
		if v:GetFullName():sub(1, 5) == 'Start' and v:IsA('ModuleScript') then
			local closure = getscriptclosure(v)
			local protos = debug.getprotos(closure)

			if protos[1] then
				if debug.info(protos[1], 'l') == 3 and #debug.info(protos[1], 'n') <= 2 then
					continue
				end
			end

			for _, func in debug.getprotos(closure) do
				for name, callback in dumplist.Constants do
					if not redline[name] then
						callback(debug.getconstants(func), func, v)
					end
				end

				for name, callback in dumplist.Protos do
					if not redline[name] then
						callback(debug.getprotos(func), func, v)
					end
				end
			end
		end
	end

	local kills = sessioninfo:AddItem('Kills')
	local deaths = sessioninfo:AddItem('Deaths')
	local games = sessioninfo:AddItem('Games')
	local wins = sessioninfo:AddItem('Wins')

	if game.PlaceId == 126691165749976 then
		task.delay(1, function()
			games:Increment()
		end)
	end

	if redline.ActionEventPacket then
		vape:Clean(redline.ActionEventPacket.OnClientEvent:Connect(function(data)
			if type(data) == 'table' then
				task.spawn(function()
					local attacker = data.agent and (playersService:GetPlayerFromCharacter(data.agent) or playersService:FindFirstChild(data.agent.Name))
					local victim = data.victim and (playersService:GetPlayerFromCharacter(data.victim) or playersService:FindFirstChild(data.victim.Name))

					if data.action == 'killed' then
						if attacker == lplr then
							vapeEvents.PlayerKill:Fire()
							kills:Increment()
						elseif victim == lplr then
							deaths:Increment()
						end
					elseif data.action == 'hit' and attacker == lplr then
						vapeEvents.Hit:Fire()
					end
				end)
			end
		end))
	end

	vape:Clean(vapeEvents.MatchEnded.Event:Connect(function(won)
		if won then
			wins:Increment()
		end
	end))

	vape:Clean(lplr.PlayerGui.ChildAdded:Connect(function(obj)
		if obj.Name == 'MatchResultsScreen' then
			local results = obj
			obj = obj:FindFirstChild('Subtext', true)
			obj = obj and obj:FindFirstChildWhichIsA('TextLabel')

			if obj then
				obj:GetPropertyChangedSignal('Text'):Wait()
				vapeEvents.MatchEnded:Fire(obj.Text:find('WON') and true or false, results)
			end
		end
	end))
end)
