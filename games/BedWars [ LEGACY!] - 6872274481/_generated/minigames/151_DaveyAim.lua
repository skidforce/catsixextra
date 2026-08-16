
run(function()
	local DaveyAim
	local Mode
	local Position
	local Range
	local LaunchCannon
	local ShowTarget
	
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	
	local function getLaunchVelocity(delta, velocity, time)
		return (delta + Vector3.new(0, workspace.Gravity * time * time * 0.5, 0)) / time - velocity
	end
	
	local function getCannon()
		local cannons = {}
		local localPosition = entitylib.character.RootPart.Position
		for _, v in store.blocks do
			if v.Name == 'cannon' and (localPosition - v.Position).Magnitude <= Range.Value then
				table.insert(cannons, v)
			end
		end
		if #cannons > 1 then
			table.sort(cannons, function(a, b)
				return (localPosition - a.Position).Magnitude < (localPosition - b.Position).Magnitude
			end)
		end
		return cannons[1] or nil
	end
	
	local function isPathBlocked(origin, velocity, time)
		local previous = origin
	
		for i = 1, 11 do
			local elapsed = time * i / 12
			local point = origin + velocity * elapsed - Vector3.new(0, workspace.Gravity * elapsed * elapsed * 0.5, 0)
			if workspace:Spherecast(previous, 2, point - previous, rayCheck) then
				return true
			end
			previous = point
		end
	
		return false
	end
	
	local function getLaunchTime(origin, delta, velocity, ceiling)
		local low, up = 0.0001, 20
	
		for _ = 1, 50 do
			local first, second = low + (up - low) / 3, up - (up - low) / 3
			if getLaunchVelocity(delta, velocity, first).Magnitude < getLaunchVelocity(delta, velocity, second).Magnitude then
				up = second
			else
				low = first
			end
		end
	
		local middle = (low + up) / 2
		if getLaunchVelocity(delta, velocity, middle).Magnitude > ceiling then return end
		if not isPathBlocked(origin, getLaunchVelocity(delta, Vector3.zero, middle), middle) then return middle end
	
		for i = 1, 20 do
			for _, time in {middle * (1 + i * 0.15), middle * (1 - i * 0.045)} do
				if getLaunchVelocity(delta, velocity, time).Magnitude <= ceiling and not isPathBlocked(origin, getLaunchVelocity(delta, Vector3.zero, time), time) then
					return time
				end
			end
		end
	
		return middle
	end
	
	local function makeVisual(target, blockPosition)
		local part = Instance.new('Part')
		part.Size = Vector3.new(3, 3, 3)
		part.CFrame = CFrame.new(blockPosition)
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		local selection = Instance.new('SelectionBox')
		selection.Adornee = part
		selection.LineThickness = 0.04
		selection.Color3 = Color3.new(1, 1, 1)
		selection.SurfaceColor3 = Color3.new(1, 1, 1)
		selection.SurfaceTransparency = 0.75
		selection.Parent = part
		local tagSize = getfontsize('Landing (000 studs)', 14, uipallet.Font, Vector2.new(100000, 100000))
		local billboard = Instance.new('BillboardGui')
		billboard.Name = 'Tag'
		billboard.Size = UDim2.fromOffset(tagSize.X + 8, tagSize.Y + 7)
		billboard.StudsOffsetWorldSpace = (target - blockPosition) + Vector3.new(0, 2, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = part
		local tag = Instance.new('TextLabel')
		tag.Size = billboard.Size
		tag.BackgroundColor3 = Color3.new()
		tag.BackgroundTransparency = 0.5
		tag.BorderSizePixel = 0
		tag.RichText = true
		tag.FontFace = uipallet.Font
		tag.TextSize = 14
		tag.TextColor3 = Color3.new(1, 1, 1)
		tag.Parent = billboard
		bedwars.QueryUtil:setQueryIgnored(part, true)
		part.Parent = gameCamera
		return part
	end
	
	local function aimCannon(cannon, direction)
		local blockPosition = bedwars.BlockController:getBlockPosition(cannon.Position)
		local aimed
		local timeout = tick() + 1
	
		repeat
			bedwars.Handler:Get('AimCannon'):Fire('SendToServer', {
				cannonBlockPos = blockPosition,
				lookVector = direction
			})
			task.wait(0.15)
			local look = cannon:GetAttribute('LookVector')
			aimed = look and (look - direction).Magnitude < 0.0001
		until aimed or tick() > timeout or not cannon.Parent
	
		return aimed
	end
	
	DaveyAim = vape.Categories.Minigames:CreateModule({
		Name = 'DaveyAim',
		Function = function(callback)
			if callback then
				DaveyAim:Toggle()
				if not entitylib.isAlive then return end
	
				local cannon = getCannon()
				if not cannon then
					notif('DaveyAim', 'No cannon in range.', 5, 'warning')
					return
				end
	
				local mouseRay = cloneref(lplr:GetMouse()).UnitRay
				local origin = Position.Value == 'Camera' and gameCamera.CFrame.Position or mouseRay.Origin
				local direction = Position.Value == 'Camera' and gameCamera.CFrame.LookVector or mouseRay.Direction
				rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, cannon}
				local ray = workspace:Raycast(origin, direction * 10000, rayCheck)
				if not ray then
					notif('DaveyAim', 'No position found.', 5, 'warning')
					return
				end
	
				local localPosition = entitylib.character.RootPart.Position
				local target = ray.Position + Vector3.new(0, entitylib.character.HipHeight, 0)
				local velocity = entitylib.character.RootPart.AssemblyLinearVelocity
				if (target - localPosition).Magnitude > 300 then
					notif('DaveyAim', `Too far away ({math.floor((target - localPosition).Magnitude)} studs away, 300 max).`, 5, 'warning')
					return
				end
	
				local time = getLaunchTime(localPosition, target - localPosition, velocity, math.sqrt(320 * workspace.Gravity))
				if not time then
					notif('DaveyAim', `Out of cannon range ({math.floor((target - localPosition).Magnitude)} studs away, 300 max).`, 5, 'warning')
					return
				end
	
				local launchDirection = getLaunchVelocity(target - localPosition, velocity, time).Unit
				local blockPosition = bedwars.BlockController:getBlockPosition(cannon.Position)
				local visual = ShowTarget.Enabled and makeVisual(target, roundPos(ray.Position - ray.Normal * 1.5)) or nil
				if visual then
					visual.Tag.TextLabel.Text = `Landing ({math.floor((target - localPosition).Magnitude)} studs)`
				end
	
				if Mode.Value == 'Legit' then
					cannon.AimPrompt:InputHoldBegin()
					task.wait(cannon.AimPrompt.HoldDuration)
	
					local timeout = tick() + 0.3
					repeat
						gameCamera.CFrame = gameCamera.CFrame:Lerp(CFrame.lookAt(gameCamera.CFrame.Position, gameCamera.CFrame.Position + launchDirection), 22 * runService.PostSimulation:Wait())
						bedwars.Handler:Get('AimCannon'):Fire('SendToServer', {
							cannonBlockPos = blockPosition,
							lookVector = gameCamera.CFrame.LookVector
						})
					until tick() > timeout
				end
	
				if not aimCannon(cannon, launchDirection) then
					notif('DaveyAim', 'Cannon refused the aim.', 5, 'warning')
					if visual then
						visual:Destroy()
					end
					return
				end
	
				if Mode.Value == 'Legit' then
					cannon.StopAimingPrompt:InputHoldBegin()
				end
				task.wait((cannon.StopAimingPrompt.HoldDuration + (0.2 + store.ping.total)) + runService.PostSimulation:Wait())
	
				if LaunchCannon.Enabled then
					if Mode.Value == 'Legit' then
						cannon.LaunchSelfPrompt:InputHoldBegin()
						task.wait(cannon.LaunchSelfPrompt.HoldDuration + runService.PostSimulation:Wait())
					else
						bedwars.CannonHandController:launchSelf(cannon)
					end
				else
					local launched, aimed = false, true
					local connection = cannon.LaunchSelfPrompt.Triggered:Connect(function(plr)
						if plr == lplr then
							launched = true
						end
					end)
					local timeout = tick() + 30
	
					repeat
						runService.PostSimulation:Wait()
						local look = cannon.Parent and cannon:GetAttribute('LookVector')
						aimed = look and (look - launchDirection).Magnitude < 0.0001
					until launched or not aimed or tick() > timeout or not entitylib.isAlive
	
					connection:Disconnect()
					if not launched then
						if not aimed then
							notif('DaveyAim', 'Cannon was re-aimed before you launched.', 5, 'warning')
						end
						if visual then
							visual:Destroy()
						end
						return
					end
				end
	
				local landing = tick() + time
				local root
				repeat
					runService.PreSimulation:Wait()
					root = entitylib.isAlive and entitylib.character.RootPart
					if root then
						local remaining = landing - tick()
						if remaining > 0.1 then
							root.AssemblyLinearVelocity = getLaunchVelocity(target - root.Position, Vector3.zero, remaining)
						end
						if visual then
							visual.Tag.TextLabel.Text = `Landing ({math.floor((target - root.Position).Magnitude)} studs)`
						end
					end
				until not root or tick() > landing
	
				if visual then
					visual:Destroy()
				end
			end
		end,
		Tooltip = 'Aims a nearby cannon at your cursor and launches you onto it'
	})
	Mode = DaveyAim:CreateDropdown({
		Name = 'Aim Mode',
		List = {'Blatant', 'Legit'},
		Default = 'Blatant'
	})
	Position = DaveyAim:CreateDropdown({
		Name = 'Position Mode',
		List = {'Mouse', 'Camera'},
		Default = 'Mouse'
	})
	Range = DaveyAim:CreateSlider({
		Name = 'Search Range',
		Min = 1,
		Max = 18,
		Default = 10,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	LaunchCannon = DaveyAim:CreateToggle({
		Name = 'Launch Cannon',
		Default = true,
		Tooltip = 'Launches you itself, turn this off to aim only and still land on target when you launch yourself'
	})
	ShowTarget = DaveyAim:CreateToggle({
		Name = 'Show Target',
		Default = true,
		Tooltip = 'Highlights the block you are landing on until you land'
	})
end)
