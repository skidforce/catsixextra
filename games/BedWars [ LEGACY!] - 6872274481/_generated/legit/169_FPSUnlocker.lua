
run(function()
	local FPSUnlocker
	local cap = getfpscap and getfpscap() or nil
	
	FPSUnlocker = vape.Legit:CreateModule({
	    Name = 'FPSUnlocker',
	    Function = function(callback)
	        if cap then
	            setfpscps(callback and 9999 or cap)
	        elseif callback then
	            setfpscap(9999)
	            notif('FPSUnlocker', 'You have to restart ur game inorder to disable this.', 8, 'info')
	        end
	    end
	})
end)
