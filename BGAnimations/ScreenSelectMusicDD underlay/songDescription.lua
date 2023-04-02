-- before loading actors, pre-calculate each group's overall duration by
-- looping through its songs and summing their duration
-- store each group's overall duration in a lookup table, keyed by group_name
-- to be retrieved + displayed when actively hovering on a group (not a song)
--
-- I haven't checked, but I assume that continually recalculating group durations could
-- have performance ramifications when rapidly scrolling through the MusicWheel
--
-- a consequence of pre-calculating and storing the group_durations like this is that
-- live-reloading a song on ScreenSelectMusic via Control R might cause the group duration
-- to then be inaccurate, until the screen is reloaded.

local group_durations = {}
for _,group_name in ipairs(SONGMAN:GetSongGroupNames()) do
	group_durations[group_name] = 0

	for _,song in ipairs(SONGMAN:GetSongsInGroup(group_name)) do
		group_durations[group_name] = group_durations[group_name] + song:MusicLengthSeconds()
	end
end

--initialize variables for CDTitles
local currentsong = GAMESTATE:GetCurrentSong()
local HasCDTitle
if GAMESTATE:GetCurrentSong() ~= nil then
HasCDTitle = currentsong:HasCDTitle()
end
local blank = THEME:GetPathG("", "_blank.png")
local CDTitlePath

-- ----------------------------------------
local MusicWheel, SelectedType

-- width of background quad
local QuadWidth = SCREEN_WIDTH/3
local Ratio = 418/164
local Height = QuadWidth/Ratio

local af = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(_screen.cx - (IsUsingWideScreen() and 0 or 165), Height)
	end,

	CurrentSongChangedMessageCommand=function(self)    self:stoptweening():sleep(0.2):queuecommand("Set") end,
	CurrentCourseChangedMessageCommand=function(self)  self:stoptweening():sleep(0.2):queuecommand("Set") end,
	CurrentStepsP1ChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):queuecommand("Set") end,
	CurrentTrailP1ChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):queuecommand("Set") end,
	CurrentStepsP2ChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):queuecommand("Set") end,
	CurrentTrailP2ChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):queuecommand("Set") end,
	SongIsReloadingMessageCommand=function(self)	   self:stoptweening():sleep(0.2):queuecommand("Set") end,
}

-- background Quad for Artist, BPM, and Song Length
af[#af+1] = Def.Quad{
	InitCommand=function(self)
		self:zoomto( IsUsingWideScreen() and QuadWidth or 311, 36 ):vertalign(top)
		self:diffuse(color("#1e282f"))
	end
}

