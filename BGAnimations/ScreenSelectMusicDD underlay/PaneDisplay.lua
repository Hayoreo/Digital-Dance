local nsj = GAMESTATE:GetNumSidesJoined()
-- the height of the footer is defined in ./_footer.lua, but we'll
-- use it here when calculating where to position the PaneDisplay
local footer_height = 32

-- height of the PaneDisplay in pixels
local pane_height = 120

local text_zoom = IsUsingWideScreen() and WideScale(0.8, 0.9) or 0.9

-- -----------------------------------------------------------------------
-- Convenience function to return the SongOrCourse and StepsOrTrail for a
-- for a player.
local GetSongAndSteps = function(player)
	local SongOrCourse = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse()) or GAMESTATE:GetCurrentSong()
	local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
	return SongOrCourse, StepsOrTrail
end

-- -----------------------------------------------------------------------
-- define the x positions of four columns, and the y positions of three rows of PaneItems
local pos = {
	col = { 
	IsUsingWideScreen() and WideScale(-120,85) or -90, },
	
	row = { 
	IsUsingWideScreen() and -55 or -55, 
	IsUsingWideScreen() and -37 or -37, 
	IsUsingWideScreen() and -19 or -19,
	IsUsingWideScreen() and -1 or -1, 
	IsUsingWideScreen() and 17 or 17, 
	IsUsingWideScreen() and 35 or 35, }
}

local num_rows = 6
local num_cols = 2

-- HighScores handled as special cases for now until further refactoring
local PaneItems = {
	-- all in one row now
	{ name=THEME:GetString("RadarCategory","Taps"),  rc='RadarCategory_TapsAndHolds'},
	{ name=THEME:GetString("RadarCategory","Holds"), rc='RadarCategory_Holds'},
	{ name=THEME:GetString("RadarCategory","Rolls"), rc='RadarCategory_Rolls'},
	{ name=THEME:GetString("RadarCategory","Jumps"), rc='RadarCategory_Jumps'},
	{ name=THEME:GetString("RadarCategory","Hands"), rc='RadarCategory_Hands'},
	{ name=THEME:GetString("RadarCategory","Mines"), rc='RadarCategory_Mines'},
	
	
	-- { name=THEME:GetString("RadarCategory","Fakes"), rc='RadarCategory_Fakes'},
	-- { name=THEME:GetString("RadarCategory","Lifts"), rc='RadarCategory_Lifts'},
}

-- -----------------------------------------------------------------------
local af = Def.ActorFrame{ Name="PaneDisplayMaster" }

