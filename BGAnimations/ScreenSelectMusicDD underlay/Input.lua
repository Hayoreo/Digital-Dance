local player = ...
local args = ...
local GroupWheel = args.GroupWheel
local SongWheel = args.SongWheel
local nsj = GAMESTATE:GetNumSidesJoined()
local holdingCtrl
local CtrlHeld = 0
local WheelWidth = SCREEN_WIDTH/3

local ChartUpdater = LoadActor("./UpdateChart.lua")
local screen = SCREENMAN:GetTopScreen()
-- initialize Players to be any HumanPlayers at screen init
-- we'll update this later via latejoin if needed
local Players = GAMESTATE:GetHumanPlayers()

local didSelectSong = false
local PressStartForOptions = false
isSortMenuVisible = false
IsSearchMenuVisible = false
InputMenuHasFocus = false
LeadboardHasFocus = false

-----------------------------------------------------
-- input handler
local t = {}
-----------------------------------------------------


local SwitchInputFocus = function(button)
	if button == "Start" or "DeviceButton_left mouse button" and not IsSearchMenuVisible then
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
		if t.WheelWithFocus == SongWheel and not IsSearchMenuVisible then
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

local SortMenuCursorLogic = function()
	-- main sorts/filters
	if DDSortMenuCursorPosition < 9 then
		MESSAGEMAN:Broadcast("UpdateCursorColor")
	end
	-- GS/Autogen filter/toggle
	if DDSortMenuCursorPosition == 9 or DDSortMenuCursorPosition == 10 then
		SortMenuNeedsUpdating = true
	end
	
	-- Favorites filter/toggle
	--[[if DDSortMenuCursorPosition == 10 then
		SortMenuNeedsUpdating = true
	end	--]]
	-- 
	-- Reset the sorts/prefrences
	if DDSortMenuCursorPosition == 11 then
		MESSAGEMAN:Broadcast("DDResetSortsFilters")
	end
	-- Switch between Song/Course Select
	if DDSortMenuCursorPosition == 12 then
		MESSAGEMAN:Broadcast("SwitchSongCourseSelect")
	end
	-- Everything from here on is dynamic so it's not always the same for each position.
	if DDSortMenuCursorPosition == 13 then
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
	if DDSortMenuCursorPosition == 14 then
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
	if DDSortMenuCursorPosition == 15 then
		if not GAMESTATE:GetCurrentStyle():GetStyleType() == 'StyleType_OnePlayerTwoSides' then
			isSortMenuVisible = false
			InputMenuHasFocus = true
			MESSAGEMAN:Broadcast("ShowTestInput")
			MESSAGEMAN:Broadcast("ToggleSortMenu")
		end
		if IsServiceAllowed(SL.GrooveStats.Leaderboard) then
			isSortMenuVisible = false
			InputMenuHasFocus = true
			MESSAGEMAN:Broadcast("ShowTestInput")
			MESSAGEMAN:Broadcast("ToggleSortMenu")
		end
	end
	if DDSortMenuCursorPosition == GetMaxCursorPosition() and GAMESTATE:GetCurrentStyle():GetStyleType() == 'StyleType_OnePlayerTwoSides' and GAMESTATE:IsPlayerEnabled(0) then
		SCREENMAN:GetTopScreen():SetNextScreenName("ScreenPractice")
		SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
	end
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
	-- Input to open the song search menu or reload a single song on the wheel. Keep track of both left and right Ctrl being held.
	if event.type == "InputEventType_FirstPress" and event.type ~= "InputEventType_Release" then
		if not IsSearchMenuVisible then
			if event.DeviceInput.button == "DeviceButton_left ctrl" or event.DeviceInput.button == "DeviceButton_right ctrl" then
				CtrlHeld = CtrlHeld + 1
			end
			
			if CtrlHeld > 0 then
				holdingCtrl = true
			end
			
			if holdingCtrl then
				if event.DeviceInput.button == "DeviceButton_f" then
					SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "sort.ogg") )
					stop_music()
					MESSAGEMAN:Broadcast("InitializeSearchMenu")
					MESSAGEMAN:Broadcast("ToggleSearchMenu")
				elseif event.DeviceInput.button == "DeviceButton_r" and GAMESTATE:GetCurrentSong() ~= nil then
					local song = GAMESTATE:GetCurrentSong()
					song:ReloadFromSongDir()
					MESSAGEMAN:Broadcast("SongIsReloading")
				end
			end
		end
		
		if event.DeviceInput.button == "DeviceButton_escape" and IsSearchMenuVisible then
			SOUND:PlayOnce( THEME:GetPathS("ScreenPlayerOptions", "cancel all.ogg") )
			MESSAGEMAN:Broadcast("ToggleSearchMenu")
		end
	end
	
	if event.type == "InputEventType_Release" then
		if event.DeviceInput.button == "DeviceButton_left ctrl" or event.DeviceInput.button == "DeviceButton_right ctrl" then
			CtrlHeld = CtrlHeld - 1
			if CtrlHeld < 0 then
				CtrlHeld = 0
			end
		end
		if CtrlHeld == 0 then
			holdingCtrl = false
		end
	end
	-- Allow Mouse Input here
	if event.type == "InputEventType_FirstPress" and event.type ~= "InputEventType_Release" and not IsSearchMenuVisible then
		if IsMouseOnScreen() and ThemePrefs.Get("MouseInput") then
			if not isSortMenuVisible and not LeadboardHasFocus and not InputMenuHasFocus then
				-- Close the song folder and switch to group wheel if mouse wheel is pressed.
				if event.DeviceInput.button == "DeviceButton_middle mouse button" and t.WheelWithFocus == SongWheel and not didSelectSong then
					stop_music()
					SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
					MESSAGEMAN:Broadcast("CloseCurrentFolder")
					CloseCurrentFolder()
				end
				
				-- Scroll the song wheel up/down with the mouse wheel.
				if event.DeviceInput.button == "DeviceButton_mousewheel up" and not PressStartForOptions then
					if IsMouseGucci(0, _screen.h - 152, SCREEN_WIDTH/3, 50, "left", "bottom") then
						if GAMESTATE:IsHumanPlayer("PlayerNumber_P1") then
							ChartUpdater.DecreaseDifficulty("PlayerNumber_P1")
						else
							t.WheelWithFocus:scroll_by_amount(-1)
							SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
							stop_music()
							ChartUpdater.UpdateCharts()
						end
					elseif IsMouseGucci(SCREEN_RIGHT, _screen.h - 152, SCREEN_WIDTH/3, 50, "right", "bottom") then
						if GAMESTATE:IsHumanPlayer("PlayerNumber_P2") then
							ChartUpdater.DecreaseDifficulty("PlayerNumber_P2")
						else
							t.WheelWithFocus:scroll_by_amount(-1)
							SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
							stop_music()
							ChartUpdater.UpdateCharts()
						end
					else
						t.WheelWithFocus:scroll_by_amount(-1)
						SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
						stop_music()
						ChartUpdater.UpdateCharts()
					end
				elseif event.DeviceInput.button == "DeviceButton_mousewheel down" and not PressStartForOptions then
					if IsMouseGucci(0, _screen.h - 152, SCREEN_WIDTH/3, 50, "left", "bottom") then
						if GAMESTATE:IsHumanPlayer("PlayerNumber_P1") then
							ChartUpdater.IncreaseDifficulty("PlayerNumber_P1")
						else
							t.WheelWithFocus:scroll_by_amount(1)
							SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
							stop_music()
							ChartUpdater.UpdateCharts()
						end
					elseif IsMouseGucci(SCREEN_RIGHT, _screen.h - 152, SCREEN_WIDTH/3, 50, "right", "bottom") then
						if GAMESTATE:IsHumanPlayer("PlayerNumber_P2") then
							ChartUpdater.IncreaseDifficulty("PlayerNumber_P2")
						else
							t.WheelWithFocus:scroll_by_amount(1)
							SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
							stop_music()
							ChartUpdater.UpdateCharts()
						end
					else
						t.WheelWithFocus:scroll_by_amount(1)
						SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
						stop_music()
						ChartUpdater.UpdateCharts()
					end
				end
				
				-- Jump the songwheel to a song/group clicked on by the left mouse button.
				if event.DeviceInput.button == "DeviceButton_left mouse button" and not PressStartForOptions then
					for i=1, 5 do
						if IsMouseGucci(_screen.cx, (_screen.cy + 45) - (i*25), WheelWidth, 24) then
							t.WheelWithFocus:scroll_by_amount(-i)
							SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
							stop_music()
							ChartUpdater.UpdateCharts()
						end
					end
					
					for i=1, 6 do
						if IsMouseGucci(_screen.cx, (_screen.cy + 45) + (i*25), WheelWidth, 24) then
							t.WheelWithFocus:scroll_by_amount(i)
							SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
							stop_music()
							ChartUpdater.UpdateCharts()
						end
					end
					
					if IsMouseGucci(_screen.cx, (_screen.cy + 45), WheelWidth, 24) then
						if t.WheelWithFocus == SongWheel then
							if t.WheelWithFocus:get_info_at_focus_pos() ~= "CloseThisFolder" then
								didSelectSong = true
								TransitionTime = 0
								PressStartForOptions = true
								SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
								MESSAGEMAN:Broadcast('ShowOptionsJawn')
							elseif t.WheelWithFocus:get_info_at_focus_pos() == "CloseThisFolder" then
								SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
								MESSAGEMAN:Broadcast("CloseCurrentFolder")
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
					
					-- Change the difficulty of the song when a player left clicks a chart.
					if GAMESTATE:IsSideJoined('PlayerNumber_P1') then
						-- Novice position
						if IsMouseGucci(3.5, _screen.h-157, 54, 42, "left", "bottom", 1) then
							ChartUpdater.ClickDifficulty("PlayerNumber_P1", "Difficulty_Beginner")
						-- Easy Position
						elseif IsMouseGucci(59.5, _screen.h-157, 54,42, "left", "bottom", 1) then
							ChartUpdater.ClickDifficulty('PlayerNumber_P1', "Difficulty_Easy")
						-- Medium Position
						elseif IsMouseGucci(115.5, _screen.h-157, 54,42, "left", "bottom", 1)  then
							ChartUpdater.ClickDifficulty('PlayerNumber_P1', "Difficulty_Medium")
						-- Hard Position
						elseif IsMouseGucci(171.5, _screen.h-157, 54,42, "left", "bottom", 1) then
							ChartUpdater.ClickDifficulty('PlayerNumber_P1', "Difficulty_Hard")
						-- Expert/Edit Position
						elseif IsMouseGucci(227.5, _screen.h-157, 54,42, "left", "bottom", 1) then
							ChartUpdater.ClickDifficulty('PlayerNumber_P1', "Difficulty_Challenge")
						end
					end
					if GAMESTATE:IsSideJoined('PlayerNumber_P2') then
						-- Novice position
						if IsMouseGucci((_screen.w/3*2 - 52.5) + 1*56, _screen.h-157, 54,42, "left", "bottom", 1) then
							ChartUpdater.ClickDifficulty("PlayerNumber_P2", "Difficulty_Beginner")	
						-- Easy Position
						elseif IsMouseGucci((_screen.w/3*2 - 52.5) + 2*56,_screen.h-157, 54,42, "left", "bottom", 1) then
							ChartUpdater.ClickDifficulty('PlayerNumber_P2', "Difficulty_Easy")
						-- Medium Position
						elseif IsMouseGucci((_screen.w/3*2 - 52.5) + 3*56, _screen.h-157, 54,42, "left", "bottom", 1)  then
							ChartUpdater.ClickDifficulty('PlayerNumber_P2', "Difficulty_Medium")
						-- Hard Position
						elseif IsMouseGucci((_screen.w/3*2 - 52.5) + 4*56, _screen.h-157, 54,42, "left", "bottom", 1) then
							ChartUpdater.ClickDifficulty('PlayerNumber_P2', "Difficulty_Hard")
						-- Expert/Edit Position
						elseif IsMouseGucci((_screen.w/3*2 - 52.5) + 5*56, _screen.h-157, 54,42, "left", "bottom", 1) then
							ChartUpdater.ClickDifficulty('PlayerNumber_P2', "Difficulty_Challenge")
						end
					end
				elseif event.DeviceInput.button == "DeviceButton_left mouse button" and PressStartForOptions then
					SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
					SCREENMAN:SetNewScreen("ScreenPlayerOptions")
					return false
				end
				
				-- Open the sort menu if the right mouse button is clicked.
				if isSortMenuVisible == false then
					if event.type ~= "InputEventType_Release" then
						if event.DeviceInput.button == "DeviceButton_right mouse button" and PressStartForOptions == false then
							local mpn = GAMESTATE:GetMasterPlayerNumber()
							PlayerControllingSort = mpn 
							MESSAGEMAN:Broadcast("InitializeDDSortMenu")
							MESSAGEMAN:Broadcast("CheckForSongLeaderboard")
							isSortMenuVisible = true
							SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "sort.ogg") )
							stop_music()
							MESSAGEMAN:Broadcast("ToggleSortMenu")
						end
					end
				end
			elseif isSortMenuVisible and not LeadboardHasFocus and not InputMenuHasFocus then
				if event.type ~= "InputEventType_Release" then
					if event.DeviceInput.button == "DeviceButton_right mouse button" then
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
						elseif IsSortMenuInputToggled then
							SOUND:PlayOnce( THEME:GetPathS("common", "invalid.ogg") )
							MESSAGEMAN:Broadcast("UpdateCursorColor")
							MESSAGEMAN:Broadcast("ToggleSortMenuMovement")
						end
					end
					if event.DeviceInput.button == "DeviceButton_mousewheel up" then
						if not IsSortMenuInputToggled then
							MESSAGEMAN:Broadcast("MoveCursorLeft")
							SOUND:PlayOnce( THEME:GetPathS("", "_prev row.ogg") )
						elseif IsSortMenuInputToggled then
							MESSAGEMAN:Broadcast("MoveSortMenuOptionLeft")
						end
					elseif event.DeviceInput.button == "DeviceButton_mousewheel down" then
						if not IsSortMenuInputToggled then
							MESSAGEMAN:Broadcast("MoveCursorRight")
							SOUND:PlayOnce( THEME:GetPathS("", "_next row.ogg") )
						elseif IsSortMenuInputToggled then
							MESSAGEMAN:Broadcast("MoveSortMenuOptionRight")
						end
					end
					if event.DeviceInput.button == "DeviceButton_left mouse button" then
						-- The top half of the sort menu
						if IsMouseGucci(SCREEN_CENTER_X + 145,SCREEN_CENTER_Y - 135, 190, 20, "right") then
							if not IsSortMenuInputToggled then
								DDSortMenuCursorPosition = 1
								MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = 1})
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							elseif DDSortMenuCursorPosition == 1 then
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SetSortMenuTopStats")
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							end
						elseif IsMouseGucci(SCREEN_CENTER_X + 145,SCREEN_CENTER_Y - 110, 190, 20, "right") then
							if not IsSortMenuInputToggled then
								DDSortMenuCursorPosition = 2
								MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = 2})
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							elseif DDSortMenuCursorPosition == 2 then
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SetSortMenuTopStats")
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )	
							end
						elseif IsMouseGucci(SCREEN_CENTER_X + 55,SCREEN_CENTER_Y - 85, 40, 20, "right") then
							if not IsSortMenuInputToggled then
								DDSortMenuCursorPosition = 3
								MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = 3})
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							elseif DDSortMenuCursorPosition == 3 then
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SetSortMenuTopStats")
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )	
							end
						elseif IsMouseGucci(SCREEN_CENTER_X + 135,SCREEN_CENTER_Y - 85, 40, 20, "right") then
							if not IsSortMenuInputToggled then
								DDSortMenuCursorPosition = 4
								MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = 4})
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							elseif DDSortMenuCursorPosition == 4 then
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SetSortMenuTopStats")
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )	
							end
						elseif IsMouseGucci(SCREEN_CENTER_X,SCREEN_CENTER_Y - 60, 40, 20, "right") then
							if not IsSortMenuInputToggled then
								DDSortMenuCursorPosition = 5
								MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = 5})
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							elseif DDSortMenuCursorPosition == 5 then
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SetSortMenuTopStats")
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )	
							end
						elseif IsMouseGucci(SCREEN_CENTER_X + 80,SCREEN_CENTER_Y - 60, 40, 20, "right") then
							if not IsSortMenuInputToggled then
								DDSortMenuCursorPosition = 6
								MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = 6})
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							elseif DDSortMenuCursorPosition == 6 then
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SetSortMenuTopStats")
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )	
							end
						elseif IsMouseGucci(SCREEN_CENTER_X + 48.5,SCREEN_CENTER_Y - 35, 65, 20, "right") then
							if not IsSortMenuInputToggled then
								DDSortMenuCursorPosition = 7
								MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = 7})
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							elseif DDSortMenuCursorPosition == 7 then
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SetSortMenuTopStats")
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )	
							end
						elseif IsMouseGucci(SCREEN_CENTER_X + 147.5,SCREEN_CENTER_Y - 35, 65, 20, "right") then
							if not IsSortMenuInputToggled then
								DDSortMenuCursorPosition = 8
								MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = 8})
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							elseif DDSortMenuCursorPosition == 8 then
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SetSortMenuTopStats")
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )	
							end
						elseif IsMouseGucci(SCREEN_CENTER_X + 122,SCREEN_CENTER_Y - 10, 65, 20, "right") then
							if not IsSortMenuInputToggled then
								DDSortMenuCursorPosition = 9
								MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = 9})
								SortMenuCursorLogic()
								MESSAGEMAN:Broadcast("SetSortMenuTopStats")
								MESSAGEMAN:Broadcast("SortMenuOptionSelected")
								SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
							end
						end
						
						-- The bottom half of the sort menu
						if not IsSortMenuInputToggled then
							for i=1, GetMaxCursorPosition() - 10 do
								if IsMouseGucci(_screen.cx + 85, (_screen.cy + 5) + (i*25), 170, 20, "right") then
									MESSAGEMAN:Broadcast("MoveCursorMouseClick", {TargetPosition = i+9})
									SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
									SortMenuCursorLogic()
								end
							end
						end
					end
				end
				--- Test input mouse controls
			elseif InputMenuHasFocus and not isSortMenuVisible and not LeadboardHasFocus then
				if event.DeviceInput.button == "DeviceButton_left mouse button" or event.DeviceInput.button == "DeviceButton_right mouse button" then
					InputMenuHasFocus = false
					SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
					MESSAGEMAN:Broadcast("HideTestInput")
				end
				-- Leaderboard input mouse controls
			elseif LeadboardHasFocus and not isSortMenuVisible and not InputMenuHasFocus then
				if event.DeviceInput.button == "DeviceButton_right mouse button" or event.DeviceInput.button == "DeviceButton_left mouse button" then
					LeadboardHasFocus = false
					SOUND:PlayOnce( THEME:GetPathS("common", "start.ogg") )
					MESSAGEMAN:Broadcast("HideLeaderboard")
				end
				if event.DeviceInput.button == "DeviceButton_mousewheel up" or event.DeviceInput.button == "DeviceButton_mousewheel down" then
					if event.type ~= "InputEventType_Repeat" then
						MESSAGEMAN:Broadcast("LeaderboardMouseInputEvent", event)
					end
				end
			end
		end
	end
				
	
	-- if any of these, don't attempt to handle input
	if t.Enabled == false or not event or not event.PlayerNumber or not event.button or IsSearchMenuVisible then
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
						SortMenuCursorLogic()
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
		if IsSearchMenuVisible or isSortMenuVisible or LeadboardHasFocus or InputMenuHasFocus then return false end

		-- latejoin
		if event.GameButton == "Start" then
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
		if event.GameButton == "Start" and not IsSearchMenuVisible then
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
		elseif event.GameButton == "MenuRight" and not holdingCtrl then
			t.WheelWithFocus:scroll_by_amount(1)
			SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )
			stop_music()
			ChartUpdater.UpdateCharts()
		elseif event.GameButton == "MenuLeft" and not holdingCtrl then
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