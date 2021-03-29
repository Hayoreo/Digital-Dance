local player = ...
local args = ...
local GroupWheel = args.GroupWheel
local SongWheel = args.SongWheel

local ChartUpdater = LoadActor("./UpdateChart.lua")

-- initialize Players to be any HumanPlayers at screen init
-- we'll update this later via latejoin if needed
local Players = GAMESTATE:GetHumanPlayers()

local ActiveOptionRow

local didSelectSong = false

-----------------------------------------------------
-- input handler
local t = {}
-----------------------------------------------------

local SwitchInputFocus = function(button)
	if button == "Start" then

		if t.WheelWithFocus == GroupWheel then
			t.WheelWithFocus = SongWheel

		elseif t.WheelWithFocus == SongWheel then
			didSelectSong = true
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
	NameOfGroup = GAMESTATE:GetCurrentSong():GetGroupName()
	return end

	-- otherwise...
	t.Enabled = false
	MESSAGEMAN:Broadcast("SwitchFocusToGroups")
	t.WheelWithFocus.container:queuecommand("Hide")
	t.WheelWithFocus = GroupWheel
	t.WheelWithFocus.container:queuecommand("Unhide")
end

t.AllowLateJoin = function()
	if GAMESTATE:GetCurrentStyle():GetName() ~= "single" then return false end
	if PREFSMAN:GetPreference("EventMode") then return true end
	if GAMESTATE:GetCoinMode() ~= "CoinMode_Pay" then return true end
	if GAMESTATE:GetCoinMode() == "CoinMode_Pay" and PREFSMAN:GetPreference("Premium") == "Premium_2PlayersFor1Credit" then return true end
	return false
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
	-- if any of these, don't attempt to handle input
	if t.Enabled == false or not event or not event.PlayerNumber or not event.button then
		return false
	end

	if not GAMESTATE:IsSideJoined(event.PlayerNumber) then
		if not t.AllowLateJoin() then return false end

		-- latejoin
		if event.GameButton == "Start" then
			GAMESTATE:JoinPlayer( event.PlayerNumber )
			Players = GAMESTATE:GetHumanPlayers()
		end
		return false
	end

	if event.type ~= "InputEventType_Release" then

		if event.GameButton == "Back" then
			if didSelectSong then
				didSelectSong = false
				MESSAGEMAN:Broadcast('HideOptionsJawn')
				return false
			end
		
			SCREENMAN:GetTopScreen():SetNextScreenName( Branch.SSMCancel() ):StartTransitioningScreen("SM_GoToNextScreen")
		end

		--------------------------------------------------------------
		--------------------------------------------------------------
		-- proceed to the next wheel
		if event.GameButton == "Start" then
			if didSelectSong then
				SCREENMAN:SetNewScreen("ScreenPlayerOptions")
				return false
			end

			if t.WheelWithFocus:get_info_at_focus_pos() == "CloseThisFolder" then
				SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
				CloseCurrentFolder()
				return false
			end

			if t.WheelWithFocus == GroupWheel then
				SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
			end

			t.WheelWithFocus.container:queuecommand("Start")
			SwitchInputFocus(event.GameButton)

			if t.WheelWithFocus.container then
				t.WheelWithFocus.container:queuecommand("Unhide")
			end
		elseif didSelectSong then
			return false
		-- navigate the wheel left and right
		elseif event.GameButton == "MenuRight" then
			t.WheelWithFocus:scroll_by_amount(1)
			SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )

			ChartUpdater.UpdateCharts()
		elseif event.GameButton == "MenuLeft" then
			t.WheelWithFocus:scroll_by_amount(-1)
			SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg") )

			ChartUpdater.UpdateCharts()
		elseif event.GameButton == "MenuUp" then
			local t = GetTimeSinceStart()
			local dt = t - lastMenuUpPressTime
			lastMenuUpPressTime = t
			if dt < 0.5 then
				ChartUpdater.DecreaseDifficulty(event.PlayerNumber)
				lastMenuUpPressTime = 0
			end
		elseif event.GameButton == "MenuDown" then
			local t = GetTimeSinceStart()
			local dt = t - lastMenuDownPressTime
			lastMenuDownPressTime = t
			if dt < 0.5 then
				ChartUpdater.IncreaseDifficulty(event.PlayerNumber)
				lastMenuDownPressTime = 0
			end
		end
	end


	return false
end

return t