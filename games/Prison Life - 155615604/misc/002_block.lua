
local CheatFlags = {Flags = {}, Flagged = {}}
run(function()
	function CheatFlags:Flag(plr, flagtype, limit)
		if CheatFlags.Flagged[plr.UserId] then
			return
		end

		if not CheatFlags.Flags[plr.UserId] then
			CheatFlags.Flags[plr.UserId] = {}
		end

		local flags = CheatFlags.Flags[plr.UserId]
		flags[flagtype] = (flags[flagtype] or 0) + 1

		if flags[flagtype] > limit then
			CheatFlags.Flagged[plr.UserId] = true
			vapeEvents.CheatFlagged:Fire(plr, flagtype)
		end
	end

	function CheatFlags:Clear()
		table.clear(CheatFlags.Flags)
		table.clear(CheatFlags.Flagged)
	end
end)