-- ActorFrame for Artist, BPM, Song length, and CDTitles because I'M GAY LOL
af[#af+1] = Def.ActorFrame{
	InitCommand=function(self) self:xy(0 - (QuadWidth/2) + 4,0) end,
	
	
	--- CDTitle
	Def.Sprite{
		Name="CDTitle",
		CurrentSongChangedMessageCommand=function(self) 		self:stoptweening():sleep(0.2):queuecommand("SetCD") end,
		CloseThisFolderHasFocusMessageCommand=function(self)	self:stoptweening():sleep(0.2):queuecommand("SetCD") end,
		GroupsHaveChangedMessageCommand=function(self) 			self:stoptweening():sleep(0.2):queuecommand("SetCD") end,
		SongIsReloadingMessageCommand=function(self)	    	self:stoptweening():sleep(0.2):queuecommand("SetCD") end,
		InitCommand=function(self) 
			local Height = self:GetHeight()
			local Width = self:GetWidth()
			local dim1, dim2=math.max(Width, Height), math.min(Width, Height)
			local ratio=math.max(dim1/dim2, 2)
			local toScale = Width > Height and Width or Height
			self:zoom(17/toScale * ratio)
			self:horizalign(right):vertalign(middle)
			self:xy(QuadWidth - 10,36/2)
			self:diffusealpha(0)
		end,
		OnCommand=function(self) 
			self:diffusealpha(0.9) 
		end,
		SetCDCommand=function(self)
			if GAMESTATE:GetCurrentSong() ~= nil then
				if GAMESTATE:GetCurrentSong():HasCDTitle() == true then
					CDTitlePath = GAMESTATE:GetCurrentSong():GetCDTitlePath()
					self:Load(CDTitlePath)
				else
					self:Load(blank)
				end
			end
			local Height = self:GetHeight()
			local Width = self:GetWidth()
			local dim1, dim2=math.max(Width, Height), math.min(Width, Height)
			local ratio=math.max(dim1/dim2, 2)
			local toScale = Width > Height and Width or Height
			self:zoom(17/toScale * ratio)
			self:visible(GAMESTATE:GetCurrentSong() ~= nil and true or false)
		end
	},
	
	-- ----------------------------------------
	-- Artist Label
	LoadFont("Common Normal")..{
		Text=THEME:GetString("SongDescription", GAMESTATE:IsCourseMode() and "NumSongs" or "Artist")..":",
		InitCommand=function(self) 
			self
				:zoom(0.65)
				:horizalign(right)
				:y(6)
				:x(35)
				:diffuse(0.5,0.5,0.5,1) end,
	},

	-- Song Artist (or number of Songs in this Course, if CourseMode)
	LoadFont("Common Normal")..{
		InitCommand=function(self) self:zoom(0.65):horizalign(left):xy(IsUsingWideScreen() and 38 or 1,6):maxwidth(WideScale(225,260)) end,
		SetCommand=function(self)
			if GAMESTATE:IsCourseMode() then
				local course = GAMESTATE:GetCurrentCourse()
				self:settext( course and #course:GetCourseEntries() or "" )
			else
				local song = GAMESTATE:GetCurrentSong()
				self:settext( song and song:GetDisplayArtist() or "" )
			end
		end
	},

	-- ----------------------------------------
	-- BPM Label
	LoadFont("Common Normal")..{
		Text=THEME:GetString("SongDescription", "BPM")..":",
		InitCommand=function(self)
			self
				:zoom(0.65)
				:y(18)
				:x(35)
				:horizalign(right)
				:diffuse(0.5,0.5,0.5,1)
		end
	},

	-- BPM value
	LoadFont("Common Normal")..{
		InitCommand=function(self)
			-- vertical align has to be middle for BPM value in case of split BPMs having a line break
			self:xy(38,18):diffuse(1,1,1,1):vertspacing(-8):vertalign(middle):horizalign(left)
		end,
		SetCommand=function(self)
			if GAMESTATE:GetCurrentSong() == nil then
				self:settext("")
			return end
				
			if MusicWheel then SelectedType = MusicWheel:GetSelectedType() end

			-- if only one player is joined, stringify the DisplayBPMs and return early
			if #GAMESTATE:GetHumanPlayers() == 1 then
				-- StringifyDisplayBPMs() is defined in ./Scipts/SL-BPMDisplayHelpers.lua
				self:settext(StringifyDisplayBPMs() or ""):zoom(0.65)
				return
			end

			-- otherwise there is more than one player joined and the possibility of split BPMs
			local p1bpm = StringifyDisplayBPMs(PLAYER_1)
			local p2bpm = StringifyDisplayBPMs(PLAYER_2)

			-- it's likely that BPM range is the same for both charts
			-- no need to show BPM ranges for both players if so
			if p1bpm == p2bpm then
				self:settext(p1bpm):zoom(0.65)

			-- different BPM ranges for the two players
			else
				-- show the range for both P1 and P2 split by a newline characters, shrunk slightly to fit the space
				self:settext( "P1 ".. p1bpm .. "\n" .. "P2 " .. p2bpm ):zoom(0.5)
				-- the "P1 " and "P2 " segments of the string should be grey
				self:AddAttribute(0,             {Length=3, Diffuse={0.60,0.60,0.60,1}})
				self:AddAttribute(3+p1bpm:len(), {Length=3, Diffuse={0.60,0.60,0.60,1}})

				if GAMESTATE:IsCourseMode() then
					-- P1 and P2's BPM text in CourseMode is white until I have time to figure CourseMode out
					self:AddAttribute(3,             {Length=p1bpm:len(), Diffuse={1,1,1,1}})
					self:AddAttribute(7+p1bpm:len(), {Length=p2bpm:len(), Diffuse={1,1,1,1}})

				else
					-- P1 and P2's BPM text is the color of their difficulty
					if GAMESTATE:GetCurrentSteps(PLAYER_1) then
						self:AddAttribute(3,             {Length=p1bpm:len(), Diffuse=DifficultyColor(GAMESTATE:GetCurrentSteps(PLAYER_1):GetDifficulty())})
					end
					if GAMESTATE:GetCurrentSteps(PLAYER_2) then
						self:AddAttribute(7+p1bpm:len(), {Length=p2bpm:len(), Diffuse=DifficultyColor(GAMESTATE:GetCurrentSteps(PLAYER_2):GetDifficulty())})
					end
				end
			end
		end
	},

	-- ----------------------------------------
	-- Song Duration Label
	LoadFont("Common Normal")..{
		Text=THEME:GetString("SongDescription", "Length")..":",
		InitCommand=function(self)
			self:diffuse(0.5,0.5,0.5,1):zoom(0.65):horizalign(right)
			self:x(35):y(30)
		end
	},

	-- Song Duration Value
	LoadFont("Common Normal")..{
		InitCommand=function(self) self:xy(38, 30):zoom(0.65):horizalign(left) end,
		SetCommand=function(self)
			local seconds

			if SelectedType == "WheelItemDataType_Song" or "SwitchFocusToSingleSong" then
				local song = GAMESTATE:GetCurrentSong()
				if song then
					seconds = song:MusicLengthSeconds()
				end

			elseif SelectedType == "WheelItemDataType_Section" then
				-- MusicWheel:GetSelectedSection() will return a string for the text of the currently active WheelItem
				-- use it here to look up the overall duration of this group from our precalculated table of group durations
				seconds = group_durations[MusicWheel:GetSelectedSection()]
			end

			-- r21 lol
			if seconds == 105.0 then self:settext(THEME:GetString("SongDescription", "r21")); return end

			if seconds then
				seconds = seconds / SL.Global.ActiveModifiers.MusicRate

				-- longer than 1 hour in length
				if seconds > 3600 then
					-- format to display as H:MM:SS
					self:settext(math.floor(seconds/3600) .. ":" .. SecondsToMMSS(seconds%3600))
				else
					-- format to display as M:SS
					self:settext(SecondsToMSS(seconds))
				end
			else
				self:settext("")
			end
		end
	}
}

return af
