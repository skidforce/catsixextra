
run(function()
	local OwlAura
	local Targets
	local Mode
	local Range
	
	OwlAura = vape.Categories.Blatant:CreateModule({
		Name = 'OwlAura',
		Function = function(callback)
			if callback then
				local owls = collection('Owl', OwlAura, function(self, obj)
					task.delay(1, function()
						if obj and obj.Parent and obj:GetAttribute('Owner') == lplr.UserId then
							table.insert(self, obj)
						end
					end)
				end)
				repeat
					if store.equippedKit ~= 'owl' then
						task.wait(1)
						continue
					end
	
					if entitylib.isAlive then
						local owl = owls[1]
						if owl then
							local origin = owl.Part.Position
							local plr = entitylib.EntityPosition({
								Origin = origin,
								Range = Range.Value,
								Part = 'RootPart',
								Players = Targets.Players.Enabled,
								NPCs = Targets.NPCs.Enabled,
								Wallcheck = Targets.Walls.Enabled,
								Sort = sortmethods[Mode.Value]
							})
	
							if plr then
								local meta = bedwars.ProjectileMeta.owl_projectile
								local targetVelocity = plr.RootPart.AssemblyLinearVelocity
								local targetAirborne = plr.Humanoid.FloorMaterial == Enum.Material.Air or math.abs(targetVelocity.Y) > 0.01
								local calc, _, travelTime = prediction.SolveTrajectory(origin, meta.launchVelocity, meta.gravitationalAcceleration, plr.RootPart.Position, targetVelocity, workspace.Gravity, plr.HipHeight, plr.Jumping and 42.6 or nil, store.airRay, targetAirborne, plr.RootPart.Position, plr.RootPart, nil, true)
								if calc and travelTime and travelTime <= (meta.lifetimeSec or 3) then
									local dir = CFrame.lookAt(origin, calc).LookVector * meta.launchVelocity
									bedwars.Handler:Get('OwlAiming'):Fire('SendToServer', {
										owl = owl.Part,
										starting = true
									})
									bedwars.Handler:Get('OwlFireProjectile'):Fire('SendToServer', {
										ProjectileRefId = httpService:GenerateGUID(true),
										direction = dir,
										fromPosition = origin,
										initialVelocity = dir
									})
									task.wait(store.ping.total or 0)
								end
							end
						end
					end
					task.wait(0.1)
				until not OwlAura.Enabled
			else
				bedwars.Handler:Get('OwlAiming'):Fire('SendToServer', {starting = false})
			end
		end,
		Tooltip = 'Automatically shoots projectiles with whisper kit'
	})
	Targets = OwlAura:CreateTargets({
		Players = true,
		Wallcheck = true
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	Mode = OwlAura:CreateDropdown({
		Name = 'Target mode',
		List = methods,
		Default = 'Distance'
	})
	Range = OwlAura:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 50,
		Default = 50,
		Suffix = function(val)
			return val <= 0 and 'stud' or 'studs'
		end
	})
end)
