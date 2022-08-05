local player = ...
local args = ...
local GroupWheel = args.GroupWheel
local SongWheel = args.SongWheel
local nsj = GAMESTATE:GetNumSidesJoined()

local ChartUpdater = LoadActor("./UpdateChart.lua")
local screen = SCREENMAN:GetTopScreen()
-- initialize Players to be any HumanPlayers at screen init
-- we'll update this later via latejoin if needed
local Players = GAMESTATE:GetHumanPlayers()

local ActiveOptionRow

local didSelectSong = false
local PressStartForOptions = false
isSortMenuVisible = false
InputMenuHasFocus = false
LeadboardHasFocus = false

-----------------------------------------------------
-- input handler
local t = {}
-----------------------------------------------------


local SwitchInputFocus = function(button)
	if button == "Start" or "DeviceButton_left mouse button" then

		if t.WheelWithFocus == GroupWheel then
			if NameOfGroup == "RANDOM-PORTAL" then
				didSelectSong = true
				TransitionTime = 0
				PressStartForOptions = true
				SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
				MESSAGEMAN:Broadcast('ShowOptionsJawn')
				t.WheelWithFocus = SongWheel
			else
				MESSAGEMAN:Broadcast("SwitchFocusToSongs")
				t.WheelWithFocus = SongWheel
			end

		elseif t.WheelWithFocus == SongWheel then
			didSelectSong = true
			TransitionTime = 0
			PressStartForOptions = true
			SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
			MESSAGEMAN:Broadcast('ShowOptionsJawn')
		end
	elseif button == "Select" or button == "Back" then
		if t.WheelWithFocus == SongWheel then
			t.WheelWithFocus = GroupWheel
		end

	end
end

-- calls needed to close the current group folder and return to choosing a group
local CloseCurrentFolder = function()
	-- if focus is already on the GroupWheel, we don't need to do anything more
	if t.WheelWithFocus == GroupWheel then 
	NameOfGroup = ""
	return end
	
	if SongSearchWheelNeedsResetting == true then
		SongSearchWheelNeedsResetting = false
		MESSAGEMAN:Broadcast("ReloadSSMDD")
	else	
		-- otherwise...
		t.Enabled = false
		MESSAGEMAN:Broadcast("SwitchFocusToGroups")
		t.WheelWithFocus.container:queuecommand("Hide")
		t.WheelWithFocus = GroupWheel
		t.WheelWithFocus.container:queuecommand("Unhide")
	end
end

t.AllowLateJoin = function()
	-- Only allow LateJoin if playing single.
	if GAMESTATE:GetCurrentStyle():GetName() ~= "single" then return false end
	return true
end

-----------------------------------------------------
-- start internal functions

t.Init = function()
	-- flag used to determine whether input is permitted
	-- false at initialization
	t.Enabled = false
	-- initialize which wheel gets focus to start based on whether or not
	-- GAMESTATE has a CurrentSong (it always should at screen init)
	t.WheelWithFocus = GAMESTATE:GetCurrentSong() and SongWheel or GroupWheel
	
end

local lastMenuUpPressTime = 0
local lastMenuDownPressTime = 0

