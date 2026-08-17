local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://api.catvape.dev/download/src/'..select(1, path:gsub('catsixextra/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func)
	xpcall(func, warn)
end
local cloneref = cloneref or function(obj)
	return obj
end
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})
getgenv().vapeEvents = vapeEvents

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local proximityPromptService = cloneref(game:GetService('ProximityPromptService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))

local isnetworkowner = isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

for _, name in {'markKnockback', 'reportHit', 'trackShot', 'expectKnockback'} do
	prediction[name] = prediction[name] or function() end
end

local rankCache = {}
local store = {
	attackReach = 0,
	lastAttack = 0,
	lastHit = 0,
	attackReachUpdate = tick(),
	damageBlockFail = tick(),
	hand = {},
	swordSpeeds = {},
	inventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	rank = setmetatable({}, {
		__index = function(self, index)
			return {async = function()
				if rankCache[index] then
					return rankCache[index]
				end

				if index then
					local rank = bedwars.Handler:Get('FetchRanks'):Fire('CallServer', {index.UserId})
					if typeof(rank) == 'table' and rank[1] and rank[1].rankDivision then
						rankCache[index] = rank[1].rankDivision
						return rankCache[index]
					end
				end

				return nil
			end}
		end
	}),
	inventories = {},
	matchState = 0,
	queueType = 'bedwars_test',
	tools = {},
	ping = {}
}
local Reach = {}
local HitBoxes = {}
local InfiniteFly = {}
local TrapDisabler
local AntiFallPart
local bedwars, remotes, sides, oldinvrender, oldSwing = {}, {}, {}

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('catsixextra/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

local function collection(tags, module, customadd, customremove)
	tags = typeof(tags) ~= 'table' and {tags} or tags
	local objs, connections = {}, {}

	for _, tag in tags do
		table.insert(connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			if customadd then
				customadd(objs, v, tag)
				return
			end
			table.insert(objs, v)
		end))
		table.insert(connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if customremove then
				customremove(objs, v, tag)
				return
			end
			v = table.find(objs, v)
			if v then
				table.remove(objs, v)
			end
		end))

		for _, v in collectionService:GetTagged(tag) do
			if customadd then
				customadd(objs, v, tag)
				continue
			end
			table.insert(objs, v)
		end
	end

	local function cleanFunc(self)
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
		table.clear(objs)
		table.clear(self)
	end
	if module then
		module:Clean(cleanFunc)
	end
	return objs, cleanFunc
end
getgenv().collection = collection

local function getBestArmor(slot)
	local closest, mag = nil, 0

	for _, item in store.inventory.inventory.items do
		local meta = item and bedwars.ItemMeta[item.itemType] or {}

		if meta.armor and meta.armor.slot == slot then
			local newmag = (meta.armor.damageReductionMultiplier or 0)

			if newmag > mag then
				closest, mag = item, newmag
			end
		end
	end

	return closest
end
getgenv().getBestArmor = getBestArmor

local function getBow()
	local bestBow, bestBowSlot, bestBowDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local bowMeta = bedwars.ItemMeta[item.itemType].projectileSource
		if bowMeta and table.find(bowMeta.ammoItemTypes, 'arrow') then
			local bowDamage = bedwars.ProjectileMeta[bowMeta.projectileType('arrow')].combat.damage or 0
			if bowDamage > bestBowDamage then
				bestBow, bestBowSlot, bestBowDamage = item, slot, bowDamage
			end
		end
	end
	return bestBow, bestBowSlot
end
getgenv().getBow = getBow

local function normalizeName(text)
	return (tostring(text):lower():gsub('[_%s]+', ' '))
end

local function matchesList(list, names)
	for _, entry in list do
		local needle = normalizeName(entry)
		if #needle > 0 then
			for _, name in names do
				if name then
					name = normalizeName(name)
					if name == needle or (' '..name):find(' '..needle, 1, true) then
						return true
					end
				end
			end
		end
	end
	return false
end

local function getMageSource(itemType)
	if itemType ~= 'wizard_stick' then return nil end

	local util = bedwars.MageKitUtil
	local elements = util and util.MageElementMeta
	if not elements then return nil end

	local chosen = elements.BASE
	local suc, unlocked = pcall(util.getUnlockedMageElements, lplr)
	if suc and type(unlocked) == 'table' then
		for key, value in unlocked do
			local element = elements[value] or elements[key]
			if element and element.projectileSource then
				chosen = element
			end
		end
	end

	return chosen and chosen.projectileSource
end

local sophiaStaffs = {'frost_staff_3', 'frost_staff_2', 'frost_staff_1'}
local nextSophiaSwap = 0

local function getSophiaSource(itemType)
	if not table.find(sophiaStaffs, itemType) then return nil end

	local controller = bedwars.FrostyGunController
	if not controller then return nil end

	if controller.projectileMode ~= bedwars.FrostyGunMode.PROJECTILE then
		if tick() >= nextSophiaSwap and bedwars.AbilityController:canUseAbility('frosty_gun_swap', {disableBlockedAbilityAlert = true}) then
			nextSophiaSwap = tick() + 1
			bedwars.AbilityController:useAbility('frosty_gun_swap')
		end
		return nil
	end

	local meta = bedwars.ItemMeta[itemType]
	return meta and meta.projectileSource or nil
end

local function getWhimSource(itemType)
	if itemType ~= 'mage_spellbook' then return nil end

	local util = bedwars.MageKitUtil
	local elements = util and util.MageElementMeta
	if not elements then return nil end

	local element = bedwars.BalanceFile.MAGE_ELEMENT_CYCLE[(lplr:GetAttribute('MageElementIndex') or 0) + 1]
	local suc, unlocked = pcall(util.getUnlockedMageElements, lplr)
	if not element or not suc or type(unlocked) ~= 'table' or table.find(unlocked, element) == nil then
		element = 'BASE'
	end

	local meta = elements[element]
	return meta and meta.projectileSource or nil
end

local function getProjectiles(whitelist, sophia, whim)
	local items = {}

	for _, item in store.inventory.inventory.items do
		local meta = bedwars.ItemMeta[item.itemType]
		local kit = (sophia and getSophiaSource(item.itemType)) or (whim and getWhimSource(item.itemType)) or nil
		local proj = kit or (meta and (meta.projectileSource or getMageSource(item.itemType)))
		if proj then
			local ammo
			if proj.ammoItemTypes and #proj.ammoItemTypes > 0 then
				for _, other in store.inventory.inventory.items do
					if table.find(proj.ammoItemTypes, other.itemType) then
						ammo = other.itemType
						break
					end
				end
			else
				ammo = item.itemType
			end

			if ammo and (kit or not whitelist or matchesList(whitelist, {ammo, item.itemType, meta.displayName})) then
				table.insert(items, {
					item,
					ammo,
					proj.projectileType(ammo),
					proj
				})
			end
		end
	end

	return items
end
getgenv().getProjectiles = getProjectiles

local function getFacingEntity(entitysettings)
	if not entitylib.isAlive then
		return nil
	end

	local rootpart = entitylib.character.RootPart
	local origin = entitysettings.Origin or rootpart.Position
	local facing = rootpart.CFrame.LookVector * Vector3.new(1, 0, 1)
	local cone = math.rad((entitysettings.Angle or 120) / 2)
	entitysettings.Angle = nil
	entitysettings.Origin = origin

	for _, entity in entitylib.AllPosition(entitysettings) do
		local delta = (entity.RootPart.Position - origin) * Vector3.new(1, 0, 1)
		if facing.Magnitude == 0 or delta.Magnitude == 0 or math.acos(math.clamp(facing.Unit:Dot(delta.Unit), -1, 1)) <= cone then
			return entity
		end
	end
	return nil
end
getgenv().getFacingEntity = getFacingEntity

local function solveProjectile(origin, speed, gravity, target)
	return prediction.SolveTrajectory(origin, speed, gravity, target.RootPart.Position, target.RootPart.Velocity, workspace.Gravity, target.HipHeight, target.Jumping and 42.6 or nil, nil, target.Humanoid.FloorMaterial == Enum.Material.Air or math.abs(target.RootPart.Velocity.Y) > 0.01, target.RootPart.Position, target.RootPart, nil, true)
end

local function fireProjectile(item, ammo, projectile, target)
	local meta = bedwars.ProjectileMeta[projectile]
	if not meta then return false end

	local origin = entitylib.character.RootPart.Position
	local speed, gravity = meta.launchVelocity, meta.gravitationalAcceleration or 196.2
	local calc = solveProjectile(origin, speed, gravity, target)
	if not calc then return false end

	local shootPosition = (CFrame.new(origin, calc) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).Position
	local aim = solveProjectile(shootPosition, speed, gravity, target) or calc
	local velocity, id = CFrame.lookAt(shootPosition, aim).LookVector * speed, httpService:GenerateGUID(true)
	bedwars.Handler:Get('ProjectileFire'):Fire('CallServerAsync',
		item.tool,
		ammo,
		projectile,
		shootPosition,
		origin,
		velocity,
		id,
		{
			drawDurationSeconds = 1,
			shotId = httpService:GenerateGUID(false)
		},
		workspace:GetServerTimeNow() - 0.045
	):andThen(function(res)
		if res then
			res.Parent = replicatedStorage
		end
	end)
	prediction.trackShot(target.RootPart)
	return true
end
getgenv().fireProjectile = fireProjectile

local function getItem(itemName, inv, find)
	for slot, item in (inv or store.inventory.inventory.items) do
		if item.itemType == itemName or (find and item.itemType:find(itemName)) then
			return item, slot
		end
	end
	return nil
end
getgenv().getItem = getItem

local function getRoactRender(func)
	return debug.getupvalue(debug.getupvalue(debug.getupvalue(func, 3).render, 2).render, 1)
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage, bestSwordRange = nil, nil, -1, -1
	for slot, item in store.inventory.inventory.items do
		local itemMeta = bedwars.ItemMeta[item.itemType]
		local swordMeta = itemMeta and itemMeta.sword or nil
		if swordMeta then
			local swordDamage = swordMeta.damage or 0
			local swordRange = swordMeta.attackRange or store.swordDistance or 0
			if swordDamage > bestSwordDamage or (swordDamage == bestSwordDamage and swordRange > bestSwordRange) then
				bestSword, bestSwordSlot, bestSwordDamage, bestSwordRange = item, slot, swordDamage, swordRange
			end
		end
	end
	return bestSword, bestSwordSlot
end
getgenv().getSword = getSword

local function getTool(breakType)
	local bestTool, bestToolSlot, bestToolDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local toolMeta = bedwars.ItemMeta[item.itemType].breakBlock
		if toolMeta then
			local toolDamage = toolMeta[breakType] or 0
			if toolDamage > bestToolDamage then
				bestTool, bestToolSlot, bestToolDamage = item, slot, toolDamage
			end
		end
	end
	return bestTool, bestToolSlot
end
getgenv().getTool = getTool

local function getWool()
	for _, wool in (inv or store.inventory.inventory.items) do
		if wool.itemType:find('wool') then
			return wool and wool.itemType, wool and wool.amount
		end
	end
end
getgenv().getWool = getWool

local function getStrength(plr)
	if not plr.Player then
		return 0
	end

	local strength = 0
	for _, v in (store.inventories[plr.Player] or {items = {}}).items do
		local itemmeta = bedwars.ItemMeta[v.itemType]
		if itemmeta and itemmeta.sword and itemmeta.sword.damage > strength then
			strength = itemmeta.sword.damage
		end
	end

	return strength
end
getgenv().getStrength = getStrength

local function isCasting()
	local casting = lplr:GetAttribute('IsCasting')
	return casting and casting ~= 0 and casting ~= ''
end
getgenv().isCasting = isCasting

local function canSwing()
	if bedwars.SwordController:getSwordSwingDisabled() or isCasting() then
		return false
	end

	local itemmeta = store.hand.tool and bedwars.ItemMeta[store.hand.tool.Name]
	return itemmeta and itemmeta.sword ~= nil and itemmeta.sword.chargedAttack == nil
end
getgenv().canSwing = canSwing

local function canPlace()
	return not bedwars.BlockPlacementController.disabled and not isCasting()
end
getgenv().canPlace = canPlace

local function getReach(tool)
	local itemmeta = tool and bedwars.ItemMeta[tool.Name]
	return itemmeta and itemmeta.sword and itemmeta.sword.attackRange or store.swordDistance
end
getgenv().getReach = getReach

local function getSwordSpeed(tool)
	local itemmeta = tool and bedwars.ItemMeta[tool.Name]
	return store.swordSpeeds[tool and tool.Name] or (itemmeta and itemmeta.sword and itemmeta.sword.attackSpeed) or 0.3
end
getgenv().getSwordSpeed = getSwordSpeed

local function getPlacedBlock(pos)
	if not pos then
		return
	end
	local roundedPosition = bedwars.BlockController:getBlockPosition(pos)
	return bedwars.BlockController:getStore():getBlockAt(roundedPosition), roundedPosition
end
getgenv().getPlacedBlock = getPlacedBlock

local function getBlocksInPoints(s, e)
	local blocks, list = bedwars.BlockController:getStore(), {}
	for x = s.X, e.X do
		for y = s.Y, e.Y do
			for z = s.Z, e.Z do
				local vec = Vector3.new(x, y, z)
				if blocks:getBlockAt(vec) then
					table.insert(list, vec * 3)
				end
			end
		end
	end
	return list
end
getgenv().getBlocksInPoints = getBlocksInPoints

local function getNearGround(range)
	range = Vector3.new(3, 3, 3) * (range or 10)
	local localPosition, mag, closest = entitylib.character.RootPart.Position, 60
	local blocks = getBlocksInPoints(bedwars.BlockController:getBlockPosition(localPosition - range), bedwars.BlockController:getBlockPosition(localPosition + range))

	for _, v in blocks do
		if not getPlacedBlock(v + Vector3.new(0, 3, 0)) then
			local newmag = (localPosition - v).Magnitude
			if newmag < mag then
				mag, closest = newmag, v + Vector3.new(0, 3, 0)
			end
		end
	end

	table.clear(blocks)
	return closest
end
getgenv().getNearGround = getNearGround

local function getShieldAttribute(char)
	local returned = 0
	for name, val in char:GetAttributes() do
		if name:find('Shield') and type(val) == 'number' and val > 0 then
			returned += val
		end
	end
	return returned
end
getgenv().getShieldAttribute = getShieldAttribute

local function markKnockback(damageTable)
	local char = damageTable.entityInstance
	local multiplier = damageTable.knockbackMultiplier
	if typeof(char) ~= 'Instance' or (multiplier and multiplier.disabled) then return end

	local root = char:IsA('Model') and char.PrimaryPart or char:IsA('BasePart') and char or nil
	local from = damageTable.fromPosition
	local impulse
	if root and from then
		local direction = bedwars.KnockbackUtil.getDirection(root.Position, from)
		if direction.Magnitude > 0 then
			impulse = bedwars.KnockbackUtil.calculateKnockbackVelocity(direction, 1, multiplier)
		end
	end

	prediction.markKnockback(char, multiplier, impulse)
end

local function expectKnockback(root, flight, from, multiplier)
	if typeof(root) ~= 'Instance' or not flight or not from then return end
	if multiplier and multiplier.disabled then return end

	local direction = bedwars.KnockbackUtil.getDirection(root.Position, from)
	if direction.Magnitude <= 0 then return end

	prediction.expectKnockback(root, workspace:GetServerTimeNow() + flight, bedwars.KnockbackUtil.calculateKnockbackVelocity(direction, 1, multiplier), multiplier)
end
getgenv().expectKnockback = expectKnockback

local function scanProjectile(origin, velocity, projectileType, shooter)
	if not entitylib.isAlive then return end

	local meta = bedwars.ProjectileMeta[projectileType]
	local drop = Vector3.new(0, -(meta and meta.gravitationalAcceleration or 196.2), 0)

	for _, v in entitylib.List do
		if v.Character == shooter then continue end

		local root, hit = v.RootPart
		local rootVelocity = root.AssemblyLinearVelocity
		for step = 1, 40 do
			local flight = step * 0.05
			local point = origin + velocity * flight + drop * (0.5 * flight * flight)
			if (point - (root.Position + rootVelocity * flight)).Magnitude <= v.HipHeight then
				hit = flight
				break
			end
		end

		if hit then
			expectKnockback(root, hit, origin, meta and meta.knockback)
		end
	end
end
getgenv().scanProjectile = scanProjectile

local function reportProjectileHit(damageTable)
	local char = damageTable.entityInstance
	local from = damageTable.fromEntity
	if (from ~= lplr.Character and from ~= lplr) or typeof(char) ~= 'Instance' then return end

	local root = char:IsA('Model') and char.PrimaryPart or char:IsA('BasePart') and char or nil
	if root then
		prediction.reportHit(root)
	end
end

local knockbackSpeed, knockbackBoost = 0, tick()
local function getSpeed()
	local multi, increase, modifiers = 0, true, bedwars.SprintController:getMovementStatusModifier():getModifiers()

	for v in modifiers do
		local val = v.constantSpeedMultiplier and v.constantSpeedMultiplier or 0
		if val and val > math.max(multi, 1) then
			increase = false
			multi = val - (0.06 * math.round(val))
		end
	end

	for v in modifiers do
		multi += math.max((v.moveSpeedMultiplier or 0) - 1, 0)
	end

	if multi > 0 and increase then
		multi += 0.16 + (0.02 * math.round(multi))
	end

	return (20 + (knockbackBoost > tick() and knockbackSpeed or 0)) * (multi + 1)
end
getgenv().getSpeed = getSpeed

local function getTableSize(tab)
	local ind = 0
	for _ in tab do
		ind += 1
	end
	return ind
end
getgenv().getTableSize = getTableSize

local function getHotbar(tool)
	for i, v in (store.inventory.hotbar or {}) do
		if v.item and v.item.tool == tool then
			return i - 1
		end
	end
	return nil
end
getgenv().getHotbar = getHotbar

local function hotbarSwitch(slot)
	if slot and store.inventory.hotbarSlot ~= slot then
		bedwars.Store:dispatch({
			type = 'InventorySelectHotbarSlot',
			slot = slot
		})
		vapeEvents.InventoryChanged.Event:Wait()
		return true
	end
	return false
end
getgenv().hotbarSwitch = hotbarSwitch

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function notif(...) return
	vape:CreateNotification(...)
end
getgenv().notif = notif

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end
getgenv().removeTags = removeTags

local function roundPos(vec)
	return Vector3.new(math.round(vec.X / 3) * 3, math.round(vec.Y / 3) * 3, math.round(vec.Z / 3) * 3)
end
getgenv().roundPos = roundPos

local function switchItem(tool, delayTime)
	delayTime = delayTime or 0.05
	local check = lplr.Character and lplr.Character:FindFirstChild('HandInvItem') or nil
	if check and check.Value ~= tool and tool.Parent ~= nil then
		task.spawn(function()
			bedwars.Handler:Get('SetInvItem'):Fire('CallServerAsync', {hand = tool})
		end)
		check.Value = tool
		if delayTime > 0 then
			task.wait(delayTime)
		end
		return true
	end
end
getgenv().switchItem = switchItem

local function waitForChildOfType(obj, name, timeout, prop)
	local check, returned = tick() + timeout
	repeat
		returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
		if returned and returned.Name ~= 'UpperTorso' or check < tick() then
			break
		end
		task.wait()
	until false
	return returned
end

local frictionTable, oldfrict = {}, {}
local frictionConnection
local frictionState

local function modifyVelocity(v)
	if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
		oldfrict[v] = v.CustomPhysicalProperties or 'none'
		v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
	end
end

local function updateVelocity(force)
	local newState = getTableSize(frictionTable) > 0
	if frictionState ~= newState or force then
		if frictionConnection then
			frictionConnection:Disconnect()
		end
		if newState then
			if entitylib.isAlive then
				for _, v in entitylib.character.Character:GetDescendants() do
					modifyVelocity(v)
				end
				frictionConnection = entitylib.character.Character.DescendantAdded:Connect(modifyVelocity)
			end
		else
			for i, v in oldfrict do
				i.CustomPhysicalProperties = v ~= 'none' and v or nil
			end
			table.clear(oldfrict)
		end
	end
	frictionState = newState
end

local kitorder = {
	hannah = 5,
	spirit_assassin = 4,
	dasher = 3,
	jade = 2,
	regent = 1
}

local sortmethods = {
	Damage = function(a, b)
		return a.Entity.Character:GetAttribute('LastDamageTakenTime') < b.Entity.Character:GetAttribute('LastDamageTakenTime')
	end,
	Threat = function(a, b)
		return getStrength(a.Entity) > getStrength(b.Entity)
	end,
	Kit = function(a, b)
		return (a.Entity.Player and kitorder[a.Entity.Player:GetAttribute('PlayingAsKits')] or 0) > (b.Entity.Player and kitorder[b.Entity.Player:GetAttribute('PlayingAsKits')] or 0)
	end,
	Health = function(a, b)
		return a.Entity.Health < b.Entity.Health
	end,
	Angle = function(a, b)
		local selfrootpos = entitylib.character.RootPart.Position
		local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
		local direction = (a.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)
		local direction2 = (b.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)
		local angle = direction.Magnitude > 0 and math.acos(math.clamp(localfacing:Dot(direction.Unit), -1, 1)) or 0
		local angle2 = direction2.Magnitude > 0 and math.acos(math.clamp(localfacing:Dot(direction2.Unit), -1, 1)) or 0
		return angle < angle2
	end,
	Mouse = function(a, b)
		local mouse = lplr:GetMouse()
		local origin = Vector2.new(mouse.X, mouse.Y)

		local posa, visa = gameCamera:WorldToScreenPoint(a.Entity.RootPart.Position)
		local posb, visb = gameCamera:WorldToScreenPoint(b.Entity.RootPart.Position)
		local dista = visa and (Vector2.new(posa.X, posa.Y) - origin).Magnitude or math.huge
		local distb = visb and (Vector2.new(posb.X, posb.Y) - origin).Magnitude or math.huge
		return (dista == dista and dista or math.huge) < (distb == distb and distb or math.huge)
	end
}
getgenv().sortmethods = sortmethods
local getBlockHits
local function getBlockDistance(a)
	local pos = (entitylib.isAlive and (entitylib.character.RootPart.Position - Vector3.new(0, 1, 0)) or Vector3.zero)
	return (pos - Vector3.new(a.Position.X, pos.Y, a.Position.Z)).Magnitude
end

local breakmethods = {
	Health = function(a, b)
		return getBlockHits(a, b)
	end,
	Distance = function(a, b)
		return getBlockDistance(a) + getBlockHits(a, b) * 0.01
	end
}

