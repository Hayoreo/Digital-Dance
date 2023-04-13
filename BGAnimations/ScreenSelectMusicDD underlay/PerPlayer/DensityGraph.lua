-- Currently the Density Graph in SSM doesn't work for Courses.
-- Disable the functionality.
-- Also disable if in 4:3 and on 2 player (there is not enough room)
local nsj = GAMESTATE:GetNumSidesJoined()

if GAMESTATE:IsCourseMode() then return end

local player = ...
local pn = ToEnumShortString(player)

-- Get the Y position for this section
local FooterHeight = 32
local PaneHeight = 120
local DifficultyHeight = 50
local StepsHeight = 20
local YPosition = _screen.h - (FooterHeight + PaneHeight + DifficultyHeight + StepsHeight)

-- Height and width of the density graph.
local height = 64
local width = IsUsingWideScreen() and SCREEN_WIDTH/3 or 309

local function getInputHandler(actor, player)
	return (function(event)
		if event.GameButton == "Start" and event.PlayerNumber == player and GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
			actor:visible(true)
		end
	end)
end

local af = Def.ActorFrame{
	InitCommand=function(self)
		if not IsUsingWideScreen() and nsj == 2 then
			self:visible(false)
		else
			self:visible( GAMESTATE:IsHumanPlayer(player) )
		end
		self:y(IsUsingWideScreen() and YPosition or _screen.cy+60)

		if player == PLAYER_2 then
			self:x(SCREEN_RIGHT - width)
		end
		if not IsUsingWideScreen() and nsj == 2 then
			self:visible(false)
		return end
	end,
	PlayerJoinedMessageCommand=function(self, params)
		if not IsUsingWideScreen() then
			self:visible(false)
		elseif params.Player == player then
			self:visible(true)
		end
	end,
	PlayerUnjoinedMessageCommand=function(self, params)
		if not IsUsingWideScreen() then
			self:visible(false)
		elseif params.Player == player then
			self:visible(false)
		end
	end,
}

af[#af+1] = Def.ActorFrame{
	Name="ChartParser",
	OnCommand=function(self)
		self:queuecommand('ShowDensityGraph')
	end,
	["CurrentSteps"..pn.."ChangedMessageCommand"]=function(self)
		self:stoptweening():sleep(0.2):queuecommand('ShowDensityGraph')
	end,
	CloseThisFolderHasFocusMessageCommand=function(self)
		self:stoptweening()
		self:stoptweening():sleep(0.2):queuecommand('Hide')
	end,
	GroupsHaveFocusMessageCommand=function(self)
		self:stoptweening()
		self:stoptweening():sleep(0.2):queuecommand('Hide')
	end,
	SongIsReloadingMessageCommand=function(self)
		self:stoptweening():sleep(0.2):queuecommand('ShowDensityGraph')
	end,
	ShowDensityGraphCommand=function(self)
		-- I don't like how it looks when the bg quad dissappears while scrolling so gonna not do that for now.
		--self:GetChild("DensityQuad"):visible(false)
		self:GetChild("DensityGraph"):visible(false)
		self:GetChild("NPS"):settext("Peak NPS: ")
		self:GetChild("NPS"):visible(false)
		self:GetChild("Breakdown"):GetChild("BreakdownText"):settext("")
		self:GetChild("Breakdown"):visible(false)
		self:GetChild("Total Measures"):GetChild("Total Measures Text"):settext("")
		self:GetChild("Total Measures"):visible(false)
		
		self:stoptweening()
		self:sleep(0.2)
		self:queuecommand("ParseChart")
	end,
	ParseChartCommand=function(self)
		local steps = GAMESTATE:GetCurrentSteps(player)
		if steps then
			MESSAGEMAN:Broadcast(pn.."ChartParsing")
			ParseChartInfo(steps, pn)
			self:queuecommand("Unhide")
		end
	end,
	UnhideCommand=function(self)
		if GAMESTATE:GetCurrentSteps(player) then
			MESSAGEMAN:Broadcast(pn.."ChartParsed")
			self:GetChild("DensityQuad"):visible(true)
			self:GetChild("DensityGraph"):visible(true)
			self:GetChild("NPS"):visible(true)
			self:GetChild("Breakdown"):visible(true)
			self:GetChild("Total Measures"):visible(true)
			self:queuecommand("Redraw")
		end
	end,
	HideCommand=function(self)
		self:stoptweening()
		self:GetChild("DensityGraph"):visible(false)
		self:GetChild("NPS"):visible(false)
		self:GetChild("Breakdown"):visible(false)
		self:GetChild("Total Measures"):visible(false)
		self:GetChild("DensityQuad"):visible(false)
	end,
}

