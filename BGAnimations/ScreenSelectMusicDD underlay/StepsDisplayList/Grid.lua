---  this difficulty grid doesn't support CourseMode
---  CourseContentsList.lua should be used instead
if GAMESTATE:IsCourseMode() then return end
-- ----------------------------------------------

-- the max amount of difficulties shown at one time
local num_rows    = 5

local P1 = GAMESTATE:IsHumanPlayer(PLAYER_1)
local P2 = GAMESTATE:IsHumanPlayer(PLAYER_2)

local GetStepsToDisplay = LoadActor("./StepsToDisplay.lua")


local function getInputHandler(actor, player)
	return (function(event)
		if event.GameButton == "Start" and event.PlayerNumber == player and GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
			actor:visible(true)
		end
	end)
end

local t = Def.ActorFrame{
	Name="StepsDisplayList",
	InitCommand=function(self) 
		self:zoom(0.875):x(IsUsingWideScreen() and -26 or _screen.cx-220):y(IsUsingWideScreen() and _screen.cy + 124 or _screen.cy - 356):playcommand("RedrawStepsDisplay") 
	end,

	OnCommand=function(self)                           self:queuecommand("RedrawStepsDisplay") end,
	CurrentSongChangedMessageCommand=function(self)    self:stoptweening():sleep(0.2):queuecommand("RedrawStepsDisplay") end,
	CurrentStepsP1ChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):queuecommand("RedrawStepsDisplay") end,
	CurrentStepsP2ChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):queuecommand("RedrawStepsDisplay") end,
	SongIsReloadingMessageCommand=function(self)	   self:stoptweening():sleep(0.2):queuecommand("RedrawStepsDisplay") end,


	
	RedrawStepsDisplayCommand=function(self)

		local song = GAMESTATE:GetCurrentSong()

		if song then
			local steps = SongUtil.GetPlayableSteps( song )

			if steps then
				local StepsToDisplay = GetStepsToDisplay(steps)

				for i=1,num_rows do
					if StepsToDisplay[i] then
						-- if this particular song has a stepchart for this row, update the Meter
						-- and BlockRow coloring appropriately
						local meter = StepsToDisplay[i]:GetMeter()
						local difficulty = StepsToDisplay[i]:GetDifficulty()
						self:GetChild("Grid"):GetChild("Meter_"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Meter_1"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Meter_2"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Meter_3"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Meter_4"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Meter_5"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Meter_6"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Meter_7"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Meter_8"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Meter_9"..i):playcommand("Set",  {Meter=meter, Difficulty=difficulty})
					else
						-- otherwise, set the meter to an empty string and hide this particular colored BlockRow
						self:GetChild("Grid"):GetChild("Meter_"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Meter_1"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Meter_2"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Meter_3"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Meter_4"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Meter_5"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Meter_6"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Meter_7"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Meter_8"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Meter_9"..i):playcommand("Unset")
					end
				end
			end
		else
			self:playcommand("Unset")
		end
	end,

}


local Grid = Def.ActorFrame{
	Name="Grid",
	InitCommand=function(self) self:xy(1,-52) end,
	
}


for RowNumber=1,num_rows do
	local GridP1X = RowNumber * 64
	local GridP2X = (_screen.w - _screen.w/3) + RowNumber * 64 + 82
	-------------------------------- Player 1 Meter stuff --------------------------------
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_1"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:y(2)
			self:x(GridP1X+2)
			if IsUsingWideScreen() then
					self:visible(P1)
				else
					self:visible(true)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( Color.Black)
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P1'))
		end
	}
	
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_2"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:y(-2)
			self:x(GridP1X-2)
			if IsUsingWideScreen() then
					self:visible(P1)
				else
					self:visible(true)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( Color.Black)
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P1'))
		end
	}
	
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_3"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:y(2)
			self:x(GridP1X - 2)
			if IsUsingWideScreen() then
					self:visible(P1)
				else
					self:visible(true)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( Color.Black)
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P1'))
		end
	}
	
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_4"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:y(-2)
			self:x(GridP1X + 2)
			if IsUsingWideScreen() then
					self:visible(P1)
				else
					self:visible(true)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( Color.Black)
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P1'))
		end
	}
	
	----- The actual numbers -----
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:x(GridP1X)
			if IsUsingWideScreen() then
					self:visible(P1)
				else
					self:visible(true)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( DifficultyColor(params.Difficulty) )
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P1'))
		end
	}
	
	-------------------------------- Player 2 Meter stuff --------------------------------
	
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_6"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:y(2)
			self:x(GridP2X + 2)
			if IsUsingWideScreen() then
					self:visible(P2)
				else
					self:visible(false)
					self:zoom(0)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( Color.Black)
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P2'))
		end
	}
	
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_7"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:y(2)
			self:x(GridP2X-2)
			if IsUsingWideScreen() then
					self:visible(P2)
				else
					self:visible(false)
					self:zoom(0)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( Color.Black)
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P2'))
		end
	}
	
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_8"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:y(-2)
			self:x(GridP2X-2)
			if IsUsingWideScreen() then
					self:visible(P2)
				else
					self:visible(false)
					self:zoom(0)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( Color.Black)
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P2'))
		end
	}
	
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_9"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:y(-2)
			self:x(GridP2X+2)
			if IsUsingWideScreen() then
					self:visible(P2)
				else
					self:visible(false)
					self:zoom(0)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( Color.Black)
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P2'))
		end
	}
	
	----- The actual numbers -----
	Grid[#Grid+1] = LoadFont("Common Bold")..{
		Name="Meter_5"..RowNumber,
		InitCommand=function(self)
			self:horizalign(center):vertalign(bottom)
			self:x(GridP2X)
			if IsUsingWideScreen() then
					self:visible(P2)
				else
					self:visible(false)
					self:zoom(0)
			end
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( DifficultyColor(params.Difficulty) )
			if params.Meter < 100 then
				self:settext(params.Meter)
			else
				self:settext("M")
			end
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P2'))
		end
	}
	
	
	
end

t[#t+1] = Grid

return t