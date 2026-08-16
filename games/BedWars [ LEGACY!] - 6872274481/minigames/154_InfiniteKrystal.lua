
run(function()
	local old
	
	vape.Categories.Minigames:CreateModule({
		Name = 'InfiniteKrystal',
		Function = function(call)
			if call then
				old = bedwars.GlacialSkaterController.updateMomentum
				bedwars.GlacialSkaterController.updateMomentum = function(self, ...)
					self.momentum = 1000
					self.lastMomentumReport = workspace:GetServerTimeNow()
					return old(self, ...)
				end
			else
				bedwars.GlacialSkaterController.updateMomentum = old
			end
		end,
		Tooltip = 'Gives you max momentum forever'
	})
end)
