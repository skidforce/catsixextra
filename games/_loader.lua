local isfile = isfile or function(f)
	local suc, res = pcall(function() return readfile(f) end)
	return suc and res ~= nil and res ~= ''
end
local vape = shared.vape
local license = ...
local function findFolder(placeId)
	if not isfile('catsixextra/games/_manifest.tsv') then return nil end
	local data = readfile('catsixextra/games/_manifest.tsv')
	for line in (data .. '\n'):gmatch('([^\r\n]+)\r?\n') do
		local id, folder = line:match('^(%d+)	(.+)$')
		if id == tostring(placeId) then return folder end
	end
	local ok, info = pcall(function() return game:GetService('MarketplaceService'):GetProductInfo(placeId) end)
	if ok and info and type(info.Name) == 'string' then
		for line in (data .. '\n'):gmatch('([^\r\n]+)\r?\n') do
			local id, folder = line:match('^(%d+)	(.+)$')
			if folder and folder:find(info.Name, 1, true) == 1 then return folder end
		end
		for line in (data .. '\n'):gmatch('([^\r\n]+)\r?\n') do
			local id, folder = line:match('^(%d+)	(.+)$')
			if folder and folder:find(info.Name, 1, true) then return folder end
		end
	end
end
local function loadGame(folder, chunkName)
	local path = 'catsixextra/games/' .. folder .. '/main.lua'
	if not isfile(path) then return nil end
	local fn, err = loadstring(readfile(path), chunkName)
	if not fn then warn('[catsixextra] failed to compile ' .. chunkName .. ': ' .. tostring(err)) end
	return fn
end
local folder = findFolder(game.PlaceId)
local uni = loadGame('Universal - 0', 'universal')
if uni then uni(license) end
if folder then
	local fn = loadGame(folder, tostring(game.PlaceId))
	if fn then fn(license) else warn('[catsixextra] no game script for ' .. tostring(game.PlaceId) .. ' (' .. folder .. ')') end
end
