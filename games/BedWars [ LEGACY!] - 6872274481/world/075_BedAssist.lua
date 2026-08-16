
run(function()
	local BedAssist
	local AimMode
	local Speed
	local Range
	local Shake
	local Mode
	local Limit
	
	local function ease(t)
		return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2
	end
	
	local started = 0
	local aimfuncs = {
		Simple = function(localcframe, pos, fps)
			local rng = Random.new()
			return localcframe:Lerp(CFrame.lookAt(localcframe.p, pos + Vector3.new((rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps)), Speed.Value * fps), Speed.Value
		end,
		Adaptive = function(localcframe, pos, fps)
			local prog, rng = ease(math.min((tick() - started) / (1 / (Speed.Value * 0.5)), 1)), Random.new()
			local speed = Speed.Value * prog
			return localcframe:Lerp(CFrame.lookAt(localcframe.p, pos + Vector3.new((rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps)), speed * fps), speed
		end
	}
	
	local function getBestPosition(block)
		local handler = bedwars.BlockController:getHandlerRegistry():getHandler(block.Name)
		local cost, pos = math.huge, nil
		local mag = 9e9
	
		local positions = (handler and handler:getContainedPositions(block) or {block.Position / 3})
	
		for _, v in positions do
			local dpos, dcost = calculatePath(block, v * 3)
			local dmag = dpos and (entitylib.character.RootPart.Position - dpos).Magnitude
	
			if dpos then
				if dcost < cost or (dcost == cost and dmag < mag) then
					cost, pos, mag = dcost, dpos, dmag
				end
			end
		end
	
		if pos and (entitylib.character.RootPart.Position - pos).Magnitude <= Range.Value then
			return pos
		end
		return nil
	end
	
	BedAssist = vape.Categories.World:CreateModule({
		Name = 'BedAssist',
		Function = function(call)
			if call then
				repeat
					task.wait()
				until store.matchState ~= 0 or not BedAssist.Enabled
				if not BedAssist.Enabled then
					return
				end
	
				local beds = collection('bed', BedAssist, function(tab, obj)
					task.delay(0, function()
						if not obj:GetAttribute('Team' .. (lplr:GetAttribute('Team') or -1) .. 'NoBreak') then
							table.insert(tab, obj)
						end
					end)
				end)
				local rng = Random.new()
				local lastbed = nil
	
				BedAssist:Clean(runService.PostSimulation:Connect(function(dt)
					if entitylib.isAlive and (not Limit.Enabled or store.hand.tool and bedwars.ItemMeta[store.hand.tool.Name].breakBlock) then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in beds do
							if (localPosition - v.Position).Magnitude <= Range.Value then
								if lastbed ~= v then
									started = tick()
								end
								lastbed = v
	
								local pos = getBestPosition(v)
								if pos then
									local pred, speed = aimfuncs[AimMode.Value](gameCamera.CFrame, pos, dt)
	
									if Mode.Value == 'Mouse' then
										pos += Vector3.new(
											(rng:NextNumber() - 0.5) * Shake.Value * 0.1,
											(rng:NextNumber() - 0.5) * Shake.Value * 0.1,
											(rng:NextNumber() - 0.5) * Shake.Value * 0.1
										)
										local campos, vis = gameCamera:WorldToViewportPoint(pos)
										if vis then
											local vec2 = (Vector2.new(campos.X, campos.Y) - inputService:GetMouseLocation()) * (speed * dt)
											mousemoverel(vec2.X, vec2.Y)
										end
									else
										gameCamera.CFrame = pred
									end
								end
								break
							end
						end
					end
				end))
			end
		end,
		Tooltip = 'Smoothly aims towards a bed close to your mouse'
	})
	local list = {'Camera'}
	if inputService.MouseEnabled and mousemoverel then
		table.insert(list, 'Mouse')
	end
	AimMode = BedAssist:CreateDropdown({
		Name = 'Mode',
		List = {'Simple', 'Adaptive'},
		Default = 'Simple'
	})
	Mode = BedAssist:CreateDropdown({
		Name = 'Aim mode',
		List = list,
		Default = 'Camera'
	})
	Speed = BedAssist:CreateSlider({
		Name = 'Aim speed',
		Min = 1,
		Max = 20,
		Default = 7
	})
	Range = BedAssist:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 20,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	Shake = BedAssist:CreateSlider({
		Name = 'Shake',
		Min = 1,
		Max = 100,
		Default = 3
	})
	Limit = BedAssist:CreateToggle({Name = 'Limit to item', Default = true})
end)
