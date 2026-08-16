
run(function()
	local InfiniteJump
	local TPDown
	local Mode
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	InfiniteJump = vape.Categories.Blatant:CreateModule({
	    Name = 'InfiniteJump',
	    Function = function(callback)
	        if callback then
	            local jumps = 0
	            InfiniteJump:Clean(inputService.JumpRequest:Connect(function()
	                jumps += 1
	                if jumps > 1 and Mode.Value == 'Velocity' then
	                    local root = entitylib.character.RootPart
	                    root.Velocity = Vector3.new(root.Velocity.X, math.sqrt(2 * workspace.Gravity * entitylib.character.Humanoid.JumpHeight), root.Velocity.Z)
	                    jumps = 0
	                elseif Mode.Value == 'Jump' then
	                    entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	                end
	            end))
	
	            local oldy = nil
	            repeat
	                if entitylib.isAlive and TPDown.Enabled and entitylib.character.AirTime then
	                    local root, airleft = entitylib.character.RootPart, (tick() - entitylib.character.AirTime)
	                    if oldy then
	                        root.CFrame = CFrame.lookAlong(Vector3.new(root.CFrame.X, oldy, root.CFrame.Z), root.CFrame.LookVector)
	                        oldy = nil
	                        task.wait(0.1)
	                    elseif airleft > 1.7 then
	                        rayParams.FilterDescendantsInstances = {lplr.Character, gameCamera}
	                        local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayParams)
	                        if ray then
	                            oldy = root.Position.Y
	                            runService.PostSimulation:Wait()
	                            root.CFrame = CFrame.lookAlong(Vector3.new(root.CFrame.X, ray.Position.Y + (entitylib.character.HipHeight or 2.5), root.CFrame.Z), root.CFrame.LookVector)
	                        end
	                    end
	                end
	                task.wait(0.1)
	            until not InfiniteJump.Enabled
	        end
	    end,
	    ExtraText = function()
	        return Mode.Value
	    end
	})
	
	Mode = InfiniteJump:CreateDropdown({
	    Name = 'Mode',
	    List = {'Velocity', 'Jump'},
	    Default = 'Jump'
	})
	TPDown = InfiniteJump:CreateToggle({Name = 'TP Down'})
end)
