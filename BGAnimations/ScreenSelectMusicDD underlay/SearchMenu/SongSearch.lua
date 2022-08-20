
local t = Def.ActorFrame{

SongSearchSSMDDMessageCommand = function(self)
	local results = 0
	
	if SongSearchAnswer ~= "" or ArtistSearchAnswer ~= "" or ChartSearchAnswer ~= "" then
		for i,song in ipairs(SongsAvailable) do
			local title = song:GetDisplayFullTitle():lower()
			local artist = song:GetDisplayArtist():lower()
			local steps_type = GAMESTATE:GetCurrentStyle():GetStepsType()
			-- the query "xl grind" will match a song called "Axle Grinder" no matter
			-- what the chart info says
			local match = true
			
			if title == "Random-Portal" or title == "RANDOM-PORTAL" then
				match = false
			end

			if SongSearchAnswer ~= "" then
				if not title:find(SongSearchAnswer:lower(), 1, true) then
					match = false
				end
			end
			
			if ArtistSearchAnswer ~= "" then
				if not artist:find(ArtistSearchAnswer:lower(), 1, true) then
					match = false
				end
			end
			
			if ChartSearchAnswer ~= "" then
				local chartMatch = false
				for i, steps in ipairs(song:GetStepsByStepsType(steps_type)) do
					local chartStr = steps:GetAuthorCredit():lower().." "..steps:GetDescription():lower()
					-- the query "br xo fs" will match any song with at least one chart that
					-- has "br", "xo" and "fs" in its AuthorCredit + Description
					
					if chartStr:find(ChartSearchAnswer:lower(), 1, true) then
						chartMatch = true
					end
				end
				if not chartMatch then
					match = false
				end
			end

			if match then
				results = results + 1
			end
		end
		if results > 0 then
			SongSearchSSMDD = true
			SongSearchWheelNeedsResetting = true
			self:sleep(0.25):queuecommand("ReloadScreen")
		else
			SM("No songs found!")
		end
	else
		SongSearchAnswer = ""
		ArtistSearchAnswer = ""
		ChartSearchAnswer = ""
		MESSAGEMAN:Broadcast("ToggleSearchMenu")
	end
end,

ReloadScreenCommand=function(self)
	screen:SetNextScreenName("ScreenReloadSSMDD")
	screen:StartTransitioningScreen("SM_GoToNextScreen")
end,

}

return t