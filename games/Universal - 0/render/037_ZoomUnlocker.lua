
run(function()
	local ZoomUnlocker
	local Distance
	local FirstPerson
	local oldmax, oldmin
	
	ZoomUnlocker = vape.Categories.Render:CreateModule({
		Name = 'ZoomUnlocker',
		Function = function(callback)
			if callback then
				oldmax, oldmin = lplr.CameraMaxZoomDistance, lplr.CameraMinZoomDistance
				repeat
					local min = FirstPerson.Enabled and 0.5 or math.min(oldmin, Distance.Value)
					if lplr.CameraMinZoomDistance ~= min or lplr.CameraMaxZoomDistance ~= Distance.Value then
						lplr.CameraMinZoomDistance = min
						lplr.CameraMaxZoomDistance = Distance.Value
					end
					task.wait()
				until not ZoomUnlocker.Enabled
			else
				lplr.CameraMinZoomDistance = oldmin
				lplr.CameraMaxZoomDistance = oldmax
			end
		end,
		Tooltip = 'Removes the zoom limit the game puts on your camera'
	})
	Distance = ZoomUnlocker:CreateSlider({
		Name = 'Distance',
		Min = 1,
		Max = 500,
		Default = 128,
		Suffix = function(val)
			return val > 1 and 'studs' or 'stud'
		end
	})
	FirstPerson = ZoomUnlocker:CreateToggle({
		Name = 'Allow first person',
		Default = true,
		Tooltip = 'Also unlocks zooming all the way in'
	})
end)
