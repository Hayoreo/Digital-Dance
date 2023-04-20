local args = ...
local player = args[1]
local PruneSongsFromGroup = args[2]
local SongSort = GetMainSortPreference()

local pn = ToEnumShortString(player)
local SongsInSet = SL.Global.Stages.PlayedThisGame

-- pre load some profile info
local player_name = PROFILEMAN:GetPlayerName(pn)
local player_profile = PROFILEMAN:GetProfile(pn)
local total_num_songs_played = player_profile:GetNumTotalSongsPlayed()
local num_times_song

-- figure out which players (if any are guests)
local GuestP1 = false
local GuestP2 = false

if player_name == "" and pn == "P1" then
	GuestP1 = true
elseif player_name == "" and pn == "P2" then
	GuestP2 = true
end

local function IsNotGuest()
	if pn == "P1" and GuestP1 then
		return false
	elseif pn == "P2" and GuestP2 then
		return false
	end
	
	return true
end

-- Help position items based on the size of the profile frame
local border = 5
local padding = 20
local width = (_screen.w/3) - border - padding
local height = 122

-- This is to prevent logic issues
if SongsInSet == 0 then
P1SongsInSet = 0
P2SongsInSet = 0
SongsInSet = 0
end

if P1SongsInSet == 0 or P1SongsInSet == nil then
P1SongsInSet = 0
end

if P2SongsInSet == 0 or P2SongsInSet == nil then
P2SongsInSet = 0
end

------------------- This is to make our numbers behave properly -------------------------------

