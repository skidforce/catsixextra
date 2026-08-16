
for _, v in {'Reach', 'TriggerBot', 'Disabler', 'AntiFall', 'HitBoxes', 'Killaura', 'MurderMystery'} do
	vape:Remove(v)
end

run(function()
	local ForceHeadshot
	
	ForceHeadshot = vape.Categories.Combat:CreateModule({
		Name = 'ForceHeadshot',
		Function = function(callback)
			if callback then
				local hook
				hook = hookfunction(jb.GunController.BulletEmitterOnLocalHitPlayer, function(...)
					local shotData = select(15, ...)
					shotData.isHeadshot = true
					return hook(...)
				end)
			else
				restorefunction(jb.GunController.BulletEmitterOnLocalHitPlayer)
			end
		end,
		Tooltip = 'Modifies bullets to always do headshot damage.'
	})
end)
