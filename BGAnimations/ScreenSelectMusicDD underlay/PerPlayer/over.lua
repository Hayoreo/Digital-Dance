local t = Def.ActorFrame{}

for player in ivalues( PlayerNumber ) do
	-- Cursor for difficulty selection
	t[#t+1] = LoadActor("./Cursor.lua", player)
	t[#t+1] = LoadActor("./Tabs.lua", player)
	
	-- testing for mouse input
	--[[t[#t+1] = Def.Quad {
		Name="MouseTest",
		InitCommand=function(self)
			self:diffuse(color("#FFFFFF")):diffusealpha(0.4)
			:zoomto(32, 14):horizalign(left):vertalign(top)
			:x(121 + (2*32))
			:y(_screen.h-149.5)
		end,
	}--]]
	
end

return t