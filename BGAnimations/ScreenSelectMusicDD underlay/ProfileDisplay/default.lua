local args = ...
local PruneSongsFromGroup = args[1]

-- don't load in course mode
if GAMESTATE:IsCourseMode() then return end

local t = Def.ActorFrame{}

for player in ivalues( PlayerNumber ) do
	-- The background and static player info (like name, and profile picture)
	t[#t+1] = LoadActor("./ProfilePane.lua", player)
	-- All the variable player profile info
	t[#t+1] = LoadActor("./ProfileStats.lua", {player, PruneSongsFromGroup})
end

return t