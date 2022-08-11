local args = ...
local af = args.af
local scrollers = args.Scrollers
local profile_data = args.ProfileData
local nsj = GAMESTATE:GetNumSidesJoined()
local IsP1Ready = false
local IsP2Ready = false
local topscreen = SCREENMAN:GetTopScreen()

-- we need to calculate how many dummy rows the scroller was "padded" with
-- (to achieve the desired transform behavior since I am not mathematically
-- perspicacious enough to have done so otherwise).
-- we'll use index_padding to get the correct info out of profile_data.
local index_padding = 0
for profile in ivalues(profile_data) do
	if profile.index == nil or profile.index <= 0 then
		index_padding = index_padding + 1
	end
end

local Handle = {}

Handle.Start = function(event)
	if event.type == "InputEventType_FirstPress" then
		-- if the input event came from a side that is not currently registered as a human player, we'll either
		-- want to reject the input (we're in Pay mode and there aren't enough credits to join the player),
		-- or we'll use ScreenSelectProfile's inscrutably custom SetProfileIndex() method to join the player.
		if not GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
			-- pass -1 to SetProfileIndex() to join that player
			-- see ScreenSelectProfile.cpp for details
			nsj = nsj + 1
			topscreen:SetProfileIndex(event.PlayerNumber, -1)
		else
			if nsj == 1 then
				MESSAGEMAN:Broadcast("StartButton")
				topscreen:queuecommand("Off"):sleep(0.4)
			elseif nsj == 2 then
				if event.PlayerNumber == "PlayerNumber_P1" and IsP1Ready == false then
					IsP1Ready = true
					if not IsP2Ready then
						MESSAGEMAN:Broadcast("StartButton")
					end
					MESSAGEMAN:Broadcast("P1ProfileReady")
				elseif  event.PlayerNumber == "PlayerNumber_P2" and IsP2Ready == false then
					IsP2Ready = true
					if not IsP1Ready then
						MESSAGEMAN:Broadcast("StartButton")
					end
					MESSAGEMAN:Broadcast("P2ProfileReady")
				end
				if IsP1Ready and IsP2Ready then
					-- we only bother checking scrollers to see if both players are
				-- trying to choose the same profile if there are scrollers because
				-- there are local profiles.  If there are no local profiles, there are
				-- no scrollers to compare.
				if PROFILEMAN:GetNumLocalProfiles() > 0
				-- and if both players have joined and neither is using a memorycard
				and #GAMESTATE:GetHumanPlayers() > 1 and not GAMESTATE:IsAnyHumanPlayerUsingMemoryCard() then
					-- and both players are trying to choose the same profile
					if scrollers[PLAYER_1]:get_info_at_focus_pos().index == scrollers[PLAYER_2]:get_info_at_focus_pos().index
					-- and that profile they are both trying to choose isn't [GUEST]
					and scrollers[PLAYER_1]:get_info_at_focus_pos().index ~= 0 then
						-- broadcast an InvalidChoice message to play the "Common invalid" sound
						-- and "shake" the playerframe for the player that just pressed start
						if event.PlayerNumber == "PlayerNumber_P1" then
							IsP1Ready = false
							MESSAGEMAN:Broadcast("P1ProfileUnReady")
						elseif event.PlayerNumber == "PlayerNumber_P2" then
							IsP2Ready = false
							MESSAGEMAN:Broadcast("P2ProfileUnReady")
						end
						MESSAGEMAN:Broadcast("InvalidChoice", {PlayerNumber=event.PlayerNumber})
						return
					end
				end

				-- otherwise, play the StartButton sound
				MESSAGEMAN:Broadcast("StartButton")
				-- and queue the OffCommand for the entire screen
				topscreen:queuecommand("Off"):sleep(0.4)
				end
			end
		end
	end
end
Handle.Center = Handle.Start


Handle.MenuLeft = function(event)
	-- don't allow player to change profiles if they're ready.
	if event.PlayerNumber == "PlayerNumber_P1" and IsP1Ready then return end
	if event.PlayerNumber == "PlayerNumber_P2" and IsP2Ready then return end
	
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) and MEMCARDMAN:GetCardState(event.PlayerNumber) == 'MemoryCardState_none' then
		local info = scrollers[event.PlayerNumber]:get_info_at_focus_pos()
		local index = type(info)=="table" and info.index or 0

		if index - 1 >= 0 then
			MESSAGEMAN:Broadcast("DirectionButton")
			scrollers[event.PlayerNumber]:scroll_by_amount(-1)

			local data = profile_data[index+index_padding-1]
			local frame = af:GetChild(ToEnumShortString(event.PlayerNumber) .. 'Frame')
			frame:GetChild("SelectedProfileText"):settext(data and data.displayname or "")
			frame:GetChild("ReadyText"):settext(data and data.displayname.."\nREADY" or "READY"):y(data and 45 or 40)
			frame:playcommand("Set", data)
		end
	end
