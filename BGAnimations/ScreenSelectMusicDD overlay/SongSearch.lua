local holdingCtrl = false
local holdingShift = false

local InputHandler = function( event )

	-- if (somehow) there's no event, bail
	if not event then return end

	if event.type == "InputEventType_FirstPress" then
		
		--Trace(event.DeviceInput.button)
		
		if event.DeviceInput.button == "DeviceButton_left ctrl" then
			holdingCtrl = true
		end
		
		if holdingCtrl then
			if event.DeviceInput.button == "DeviceButton_f" then
				holdingCtrl = false
				SearchInput = true
				MESSAGEMAN:Broadcast("SongSearchSSMDD")
			end
		end
		
	end
	
	if event.type == "InputEventType_Release" then
		if event.DeviceInput.button == "DeviceButton_left ctrl" then
			holdingCtrl = false
		end
	end

end


local t = Def.ActorFrame{
	OnCommand=function(self)
		screen = SCREENMAN:GetTopScreen()
		screen:AddInputCallback( InputHandler )
		if SongSearchSSMDD == true then
			SongSearchSSMDD = false
			SongSearchAnswer = nil
		end	
	end,

	SongSearchSSMDDMessageCommand = function(self)
		SCREENMAN:AddNewScreenToTop("ScreenTextEntry");
		local songSearch = {
			Question = "\nSEARCH FOR:\nSongs\nSong Artists\nStep Artists",
			MaxInputLength = 52,
			OnOK = function(answer)
				--- has to sleep in order to be able to reload because #StepmaniaMoment
				--- If the player doesn't enter any text and just presses enter just reload the screen to the normal wheel
				if answer ~= "" then
					local results = 0
					for i,song in ipairs(SongsAvailable) do
						local match = false
						local title = song:GetDisplayFullTitle():lower()
						local artist = song:GetDisplayArtist():lower()
						local steps_type = GAMESTATE:GetCurrentStyle():GetStepsType()
						-- the query "xl grind" will match a song called "Axle Grinder" no matter
						-- what the chart info says
						if title:match(answer:lower()) then
							if title ~= "Random-Portal" and title ~= "RANDOM-PORTAL" then
								match = true
								results = results + 1
							end
						elseif artist:match(answer:lower()) then
							if title ~= "Random-Portal" and title ~= "RANDOM-PORTAL" then
								match = true
								results = results + 1
							end
						end
						
						if not match then
							for i, steps in ipairs(song:GetStepsByStepsType(steps_type)) do
								local chartStr = steps:GetAuthorCredit().." "..steps:GetDescription()
								-- the query "br xo fs" will match any song with at least one chart that
								-- has "br", "xo" and "fs" in its AuthorCredit + Description
								
								if chartStr:lower():match(answer:lower()) then
									if title ~= "Random-Portal" and title ~= "RANDOM-PORTAL" then
										match = true
										results = results + 1
									end
								else
									match = false
									break
								end
							end
						end
					end
					if results > 0 then
						self:sleep(0.2):queuecommand("TurnOffSearchInput")
						SongSearchSSMDD = true
						SongSearchAnswer = answer
						SongSearchWheelNeedsResetting = true
						self:sleep(0.25):queuecommand("ReloadScreen")
					else
						self:sleep(0.2):queuecommand("TurnOffSearchInput")
						SM("No songs found!")
					end
				else
					self:sleep(0.2):queuecommand("TurnOffSearchInput")
					SongSearchSSMDD = false
					SongSearchAnswer = nil
					SongSearchWheelNeedsResetting = false
					self:sleep(0.25):queuecommand("ReloadScreen")
				end
				
			end,
			OnCancel = function()
				self:sleep(0.2):queuecommand("TurnOffSearchInput")
			end,
			};
			SCREENMAN:GetTopScreen():Load(songSearch)
	end,
	
	TurnOffSearchInputCommand=function(self)
		SearchInput = false
	end,
	
	ReloadScreenCommand=function(self)
		screen:SetNextScreenName("ScreenReloadSSMDD")
		screen:StartTransitioningScreen("SM_GoToNextScreen")
	end,
}

return t