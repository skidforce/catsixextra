run(function()
	local charscript = lplr.PlayerScripts.CharacterController
	local env = getsenv(charscript)
	if not (env and env.startHit) then
		repeat
			env = getsenv(charscript)
			task.wait()
		until env and env.startHit or vape.Loaded == nil

		if vape.Loaded == nil then return end
	end

	arena = {
		Client = getsenv(charscript),
		PlayerState = require(charscript.PlayerState),
		Inventory = require(charscript.Inventory),
		MoveController = require(lplr.PlayerScripts.PlayerModule):GetControls(),
		SwingFunction = debug.getupvalue(getsenv(charscript).startHit, 1)
	}

	for _, v in getconnections(runService.Heartbeat) do
		if v.Function and islclosure(v.Function) and debug.getconstants(v.Function)[1] == 0.05 then
			-- screw mobile exploits, I only have to add this check because none of these pastesploits can implement a *proper* task scheduler for script execution, what a joke.
			arena.TickFunction = debug.getupvalue(v.Function, 3)
		end
	end

	for _, v in getconnections(replicatedStorage.Remotes.LoadLocalCharacter.OnClientEvent) do
		if v.Function then
			arena.MoveFunction = debug.getupvalue(v.Function, 9)
		end
	end

	vape:Clean(function()
		table.clear(arena)
	end)
end)
