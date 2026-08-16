
local SendHook = {Hooks = {}}
do
	local oldsend

	local function Hook(...)
		local args = table.pack(...)
		for _, v in SendHook.Hooks do
			if v[2](args) then
				return
			end
		end

		return oldsend(unpack(args, 1, args.n))
	end

	function SendHook:DoHook()
		if not oldsend and next(self.Hooks) then
			oldsend = hookfunction(redline.Packet.Fire, function(...)
				return Hook(...)
			end)
		end
	end

	function SendHook:Add(key, val, priority)
		table.insert(self.Hooks, {key, val, priority or 0})
		table.sort(self.Hooks, function(a, b)
			return a[3] < b[3]
		end)

		if not oldsend then
			if (os.clock() - starttime) < 2 then
				task.defer(function()
					task.delay(2, function()
						self:DoHook()
					end)
				end)
			else
				self:DoHook()
			end
		end
	end

	function SendHook:Remove(key)
		for i, v in self.Hooks do
			if v[1] == key then
				table.remove(self.Hooks, i)
				break
			end
		end

		if oldsend and not next(self.Hooks) then
			if restorefunction then
				restorefunction(redline.Packet.Fire)
			else
				hookfunction(redline.Packet.Fire, oldsend)
			end

			oldsend = nil
		end
	end
end

for _, v in {'Reach', 'TriggerBot', 'AntiFall', 'Desync', 'HitBoxes', 'Invisible', 'Jesus', 'MouseTP', 'Spider', 'SpinBot', 'Swim', 'TargetStrafe', 'AntiRagdoll', 'Disabler', 'StateSpoofer', 'Parkour', 'SafeWalk', 'MurderMystery'} do
	vape:Remove(v)
end

run(function()
	local Reach
	
	Reach = vape.Categories.Combat:CreateModule({
		Name = 'Reach',
		Function = function(callback)
			if callback then
				SendHook:Add('Reach', function(args)
					local self = args[1]
					if self and rawget(self, 'Name') == redline.AttackPacket then
						if typeof(args[4]) == 'string' then
							for _, box in redline_boxes do
								if #castHitbox(box.data, CFrame.lookAlong(entitylib.character.RootPart.Position + Vector3.new(0, 2, 0), args[5])) > 0 then
									args[4] = box.boxtype
									break
								end
							end
						end
					end
				end, 2)
			else
				SendHook:Remove('Reach')
			end
		end,
		Tooltip = 'Extends attack reach by picking the best hitbox type. (RISKY)'
	})
end)
