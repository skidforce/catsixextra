local isfile = isfile or function(f)
	local suc, res = pcall(function() return readfile(f) end)
	return suc and res ~= nil and res ~= ''
end
local vape = shared.vape
local license = ...
local function findFolder(placeId)
	if not isfile('catsixextra/games/_manifest.tsv') then return nil end
	local data = readfile('catsixextra/games/_manifest.tsv')
for line in (data .. '\n'):gmatch('([^\n]+\n?)') do
		local id, folder = line:match('^(%d+)	(.+)$')
		if id == tostring(placeId) then return folder end
	end
end
local function loadGame(folder, chunkName)
	local path = 'catsixextra/games/' .. folder .. '/main.lua'
	if not isfile(path) then return nil end
	return loadstring(readfile(path), chunkName)
end
local folder = findFolder(game.PlaceId)
local uni = loadGame('Universal - 0', 'universal')
if uni then uni(license) end
if folder then
	local fn = loadGame(folder, tostring(game.PlaceId))
	if fn then fn(license) end
end
