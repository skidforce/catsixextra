entitylib.start()

local require, debug, cheatenginelib = require, debug, nil
run(function()
	getgenv().canDebug = not table.find({'Solara', 'Xeno'}, ({identifyexecutor()})[1]) and true or false
	if not canDebug then
		cheatenginelib = loadstring(downloadFile('catsix/libraries/cheatengine.lua'), 'cheatengine')(vape, vapeEvents, entitylib)
		require = function(v) 
			return cheatenginelib[({v:GetFullName():gsub(lplr.Name, 'PlayerTemplate')})[1]]:await()
		end
		debug = setmetatable({getproto = function() return function() end end}, {
			__index = function(self, index)
				self[index] = function() end
				return self[index]
			end
		})
	end
end)
