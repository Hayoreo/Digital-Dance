local t = Def.ActorFrame{}

for player in ivalues( PlayerNumber ) do
	-- Cursor for difficulty selection
	t[#t+1] = LoadActor("./Cursor.lua", player)
	t[#t+1] = LoadActor("./Tabs.lua", player)
end

return t