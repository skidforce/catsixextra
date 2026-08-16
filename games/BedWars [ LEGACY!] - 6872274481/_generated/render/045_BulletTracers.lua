
run(function()
	local BulletTracers
	local Material
	local Lifetime
	local Curve
	local Opacity
	local Thickness
	local Color
	local Fade
	
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	
	BulletTracers = vape.Categories.Render:CreateModule({
		Name = 'ProjectileTracers',
		Function = function(callback)
			if callback then
				BulletTracers:Clean(workspace.ChildAdded:Connect(function(projectile)
					task.delay(0, function()
						if not BulletTracers.Enabled or not projectile.Parent or projectile:GetAttribute('ProjectileShooter') ~= lplr.UserId then
							return
						end
						local filter = {projectile}
						if lplr.Character then table.insert(filter, lplr.Character) end
						rayCheck.FilterDescendantsInstances = filter
						local root = projectile:IsA('BasePart') and projectile or projectile:IsA('Model') and projectile.PrimaryPart
						local meta = bedwars.ProjectileMeta[projectile.Name]
						if not root or not meta then return end
						local origin = root.Position
						local velocity = root.AssemblyLinearVelocity
						local velocityMagnitude = velocity.Magnitude
						if velocityMagnitude <= 0 then
							return
						end
						local velocityUnit = velocity / velocityMagnitude
						local gravity = meta.gravitationalAcceleration or workspace.Gravity
						local ray = workspace:Raycast(origin, velocityUnit * 2000, rayCheck)
						local endpoint = ray and ray.Position or (origin + velocityUnit * 2000)
						local travelTime = (endpoint - origin).Magnitude / velocityMagnitude
	
						prediction.SpawnArcTracer(origin, velocityUnit, velocityMagnitude, gravity, travelTime, Curve.Value, {
							Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value),
							Transparency = Opacity.Value,
							Thick = Thickness.Value,
							Material = Enum.Material[Material.Value],
							Lifetime = Lifetime.Value,
							Fade = Fade.Enabled
						})
					end)
				end))
			end
		end,
		Tooltip = 'Replacement tracers for projectiles'
	})
	local materials = {'SmoothPlastic'}
	for _, v in Enum.Material:GetEnumItems() do
		if v.Name ~= 'SmoothPlastic' then
			table.insert(materials, v.Name)
		end
	end
	Material = BulletTracers:CreateDropdown({
		Name = 'Material',
		List = materials
	})
	Color = BulletTracers:CreateColorSlider({
		Name = 'Tracer Color',
		DefaultOpacity = 0.5
	})
	Thickness = BulletTracers:CreateSlider({
		Name = 'Thickness',
		Min = 0.01,
		Max = 1,
		Default = 0.1,
		Decimal = 100
	})
	Curve = BulletTracers:CreateSlider({
		Name = 'Curveness',
		Min = 1,
		Max = 100,
		Default = 40,
		Tooltip = 'How curve the projectile is gonna be\n(More curve = more lag)'
	})
	Opacity = BulletTracers:CreateSlider({
		Name = 'Opacity',
		Min = 0,
		Max = 1,
		Default = 0,
		Decimal = 100
	})
	Lifetime = BulletTracers:CreateSlider({
		Name = 'Lifetime',
		Min = 0,
		Max = 5,
		Decimal = 100,
		Default = 2,
		Suffix = 'secs'
	})
	Fade = BulletTracers:CreateToggle({
		Name = 'Fade',
		Default = true
	})
end)
