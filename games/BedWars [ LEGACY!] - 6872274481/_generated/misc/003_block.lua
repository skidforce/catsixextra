
local calculatePath
run(function()
	local Client, OldGet, OldBreak, OldHit, OldWallcheck
	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function()
			if not canDebug then
				return require(replicatedStorage['rbxts_include']['node_modules']['@easy-games'].knit.src).KnitClient
			end
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
		end)
		if KnitInit and Knit then break end
		task.wait()
	until KnitInit and Knit

	if canDebug and not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end

	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local InventoryUtil = require(replicatedStorage.TS.inventory['inventory-util']).InventoryUtil
	local ItemMetaModule = require(replicatedStorage.TS.item['item-meta'])
	local TeamUpgradeModule = require(replicatedStorage.TS.games.bedwars['team-upgrade']['team-upgrade-meta'])
	local Remotes = require(game:GetService("ReplicatedStorage").TS.remotes).default

	Client = Remotes.Client
	OldGet = Client.Get

	local RemoteHandler = {} -- thanks lr <3
	RemoteHandler.CachedRemotes = {}
	RemoteHandler.__index = RemoteHandler

	local RemoteDefinitionConstruct, RemotesInConstruct
	if canDebug then
		RemoteDefinitionConstruct, RemotesInConstruct = next(getupvalue(getrawmetatable(Remotes.Server).Get, 1))
	end

	local GlobalMiddleware = RemoteDefinitionConstruct and getupvalue(RemoteDefinitionConstruct.globalMiddleware[2], 1)
	if canDebug and (not GlobalMiddleware or typeof(GlobalMiddleware) ~= "table") then
		notif('Cat', 'Failed to load ratelimits, report this to a developer.', 30, 'alert')
	end

	function RemoteHandler.Get(self, RemoteID: string)
		if RemoteHandler.CachedRemotes[RemoteID] then
			return RemoteHandler.CachedRemotes[RemoteID]
		end

		local Remote = {}
		setmetatable(Remote, RemoteHandler)

		Remote.ID = RemoteID
		Remote.RequestsInLastMinute = 0
		Remote.MaxRequestsPerMinute = Remote:GetRateLimit()
		Remote.LastRateLimitReset = 0
	
		local Success, AttempedRemote = pcall(Client.Get, Client, Remote.ID)
		Remote.Success = Success
		Remote.Remote = AttempedRemote

		if not Success or not Remote.Remote then
			notif('Cat', `Tried to Get remote {Remote.ID}, remote is invalid`, 15, 'alert')
			Remote.Remote = nil
		end

		RemoteHandler.CachedRemotes[RemoteID] = Remote
		return Remote
	end

	local lastNotify = 0
	function RemoteHandler:Fire(Method: string?, ...)
		local Remote = self.Remote
		if not self.Success or not Remote then
			if tick() - lastNotify > 0.5 then
				lastNotify = tick()
				--notif('Cat', `Tried to Fire remote {Remote.ID}, remote is invalid`, 10, 'alert')
			end
			return {
				andThen = function() end
			}
		end

		if (os.clock() - self.LastRateLimitReset) >= 60 then
			self:ResetRateLimit()
		end

		if self:GetCurrentRequests() >= self:GetRateLimit() then
			if tick() - lastNotify > 0.5 then
				lastNotify = tick()
				--notif('Cat', `{self.ID} has hit its rate limit of {self.MaxRequestsPerMinute} requests per min`, 15, 'alert')
			end
			return {andThen = function() end}
		end

		self:IncrementRequests()
		local CallingFunction = (Method and Remote[Method]) or (Remote.CallServer or Remote.CallServerAsync or Remote.SendToServer)
		if CallingFunction then
			return CallingFunction(Remote, ...)
		end

		return
	end

	function RemoteHandler:ResetRateLimit()
		self.RequestsInLastMinute = 0
		self.LastRateLimitReset = os.clock()
	end

	function RemoteHandler:GetCurrentRequests()
		return self.RequestsInLastMinute
	end

	function RemoteHandler:IncrementRequests()
		self.RequestsInLastMinute = self.RequestsInLastMinute + 1
	end

	function RemoteHandler:GetRateLimit()
		local RemoteName: string = self.ID
		if self.CachedRemotes[RemoteName] then
			return self.CachedRemotes[RemoteName].MaxRequestsPerMinute
		end

		if not GlobalMiddleware then
			local CachedLimits = cheatenginelib and cheatenginelib.RateLimits
			return CachedLimits and CachedLimits[RemoteName] or 300
		end

		local GlobalFind = GlobalMiddleware[RemoteName]
		local RateLimitValue: number = (typeof(GlobalFind) ~= "number" and 300) or GlobalFind

		if not GlobalFind then
			local TargetRemote = RemotesInConstruct[RemoteName]
			local RemoteRateLimit = (TargetRemote and TargetRemote.ServerMiddleware)
			if RemoteRateLimit and typeof(RemoteRateLimit) == "table" then
				for i,v in RemoteRateLimit do
					if typeof(v) == "function" and (#getupvalues(v) >= 6 and tostring(getupvalue(v, 6)):find("Request limit")) then
						local Value: number = getupvalue(v, 3)
						RateLimitValue = (typeof(Value) == "number" and Value) or RateLimitValue
						break
					end
				end
			end
		end
	
		return RateLimitValue
	end

	bedwars = setmetatable({
		AbilityController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController'),
		AbilityIndicatorUtil = require(replicatedStorage.TS.games.bedwars.items['ability-indicator']['ability-indicator-util']).AbilityIndicatorUtil,
		AnimationType = require(replicatedStorage.TS.animation['animation-type']).AnimationType,
		AnimationUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out['shared'].util['animation-util']).AnimationUtil,
		AdetundeUtil = require(replicatedStorage.TS.games.bedwars.items['frosty-hammer']['frosty-hammer-util']).FrostyHammerUtil,
		AdetundeUpgradeMeta = require(replicatedStorage.TS.games.bedwars.items['frosty-hammer']['frosty-hammer-upgrades']).FrostyHammerUpgradeMeta,
		AppController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.controllers['app-controller']).AppController,
		BalanceFile = require(replicatedStorage.TS.balance['balance-file']).BalanceFile,
		BedBreakEffectMeta = require(replicatedStorage.TS.locker['bed-break-effect']['bed-break-effect-meta']).BedBreakEffectMeta,
		BedwarsKitMeta = require(replicatedStorage.TS.games.bedwars.kit['bedwars-kit-meta']).BedwarsKitMeta,
		BlackMarketeerBalance = require(replicatedStorage.TS.balance['black-marketeer-balance']).BlackMarketeerBalance,
		BlockBreaker = Knit.Controllers.BlockBreakController.blockBreaker,
		BlockController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine,
		BlockEngine = require(lplr.PlayerScripts.TS.lib['block-engine']['client-block-engine']).ClientBlockEngine,
		BlockPlacer = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.client.placement['block-placer']).BlockPlacer,
		BowConstantsTable = debug.getupvalue(Knit.Controllers.ProjectileController.enableBeam, 8) or (cheatenginelib and cheatenginelib.BowConstantsTable),
		BlockSelector = require(replicatedStorage.rbxts_include.node_modules['@easy-games']['block-engine'].out.client.select['block-selector']).BlockSelector,
		BlockSelectorMode = require(replicatedStorage.rbxts_include.node_modules['@easy-games']['block-engine'].out.client.select['block-selector']).BlockSelectorMode,
		ClickHold = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.ui.lib.util['click-hold']).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts'].net.out.client),
		ClientDamageBlock = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.shared.remotes).BlockEngineRemotes.Client,
		CombatConstant = require(replicatedStorage.TS.combat['combat-constant']).CombatConstant,
		DamageIndicator = Knit.Controllers.DamageIndicatorController.spawnDamageIndicator,
		DefaultKillEffect = require(lplr.PlayerScripts.TS.controllers.global.locker['kill-effect'].effects['default-kill-effect']),
		EmoteType = require(replicatedStorage.TS.locker.emote['emote-type']).EmoteType,
		EmoteDisplayMeta = require(replicatedStorage.TS.locker.emote['emote-display-meta']).EmoteDisplayMeta,
		EmoteMeta = require(replicatedStorage.TS.locker.emote['emote-meta']).EmoteMeta,
		EnchantMeta = require(replicatedStorage.TS.enchant['enchant-meta']).EnchantMeta,
		FrostyGunMode = require(replicatedStorage.TS.games.bedwars.kit.kits['frosty-gun']['frosty-gun-util']).FrostyGunMode,
		GameAnimationUtil = require(replicatedStorage.TS.animation['animation-util']).GameAnimationUtil,
		GamePlayerUtil = require(replicatedStorage.TS.player['player-util']).GamePlayerUtil,
		getIcon = function(item, showinv)
			local itemmeta = bedwars.ItemMeta[item.itemType]
			return itemmeta and showinv and itemmeta.image or ''
		end,
		getItemSkinMeta = require(replicatedStorage.TS.games.bedwars['item-skin']['item-skin-meta']).getItemSkinMeta,
		getInventory = function(plr)
			local suc, res = pcall(function()
				return InventoryUtil.getInventory(plr)
			end)
			return suc and res or {
				items = {},
				armor = {}
			}
		end,
		Handler = RemoteHandler,
		HudAliveCount = require(lplr.PlayerScripts.TS.controllers.global['top-bar'].ui.game['hud-alive-player-counts']).HudAlivePlayerCounts,
		ImageList = require(replicatedStorage.TS.image['image-id']).BedwarsImageId,
		ItemMeta = debug.getupvalue(ItemMetaModule.getItemMeta, 1) or ItemMetaModule.items,
		IsItemClaw = require(replicatedStorage.TS.games.bedwars.kit.kits.summoner['summoner-kit-util']).summoner_isItemClaw,
		ItemSkinType = require(replicatedStorage.TS.games.bedwars['item-skin']['item-skin-types']).ItemSkinType,
		KillEffectMeta = require(replicatedStorage.TS.locker['kill-effect']['kill-effect-meta']).KillEffectMeta,
		KillFeedController = Flamework.resolveDependency('client/controllers/game/kill-feed/kill-feed-controller@KillFeedController'),
		Knit = Knit,
		KnockbackUtil = require(replicatedStorage.TS.damage['knockback-util']).KnockbackUtil,
		MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage['mage-kit-util']).MageKitUtil,
		NametagController = Knit.Controllers.NametagController,
		PartyController = Flamework.resolveDependency('@easy-games/lobby:client/controllers/party-controller@PartyController'),
		ProjectileMeta = require(replicatedStorage.TS.projectile['projectile-meta']).ProjectileMeta,
		QueryUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil,
		QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui['queue-card']).QueueCard,
		QueueMeta = require(replicatedStorage.TS.game['queue-meta']).QueueMeta,
		RankMeta = require(replicatedStorage.TS.rank['rank-meta']).RankMeta,
		Roact = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts']['roact'].src),
		RuntimeLib = require(replicatedStorage['rbxts_include'].RuntimeLib),
		scaleTool = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts']['scale-model'].out).scaleTool,
		StatusEffectUtil = require(replicatedStorage.TS['status-effect']['status-effect-util']).StatusEffectUtil,
		StatusEffectMeta = require(replicatedStorage.TS['status-effect']['status-effect-type']).StatusEffectType,
		SummonerKitBalance = require(replicatedStorage.TS.games.bedwars.kit.kits.summoner['summoner-kit-balance']).SummonerKitBalance,
		SoundList = require(replicatedStorage.TS.sound['game-sound']).GameSound,
		SettingsMeta = require(replicatedStorage.TS.settings['settings-meta']).SettingMeta,
		SharedConstants = require(replicatedStorage.TS['shared-constants']).CpsConstants,
		SoulBrokerConstants = require(replicatedStorage.TS.games.bedwars.kit.kits['soul-broker']['soul-broker-constants']).SoulBrokerConstants,
		SorcererBalance = require(replicatedStorage.TS.balance['sorcerer-balance']).SorcererBalance,
		SorcererTierMeta = require(replicatedStorage.TS.balance['sorcerer-balance']).SorcererTierMeta,
		SummonerUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.summoner['summoner-kit-util']),
		AudioManager = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).AudioManager,
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		SyncEvents = require(lplr.PlayerScripts.TS['client-sync-events']).ClientSyncEvents,
		TeamUpgradeMeta = debug.getupvalue(TeamUpgradeModule.getTeamUpgradeMetaForQueue, 2) or (cheatenginelib and cheatenginelib.TeamUpgradeMeta),
		UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
		VisualizerUtils = require(lplr.PlayerScripts.TS.lib.visualizer['visualizer-utils']).VisualizerUtils,
		WeldTable = require(replicatedStorage.TS.util['weld-util']).WeldUtil,
		WinEffectMeta = require(replicatedStorage.TS.locker['win-effect']['win-effect-meta']).WinEffectMeta,
		WizardUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.wizard['wizard-util']).WizardUtil,
		ZapNetworking = require(lplr.PlayerScripts.TS.lib.network)
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})
	store.enchants = setmetatable({}, {
		__index = function(self, plr)
			return {
				async = function()
					if plr and plr.Character then
						for i in plr.Character:GetAttributes() do
							if i:find('StatusEffect_') and not i:find('_stacks') then
								local name = bedwars.StatusEffectMeta[({i:gsub('StatusEffect_', '')})[1]]
								if bedwars.StatusEffectMeta[name] then
									name = bedwars.StatusEffectMeta[name]
									for num = 1, 3 do
										name = name:gsub(`_{num}`, '')
									end

									if bedwars.EnchantMeta[name] then
										return bedwars.EnchantMeta[name].image
									end
								end
							end
						end
					end
					return nil
				end,
			}
		end
	})
	getgenv().store = store
	getgenv().bedwars = bedwars

	entitylib.Raycast = function(origin, direction, params)
		return bedwars.QueryUtil:raycast(origin, direction, params)
	end
	prediction.Raycast = entitylib.Raycast

	OldWallcheck = entitylib.Wallcheck
	local wallcheckParams = RaycastParams.new()
	wallcheckParams.FilterType = Enum.RaycastFilterType.Exclude

	local function getFeetPosition(character)
		local root = character.PrimaryPart
		if not root then return nil end

		local humanoid = character:FindFirstChildWhichIsA('Humanoid')
		return root.Position - Vector3.new(0, (humanoid and humanoid.HipHeight or 0) + (root.Size.Y / 2), 0)
	end

	local function isSegmentBlocked(from, to)
		return entitylib.Raycast(from, to - from, wallcheckParams) or entitylib.Raycast(to, from - to, wallcheckParams)
	end

	entitylib.Wallcheck = function(origin, position, ignoreobject, entity)
		local character = entity and entity.Character
		local selfcharacter = lplr.Character
		local selffeet = selfcharacter and getFeetPosition(selfcharacter)
		local targetfeet = character and getFeetPosition(character)
		if not selffeet or not targetfeet then
			return OldWallcheck(origin, position, ignoreobject)
		end

		local humanoid = selfcharacter:FindFirstChildWhichIsA('Humanoid')
		local scale = humanoid and humanoid:FindFirstChild('BodyHeightScale')
		local height = Vector3.new(0, 5 * (scale and scale.Value or 1), 0)
		local selfhead, targethead = selffeet + height, targetfeet + height

		local filter = {selfcharacter, character}
		for _, v in collectionService:GetTagged('DontBlockSwordRaycast') do
			table.insert(filter, v)
		end
		if typeof(ignoreobject) == 'table' then
			for _, v in ignoreobject do
				table.insert(filter, v)
			end
		end
		wallcheckParams.FilterDescendantsInstances = filter

		return isSegmentBlocked(selffeet, targetfeet) and isSegmentBlocked(selfhead, targethead) and isSegmentBlocked((selffeet + selfhead) / 2, (targetfeet + targethead) / 2) or nil
	end

	OldBreak = bedwars.BlockController.isBlockBreakable
	OldHit = bedwars.BlockBreaker.hitBlock

	Client.Get = function(self, remoteName)
		local call = OldGet(self, remoteName)

		if remoteName == 'SwordHit' then
			return {
				instance = call.instance,
				SendToServer = function(_, attackTable, ...)
					local selfpos = attackTable.validate.selfPosition.value
					local targetpos = attackTable.validate.targetPosition.value
					store.attackReach = ((selfpos - targetpos).Magnitude * 100) // 1 / 100
					store.attackReachUpdate = tick() + 1

					if Reach.Enabled or HitBoxes.Enabled then
						attackTable.validate.raycast = attackTable.validate.raycast or {}
						attackTable.validate.selfPosition.value += CFrame.lookAt(selfpos, targetpos).LookVector * math.max((selfpos - targetpos).Magnitude - (getReach(attackTable.weapon) - 0.001), 0)
					end

					return call:SendToServer(attackTable, ...)
				end
			}
		elseif remoteName == 'StepOnSnapTrap' and TrapDisabler.Enabled then
			return {SendToServer = function() end}
		end

		return call
	end


	bedwars.BlockBreaker.hitBlock = function(self, ...)
		store.lastHit = tick()
		return OldHit(self, ...)
	end

	local breakroutes, blockhealthbar = {}, {blockHealth = -1, breakingBlockPosition = Vector3.zero}
	store.swordDistance = bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE
	store.blockPlacer = bedwars.BlockPlacer.new(bedwars.BlockEngine, 'wool_white')

	local function getBlockHealth(block, blockpos)
		local blockdata = bedwars.BlockController:getStore():getBlockData(blockpos)
		return (blockdata and (blockdata:GetAttribute('1') or blockdata:GetAttribute('Health')) or block:GetAttribute('Health'))
	end

	getBlockHits = function(block, blockpos)
		if not block then return 0 end
		local breaktype = bedwars.ItemMeta[block.Name].block.breakType
		local tool = store.tools[breaktype]
		tool = tool and bedwars.ItemMeta[tool.itemType].breakBlock[breaktype] or 2
		return getBlockHealth(block, bedwars.BlockController:getBlockPosition(blockpos)) / tool
	end

	--[[
		Pathfinding using a luau version of dijkstra's algorithm
		Source: https://stackoverflow.com/questions/39355587/speeding-up-dijkstras-algorithm-to-solve-a-3d-maze
	]]
	calculatePath = function(target, blockpos, solidonly, breakmethod)
		local heap = {}
		local function push(cost, node)
			local index = #heap + 1
			heap[index] = {cost, node}

			while index > 1 do
				local parent = index // 2
				if heap[parent][1] <= heap[index][1] then break end
				heap[parent], heap[index] = heap[index], heap[parent]
				index = parent
			end
		end

		local function pop()
			local size = #heap
			if size == 0 then return end
			local root = heap[1]

			heap[1], heap[size], size = heap[size], nil, size - 1
			local index = 1

			while true do
				local left, right, smallest = index * 2, (index * 2) + 1, index
				if left <= size and heap[left][1] < heap[smallest][1] then smallest = left end
				if right <= size and heap[right][1] < heap[smallest][1] then smallest = right end
				if smallest == index then break end

				heap[index], heap[smallest] = heap[smallest], heap[index]
				index = smallest
			end

			return root[1], root[2]
		end

		local routes = {}
		local function isOpen(cell)
			if routes[cell] ~= nil then
				return routes[cell]
			end
			local queue, seen, open = {cell}, {[cell] = true}, true

			for _ = 1, 400 do
				local current = table.remove(queue)
				if not current then
					open = false
					break
				end
				if (current - blockpos).Magnitude > 15 then break end

				for _, side in sides do
					side = current + side
					if seen[side] or getPlacedBlock(side) then continue end
					seen[side] = true
					table.insert(queue, side)
				end
			end

			for reached in seen do
				routes[reached] = open
			end
			return open
		end

		local origin, dug = entitylib.character.RootPart.Position, {}

		local function blockAt(pos)
			if dug[pos] then return nil end
			return (getPlacedBlock(pos))
		end

		local function boundary(index, component, delta)
			if delta == 0 then
				return 0, math.huge, math.huge
			end
			local step = delta > 0 and 1 or -1
			return step, ((((index + (step * 0.5)) * 3) - component) / delta), (3 / math.abs(delta))
		end

		local function trace(from, cell)
			local start, direction = bedwars.BlockController:getBlockPosition(from), cell - from
			local x, y, z = start.X, start.Y, start.Z

			local stepx, nextx, deltax = boundary(x, from.X, direction.X)
			local stepy, nexty, deltay = boundary(y, from.Y, direction.Y)
			local stepz, nextz, deltaz = boundary(z, from.Z, direction.Z)

			for _ = 1, 100 do
				if nextx > 1 and nexty > 1 and nextz > 1 then break end

				if nextx <= nexty and nextx <= nextz then
					x, nextx = x + stepx, nextx + deltax
				elseif nexty <= nextz then
					y, nexty = y + stepy, nexty + deltay
				else
					z, nextz = z + stepz, nextz + deltaz
				end

				if blockAt(Vector3.new(x, y, z) * 3) then
					return false
				end
			end

			return true
		end

		local sightlines, simlines = {}, {}
		local eyes = {entitylib.character.Head.Position, gameCamera.CFrame.Position}
		local function canSee(cell)
			local memo = next(dug) and simlines or sightlines
			if memo[cell] == nil then
				memo[cell] = false
				for _, eye in eyes do
					if trace(eye, cell) then
						memo[cell] = true
						break
					end
				end
			end
			return memo[cell]
		end

		local function canBreak(node, anywhere)
			if not blockAt(node) or (node - origin).Magnitude > 30 then return false end

			for _, side in sides do
				side = node + side
				if not blockAt(side) and (anywhere or canSee(side)) then
					return true
				end
			end

			return false
		end

		if not solidonly then
			if canBreak(blockpos) then
				breakroutes[blockpos] = nil
				return blockpos, 0
			end

			local stored = breakroutes[blockpos]
			if stored then
				local away = origin - stored.origin
				local walked = Vector3.new(away.X, 0, away.Z).Magnitude <= 12

				while stored.nodes[1] and not getPlacedBlock(stored.nodes[1]) do
					table.remove(stored.nodes, 1)
				end

				local node = stored.nodes[1]
				if node and canBreak(node, walked) then
					return node, stored.costs[node], stored.chain
				end

				breakroutes[blockpos] = nil
			end
		end

		local visited, distances, exposed, path = {}, {[blockpos] = 0}, {}, {}
		local gaps, sources = {[blockpos] = 0}, {[blockpos] = blockpos}
		push(0, blockpos)

		for _ = 1, 10000 do
			local cost, node = pop()
			if not node then break end
			if visited[node] then continue end
			visited[node] = true
			local current, source = getPlacedBlock(node), sources[node]

			for _, side in sides do
				side = node + side
				if visited[side] then continue end

				local block = getPlacedBlock(side)
				if not block then
					if current then
						local cells = exposed[node]
						if cells then
							table.insert(cells, side)
						else
							exposed[node] = {side}
						end
					end

					local gap = current and 1 or (gaps[node] + 1)
					if not solidonly and gap <= 2 and (side - blockpos).Magnitude <= 15 and cost < (distances[side] or math.huge) and not isOpen(side) then
						distances[side] = cost
						gaps[side] = gap
						sources[side] = source
						push(cost, side)
					end
					continue
				end

				if block:GetAttribute('NoBreak') or block == target then continue end

				local curdist = cost + getBlockHits(block, side)
				if curdist < (distances[side] or math.huge) then
					distances[side] = curdist
					gaps[side] = 0
					sources[side] = side
					path[side] = source
					push(curdist, side)
				end
			end
		end

		local look = gameCamera.CFrame.LookVector
		local candidates = {}
		for node, cells in exposed do
			local delta = node - origin
			local magnitude = delta.Magnitude
			table.insert(candidates, {distances[node], node, cells, magnitude, magnitude > 0 and delta:Dot(look) / magnitude or 1, (node.X * 1000000) + (node.Y * 1000) + node.Z})
		end
		local nearest, cheapest = breakmethod == breakmethods.Distance, math.huge
		local previous = store.breakTarget
		for _, v in candidates do
			cheapest = math.min(cheapest, v[1])
		end
		table.sort(candidates, function(a, b)
			if nearest then
				if (a[1] <= cheapest) ~= (b[1] <= cheapest) then
					return a[1] <= cheapest
				end
			elseif a[1] ~= b[1] then
				return a[1] < b[1]
			end

			if previous and (a[2] == previous) ~= (b[2] == previous) then
				return a[2] == previous
			end

			if a[4] ~= b[4] then
				return a[4] < b[4]
			end
			if a[5] ~= b[5] then
				return a[5] > b[5]
			end
			return a[6] < b[6]
		end)

		local function walk(node)
			while node do
				if not canBreak(node) then break end
				dug[node] = true
				node = path[node]
			end

			table.clear(dug)
			table.clear(simlines)
			return node == nil
		end

		local pos, cost, backup, backupcost, tries = nil, nil, nil, nil, 0

		for _, candidate in candidates do
			if (candidate[2] - origin).Magnitude > 30 then continue end
			if not solidonly and getPlacedBlock(candidate[2]) == target then continue end

			local entry = false
			for _, cell in candidate[3] do
				if solidonly and isOpen(cell) or not solidonly and canSee(cell) then
					entry = true
					break
				end
			end
			if not entry then continue end

			if solidonly or walk(candidate[2]) then
				pos, cost = candidate[2], candidate[1]
				break
			end

			backup, backupcost = backup or candidate[2], backupcost or candidate[1]
			tries += 1
			if tries >= 10 then break end
		end

		if not pos and backup then
			pos, cost = backup, backupcost
		end

		if not pos and solidonly and candidates[1] then
			pos, cost = candidates[1][2], candidates[1][1]
		end

		if pos then
			local nodes, chain, costs = {}, {}, {}
			local node = pos

			while node do
				table.insert(nodes, node)
				costs[node] = distances[node]
				chain[node] = path[node]
				node = path[node]
			end

			if not solidonly then
				breakroutes[blockpos] = {nodes = nodes, chain = chain, costs = costs, origin = origin}
			end

			return pos, cost, chain
		end

		return
	end

	bedwars.placeBlock = function(pos, item)
		if not canPlace() then return end
		if getItem(item) then
			store.blockPlacer.blockType = item
			return store.blockPlacer:placeBlock(bedwars.BlockController:getBlockPosition(pos))
		end
	end

	bedwars.breakBlock = function(block, effects, anim, customHealthbar, autotool, wallcheck, method, directonly)
		if lplr:GetAttribute('DenyBlockBreak') or not entitylib.isAlive or (vape.Modules.InfiniteFly or {}).Enabled then return end
		local handler = bedwars.BlockController:getHandlerRegistry():getHandler(block.Name)
		local localPosition = entitylib.character.RootPart.Position
		local cost, pos, target, path = math.huge
		local direct = false

		for _, v in (handler and handler:getContainedPositions(block) or {block.Position / 3}) do
			local dpos, dcost, dpath = calculatePath(block, v * 3, not wallcheck, method or nil)
			local distance = dpos and (localPosition - dpos).Magnitude or math.huge
			local hit = dpos == v * 3
			if dpos and (hit and not direct or hit == direct and (dcost < cost or (dcost == cost and distance < (localPosition - pos).Magnitude))) then
				cost, pos, target, path, direct = dcost, dpos, v * 3, dpath, hit
			end
		end

		if directonly and not direct then return end

		store.breakTarget = pos

		if pos then
			if (entitylib.character.RootPart.Position - pos).Magnitude > 30 then return end
			local dblock, dpos = getPlacedBlock(pos)
			if not dblock then return end

			if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 0.4 then
				local breaktype = bedwars.ItemMeta[dblock.Name].block.breakType
				local tool = store.tools[breaktype]
				if tool then
					if autotool then
						local hotbar = getHotbar(tool.tool)
						if hotbar then
							hotbarSwitch(hotbar)
						end
					else
						switchItem(tool.tool)
					end
				end
			end

			if blockhealthbar.blockHealth == -1 or dpos ~= blockhealthbar.breakingBlockPosition then
				blockhealthbar.blockHealth = getBlockHealth(dblock, dpos)
				blockhealthbar.breakingBlockPosition = dpos
			end

			bedwars.ClientDamageBlock:Get('DamageBlock'):CallServerAsync({
				blockRef = {blockPosition = dpos},
				hitPosition = pos,
				hitNormal = Vector3.FromNormalId(Enum.NormalId.Top)
			}):andThen(function(result)
				if result then
					if result == 'cancelled' then
						store.damageBlockFail = tick() + 1
						return
					end

					if effects then
						local blockdmg = (blockhealthbar.blockHealth - (result == 'destroyed' and 0 or getBlockHealth(dblock, dpos)))
						customHealthbar = customHealthbar or bedwars.BlockBreaker.updateHealthbar
						customHealthbar(bedwars.BlockBreaker, {blockPosition = dpos}, blockhealthbar.blockHealth, dblock:GetAttribute('MaxHealth'), blockdmg, dblock)
						blockhealthbar.blockHealth = math.max(blockhealthbar.blockHealth - blockdmg, 0)

						if blockhealthbar.blockHealth <= 0 then
							bedwars.BlockBreaker.breakEffect:playBreak(dblock.Name, dpos, lplr)
							bedwars.BlockBreaker.blockHealthbar:destroy()
							blockhealthbar.breakingBlockPosition = Vector3.zero
						else
							bedwars.BlockBreaker.breakEffect:playHit(dblock.Name, dpos, lplr)
						end
					end

					if anim then
						local animation = bedwars.AnimationUtil:playAnimation(lplr, bedwars.BlockController:getAnimationController():getAssetId(1))
						bedwars.ViewmodelController:playAnimation(15)
						task.wait(0.3)
						animation:Stop()
						animation:Destroy()
					end
				end
			end)

			if effects then
				return pos, path, target
			end
		end
	end

	for _, v in Enum.NormalId:GetEnumItems() do
		table.insert(sides, Vector3.FromNormalId(v) * 3)
	end

	local function updateStore(new, old)
		if new.Bedwars ~= old.Bedwars then
			store.equippedKit = new.Bedwars.kit ~= 'none' and new.Bedwars.kit or ''
		end

		if new.Game ~= old.Game then
			store.matchState = new.Game.matchState
			store.queueType = new.Game.queueType or 'bedwars_test'
		end

		if new.Inventory ~= old.Inventory then
			local newinv = (new.Inventory and new.Inventory.observedInventory or {inventory = {}})
			local oldinv = (old.Inventory and old.Inventory.observedInventory or {inventory = {}})
			store.inventory = newinv

			if newinv ~= oldinv then
				vapeEvents.InventoryChanged:Fire()
			end

			if newinv.inventory.items ~= oldinv.inventory.items then
				vapeEvents.InventoryAmountChanged:Fire()
				store.tools.sword = getSword()
				for _, v in {'stone', 'wood', 'wool'} do
					store.tools[v] = getTool(v)
				end
			end

			if newinv.inventory.hand ~= oldinv.inventory.hand then
				local currentHand, toolType = new.Inventory.observedInventory.inventory.hand, ''
				if currentHand then
					local handData = bedwars.ItemMeta[currentHand.itemType] or {}
					toolType = handData.sword and 'sword' or handData.block and 'block' or currentHand.itemType:find('bow') and 'bow'
				end

				store.hand = {
					tool = currentHand and currentHand.tool,
					amount = currentHand and currentHand.amount or 0,
					toolType = toolType
				}
			end
		end
	end

	local storeChanged = bedwars.Store.changed:connect(updateStore)
	updateStore(bedwars.Store:getState(), {})

	for _, event in {'MatchEndEvent', 'EntityDeathEvent', 'BedwarsBedBreak', 'BalloonPopped', 'AngelProgress', 'GrapplingHookFunctions'} do
		if not vape.Connections then return end
		bedwars.Client:WaitFor(event):andThen(function(connection)
			vape:Clean(connection:Connect(function(...)
				vapeEvents[event]:Fire(...)
			end))
		end)
	end

	vape:Clean(bedwars.ZapNetworking.EntityDamageEventZap.On(function(...)
		local damageTable = {
			entityInstance = ...,
			damage = select(2, ...),
			damageType = select(3, ...),
			fromPosition = select(4, ...),
			fromEntity = select(5, ...),
			knockbackMultiplier = select(6, ...),
			knockbackId = select(7, ...),
			disableDamageHighlight = select(13, ...)
		}
		markKnockback(damageTable)
		reportProjectileHit(damageTable)
		vapeEvents.EntityDamageEvent:Fire(damageTable)
	end))

	local swordSwing = bedwars.SyncEvents.SwordSwing:setPriority(500):connect(function(event)
		if store.swordSpeeds and event.swordType and typeof(event.attackSpeed) == 'number' then
			store.swordSpeeds[event.swordType] = event.attackSpeed
		end
	end)
	vape:Clean(function()
		swordSwing:Destroy()
	end)

	vape:Clean(bedwars.SyncEvents.ProjectileLaunched:connect(function(event)
		if typeof(event.origin) ~= 'Vector3' or typeof(event.launchVelocity) ~= 'Vector3' then return end
		if event.shooter == lplr.Character then return end
		scanProjectile(event.origin, event.launchVelocity, event.projectileType, event.shooter)
	end))

	vape:Clean(bedwars.ZapNetworking.BreakBlockEventZap.On(function(...)
		local data = {
			blockRef = {
				blockPosition = ...,
			},
			player = select(5, ...)
		}
		local broken = breakroutes[data.blockRef.blockPosition * 3]
		if broken then
			table.clear(broken.nodes)
			table.clear(broken.chain)
			table.clear(broken.costs)
			breakroutes[data.blockRef.blockPosition * 3] = nil
		end
		vapeEvents.BreakBlockEvent:Fire(data)
	end))

	store.blocks = collection('block', vape)
	store.shop = collection({'BedwarsItemShop', 'TeamUpgradeShopkeeper'}, vape, function(tab, obj)
		table.insert(tab, {
			Id = obj.Name,
			RootPart = obj,
			Shop = obj:HasTag('BedwarsItemShop'),
			Upgrades = obj:HasTag('TeamUpgradeShopkeeper')
		})
	end)
	store.enchant = collection({'enchant-table', 'broken-enchant-table'}, vape, nil, function(tab, obj, tag)
		if obj:HasTag('enchant-table') and tag == 'broken-enchant-table' then return end
		obj = table.find(tab, obj)
		if obj then
			table.remove(tab, obj)
		end
	end)

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	local mapname = 'Unknown'
	sessioninfo:AddItem('Map', 0, function()
		return mapname
	end, false)

	task.delay(1, function()
		games:Increment()
	end)

	task.spawn(function()
		pcall(function()
			repeat task.wait() until store.matchState ~= 0 or vape.Loaded == nil
			if vape.Loaded == nil then return end
			local map = workspace:WaitForChild('Map', 9e9):WaitForChild('Worlds', 9e9):GetChildren()[1]
			mapname = map.Name
			mapname = string.gsub(string.split(mapname, '_')[2] or mapname, '-', '') or 'Blank'
			store.map = map
			vape:Clean(map.Blocks.ChildAdded:Connect(function(v)
				task.defer(function()
					if v:IsA('BasePart') and v:GetAttribute('Block') and (v:GetAttribute('PlacedByUserId') or 0) ~= 0 then
						local pos = v.Position / 3
						vapeEvents.PlaceBlockEvent:Fire({
							blockRef = {blockPosition = Vector3.new(math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))},
							player = playersService:GetPlayerByUserId(v:GetAttribute('PlacedByUserId'))
						})
					end
				end)
			end))
		end)
	end)

	vape:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
		if bedTable.player and bedTable.player.UserId == lplr.UserId then
			beds:Increment()
		end
	end))

	vape:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(winTable)
		if (bedwars.Store:getState().Game.myTeam or {}).id == winTable.winningTeamId or lplr.Neutral then
			wins:Increment()
		end
	end))

	vape:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
		local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
		local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
		if not killed or not killer then return end

		if killed ~= lplr and killer == lplr then
			kills:Increment()
		end
	end))

	task.spawn(function()
		repeat task.wait() until store.map or vape.Loaded == nil
		if vape.Loaded == nil then return end
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Include
		rayParams.FilterDescendantsInstances = {store.map}
		store.airRay = rayParams

		repeat
			if entitylib.isAlive then
				entitylib.character.AirTime = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and tick() or entitylib.character.AirTime
			end

			for _, v in entitylib.List do
				v.LandTick = math.abs(v.RootPart.Velocity.Y) < 0.1 and v.LandTick or tick()
				if (tick() - v.LandTick) > 0.2 and v.Jumps ~= 0 then
					v.Jumps = 0
					v.Jumping = false
				end

				local velocity = v.RootPart.AssemblyLinearVelocity
				local moving = velocity.Magnitude > 1
				if (tick() - (v.TrackTick or 0)) >= (moving and 1 / 30 or 0.2) then
					v.TrackTick = tick()
					prediction.Observe(v.RootPart, v.RootPart.Position, velocity, v.Humanoid.FloorMaterial == Enum.Material.Air or math.abs(velocity.Y) > 0.01, workspace.Gravity, moving and entitylib.isAlive and entitylib.character.RootPart.Position or nil, v.HipHeight, v.Jumping and 42.6 or nil)
				end
			end
			task.wait()
		until vape.Loaded == nil
	end)

	pcall(function()
		if getthreadidentity and setthreadidentity then
			local old = getthreadidentity()
			setthreadidentity(2)

			bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
			bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
			bedwars.Shop.getShopItem('iron_sword', lplr)

			setthreadidentity(old)
			store.shopLoaded = true
		else
			task.spawn(function()
				repeat
					task.wait(0.1)
				until vape.Loaded == nil or bedwars.AppController:isAppOpen('BedwarsItemShopApp')

				bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
				bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
				store.shopLoaded = true
			end)
		end
	end)

	vape:Clean(function()
		task.wait(1)
		Client.Get = OldGet
		bedwars.BlockBreaker.hitBlock = OldHit
		bedwars.BlockController.isBlockBreakable = OldBreak
		store.blockPlacer:disable()
		for _, v in vapeEvents do
			v:Destroy()
		end
		for _, v in breakroutes do
			table.clear(v.nodes)
			table.clear(v.chain)
			table.clear(v.costs)
			table.clear(v)
		end
		table.clear(store.blockPlacer)
		table.clear(vapeEvents)
		table.clear(bedwars)
		table.clear(store)
		table.clear(breakroutes)
		table.clear(sides)
		table.clear(remotes)
		storeChanged:disconnect()
		storeChanged = nil
	end)
end)
