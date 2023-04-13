local t = Def.ActorFrame{}

-- always add StepArtist and PaneDisplay actors for both players, even if only one is joined right now
-- if the other player suddenly latejoins, we can't dynamically add more actors to the screen
-- we can only unhide hidden actors that were there all along
for player in ivalues( PlayerNumber ) do
	-- AuthorCredit, Description, and ChartName associated with the current stepchart
	t[#t+1] = LoadActor("./StepArtist.lua", player)

	-- Density Graph
	t[#t+1] = LoadActor("./DensityGraph.lua", player)
	
	-- Custom Scorebox for secondary chart pane
	t[#t+1] = LoadActor("./Scorebox.lua", player)
end

	t[#t+1] = LoadActor("./DifficultyBG.lua")

return t