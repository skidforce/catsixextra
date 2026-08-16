run(function()
	local rayParams = RaycastParams.new()
	local overlapParams = OverlapParams.new()
	rayParams.CollisionGroup = 'ClientBullet'
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.CollisionGroup = 'ClientBullet'
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	OriginScanner.Ray = rayParams

	local positions = {
		Vector3.new(0, 1, 0),
		Vector3.new(1, 0, 0),
		Vector3.new(0.7, -0.5, -0.5),
		Vector3.new(-0.1, -0.8, -0.8),
		Vector3.new(-0.8, -0.5, -0.5),
		Vector3.new(-1, 0, 0),
		Vector3.new(-0.8, 0.4, 0.4),
		Vector3.new(0, 0.7, 0.7),
		Vector3.new(0.7, 0.5, 0.5),
		Vector3.new(1, 0, 0),
		Vector3.new(0.7, 0, -0.8),
		Vector3.new(-0.1, 0, -1),
		Vector3.new(-0.8, 0, -0.8),
		Vector3.new(-1, 0, 0),
		Vector3.new(-0.8, 0, 0.7),
		Vector3.new(0, 0, 1),
		Vector3.new(0.7, 0, 0.7),
		Vector3.new(1, 0, 0),
		Vector3.new(0.7, 0.4, -0.5),
		Vector3.new(-0.1, 0.7, -0.8),
		Vector3.new(-0.8, 0.4, -0.5),
		Vector3.new(-1, -0.1, 0),
		Vector3.new(-0.8, -0.5, 0.4),
		Vector3.new(0, -0.8, 0.7),
		Vector3.new(0.7, -0.6, 0.5),
		Vector3.new(0, -1, 0)
	}

	function OriginScanner:Scan(origin, target, extra, part)
		local scanPositions = {}
		local hitboxPositions = {}
		local returnHitbox
		local diff = CFrame.lookAt(origin * Vector3.new(1, 0, 1), target * Vector3.new(1, 0, 1)).LookVector

		if OriginScanner.Cache[part] then
			return table.unpack(OriginScanner.Cache[part])
		end

		if extra then
			if (origin - extra).Magnitude < 7.5 then
				table.insert(scanPositions, extra)
			else
				table.insert(hitboxPositions, target)
				for _, v in Enum.NormalId:GetEnumItems() do
					local vec = Vector3.fromNormalId(v)

					if (vec * Vector3.new(1, 0, 1)):Dot(-diff) > -0.5 then
						local pos = target + vec * 6

						if checkPoint(pos, overlapParams) then
							table.insert(hitboxPositions, pos)
						end
					end
				end
			end
		end

		if #scanPositions <= 0 then
			for _, v in positions do
				if (v * Vector3.new(1, 0, 1)):Dot(diff) > -0.5 then
					table.insert(scanPositions, origin + v * 6)
				end
			end
		end

		if #hitboxPositions > 0 then
			for _, hitbox in hitboxPositions do
				for _, pos in scanPositions do
					local ray = workspace:Raycast(hitbox, (pos - hitbox), rayParams)

					if not ray and checkPoint(pos, overlapParams) then
						OriginScanner.Cache[part] = {pos, hitbox}
						return pos, hitbox
					end
				end
			end
		else
			for _, pos in scanPositions do
				local ray = workspace:Raycast(target, (pos - target), rayParams)

				if not ray and checkPoint(pos, overlapParams) then
					OriginScanner.Cache[part] = {pos}
					return pos
				end
			end
		end
	end

	function OriginScanner:UpdateIgnore()
		local ignore = {lplr.Character}
		for _, entity in entitylib.List do
			table.insert(ignore, entity.Character)
		end

		rayParams.FilterDescendantsInstances = ignore
		overlapParams.FilterDescendantsInstances = ignore
	end
end)