t.Handler = function(event)
	-- Allow Mouse Input here
	if event.type == "InputEventType_FirstPress" then
		if event.DeviceInput.button == "DeviceButton_middle mouse button" and t.WheelWithFocus == SongWheel and not didSelectSong then
			stop_music()
			SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
			MESSAGEMAN:Broadcast("CloseCurrentFolder")
			CloseCurrentFolder()
		end
		if event.DeviceInput.button == "DeviceButton_left mouse button" then
			for i=1, 4 do
				if IsMouseGucci(_screen.cx, (_screen.cy + 45) - (i*25), 320, 24) then
					t.WheelWithFocus:scroll_by_amount(-i)
					SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
					stop_music()
					ChartUpdater.UpdateCharts()
				end
			end
			
			for i=1, 6 do
				if IsMouseGucci(_screen.cx, (_screen.cy + 45) + (i*25), 320, 24) then
					t.WheelWithFocus:scroll_by_amount(i)
					SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
					stop_music()
					ChartUpdater.UpdateCharts()
				end
			end
			
			if IsMouseGucci(_screen.cx, (_screen.cy + 45), 320, 24) then
				if t.WheelWithFocus == SongWheel then
					if didSelectSong then
						SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
						SCREENMAN:SetNewScreen("ScreenPlayerOptions")
						return false
					end
					if t.WheelWithFocus:get_info_at_focus_pos() ~= "CloseThisFolder" then
						didSelectSong = true
						TransitionTime = 0
						PressStartForOptions = true
						SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
						MESSAGEMAN:Broadcast('ShowOptionsJawn')
					elseif t.WheelWithFocus:get_info_at_focus_pos() == "CloseThisFolder" then
						SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
						CloseCurrentFolder()
						return false
					end
				elseif t.WheelWithFocus == GroupWheel then
					if NameOfGroup == "RANDOM-PORTAL" then
						didSelectSong = true
						TransitionTime = 0
						PressStartForOptions = true
						SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
						MESSAGEMAN:Broadcast('ShowOptionsJawn')
						t.WheelWithFocus = SongWheel
					else
						SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
						t.WheelWithFocus.container:queuecommand("Start")
						SwitchInputFocus(event.DeviceInput.button)

						if t.WheelWithFocus.container then
							t.WheelWithFocus.container:queuecommand("Unhide")
						end
					end
				end
			end
			
		end
	end
	
	-- if any of these, don't attempt to handle input
	if t.Enabled == false or not event or not event.PlayerNumber or not event.button or SearchInput then
		return false
	end
	
	if isSortMenuVisible == false then
		if event.type ~= "InputEventType_Release" and event.type == "InputEventType_FirstPress" then
			if event.GameButton == "Select" then
				if event.PlayerNumber == 'PlayerNumber_P1' then
					PlayerControllingSort = 'PlayerNumber_P1' 
				else
					PlayerControllingSort = 'PlayerNumber_P2'
				end
				MESSAGEMAN:Broadcast("InitializeDDSortMenu")
				MESSAGEMAN:Broadcast("CheckForSongLeaderboard")
			end
		end
	end
	
	
	if isSortMenuVisible then
		if event.type ~= "InputEventType_Release" then
			if GAMESTATE:IsSideJoined(event.PlayerNumber) and event.PlayerNumber == PlayerControllingSort then
				if event.type == "InputEventType_FirstPress" then
					if event.GameButton == "Select" or event.GameButton == "Back" then
						if IsSortMenuInputToggled == false then
							if SortMenuNeedsUpdating == true then
								SortMenuNeedsUpdating = false
								MESSAGEMAN:Broadcast("ToggleSortMenu")
								MESSAGEMAN:Broadcast("ReloadSSMDD")
								isSortMenuVisible = false
								SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
							elseif SortMenuNeedsUpdating == false then
								isSortMenuVisible = false
								SOUND:PlayOnce( THEME:GetPathS("ScreenPlayerOptions", "cancel all.ogg") )
								MESSAGEMAN:Broadcast("ToggleSortMenu")
							end
						end
					end
				end
				if event.GameButton == "Start" then
					if event.type == "InputEventType_FirstPress" then
						-- main sorts/filters
						if DDSortMenuCursorPosition < 9 then
							MESSAGEMAN:Broadcast("UpdateCursorColor")
						end
						-- GS pack filter/toggle
						if DDSortMenuCursorPosition == 9 then
							SortMenuNeedsUpdating = true
						end	
						
						-- Favorites filter/toggle
						--[[if DDSortMenuCursorPosition == 10 then
							SortMenuNeedsUpdating = true
						end	--]]
						-- 
						-- Reset the sorts/prefrences
						if DDSortMenuCursorPosition == 10 then
							MESSAGEMAN:Broadcast("DDResetSortsFilters")
						end
						-- Switch between Song/Course Select
						if DDSortMenuCursorPosition == 11 then
							MESSAGEMAN:Broadcast("SwitchSongCourseSelect")
						end
						-- Everything from here on is dynamic so it's not always the same for each position.
						if DDSortMenuCursorPosition == 12 then
							if GAMESTATE:GetCurrentStyle():GetStyleType() ~= 'StyleType_TwoPlayersTwoSides' then
								MESSAGEMAN:Broadcast("DDSwitchStyles")
							elseif IsServiceAllowed(SL.GrooveStats.Leaderboard) then
								local curSong=GAMESTATE:GetCurrentSong()
								if not curSong then
									isSortMenuVisible = false
									InputMenuHasFocus = true
									MESSAGEMAN:Broadcast("ShowTestInput")
									MESSAGEMAN:Broadcast("ToggleSortMenu")
								else
									LeadboardHasFocus = true
									isSortMenuVisible = false
									MESSAGEMAN:Broadcast("ToggleSortMenu")
									MESSAGEMAN:Broadcast("ShowLeaderboard")
								end
							else
								isSortMenuVisible = false
								InputMenuHasFocus = true
								MESSAGEMAN:Broadcast("ShowTestInput")
								MESSAGEMAN:Broadcast("ToggleSortMenu")
							end
						end
						if DDSortMenuCursorPosition == 13 then
							if GAMESTATE:GetCurrentStyle():GetStyleType() ~= 'StyleType_TwoPlayersTwoSides' and IsServiceAllowed(SL.GrooveStats.Leaderboard) then
									local curSong=GAMESTATE:GetCurrentSong()
									if not curSong then
										isSortMenuVisible = false
										InputMenuHasFocus = true
										MESSAGEMAN:Broadcast("ShowTestInput")
										MESSAGEMAN:Broadcast("ToggleSortMenu")
									else
										LeadboardHasFocus = true
										isSortMenuVisible = false
										MESSAGEMAN:Broadcast("ToggleSortMenu")
										MESSAGEMAN:Broadcast("ShowLeaderboard")
									end
							elseif GAMESTATE:GetCurrentStyle():GetStyleType() ~= 'StyleType_TwoPlayersTwoSides' then
								if IsServiceAllowed(SL.GrooveStats.Leaderboard) then 
									local curSong=GAMESTATE:GetCurrentSong()
									if not curSong then
										isSortMenuVisible = false
										InputMenuHasFocus = true
										MESSAGEMAN:Broadcast("ShowTestInput")
										MESSAGEMAN:Broadcast("ToggleSortMenu")
									else
										LeadboardHasFocus = true
										isSortMenuVisible = false
										MESSAGEMAN:Broadcast("ToggleSortMenu")
										MESSAGEMAN:Broadcast("ShowLeaderboard")
									end
								else
									isSortMenuVisible = false
									InputMenuHasFocus = true
									MESSAGEMAN:Broadcast("ShowTestInput")
									MESSAGEMAN:Broadcast("ToggleSortMenu")
								end
							else
								isSortMenuVisible = false
								InputMenuHasFocus = true
								MESSAGEMAN:Broadcast("ShowTestInput")
								MESSAGEMAN:Broadcast("ToggleSortMenu")
							end
							
						end
						if DDSortMenuCursorPosition == 14 then
							isSortMenuVisible = false
							InputMenuHasFocus = true
							MESSAGEMAN:Broadcast("ShowTestInput")
							MESSAGEMAN:Broadcast("ToggleSortMenu")
						end
					end
				end
				
				if event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
					MESSAGEMAN:Broadcast("MoveCursorLeft")
					SOUND:PlayOnce( THEME:GetPathS("", "_prev row.ogg") )
					
				end
				
				if event.GameButton == "MenuRight" or event.GameButton == "MenuDown" then
					MESSAGEMAN:Broadcast("MoveCursorRight")
					SOUND:PlayOnce( THEME:GetPathS("", "_next row.ogg") )
				end
				
				if IsSortMenuInputToggled == true then
					if event.GameButton == "Start" and event.type == "InputEventType_FirstPress" and event.type ~= "InputEventType_Release" then
						MESSAGEMAN:Broadcast("SetSortMenuTopStats")
						MESSAGEMAN:Broadcast("UpdateCursorColor")
					end
				end
						if IsSortMenuInputToggled == true then
							if event.GameButton == "Start" and event.type == "InputEventType_FirstPress" and event.type ~= "InputEventType_Release" then
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							end
						elseif event.GameButton == "Start" and event.type == "InputEventType_FirstPress" and event.type ~= "InputEventType_Release" then
							MESSAGEMAN:Broadcast("SortMenuOptionSelected")
							SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
						end
				
				---- This stops the cursor from moving when selecting a variable option
				---- Like filtering bpms/difficulties/etc
				if IsSortMenuInputToggled == true then
					if event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
						MESSAGEMAN:Broadcast("MoveSortMenuOptionLeft")
					elseif event.GameButton == "MenuRight" or event.GameButton == "MenuDown"then
						MESSAGEMAN:Broadcast("MoveSortMenuOptionRight")
					elseif event.GameButton == "Select" or event.GameButton == "Back" then
						SOUND:PlayOnce( THEME:GetPathS("common", "invalid.ogg") )
						MESSAGEMAN:Broadcast("UpdateCursorColor")
						MESSAGEMAN:Broadcast("ToggleSortMenuMovement")
					end
				end
			else end
		end
		
		return false
	end
	
	--- Input handler for the Test Input screen
	if InputMenuHasFocus then
		if not (event and event.PlayerNumber and event.button) then
			return false
		end
		-- don't handle input for a non-joined player
		if not GAMESTATE:IsSideJoined(event.PlayerNumber) then
			return false
		end

		SOUND:StopMusic()

		local screen   = SCREENMAN:GetTopScreen()
		local overlay  = screen:GetChild("Overlay")

		-- broadcast event data using MESSAGEMAN for the TestInput overlay to listen for
		if event.type ~= "InputEventType_Repeat" then
			MESSAGEMAN:Broadcast("TestInputEvent", event)
		end

		-- pressing Start or Back (typically Esc on a keyboard) will queue "DirectInputToEngine"
		-- but only if the event.type is not a Release
		-- as soon as TestInput is activated via the SortMenu, the player is likely still holding Start
		-- and will soon release it to start testing their input, which would inadvertently close TestInput
		if (event.GameButton == "Start" or event.GameButton == "Back") and event.type ~= "InputEventType_Release" then
			InputMenuHasFocus = false
			SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
			MESSAGEMAN:Broadcast("HideTestInput")
		end

		return false
	end
	
	--- Input handler for the GS/RPG leaderboards
	if LeadboardHasFocus then
		if not (event and event.PlayerNumber and event.button) then
			return false
		end
		-- Don't handle input for a non-joined player.
		if not GAMESTATE:IsSideJoined(event.PlayerNumber) then
			return false
		end

		SOUND:StopMusic()

		local screen   = SCREENMAN:GetTopScreen()
		local overlay  = screen:GetChild("Overlay")

		-- Broadcast event data using MESSAGEMAN for the Leaderboard overlay to listen for.
		if event.type ~= "InputEventType_Repeat" then
			MESSAGEMAN:Broadcast("LeaderboardInputEvent", event)
		end

		-- Pressing Start or Back (typically Esc on a keyboard) will queue "DirectInputToEngine"
		-- but only if the event.type is not a Release.
		-- As soon as the Leaderboard is activated via the SortMenu, the player is likely still holding Start
		-- and will soon release it to start testing their input, which would inadvertently close the Leaderboard.
		if (event.GameButton == "Start" or event.GameButton == "Back") and event.type ~= "InputEventType_Release" then
			LeadboardHasFocus = false
			SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
			MESSAGEMAN:Broadcast("HideLeaderboard")
		end

		return false
	end
	
	-- Disable input if EscapeFromEventMode is active
	if EscapeFromEventMode then
		t.enabled = false
	end
	
