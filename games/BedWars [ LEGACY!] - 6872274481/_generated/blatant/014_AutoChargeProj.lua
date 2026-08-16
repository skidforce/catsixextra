
run(function()
	local AutoChargeProj
	local Percentage

	local old

	AutoChargeProj = vape.Categories.Blatant:CreateModule({
		Name = 'AutoChargeProj',
		Function = function(callback)
			if callback then
				old = bedwars.ProjectileController.calculateImportantLaunchValues
				bedwars.ProjectileController.calculateImportantLaunchValues = function(self, launchdata, ...)
					local projmeta = bedwars.ProjectileMeta[launchdata.projectile]
					if projmeta and projmeta.predictionLifetimeSec and launchdata.drawDurationSeconds then
						launchdata.drawDurationSeconds = math.max(launchdata.drawDurationSeconds, projmeta.predictionLifetimeSec * (Percentage.Value / 100))
						launchdata.velocityMultiplier = math.max(launchdata.velocityMultiplier or 0, Percentage.Value / 100)
					end
					return old(self, launchdata, ...)
				end
			else
				bedwars.ProjectileController.calculateImportantLaunchValues = old
			end
		end,
		Tooltip = 'Instantly charges your projectile item to a certain percentage'
	})
	Percentage = AutoChargeProj:CreateSlider({
		Name = 'Percentage',
		Min = 0,
		Max = 100,
		Default = 50,
		Suffix = '%'
	})
end)
