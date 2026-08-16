
run(function()
	local DeviceSpoofer
	local Device
	local oldDevice, old
	
	DeviceSpoofer = vape.Categories.Utility:CreateModule({
		Name = 'DeviceSpoofer',
		Function = function(callback)
			if callback then
				oldDevice, old = bedwars.UserInputController:getUserInputType(), bedwars.UserInputController.getUserInputType
				bedwars.UserInputController.getUserInputType = function()
					return Device.Value:upper()
				end
				bedwars.Handler:Get('SendUserInputType'):Fire('SendToServer', {userInputType = Device.Value:upper()})
			else
				bedwars.UserInputController.getUserInputType = old
				bedwars.Handler:Get('SendUserInputType'):Fire('SendToServer', {userInputType = oldDevice})
				old = nil
			end
		end,
		Tooltip = 'Spoofs the device you show up as to the server',
		ExtraText = function()
			return Device.Value
		end
	})
	Device = DeviceSpoofer:CreateDropdown({
		Name = 'Device',
		List = {'Mobile', 'PC', 'Gamepad'},
		Function = function(val)
			if DeviceSpoofer.Enabled then
				bedwars.Handler:Get('SendUserInputType'):Fire('SendToServer', {userInputType = val:upper()})
			end
		end
	})
end)
