
run(function()
	local DeathAdderAimbot
	local Mode
	local BedRange
	local Targets
	local Sort
	local TargetPart
	local FOV
	
	local old
	
	local function getBed(localPosition)
		local closest, magnitude = nil, BedRange.Value
		for _, bed in collectionService:GetTagged('bed') do
			if not bed:GetAttribute(`Team{lplr:GetAttribute('Team') or -1}NoBreak`) then
				local mag = (localPosition - bed.Position).Magnitude
				if mag <= magnitude then
					closest, magnitude = bed, mag
				end
			end
		end
		return closest
	end
	
	local function getAim(localPosition)
		if Mode.Value == 'Bed' then
			local bed = getBed(localPosition)
			return bed and bed.Position or nil
		end
	
		local ent = entitylib.EntityMouse({
			Range = FOV.Value,
			Part = 'RootPart',
			Wallcheck = Targets.Walls.Enabled,
			Players = Targets.Players.Enabled,
			NPCs = Targets.NPCs.Enabled,
			Origin = localPosition,
			Sort = sortmethods[Sort.Value]
		})
		if not ent then return nil end
	
		targetinfo.Targets[ent] = tick() + 1
		local tierdata = bedwars.SorcererBalance.getSorcererTierData(bedwars.SorcererBalance.getSorcererTier(lplr))
		local aim = ent[TargetPart.Value].Position
		local speed = tierdata and tierdata.projectileVelocity or 70
		return aim + (ent.RootPart.AssemblyLinearVelocity * ((aim - localPosition).Magnitude / speed))
	end
	
	DeathAdderAimbot = vape.Categories.Blatant:CreateModule({
		Name = 'DeathAdderAimbot',
		Function = function(callback)
			if callback then
				old = bedwars.SorcererController.getProjectileDirection
				bedwars.SorcererController.getProjectileDirection = function(self, ...)
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						local aim = getAim(localPosition)
						if aim and aim ~= localPosition then
							return (aim - localPosition).Unit
						end
					end
	
					return old(self, ...)
				end
			else
				bedwars.SorcererController.getProjectileDirection = old
			end
		end,
		Tooltip = 'Silently aims Death Adder\'s spell at a bed or a player'
	})
	Mode = DeathAdderAimbot:CreateDropdown({
		Name = 'Mode',
		List = {'Player', 'Bed'},
		Function = function(val)
			if BedRange then
				BedRange.Object.Visible = val == 'Bed'
				FOV.Object.Visible = val == 'Player'
				TargetPart.Object.Visible = val == 'Player'
				Sort.Object.Visible = val == 'Player'
			end
		end,
		Tooltip = 'Bed aims at the closest enemy bed, Player leads the closest enemy'
	})
	BedRange = DeathAdderAimbot:CreateSlider({
		Name = 'Bed range',
		Min = 1,
		Max = 60,
		Default = 60,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Targets = DeathAdderAimbot:CreateTargets({
		Players = true,
		Walls = true
	})
	local methods = {'Distance', 'Damage'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	Sort = DeathAdderAimbot:CreateDropdown({
		Name = 'Target mode',
		List = methods,
		Default = 'Distance',
		Darker = true
	})
	TargetPart = DeathAdderAimbot:CreateDropdown({
		Name = 'Part',
		List = {'RootPart', 'Head'},
		Darker = true
	})
	FOV = DeathAdderAimbot:CreateSlider({
		Name = 'FOV',
		Min = 1,
		Max = 1000,
		Default = 1000,
		Darker = true
	})
end)