for player in ivalues(PlayerNumber) do
	local pn = ToEnumShortString(player)

	af[#af+1] = Def.ActorFrame{ Name="PaneDisplay"..ToEnumShortString(player) }

	local af2 = af[#af]

	af2.InitCommand=function(self)
		self:visible(GAMESTATE:IsHumanPlayer(player))
		if player == PLAYER_1 then
			self:x(IsUsingWideScreen() and _screen.cx/3 or 160)		
		elseif player == PLAYER_2 then
			self:x(IsUsingWideScreen() and _screen.w - (_screen.w/6) or SCREEN_RIGHT - 160)
			if not IsUsingWideScreen()then
				if nsj == 1 then
					self:x(160)
				elseif nsj == 2 then
					self:x(SCREEN_RIGHT - 160)
				end
			end
		end
		self:y(_screen.h - footer_height - 50)
	end

	af2.PlayerJoinedMessageCommand=function(self, params)
		if player==params.Player then
			-- ensure BackgroundQuad is colored before it is made visible
			self:GetChild("BackgroundQuad"):playcommand("Set")
			self:visible(true)
				:zoom(0):croptop(0):bounceend(0.3):zoom(1)
				:playcommand("Update")
		end
	end
	-- player unjoining is not currently possible in SL, but maybe someday
	af2.PlayerUnjoinedMessageCommand=function(self, params)
		if player==params.Player then
			self:accelerate(0.3):croptop(1):sleep(0.01):zoom(0):queuecommand("Hide")
		end
	end
	af2.HideCommand=function(self) self:visible(false) end

	af2.OnCommand=function(self)                                    self:playcommand("Set") end
	af2.SLGameModeChangedMessageCommand=function(self)              self:playcommand("Set") end
	af2.CurrentCourseChangedMessageCommand=function(self)			self:stoptweening():sleep(0.2):queuecommand("Set") end
	af2.CurrentSongChangedMessageCommand=function(self)				self:stoptweening():sleep(0.2):queuecommand("Set"):queuecommand('LoadSong') end
	af2["CurrentSteps"..pn.."ChangedMessageCommand"]=function(self) self:stoptweening():sleep(0.2):queuecommand("Set") end
	af2["CurrentTrail"..pn.."ChangedMessageCommand"]=function(self) self:playcommand("Set") end
	af2.SongIsReloadingMessageCommand=function(self)				self:stoptweening():sleep(0.2):queuecommand("Set") end

	-- -----------------------------------------------------------------------
	
	-- colored border
	af2[#af2+1] = Def.Quad{
		Name="BackgroundQuad",
		InitCommand=function(self)
			self:zoomtowidth(IsUsingWideScreen() and _screen.w/3 or 310)
			self:zoomtoheight(pane_height)
			self:y(-10)
			self:x(IsUsingWideScreen() and 0 or -6)
			if player == PLAYER_2 and not IsUsingWideScreen() and nsj == 2 then
				self:zoomtowidth(320)
				self:addx(5)
			end
		end,
		SetCommand=function(self)
			local SongOrCourse, StepsOrTrail = GetSongAndSteps(player)
			if GAMESTATE:IsHumanPlayer(player) then
				if StepsOrTrail then
					local difficulty = StepsOrTrail:GetDifficulty()
					self:diffuse( DifficultyColor(difficulty) )
				else
					self:diffuse( PlayerColor(player) )
				end
			end
		end
	}
	
	--- inner black quad
	af2[#af2+1] = Def.Quad{
		Name="BackgroundQuad2",
		InitCommand=function(self)
			self:zoomtowidth(IsUsingWideScreen() and _screen.w/3 - 5 or 310)
			self:zoomtoheight(pane_height - 5)
			self:diffuse(Color.Black)
			self:y(-10)
			self:x(IsUsingWideScreen() and 0 or -6)
			if player == PLAYER_2 and not IsUsingWideScreen() and nsj == 2 then
				self:zoomtowidth(320)
				self:addx(5)
			end
		end,
	}

	-- -----------------------------------------------------------------------
	-- loop through the six sub-tables in the PaneItems table
	-- add one BitmapText as the label and one BitmapText as the value for each PaneItem

	for i, item in ipairs(PaneItems) do

		local col = 1
		local row = math.floor((i-1)/1) + 1

		af2[#af2+1] = Def.ActorFrame{

			Name=item.name,

			-- numerical value
			LoadFont("Common Normal")..{
				InitCommand=function(self)
					self:zoom(text_zoom):diffuse(Color.White):horizalign(right)
					self:x(pos.col[col])
					self:y(pos.row[row])
				end,
				LoadSongCommand=function(self)
					local SongOrCourse, StepsOrTrail = GetSongAndSteps(player)
					if not SongOrCourse then self:settext("?"); return end
					if not StepsOrTrail then self:settext("");  return end
				end,
				[pn.."ChartParsedMessageCommand"]=function(self)
					local SongOrCourse, StepsOrTrail = GetSongAndSteps(player)
					if not SongOrCourse then self:settext("?"); return end
					if not StepsOrTrail then self:settext("");  return end
					if item.rc then
						local val = StepsOrTrail:GetRadarValues(player):GetValue( item.rc )
						-- the engine will return -1 as the value for autogenerated content; show a question mark instead if so
						self:settext( val >= 0 and val or "?" )
					end
				end
			},

			-- label
			LoadFont("Common Normal")..{
				Text=item.name,
				InitCommand=function(self)
					self:zoom(text_zoom):diffuse(Color.White):horizalign(left)
					self:x(pos.col[col]+3)
					self:y(pos.row[row])
				end,
				LoadSongCommand=function(self)
					self:settext(item.name)
				end,
				[pn.."ChartParsedMessageCommand"]=function(self)
					if THEME:GetCurLanguage() == "en" then
						local SongOrCourse, StepsOrTrail = GetSongAndSteps(player)
						local val = StepsOrTrail:GetRadarValues(player):GetValue( item.rc )
						if val == 1 then
							self:settext(item.name:sub(1, #item.name - 1))
						else
							self:settext(item.name)
						end
					end
				end
			},
		}
	end
	
		-- Tech data
	af2[#af2+1] = Def.ActorFrame{
		Name="PatternInfo",
		InitCommand=function(self)
			self:x(5):y(-15)
		end,
	}

	local af3 = af2[#af2]

	local layout = {
		{"Crossovers"},
		{"Footswitches"},
		{"Sideswitches"},
		{"Jacks"},
		{"Brackets"},
	}

	local colSpacing = 150
	local rowSpacing = 18
	local width = IsUsingWideScreen() and SCREEN_WIDTH/3 or 309
	local height = 64

	for i, row in ipairs(layout) do
		for j, col in pairs(row) do
			af3[#af3+1] = LoadFont("Common normal")..{
				Text="0",
				Name=col .. "Value",
				InitCommand=function(self)
					local textHeight = 17
					self:zoom(text_zoom):horizalign(right)
					self:diffuse(Color.White)
					self:xy(-width/2 + 40, -height/2 + 10)
					self:addx((j-1)*colSpacing)
					self:addy((i-1)*rowSpacing)
				end,
				LoadSongCommand=function(self)
					if GAMESTATE:GetCurrentSong() == nil then
						self:settext("?")
					else
						self:settext(SL[pn].Streams[col])
					end
				end,
				[pn.."ChartParsedMessageCommand"]=function(self)
					self:settext(SL[pn].Streams[col])
				end
			}

			af3[#af3+1] = LoadFont("Common normal")..{
				Text=col,
				Name=col,
				InitCommand=function(self)
					local textHeight = 17
					self:diffuse(Color.White)
					self:maxwidth(width/text_zoom):zoom(text_zoom):horizalign(left)
					self:xy(-width/2 + 50, -height/2 + 10)
					self:addx((j-1)*colSpacing)
					self:addy((i-1)*rowSpacing)
				end,
				LoadSongCommand=function(self)
					self:settext(col)
				end,
				[pn.."ChartParsedMessageCommand"]=function(self)
					if THEME:GetCurLanguage() == "en" then
						if SL[pn].Streams[col] == 1 then
							if i == 1 or i >= 4 then
								self:settext(col:sub(1, #col - 1))
							else
								self:settext(col:sub(1, #col - 2))
							end
						else
							self:settext(col)
						end
					end
				end,
			}

		end
	end
end

return af