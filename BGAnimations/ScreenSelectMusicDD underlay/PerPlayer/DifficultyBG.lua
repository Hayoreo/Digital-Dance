---- Have to put this here because of layering issues that would otherwise occur lmao

local P1 = GAMESTATE:IsHumanPlayer(PLAYER_1)
local P2 = GAMESTATE:IsHumanPlayer(PLAYER_2)

local FooterHeight = 32
local PaneHeight = 120
local QuadY = _screen.h - FooterHeight - PaneHeight

local Player1X = IsUsingWideScreen() and 0 or SCREEN_LEFT + 160
local QuadHeight = 50
local QuadWidth = SCREEN_WIDTH/3

local function getInputHandler(actor, player)
	return (function(event)
		if event.GameButton == "Start" and event.PlayerNumber == player and GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
			actor:visible(true)
		end
	end)
end

local af = Def.ActorFrame{
	Name="DifficultyBGs",
	InitCommand=function(self) self:y(QuadY) end,
	
	--- The background quad for the grid to make the whole thing more legible.
	Def.Quad{
		Name="DiffBackground",
		InitCommand=function(self)
				self:draworder(0):diffuse(color("#1e282f")):horizalign(left):vertalign(bottom)
				if IsUsingWideScreen() then
					self:zoomto(QuadWidth,QuadHeight)
					self:visible(P1)
				else
					self:zoomto(270,40)
					self:visible(true)
				end
				
		end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P1'))
		end
	},
	
	Def.Quad{
		Name="DiffBackground2",
		InitCommand=function(self)
			if IsUsingWideScreen() then
				self:x(SCREEN_RIGHT):horizalign(right):vertalign(bottom)
				self:draworder(0)
				self:diffuse(color("#1e282f"))
				self:zoomto(QuadWidth,QuadHeight)
				self:visible(P2)
			else
				self:visible(false)
			end
		end,
		OnCommand=function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(getInputHandler(self, 'PlayerNumber_P2'))
		end
	},
	
	
}

return af