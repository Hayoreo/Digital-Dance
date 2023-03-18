local player = ...
local style = GAMESTATE:GetCurrentStyle()
local game = GAMESTATE:GetCurrentGame()

if (GAMESTATE:IsCourseMode() or
		not IsItlActive() or
		game:GetName() ~= "dance" or
		(style:GetName() ~= "single" and style:GetName() ~= "versus")) then
	return
end

local t = Def.ActorFrame {
	OnCommand=function(self)
		UpdateItlData(player)
	end
}

return t