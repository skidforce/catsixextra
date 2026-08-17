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
	func()
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

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local replicatedFirst = cloneref(game:GetService('ReplicatedFirst'))
local collectionService = cloneref(game:GetService('CollectionService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local runService = cloneref(game:GetService('RunService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local whitelist = vape.Libraries.whitelist
local drawingactor = loadstring(downloadFile('catsixextra/libraries/drawing.lua'), 'drawing')(...)
local redline = {Teams = {}}
local starttime = os.clock()
local TargetStrafeVector
local latestHash = 'c401462bc7f7f49e53b4a8da2de5b57bc2d7e14df1b773e5ccd1bcddb28db9c843b8902d2c93738a2f042e533d3d4971'
local redline_boxes = {
	{
		boxtype = 'redliner_melee',
		data = {
			size = Vector3.new(17.75, 14, 22),
			offset = CFrame.new(0, 0, -11)
		}
	},
	{
		boxtype = 'redliner_charged_melee',
		data = {
			size = Vector3.new(39, 14, 35),
			offset = CFrame.new(0, -0.5, -9)
		}
	}
}

local function addVelocity(velo)
	if redline[redline.MoveController] and typeof(redline[redline.MoveController][redline.LaunchpadFunction]) == 'function' then
		local pad = Instance.new('Model')
		local origin = Instance.new('Part')
		origin.Name = 'Origin'
		origin.CFrame = CFrame.new(100, 100, 100)
		origin.Parent = pad
		local goal = Instance.new('Part')
		goal.Name = 'LaunchGoal'
		goal.CFrame = CFrame.new(100, 100, 100) + (velo.Unit == velo.Unit and velo.Unit or Vector3.zero)
		goal.Parent = pad
		redline[redline.MoveController][redline.LaunchpadFunction](redline[redline.MoveController], pad, {
			base_strength = velo.Magnitude,
			max_strength = velo.Magnitude
		})

		pad:Destroy()
		pad:ClearAllChildren()
	end
end

local function castHitbox(data, origin)
	local hit_hurtboxes = {}
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.RespectCanCollide = false
	params.FilterDescendantsInstances = collectionService:GetTagged('Hurtbox')

	for _, v in params.FilterDescendantsInstances do
		v.Transparency = 0
	end

	for _, hit in workspace:GetPartBoundsInBox(origin * data.offset, data.size, params) do
		if hit:FindFirstAncestorWhichIsA('Model') ~= lplr.Character then
			table.insert(hit_hurtboxes, hit)
		end
	end

	return hit_hurtboxes
end

local function searchForPacket(func, unreliable)
	for _, v in debug.getconstants(func) do
		if rawget(unreliable and redline.Packets.unreliablePackets or redline.Packets, v) then
			return v
		end
	end
end

local function getIndicators()
	return redline[redline.IndicatorController] and redline[redline.IndicatorController][redline.IndicatorTable] or {}
end

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

local function notif(...)
	return vape:CreateNotification(...)
end

local function warningRoutine(hash)
	local path = 'catsixextra/profiles/agreementhash.txt'
	if (isfile(path) and readfile(path) or '') ~= hash then
		local box = Instance.new('TextLabel')
		box.Size = UDim2.fromScale(1, 1)
		box.BackgroundColor3 = Color3.new()
		box.BackgroundTransparency = 0.5
		box.Text = '!WARNING!\nThe game\'s update hash is not the same as the current script hash, this !MAY! mean the game developer has added detections.\nBy clicking OK, you agree to all risks of using this product.\n\n- 7GrandDad'
		box.TextColor3 = Color3.new(1, 1, 1)
		box.TextScaled = true
		box.Font = Enum.Font.Arial
		box.Parent = vape.gui
		local button = Instance.new('TextButton')
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Size = UDim2.fromScale(0.2, 0.05)
		button.Position = UDim2.fromScale(0.5, 0.95)
		button.BackgroundColor3 = Color3.new()
		button.Text = 'OK'
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.Arial
		button.Parent = box

		button.MouseButton1Click:Connect(function()
			writefile(path, hash)
			box:Destroy()
		end)

		box.Destroying:Wait()
	end
end

if not select(1, ...) then
	if run_on_actor then
		local oldreload = shared.vapereload
		vape.Load = function()
			task.delay(0.1, function()
				vape:Uninject()
			end)
		end

		task.spawn(function()
			repeat task.wait() until not shared.vape
			local executionString = "loadfile('catsixextra/main.lua')("..drawingactor..")"
			for i, v in shared do
				if type(v) == 'string' then
					executionString = string.format("shared.%s = '%s'", i, v)..'\n'..executionString
				elseif type(v) == 'boolean' then
					executionString = string.format("shared.%s = %s", i, tostring(v))..'\n'..executionString
				end
			end
			if oldreload then
				executionString = 'shared.vapereload = true\n'..executionString
			end

			if getactorthreads and run_on_thread then
				for _, v in getactorthreads() do
					run_on_thread(v, executionString)
					return
				end
			elseif getactorstates then
				for _, v in getactorstates() do
					if type(v) ~= 'thread' then
						v:Execute(executionString)
						return
					end
				end
			end

			for _, v in (getdeletedactors or getactors)() do
				run_on_actor(v, executionString)
				return
			end

			lplr:Kick('Failed to find actor, Executor: '..identifyexecutor())
		end)
	else
		vape.Load = function()
			notif('Vape', 'Missing actor functions.', 10, 'alert')
		end
	end

	return
end

