-- Currently the Density Graph in SSM doesn't work for Courses.
-- Disable the functionality.
-- Also disable if in 4:3 and on 2 player (there is not enough room)
local nsj = GAMESTATE:GetNumSidesJoined()

if GAMESTATE:IsCourseMode() then return end

local player = ...
local pn = ToEnumShortString(player)

-- Height and width of the density graph.
local height = 64
local width = IsUsingWideScreen() and WideScale(161,267) or 309

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
		self:horizalign(left)
		self:x(SCREEN_LEFT + width/2)
		self:y(IsUsingWideScreen() and _screen.cy-30 or _screen.cy+60)

		if player == PLAYER_2 then
			self:x(SCREEN_RIGHT - width/2)
			if IsUsingWideScreen() then
				self:addx(0.5)
			elseif nsj == 1 then
				self:x(SCREEN_LEFT + width/2)
			end
		end
		if IsUsingWideScreen() then
			self:addx(-1)
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
		self:diffuse(color("#1e282f")):zoomto(width, height)
	end,
}

-- The Density Graph itself. It already has a "RedrawCommand".
af2[#af2+1] = NPS_Histogram(player, width, height)..{
	Name="DensityGraph",
	OnCommand=function(self)
		self:addx(-width/2):addy(height/2)
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
		self:horizalign(player == PLAYER_1 and left or right):zoom(0.8):addy(-56)
		if player == PLAYER_1 then
			self:addx(-125)
		elseif player == PLAYER_2 then
			self:addx(130)
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
		self:addy(height/2 + actorHeight/2)
	end,

	Def.Quad{
		InitCommand=function(self)
			local bgHeight = 17
			self:diffuse(color("#000000")):zoomto(width, bgHeight):diffusealpha(0.85)
		end
	},
	
	LoadFont("Miso/_miso")..{
		Text="",
		Name="BreakdownText",
		InitCommand=function(self)
			local textHeight = 17
			local textZoom = 0.8
			self:maxwidth(width/textZoom):zoom(textZoom)
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
		self:x(-125)
		self:addy(-40)
		if player == PLAYER_1 then
			self:horizalign(left)
		elseif player == PLAYER_2 then
			self:horizalign(right)
			self:addx(255)
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

return af