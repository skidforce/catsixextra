
run(function()
	local SetEmote
	local Emote
	local track
	
	local list, old = {}, {}
	for i, v in bedwars.EmoteMeta do
		if i ~= bedwars.EmoteType.NONE and v.name and not old[v.name] then
			old[v.name] = i
			table.insert(list, v.name)
		end
	end
	table.sort(list)
	
	local function cancelEmote()
		if entitylib.isAlive then
			if track then
				track:Stop()
				track:Destroy()
				track = nil
			end
			if lplr.Character:GetAttribute('PlayingEmote') then
				lplr.Character:SetAttribute('PlayingEmote', nil)
			end
		end
	end
	
	SetEmote = vape.Categories.Utility:CreateModule({
		Name = 'SetEmote',
		Function = function(callback)
			if callback then
				SetEmote:Toggle()
				if entitylib.isAlive then
					local emoteType = old[Emote.Value]
					local meta = bedwars.EmoteMeta[emoteType]
					if meta then
						lplr.Character:SetAttribute('PlayingEmote', emoteType)
						local playBeginSounds = bedwars.EmoteController.createEmoteBeginAudioPlayers or bedwars.EmoteController.playEmoteBeginSounds
						if playBeginSounds then
							playBeginSounds(bedwars.EmoteController, emoteType, lplr)
						end
						local animation = meta.animation
						if not animation and meta.emoteDisplayType then
							local display = bedwars.EmoteDisplayMeta[meta.emoteDisplayType]
							animation = display and display.animation
						end
						if animation and not noAutoPlayAnimation then
							track = lplr.Character.Humanoid:LoadAnimation(bedwars.GameAnimationUtil:getAnimation(animation.type))
							track.Looped = animation.looped or false
							track:Play(nil, nil, animation.speed or 1)
						end
						if not meta.animation then
							local gui = Instance.new('BillboardGui')
							gui.Size = UDim2.fromScale(6, 2.5)
							gui.StudsOffset = Vector3.new(0, 2, 0)
							gui.AlwaysOnTop = true
							gui.Adornee = lplr.Character.Head
	
							local image = Instance.new('ImageLabel')
							image.AnchorPoint = Vector2.new(0.5, 1)
							image.Position = UDim2.fromScale(0.5, 1)
							image.Size = UDim2.fromScale(0, 0)
							image.Image = meta.image
							image.BackgroundTransparency = 1
							image.ImageTransparency = 1
							image.ScaleType = Enum.ScaleType.Fit
							image.Parent = gui
	
							gui.Parent = lplr.Character.Head
							tweenService:Create(image, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
								Position = UDim2.fromScale(0.5, 0.5),
								Size = UDim2.fromScale(1, 1),
								ImageTransparency = 0
							}):Play()
						end
						if meta.allowMovement then
							task.delay(6, cancelEmote)
						else
							lplr.Character.Humanoid:GetPropertyChangedSignal('MoveDirection'):Once(cancelEmote)
						end
					end
				end
			end
		end,
		Tooltip = 'Plays selected emote clientsidedly'
	})
	Emote = SetEmote:CreateDropdown({
		Name = 'Emote',
		List = list,
		Default = 'nightmare'
	})
end)