local af2 = af[#af]

-- Background quad for the density graph
af2[#af2+1] = Def.Quad{
	Name="DensityQuad",
	InitCommand=function(self)
		self:diffuse(color("#1e282f")):zoomto(width, height):vertalign(bottom):horizalign(left)
		self:y(-17)
	end,
}

-- The Density Graph itself. It already has a "RedrawCommand".
af2[#af2+1] = NPS_Histogram(player, width, height)..{
	Name="DensityGraph",
	OnCommand=function(self)
		self:horizalign(left):y(-17)
	end,
}
-- Don't let the density graph parse the chart.
-- We do this in parent actorframe because we want to "stall" before we parse.
af2[#af2]["CurrentSteps"..pn.."ChangedMessageCommand"] = nil

-- The Peak NPS text
af2[#af2+1] = LoadFont("Miso/_miso")..{
	Name="NPS",
	Text="Peak NPS: ",
	InitCommand=function(self)
		self:y(-20 - height):horizalign(player == PLAYER_1 and left or right):vertalign(bottom):zoom(0.8)
		if player == PLAYER_1 then
			self:x(5)
		elseif player == PLAYER_2 then
			self:x(SCREEN_WIDTH/3 - 5)
		end
		-- We want white text.
		self:diffuse({1, 1, 1, 1})
	end,
	RedrawCommand=function(self)
		local npsBPM = round((SL[pn].Streams.PeakNPS * SL.Global.ActiveModifiers.MusicRate) * 15, 2)
		if SL[pn].Streams.PeakNPS ~= 0 then
			self:settext(("Peak NPS: %.1f"):format(SL[pn].Streams.PeakNPS * SL.Global.ActiveModifiers.MusicRate).. " ("..npsBPM..")")
		end
	end
}

-- Breakdown
af2[#af2+1] = Def.ActorFrame{
	Name="Breakdown",
	InitCommand=function(self)
		local actorHeight = 17
	end,

	Def.Quad{
		InitCommand=function(self)
			local bgHeight = 17
			self:diffuse(color("#000000")):zoomto(width, bgHeight):vertalign(bottom):horizalign(left):diffusealpha(0.85)
		end
	},
	
	LoadFont("Miso/_miso")..{
		Text="",
		Name="BreakdownText",
		InitCommand=function(self)
			local textHeight = 17
			local textZoom = 0.8
			self:maxwidth(width/textZoom):zoom(textZoom):vertalign(bottom):horizalign(center)
			self:y(-2)
			self:x(width/2)
		end,
		RedrawCommand=function(self)
			local textZoom = 0.8
			self:settext(GenerateBreakdownText(pn, 0))
			local minimization_level = 1
			while self:GetWidth() > (width/textZoom) and minimization_level < 4 do
				self:settext(GenerateBreakdownText(pn, minimization_level))
				minimization_level = minimization_level + 1
			end
		end,
	}
}

-- Total Measures Text
af2[#af2+1] = Def.ActorFrame{
	Name="Total Measures",
	InitCommand=function(self)
		self:y(-42 - height):vertalign(bottom)
		if player == PLAYER_1 then
			self:x(5):horizalign(left)
		elseif player == PLAYER_2 then
			self:x(SCREEN_WIDTH/3 - 5):horizalign(right)
		end
	end,
	
	LoadFont("Miso/_miso")..{
		Text="",
		Name="Total Measures Text",
		InitCommand=function(self)
			local textHeight = 17
			local textZoom = 0.8
			self:maxwidth(width/textZoom):zoom(textZoom)
		end,
		RedrawCommand=function(self)
			local textZoom = 0.8
			local streamMeasures, breakMeasures = GetTotalStreamAndBreakMeasures(pn)
			local totalMeasures = streamMeasures + breakMeasures
			local SongDensity = " (".. round( (streamMeasures/totalMeasures)*100 ,2) .."%)"
			if player == PLAYER_1 then
				self:horizalign(left)
			elseif player == PLAYER_2 then
				self:horizalign(right)
			end
			self:settext(streamMeasures == 0 and "" or "Total Measures: "..streamMeasures..SongDensity)
		end,
	}
}

-- Tech data
af2[#af2+1] = Def.ActorFrame{
	Name="PatternInfo",
	InitCommand=function(self)
		if player == PLAYER_1 then
			self:addy(125)
			self:addx(285)
		else
			self:addy(125)
			self:addx(285)
		end
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

for i, row in ipairs(layout) do
	for j, col in pairs(row) do
		af3[#af3+1] = LoadFont("Common normal")..{
			Text="0",
			Name=col .. "Value",
			InitCommand=function(self)
				local textHeight = 17
				local textZoom = 0.9
				self:zoom(textZoom):horizalign(right)
				self:diffuse(Color.White)
				self:xy(-width/2 + 40, -height/2 + 10)
				self:addx((j-1)*colSpacing)
				self:addy((i-1)*rowSpacing)
			end,
			HideCommand=function(self)
				if GAMESTATE:GetCurrentSong() == nil then
					self:settext("?")
				else
					self:settext("0")
				end
			end,
			RedrawCommand=function(self)
				self:settext(SL[pn].Streams[col])
			end
		}

		af3[#af3+1] = LoadFont("Common normal")..{
			Text=col,
			Name=col,
			InitCommand=function(self)
				local textHeight = 17
				local textZoom = 0.9
				self:diffuse(Color.White)
				self:maxwidth(width/textZoom):zoom(textZoom):horizalign(left)
				self:xy(-width/2 + 50, -height/2 + 10)
				self:addx((j-1)*colSpacing)
				self:addy((i-1)*rowSpacing)
			end,
		}

	end
end

return af