-- for commas
local function comma_value(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end


local af = Def.ActorFrame{
	InitCommand=function(self) 
		self:visible(GAMESTATE:IsPlayerEnabled(pn)):queuecommand("GetPlayerGrades") 
	end,
	CurrentGroupChangedMessageCommand=function(self)
		self:stoptweening():sleep(0.2):queuecommand("GetPlayerGrades")
	end,
	["CurrentSteps"..pn.."ChangedMessageCommand"]=function(self)
		self:stoptweening():sleep(0.2):queuecommand("GetPlayerGrades")
	end,
}

-- define some variables for the next function
local num_tiers = THEME:GetMetric("PlayerStageStats", "NumGradeTiersUsed")
local grades = {}

for i=1,num_tiers do
	grades[ ("Grade_Tier%02d"):format(i) ] = i-1
end

-- assign the "Grade_Failed" key a value equal to num_tiers
grades["Grade_Failed"] = num_tiers

-- Get grade counts for all songs of a profile
af.GetPlayerGradesCommand=function(self)
	local SongCount = 0
	local scores = {
		Grade_Tier01 = 0,
		Grade_Tier02 = 0,
		Grade_Tier03 = 0,
		Grade_Tier04 = 0,
		Passes = 0
	}
	
	local songs = PruneSongsFromGroup(NameOfGroup)
	local stepstype = GAMESTATE:GetCurrentStyle():GetStepsType()
	local steps = GAMESTATE:GetCurrentSteps(player)
	
	if steps then
		-- Get current difficulty
		local difficulty = steps:GetDifficulty()
		for song in ivalues(songs) do
			local stepses = song:GetAllSteps()
			for songsteps in ivalues(stepses) do
				local stepsdiff = songsteps:GetDifficulty()
				-- Only show grades for the current difficulty if sorted by group
				if SongSort == 1 then
					if difficulty == stepsdiff and stepstype == songsteps:GetStepsType() then
						SongCount = SongCount + 1
						HighScoreList = player_profile:GetHighScoreListIfExists(song,songsteps)
						if HighScoreList ~= nil then 
							HighScores = HighScoreList:GetHighScores()
							-- Get highest score
							if #HighScores > 0 then
								local grade = HighScores[1]:GetGrade()
								if grade ~= "Grade_Failed" then
									scores["Passes"] = scores["Passes"] + 1
									if grades[grade] < 4 then
										scores[grade] = scores[grade] + 1
									end
								end
							end
						end
					end
				-- if sorted by difficulty only show grades if they match the difficulty of the group folder
				elseif SongSort == 6 then
					if (songsteps:GetMeter() == NameOfGroup or (songsteps:GetMeter() >= 40 and NameOfGroup == "40+")) and stepstype == songsteps:GetStepsType() then
						SongCount = SongCount + 1
						HighScoreList = player_profile:GetHighScoreListIfExists(song,songsteps)
						if HighScoreList ~= nil then 
							HighScores = HighScoreList:GetHighScores()
							-- Get highest score
							if #HighScores > 0 then
								local grade = HighScores[1]:GetGrade()
								if grade ~= "Grade_Failed" then
									scores["Passes"] = scores["Passes"] + 1
									if grades[grade] < 4 then
										scores[grade] = scores[grade] + 1
									end
								end
							end
						end
					end
				-- for all other sorts get all grades from all available steps
				else
					if stepstype == songsteps:GetStepsType() then
						SongCount = SongCount + 1
						HighScoreList = player_profile:GetHighScoreListIfExists(song,songsteps)
						if HighScoreList ~= nil then 
							HighScores = HighScoreList:GetHighScores()
							-- Get highest score
							if #HighScores > 0 then
								local grade = HighScores[1]:GetGrade()
								if grade ~= "Grade_Failed" then
									scores["Passes"] = scores["Passes"] + 1
									if grades[grade] < 4 then
										scores[grade] = scores[grade] + 1
									end
								end
							end
						end
					end
				end
				
				
			end
		end
		self:playcommand("SetGrades", {scores=scores, SongCount = SongCount})
	else
		self:visible(false)
	end
end

-- Songs played set (label)
af[#af+1] = Def.BitmapText{
	Font="Miso/_miso",
	Name="SongsPlayedSetValue"..pn,
	InitCommand=function(self)
		local zoom = 0.75
		self:horizalign(right):vertalign(bottom):diffuse(color("#a58cff"))
			:x(pn == "P1" and padding/2 + border/2 + width - 45 or _screen.w - padding/2 - border/2 - 45)
			:y(padding/2 + border/2 + 17)
			:maxwidth((width-110)/zoom)
			:zoom(zoom)
			:settext("Songs played (set):")
	end,
}


-- Songs played set (value)
af[#af+1] = Def.BitmapText{
	Font="Miso/_miso",
	Name="SongsPlayedSet"..pn,
	InitCommand=function(self)
		local zoom = 0.75
		self:horizalign(left):vertalign(bottom)
			:x(pn == "P1" and padding/2 + border/2 + width - 43 or _screen.w - padding/2 - border/2 - 43)
			:y(padding/2 + border/2 + 17)
			:maxwidth(43/zoom)
			:zoom(zoom)
			:settext(pn == "P1" and comma_value(P1SongsInSet) or comma_value(P2SongsInSet))
	end,
}


-- Songs played lifetime (label)
af[#af+1] = Def.BitmapText{
	Font="Miso/_miso",
	Name="SongsPlayedLifetimeLabel"..pn,
	InitCommand=function(self)
		local zoom = 0.75
		self:horizalign(right):vertalign(bottom):diffuse(color("#a58cff"))
			:x(pn == "P1" and padding/2 + border/2 + width - 45 or _screen.w - padding/2 - border/2 - 45)
			:y(padding/2 + border/2 + 32)
			:maxwidth((width-110)/zoom)
			:zoom(zoom)
			:settext("Songs played (lifetime):")
			-- don't show this if the player doesn't have a profile
			self:visible(IsNotGuest())
	end,
}

-- Songs played lifetime (value)
af[#af+1] = Def.BitmapText{
	Font="Miso/_miso",
	Name="SongsPlayedLifetimeValue"..pn,
	InitCommand=function(self)
		local zoom = 0.75
		self:horizalign(left):vertalign(bottom)
			:x(pn == "P1" and padding/2 + border/2 + width - 43 or _screen.w - padding/2 - border/2 - 43)
			:y(padding/2 + border/2 + 32)
			:maxwidth(43/zoom)
			:zoom(zoom)
			:settext(comma_value(total_num_songs_played))
			-- don't show this if the player doesn't have a profile
			self:visible(IsNotGuest())
	end,
}

-- Number of times song played (label)
af[#af+1] = Def.BitmapText{
	Font="Miso/_miso",
	Name="NumberOfTimesSongsPlayed"..pn,
	InitCommand=function(self)
		local zoom = 0.75
		self:horizalign(right):vertalign(bottom):diffuse(color("#a58cff"))
			:x(pn == "P1" and padding/2 + border/2 + width - 45 or _screen.w - padding/2 - border/2 - 45)
			:y(padding/2 + border/2 + 47)
			:maxwidth((width-110)/zoom)
			:zoom(zoom)
			:settext("Play count:")
			-- don't show this if the player doesn't have a profile
			self:visible(IsNotGuest())
	end,
}

-- Number of times song played (value)
af[#af+1] = Def.BitmapText{
	Font="Miso/_miso",
	Name="NumberOfTimesSongsPlayedValue"..pn,
	InitCommand=function(self)
		local zoom = 0.75
		local song = GAMESTATE:GetCurrentSong()
		local num_times_song = player_profile:GetSongNumTimesPlayed(song)
		self:horizalign(left):vertalign(bottom)
			:x(pn == "P1" and padding/2 + border/2 + width - 43 or _screen.w - padding/2 - border/2 - 43)
			:y(padding/2 + border/2 + 47)
			:maxwidth(43/zoom)
			:zoom(zoom)
			-- don't show this if the player doesn't have a profile
			self:visible(IsNotGuest())
			self:settext(comma_value(num_times_song))
	end,
	CurrentSongChangedMessageCommand=function(self)
		if GAMESTATE:GetCurrentSong() == nil then
			self:settext("?")
		end
	end,
	[pn.."ChartParsedMessageCommand"]=function(self)
			local song = GAMESTATE:GetCurrentSong()
			local num_times_song = player_profile:GetSongNumTimesPlayed(song)
			
			-- don't show this if the player doesn't have a profile
			self:visible(IsNotGuest())
			self:settext(comma_value(num_times_song))
	end,
}

-- Grades and grade count
local columnWidth = 100
for i=1,4 do
	af[#af+1] = Def.Sprite{
		Texture=THEME:GetPathG("","_grades/assets/grades 1x18.png"),
		InitCommand=function(self) self:zoom(0):sleep(0.2):zoom(0.2):animate(false) end,
		SetGradesCommand=function(self, params)
			self:setstate(grades["Grade_Tier0"..i])
			self:horizalign(left):vertalign(bottom)
			if pn == "P1" then
				self:x(85 + (i*40))
				self:y(96)
			else
				self:x(_screen.w - padding/2 - border/2 - ((width - 73) - (i*40)))
				self:y(96)
			end
			-- don't show this if the player doesn't have a profile
			self:visible(IsNotGuest())
		end,
	}
	
	af[#af+1] = LoadFont("Common Normal")..{
		Name="Grade" ..i,
		Text="",
		SetGradesCommand=function(self,params)
			local zoom = 0.7
			local text = params.scores["Grade_Tier0"..i]
			self:settext(comma_value(text))
			self:horizalign(center):vertalign(bottom)
			self:zoom(zoom)
			self:maxwidth(30/zoom)
			if pn == "P1" then
				self:x(93 + (i*40))
				self:y(112)
			else
				self:x(_screen.w - padding/2 - border/2 - ((width - 81) - (i*40)))
				self:y(112)
			end
			-- don't show this if the player doesn't have a profile
			self:visible(IsNotGuest())
		end,
	}
	
end

-- # of song passes per group
af[#af+1] = Def.BitmapText{
	Font="Miso/_miso",
	Name="NumberOfSongPassesValue"..pn,
	SetGradesCommand=function(self,params)
		local zoom = 0.75
		local text = "Passes: " .. comma_value(params.scores["Passes"]) .. " / " .. comma_value(params.SongCount)
		local TextColor = color("#a58cff")
		self:horizalign(center):vertalign(bottom)
			:x(pn == "P1" and padding/2 + border + ((width + 100)/2) or _screen.w - padding/2 - border - ((width - 100)/2))
			:y(padding/2 + border/2 + height - 5)
			:maxwidth((width - 110 - (border/2))/zoom)
			:zoom(zoom)
			:settext(text)
			:AddAttribute(0, {Length = 7, Diffuse = TextColor;})
			-- don't show this if the player doesn't have a profile
			self:visible(IsNotGuest())
	end,
}

return af