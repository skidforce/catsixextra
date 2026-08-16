
run(function()
	local FFlag
	local Flags
	
	local function ChangeFFlag(suc)
		if not suc or not FFlag.Enabled then
			return
		end
		local success, json = pcall(function()
			return httpService:JSONDecode(Flags.Value)
		end)
	
		if not success or typeof(json) ~= 'table' then
			notif('Vape', 'Invalid json format for fflag', 12, 'warning')
			return
		end
	
		for i, v in json do
			i = i:gsub('DFInt', ''):gsub('DFFlag', ''):gsub('FFlag', ''):gsub('FInt', ''):gsub('DFString', ''):gsub('FString', '')
			pcall(setfflag, i, tostring(v))
		end
	
		notif('Vape', 'FFlags applied, Go in a new game to take effect', 12, 'info')
	end
	
	FFlag = vape.Legit:CreateModule({
		Name = 'FFlagEditor',
		Function = function(call)
			if call then
				ChangeFFlag(true)
			else
				notif('Vape', 'Inorder to disable fflags you have applied, You need to restart roblox', 20, 'info')
			end
		end
	})
	
	Flags = FFlag:CreateTextBox({
		Name = 'FFlags',
		Placeholder = 'json format only',
		Function = ChangeFFlag
	})
end)