end
Handle.MenuUp = Handle.MenuLeft
Handle.DownLeft = Handle.MenuLeft

Handle.MenuRight = function(event)
	-- don't allow player to change profiles if they're ready.
	if event.PlayerNumber == "PlayerNumber_P1" and IsP1Ready then return end
	if event.PlayerNumber == "PlayerNumber_P2" and IsP2Ready then return end
	
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) and MEMCARDMAN:GetCardState(event.PlayerNumber) == 'MemoryCardState_none' then
		local info = scrollers[event.PlayerNumber]:get_info_at_focus_pos()
		local index = type(info)=="table" and info.index or 0

		if index+1 <= PROFILEMAN:GetNumLocalProfiles() then
			MESSAGEMAN:Broadcast("DirectionButton")
			scrollers[event.PlayerNumber]:scroll_by_amount(1)

			local data = profile_data[index+index_padding+1]
			local frame = af:GetChild(ToEnumShortString(event.PlayerNumber) .. 'Frame')
			frame:GetChild("SelectedProfileText"):settext(data and data.displayname or "")
			frame:GetChild("ReadyText"):settext(data and data.displayname.."\nREADY" or "READY"):y(data and 45 or 40)
			frame:playcommand("Set", data)
		end
	end
end
Handle.MenuDown = Handle.MenuRight
Handle.DownRight = Handle.MenuRight

Handle.Back = function(event)
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
		if event.PlayerNumber == "PlayerNumber_P1" and IsP1Ready then
			IsP1Ready = false
			MESSAGEMAN:Broadcast("BackButton")
			MESSAGEMAN:Broadcast("P1ProfileUnReady")
		elseif event.PlayerNumber == "PlayerNumber_P2" and IsP2Ready then
			IsP2Ready = false
			MESSAGEMAN:Broadcast("BackButton")
			MESSAGEMAN:Broadcast("P2ProfileUnReady")
		elseif not IsP1Ready and not IsP2Ready then
			nsj = nsj - 1
			MESSAGEMAN:Broadcast("BackButton")
			-- ScreenSelectProfile:SetProfileIndex() will interpret -2 as
			-- "Unjoin this player and unmount their USB stick if there is one"
			-- see ScreenSelectProfile.cpp for details
			SCREENMAN:GetTopScreen():SetProfileIndex(event.PlayerNumber, -2)
		elseif event.PlayerNumber == "PlayerNumber_P1" and not IsP1Ready and nsj == 2 then
			nsj = nsj - 1
			MESSAGEMAN:Broadcast("BackButton")
			SCREENMAN:GetTopScreen():SetProfileIndex(event.PlayerNumber, -2)
			MESSAGEMAN:Broadcast("StartButton")
			topscreen:queuecommand("Off"):sleep(0.4)
		elseif event.PlayerNumber == "PlayerNumber_P2" and not IsP2Ready and nsj == 2 then
			nsj = nsj - 1
			MESSAGEMAN:Broadcast("BackButton")
			SCREENMAN:GetTopScreen():SetProfileIndex(event.PlayerNumber, -2)
			MESSAGEMAN:Broadcast("StartButton")
			topscreen:queuecommand("Off"):sleep(0.4)
		end
	elseif GAMESTATE:GetNumPlayersEnabled()==0 then
		SCREENMAN:GetTopScreen():Cancel()
	end
end
Handle.Select = Handle.Back


