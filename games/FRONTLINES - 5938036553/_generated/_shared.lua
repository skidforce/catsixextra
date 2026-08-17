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

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local runService = cloneref(game:GetService('RunService'))
local tweenService = cloneref(game:GetService('TweenService'))
local debrisService = cloneref(game:GetService('Debris'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local getcustomasset = vape.Libraries.getcustomasset
local drawingactor = loadstring(downloadFile('catsixextra/libraries/drawing.lua'), 'drawing')(...)
local function notif(...)
	return vape:CreateNotification(...)
end

if not select(1, ...) and game.PlaceId == 5938036553 then
	if run_on_actor and getactors then
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

			for i, v in getactors() do
				if tostring(v) == 'frontlines_client_actor' then
					run_on_actor(v, executionString)
					return
				end
			end
			notif('Vape', 'Failed to find actor', 10, 'alert')
		end)
	else
		vape.Load = function()
			notif('Vape', 'Missing actor functions.', 10, 'alert')
		end
	end

	return
end

local frontlines = {Functions = {}}

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

local function getTeam(ent)
	return frontlines.Main.globals.cli_teams[ent.Id]
end

local function getKey(id, server)
	for i, v in frontlines.Main.enums[(server and 's' or 'c')..'_net_msg'] do
		if v == id then
			return i
		end
	end
end

local function hookEvent(id, rfunc)
	local suc, res = pcall(function()
		local func = frontlines.Events[frontlines.Main.exe_func_t[id]]
		local hook

		local function newFunc(...)
			if rfunc(...) then return end
			return hook(...)
		end

		hook = hookfunction(func, function(...) return newFunc(...) end)
		frontlines.Functions[func] = hook
		return function()
			if not frontlines.Functions[func] then return end
			--restorefunction(func)
			hookfunction(func, frontlines.Functions[func])
			frontlines.Functions[func] = nil
		end
	end)

	if not suc then
		notif('Vape', 'Failed to hook ('..id..')', 10, 'alert')
	end

	return type(res) == 'function' and res or function() end
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

