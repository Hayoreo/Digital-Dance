local player = ...
local pn = ToEnumShortString(player)

local InitialTab
local InitialTabNumber

local TabText = {}
MaxTabs = 0

if DDStats.GetStat(pn, 'LastTab') ~= nil then
	InitialTab = DDStats.GetStat(pn, 'LastTab')
else
	InitialTab = "Steps"
end

local TabText = {}
MaxTabs = 0

TabText[#TabText+1] = "Steps"

-- Only show the online tabs if they're available
if IsServiceAllowed(SL.GrooveStats.GetScores) then
	TabText[#TabText+1] = "GS"
	TabText[#TabText+1] = "RPG"
	TabText[#TabText+1] = "ITL"
end
TabText[#TabText+1] = "Local"

MaxTabs = #TabText

local function TabToNumber(Tab)
	local value
	for i=1, MaxTabs do
		if TabText[i] == Tab then
			value = i
		end
	end
	if value == nil then value = 1 end
	return value
end

local function NumberToTab(Tab)
	local value
	for i=1, MaxTabs do
		if i == Tab then
			value = TabText[i]
		end
	end
	if value == nil then value = "Steps" end
	
	if pn == "P1" then
		DDStats.SetStat(PLAYER_1, 'LastTab', value)
		DDStats.Save(PLAYER_1)
	elseif pn == "P2" then
		DDStats.SetStat(PLAYER_2, 'LastTab', value)
		DDStats.Save(PLAYER_2)
	end
	
	return value
end

local t = Def.ActorFrame{
	OnCommand=function(self)
		self:xy(SCREEN_LEFT + 2.5,_screen.h - 149.5)
		:visible(GAMESTATE:IsHumanPlayer(pn))
	end,
}
	
--- bg for tabs
t[#t+1] = Def.Quad {
	Name="BGTab",
	InitCommand=function(self)
		self:diffuse(color("#737373")):zoomto(2 + ((MaxTabs * 32)), 14):horizalign(left):vertalign(top)
		:x(pn == "P1" and 0 or _screen.w - 284.5)
	end,
}

-- thee tabs
for i=1,MaxTabs do
	t[#t+1] = Def.Quad {
		Name="Tab"..i,
		InitCommand=function(self)
			self:diffuse(color("#000000")):zoomto(30, 10):horizalign(left):vertalign(top)
			:x(pn == "P1" and -30 + (i*32) or  (_screen.w - _screen.w/3) -30 + (i*32))
			:y(2)
			if i == TabToNumber(InitialTab) then
				-- highlight color
				self:diffuse(color("#3d304a"))
			end
		end,
		["TabClicked"..player.."MessageCommand"]=function(self, TabClicked)
			NumberToTab(TabClicked[1])
			self:GetParent():GetChild("Tab"..i):diffuse(color("#000000"))
			self:GetParent():GetChild("Tab"..TabClicked[1]):diffuse(color("#3d304a"))
		end,
	}
	
	-- Text
t[#t+1] = LoadFont("Common Normal")..{
	Name="TabText"..i,
	Text="",
	InitCommand=function(self)
		self:diffuse(Color.White)
		:x(pn == "P1" and -14.5 + (i*32) or (_screen.w - _screen.w/3) - 14.5 + (i*32))
		:y(10.5)
		:zoom(0.5)
		:maxwidth(60)
		:draworder(2)
		:horizalign(center):vertalign(bottom)
		:settext(TabText[i])
	end,
	
}
end


return t