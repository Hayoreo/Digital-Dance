local player = ...
local pn = ToEnumShortString(player)
local MaxTabs

local t = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(_screen.w/3 - 2.5,_screen.h - 149.5)
		:visible(GAMESTATE:IsHumanPlayer(pn))
	end,
}

local TabText = {
	"Steps"
}

-- Only show the online tabs if they're available
if IsServiceAllowed(SL.GrooveStats.GetScores) then

TabText[#TabText+1] = "GS"
TabText[#TabText+1] = "RPG"
TabText[#TabText+1] = "ITL"

end

TabText[#TabText+1] = "Local"

MaxTabs = #TabText
	
--- bg for tabs
t[#t+1] = Def.Quad {
	Name="BGTab",
	InitCommand=function(self)
		self:diffuse(color("#737373")):zoomto(162, 14):horizalign(right):vertalign(top)
		:x(player == "PlayerNumber_P1" and 0 or _screen.w - 285)
	end,
}


-- thee tabs
for i=1,MaxTabs do
	t[#t+1] = Def.Quad {
		Name="Tab"..i,
		InitCommand=function(self)
			self:diffuse(color("#000000")):zoomto(30, 10):horizalign(right):vertalign(top)
			:x(player == "PlayerNumber_P1" and -162 + (i*32) or  407 + (i*32))
			:y(2)
			if i == 1 then
				-- highlight color
				self:diffuse(color("#3d304a"))
			end
		end,
		["TabClicked"..player.."MessageCommand"]=function(self, TabClicked)
			self:GetParent():GetChild("Tab"..i):diffuse(color("#000000"))
			self:GetParent():GetChild("Tab"..TabClicked[1]):diffuse(color("#3d304a"))
		end,
	}
	
	-- Text
t[#t+1] = LoadFont("Common Normal")..{
	Name="Rank"..i,
	Text="",
	InitCommand=function(self)
		self:diffuse(Color.White)
		:x(player == "PlayerNumber_P1" and -177 + (i*32) or _screen.w - _screen.w/2 - 35 + (i*32))
		:y(10.5)
		:zoom(0.5)
		:maxwidth(60)
		:horizalign(center):vertalign(bottom)
		:settext(TabText[i])
	end,
	
}
end


return t