if not GAMESTATE:IsSideJoined(event.PlayerNumber) then
		if not t.AllowLateJoin() then return false end

		-- latejoin
		if event.GameButton == "Start" and not SearchInput then
			GAMESTATE:JoinPlayer( event.PlayerNumber )
			Players = GAMESTATE:GetHumanPlayers()
			MESSAGEMAN:Broadcast("ReloadSSMDD")
		end
		return false
	end

	if event.type ~= "InputEventType_Release" then

		if event.GameButton == "Back" and event.type == "InputEventType_FirstPress" then
			if didSelectSong then
				didSelectSong = false
				PressStartForOptions = false
				MESSAGEMAN:Broadcast('HideOptionsJawn')
				return false
			end
		
			SCREENMAN:GetTopScreen():SetNextScreenName( Branch.SSMCancel() ):StartTransitioningScreen("SM_GoToNextScreen")
		end
		-------------------------------------------------------------
		if event.GameButton == "Select" and event.type == "InputEventType_FirstPress"  then
			if PressStartForOptions == false then
					isSortMenuVisible = true
					SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "sort.ogg") )
					stop_music()
					MESSAGEMAN:Broadcast("ToggleSortMenu")
			end
		end
		UpdateGroupWheelMessageCommand = function(self)
			t.WheelWithFocus:scroll_by_amount(1)
		end
		--------------------------------------------------------------
		-- proceed to the next wheel
		if event.GameButton == "Start" then
			if event.type == "InputEventType_FirstPress" then
				if didSelectSong then
					SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
					SCREENMAN:SetNewScreen("ScreenPlayerOptions")
					return false
				end
				
				if NameOfGroup == "RANDOM-PORTAL" then
					didSelectSong = true
					PressStartForOptions = true
					SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
					MESSAGEMAN:Broadcast('ShowOptionsJawn')
					return
				end

				if t.WheelWithFocus:get_info_at_focus_pos() == "CloseThisFolder" then
					SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
					CloseCurrentFolder()
					return false
				end

				if t.WheelWithFocus == GroupWheel and NameOfGroup ~= "RANDOM-PORTAL" then
					SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
				end

				t.WheelWithFocus.container:queuecommand("Start")
				SwitchInputFocus(event.GameButton)

				if t.WheelWithFocus.container then
					t.WheelWithFocus.container:queuecommand("Unhide")
				end
			end
		elseif didSelectSong then
			return false
		-- navigate the wheel left and right
		elseif event.GameButton == "MenuRight" then
			t.WheelWithFocus:scroll_by_amount(1)
			SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
			stop_music()
			ChartUpdater.UpdateCharts()
		elseif event.GameButton == "MenuLeft" then
			t.WheelWithFocus:scroll_by_amount(-1)
			SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
			stop_music()
			ChartUpdater.UpdateCharts()
		elseif event.GameButton == "MenuUp" or event.button == "Up" then
			if event.type == "InputEventType_FirstPress" then
				local t = GetTimeSinceStart()
				local dt = t - lastMenuUpPressTime
				lastMenuUpPressTime = t
				if dt < 0.5 then
					ChartUpdater.DecreaseDifficulty(event.PlayerNumber)
					lastMenuUpPressTime = 0
				end
			end
		elseif event.GameButton == "MenuDown" or event.button == "Down" then
			if event.type == "InputEventType_FirstPress" then
				local t = GetTimeSinceStart()
				local dt = t - lastMenuDownPressTime
				lastMenuDownPressTime = t
				if dt < 0.5 then
					ChartUpdater.IncreaseDifficulty(event.PlayerNumber)
					lastMenuDownPressTime = 0
				end
			end
		end
	end


	return false
end

return t