local InputHandler = function(event)
	-- Let's do mouse input here.
	if event.type == "InputEventType_FirstPress" and event.type ~= "InputEventType_Release" then
		if event.DeviceInput.button == "DeviceButton_left mouse button" then
			-- Player one join
			if IsMouseGucci(_screen.cx - 150, _screen.cy,184,216, "center", "middle") then
				if IsP1Ready then return end
				if not GAMESTATE:IsHumanPlayer("PlayerNumber_P1") then
					-- pass -1 to SetProfileIndex() to join that player
					-- see ScreenSelectProfile.cpp for details
					nsj = nsj + 1
					topscreen:SetProfileIndex("PlayerNumber_P1", -1)
				elseif IsMouseGucci(_screen.cx - 150, _screen.cy,184,216, "center", "middle") then
					if nsj == 1 then
						MESSAGEMAN:Broadcast("StartButton")
						topscreen:queuecommand("Off"):sleep(0.4)
					elseif nsj == 2 then
						IsP1Ready = true
						if not IsP2Ready then
							MESSAGEMAN:Broadcast("StartButton")
						end
						MESSAGEMAN:Broadcast("P1ProfileReady")
						if IsP1Ready and IsP2Ready then
							-- we only bother checking scrollers to see if both players are
							-- trying to choose the same profile if there are scrollers because
							-- there are local profiles.  If there are no local profiles, there are
							-- no scrollers to compare.
							if PROFILEMAN:GetNumLocalProfiles() > 0
							-- and if both players have joined and neither is using a memorycard
							and #GAMESTATE:GetHumanPlayers() > 1 and not GAMESTATE:IsAnyHumanPlayerUsingMemoryCard() then
								-- and both players are trying to choose the same profile
								if scrollers[PLAYER_1]:get_info_at_focus_pos().index == scrollers[PLAYER_2]:get_info_at_focus_pos().index
								-- and that profile they are both trying to choose isn't [GUEST]
								and scrollers[PLAYER_1]:get_info_at_focus_pos().index ~= 0 then
									-- broadcast an InvalidChoice message to play the "Common invalid" sound
									-- and "shake" the playerframe for the player that just pressed start
									IsP1Ready = false
									MESSAGEMAN:Broadcast("P1ProfileUnReady")
									MESSAGEMAN:Broadcast("InvalidChoice", {PlayerNumber="PlayerNumber_P1"})
									return
								end
								-- otherwise, play the StartButton sound
								MESSAGEMAN:Broadcast("StartButton")
								-- and queue the OffCommand for the entire screen
								topscreen:queuecommand("Off"):sleep(0.4)
							end
						end
					end
				end
			end
			
			-- Player two join
			if IsMouseGucci(_screen.cx + 150, _screen.cy,184,216, "center", "middle") then
				if IsP2Ready then return end
				if not GAMESTATE:IsHumanPlayer("PlayerNumber_P2") then
					-- pass -1 to SetProfileIndex() to join that player
					-- see ScreenSelectProfile.cpp for details
					nsj = nsj + 1
					topscreen:SetProfileIndex("PlayerNumber_P2", -1)
				elseif IsMouseGucci(_screen.cx + 150, _screen.cy,184,216, "center", "middle") then
					if nsj == 1 then
						MESSAGEMAN:Broadcast("StartButton")
						topscreen:queuecommand("Off"):sleep(0.4)
					elseif nsj == 2 then
						IsP2Ready = true
						if not IsP1Ready then
							MESSAGEMAN:Broadcast("StartButton")
						end
						MESSAGEMAN:Broadcast("P2ProfileReady")
						if IsP1Ready and IsP2Ready then
							-- we only bother checking scrollers to see if both players are
							-- trying to choose the same profile if there are scrollers because
							-- there are local profiles.  If there are no local profiles, there are
							-- no scrollers to compare.
							if PROFILEMAN:GetNumLocalProfiles() > 0
							-- and if both players have joined and neither is using a memorycard
							and #GAMESTATE:GetHumanPlayers() > 1 and not GAMESTATE:IsAnyHumanPlayerUsingMemoryCard() then
								-- and both players are trying to choose the same profile
								if scrollers[PLAYER_1]:get_info_at_focus_pos().index == scrollers[PLAYER_2]:get_info_at_focus_pos().index
								-- and that profile they are both trying to choose isn't [GUEST]
								and scrollers[PLAYER_1]:get_info_at_focus_pos().index ~= 0 then
									-- broadcast an InvalidChoice message to play the "Common invalid" sound
									-- and "shake" the playerframe for the player that just pressed start
									IsP2Ready = false
									MESSAGEMAN:Broadcast("P2ProfileUnReady")
									MESSAGEMAN:Broadcast("InvalidChoice", {PlayerNumber="PlayerNumber_P2"})
									return
								end
								-- otherwise, play the StartButton sound
								MESSAGEMAN:Broadcast("StartButton")
								-- and queue the OffCommand for the entire screen
								topscreen:queuecommand("Off"):sleep(0.4)
							end
						end
					end
				end
			end
		end
		
		-- Scroll through available profiles with mouse wheel
		if event.DeviceInput.button == "DeviceButton_mousewheel down" then
			-- Player one (only scroll if they are on profile select, but not ready.)
			if IsMouseGucci(_screen.cx - 150, _screen.cy,184,216, "center", "middle") and GAMESTATE:IsHumanPlayer("PlayerNumber_P1") and not IsP1Ready then
				event.PlayerNumber = "PlayerNumber_P1"
			elseif IsMouseGucci(_screen.cx + 150, _screen.cy,184,216, "center", "middle") and GAMESTATE:IsHumanPlayer("PlayerNumber_P2") and not IsP2Ready then
				event.PlayerNumber = "PlayerNumber_P2"
			else
				return
			end
			if MEMCARDMAN:GetCardState(event.PlayerNumber) == 'MemoryCardState_none' then
				local info = scrollers[event.PlayerNumber]:get_info_at_focus_pos()
				local index = type(info)=="table" and info.index or 0

				if index+1 <= PROFILEMAN:GetNumLocalProfiles() then
					MESSAGEMAN:Broadcast("DirectionButton")
					scrollers[event.PlayerNumber]:scroll_by_amount(1)

					local data = profile_data[index+index_padding+1]
					local frame = af:GetChild(ToEnumShortString(event.PlayerNumber) .. 'Frame')
					frame:GetChild("SelectedProfileText"):settext(data and data.displayname or "")
					frame:GetChild("ReadyText"):settext(data and data.displayname.."\nREADY" or "READY"):y(data and 45 or 40)
					frame:playcommand("Set", data)
				end
			end
		elseif event.DeviceInput.button == "DeviceButton_mousewheel up" then
			if IsMouseGucci(_screen.cx - 150, _screen.cy,184,216, "center", "middle") and GAMESTATE:IsHumanPlayer("PlayerNumber_P1") and not IsP1Ready then
				event.PlayerNumber = "PlayerNumber_P1"
			elseif IsMouseGucci(_screen.cx + 150, _screen.cy,184,216, "center", "middle") and GAMESTATE:IsHumanPlayer("PlayerNumber_P2") and not IsP2Ready then
				event.PlayerNumber = "PlayerNumber_P2"
			else
				return
			end
			if MEMCARDMAN:GetCardState(event.PlayerNumber) == 'MemoryCardState_none' then
				local info = scrollers[event.PlayerNumber]:get_info_at_focus_pos()
				local index = type(info)=="table" and info.index or 0

				if index - 1 >= 0 then
					MESSAGEMAN:Broadcast("DirectionButton")
					scrollers[event.PlayerNumber]:scroll_by_amount(-1)

					local data = profile_data[index+index_padding-1]
					local frame = af:GetChild(ToEnumShortString(event.PlayerNumber) .. 'Frame')
					frame:GetChild("SelectedProfileText"):settext(data and data.displayname or "")
					frame:GetChild("ReadyText"):settext(data and data.displayname.."\nREADY" or "READY"):y(data and 45 or 40)
					frame:playcommand("Set", data)
				end
			end
		end
		
		-- Unready or unjoin player
		if event.DeviceInput.button == "DeviceButton_right mouse button" then
			local NoPlayers
			
			if IsMouseGucci(_screen.cx - 150, _screen.cy,184,216, "center", "middle") then
				event.PlayerNumber = "PlayerNumber_P1"
			elseif IsMouseGucci(_screen.cx + 150, _screen.cy,184,216, "center", "middle") then
				event.PlayerNumber = "PlayerNumber_P2"
			elseif nsj == 0 then
				NoPlayers = true
				SCREENMAN:GetTopScreen():Cancel()
			else
				return
			end
			
			if not NoPlayers and GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
				if event.PlayerNumber == "PlayerNumber_P1" and IsP1Ready then
					IsP1Ready = false
					MESSAGEMAN:Broadcast("BackButton")
					MESSAGEMAN:Broadcast("P1ProfileUnReady")
				elseif event.PlayerNumber == "PlayerNumber_P2" and IsP2Ready then
					IsP2Ready = false
					MESSAGEMAN:Broadcast("BackButton")
					MESSAGEMAN:Broadcast("P2ProfileUnReady")
				elseif not IsP1Ready and not IsP2Ready then
					nsj = nsj - 1
					MESSAGEMAN:Broadcast("BackButton")
					-- ScreenSelectProfile:SetProfileIndex() will interpret -2 as
					-- "Unjoin this player and unmount their USB stick if there is one"
					-- see ScreenSelectProfile.cpp for details
					SCREENMAN:GetTopScreen():SetProfileIndex(event.PlayerNumber, -2)
				elseif event.PlayerNumber == "PlayerNumber_P1" and not IsP1Ready and nsj == 2 then
					nsj = nsj - 1
					MESSAGEMAN:Broadcast("BackButton")
					SCREENMAN:GetTopScreen():SetProfileIndex(event.PlayerNumber, -2)
					MESSAGEMAN:Broadcast("StartButton")
					topscreen:queuecommand("Off"):sleep(0.4)
				elseif event.PlayerNumber == "PlayerNumber_P2" and not IsP2Ready and nsj == 2 then
					nsj = nsj - 1
					MESSAGEMAN:Broadcast("BackButton")
					SCREENMAN:GetTopScreen():SetProfileIndex(event.PlayerNumber, -2)
					MESSAGEMAN:Broadcast("StartButton")
					topscreen:queuecommand("Off"):sleep(0.4)
				end
			elseif GAMESTATE:GetNumPlayersEnabled()==0 then
				SCREENMAN:GetTopScreen():Cancel()
			end
		end
		
	end
	
	if not event or not event.button then return false end

	if event.type ~= "InputEventType_Release" then
		if Handle[event.GameButton] then Handle[event.GameButton](event) end
	end
end

return InputHandler