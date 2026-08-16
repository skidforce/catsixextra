
run(function()
	local NoFall
	local groundHit = bedwars.Handler:Get('GroundHit')
	
	NoFall = vape.Categories.Blatant:CreateModule({
		Name = 'NoFall',
		Function = function(callback)
			if callback then
				if entitylib.isAlive and getconnections then
					for _, v in getconnections(entitylib.character.Humanoid.StateChanged) do
						v:Disable()
					end
				end
				local tracked = 0
				NoFall:Clean(runService.PostSimulation:Connect(function()
					if entitylib.isAlive and store.matchState == 1 and not (vape.Modules.InfiniteFly or {}).Enabled then
						local root = entitylib.character.RootPart
						local velo = root.Velocity
						if tracked < -45 then
							root.Velocity = Vector3.new(0, 2.5, 0)
							entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
							runService.PreRender:Wait()
							root.Velocity = velo
							groundHit:Fire('SendToServer', nil, Vector3.new(0, tracked, 0), workspace:GetServerTimeNow())
						end
						tracked = velo.Y
					end
				end))
	
				NoFall:Clean(entitylib.Events.LocalAdded:Connect(function(ent)
					if ent.Humanoid:WaitForChild('Animator', 5) then
						task.wait(0.5)
						if NoFall.Enabled then
							NoFall:Toggle()
							NoFall:Toggle()
						end
					end
				end))
			end
		end,
		Tooltip = 'Prevents taking fall damage.'
	})
end)
