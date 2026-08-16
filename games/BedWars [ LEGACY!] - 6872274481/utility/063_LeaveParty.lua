
run(function()
	local LeaveParty; LeaveParty = vape.Categories.Utility:CreateModule({
		Name = 'LeaveParty',
		Function = function(callback)
			if callback then
				bedwars.PartyController:leaveParty()
				LeaveParty:Toggle()
			end
		end
	})
end)
