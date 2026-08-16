
run(function()
	local ClaimRewards
	local CratesOnly
	local Notify
	
	local function getClaimed()
		local claimed = bedwars.MilestonesController.milestoneRewardsClaimed
		if claimed then return claimed end
		local state = bedwars.Store:getState().Bedwars
		return state and state.milestoneRewardsClaimed or {}
	end
	
	ClaimRewards = vape.Categories.Utility:CreateModule({
		Name = 'ClaimRewards',
		Function = function(callback)
			if callback then
				repeat
					local level = bedwars.Store:getState().Bedwars.playerLevel or 0
					local claimed = getClaimed()
	
					for _, reward in bedwars.MilestoneRewards do
						if reward.levelRequirement <= level and not table.find(claimed, reward.id) and (not CratesOnly.Enabled or reward.instantClaim) then
							if bedwars.Client:Get('ClaimMilestoneReward'):CallServer(reward.id) then
								table.insert(claimed, reward.id)
								if Notify.Enabled then
									notif('ClaimRewards', `Claimed {reward.description or reward.id}`, 5)
								end
							end
							task.wait(1)
							if not ClaimRewards.Enabled then break end
						end
					end
	
					task.wait(5)
				until not ClaimRewards.Enabled
			end
		end,
		Tooltip = 'Automatically claims every level milestone reward as soon as you unlock it'
	})
	CratesOnly = ClaimRewards:CreateToggle({
		Name = 'Crates only',
		Tooltip = 'Only claims the instant rewards like the lucky and diamond crates, leaves kits and cosmetics alone'
	})
	Notify = ClaimRewards:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you what got claimed'
	})
end)
