
run(function()
	local Velocity
	local Horizontal
	local Vertical
	local Chance
	local TargetCheck
	local rand, old = Random.new()
	local knockbackModule = replicatedStorage.TS.damage['knockback-util']
	local defaults
	
	local function applyKnockbackConstants()
		if not defaults then return end
	
		knockbackModule:SetAttribute('ConstantManager_kbDirectionStrength', defaults.horizontal * (Horizontal.Value / 100))
		knockbackModule:SetAttribute('ConstantManager_kbUpwardStrength', defaults.vertical * (Vertical.Value / 100))
	end
	
	local function restoreKnockbackConstants()
		if not defaults then return end
	
		knockbackModule:SetAttribute('ConstantManager_kbDirectionStrength', defaults.horizontal)
		knockbackModule:SetAttribute('ConstantManager_kbUpwardStrength', defaults.vertical)
	end
	
	Velocity = vape.Categories.Combat:CreateModule({
		Name = 'Velocity',
		Function = function(callback)
			if not canDebug then
				if callback then
					defaults = defaults or {
						horizontal = knockbackModule:GetAttribute('ConstantManager_kbDirectionStrength'),
						vertical = knockbackModule:GetAttribute('ConstantManager_kbUpwardStrength')
					}
					applyKnockbackConstants()
				else
					restoreKnockbackConstants()
				end
				return
			end
	
			if callback then
				old = bedwars.KnockbackUtil.applyKnockback
				bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
					if rand:NextNumber(0, 100) > Chance.Value then return end
					local check = (not TargetCheck.Enabled) or entitylib.EntityPosition({
						Range = 50,
						Part = 'RootPart',
						Players = true
					})
	
					if check then
						knockback = knockback or {}
						if Horizontal.Value == 0 and Vertical.Value == 0 then return end
						knockback.horizontal = (knockback.horizontal or 1) * (Horizontal.Value / 100)
						knockback.vertical = (knockback.vertical or 1) * (Vertical.Value / 100)
					end
					
					return old(root, mass, dir, knockback, ...)
				end
			else
				bedwars.KnockbackUtil.applyKnockback = old
			end
		end,
		Tooltip = 'Reduces knockback taken'
	})
	Horizontal = Velocity:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%',
		Function = function()
			if not canDebug and Velocity.Enabled then
				applyKnockbackConstants()
			end
		end
	})
	Vertical = Velocity:CreateSlider({
		Name = 'Vertical',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%',
		Function = function()
			if not canDebug and Velocity.Enabled then
				applyKnockbackConstants()
			end
		end
	})
	Chance = Velocity:CreateSlider({
		Name = 'Chance',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
	TargetCheck = Velocity:CreateToggle({Name = 'Only when targeting'})
end)
