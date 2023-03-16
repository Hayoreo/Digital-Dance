-- This file will track the time that a player fails and show on the Evaluation screen.
-- Additionally, if the player fails inside a stream (16ths or higher) it will display 
-- the position in the stream (16ths) that they fail.

-- This does not count if the player holds start to fail

local player = ...
local pn = ToEnumShortString(player)

local af = Def.Actor{
	HealthStateChangedMessageCommand=function(self, param)
		if GAMESTATE:IsCourseMode() then
			return
		end
		-- Only do something if the player fails
		if param.PlayerNumber == player and param.HealthState == "HealthState_Dead" then			
			local playerState = GAMESTATE:GetPlayerState(player)			
			
			-- These functions already account for rate mod
			local currentSecond = getCurrentTimePlayed(player)
			-- Not only is the course mode graph useless, it's also kinda weird
			-- It only shows the lifebar history for the entire course up until the end of the current song
			-- So for positioning in course mode, we need to find the total time of all the songs
			-- up until the end of the current song. This is maybe correct
			local totalSeconds = getTotalSongOrCourseLength(player)
			local deathSecond = getCurrentTimePlayed(player)

			local currentMeasure = math.floor(playerState:GetSongPosition():GetSongBeatVisible()/4)
			
			local streams = SL[pn].Streams
			local storage = SL[pn].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1]
			
			storage.TotalSeconds = totalSeconds
			storage.DeathSecond = deathSecond
			storage.GraphPercentage = deathSecond / totalSeconds
			storage.GraphLabel = totalSeconds - deathSecond

			-- find out if this measure was a stream (16ths or higher)
			if streams.NotesPerMeasure[currentMeasure + 1] >= 16 then
				-- find out which measure the fail was 
				for i = 1, #streams.Measures do
					local streamStartMeasure = streams.Measures[i].streamStart
					local streamEndMeasure = streams.Measures[i].streamEnd

					if currentMeasure >= streamStartMeasure and currentMeasure < streamEndMeasure then
						measuresCompleted = currentMeasure - streamStartMeasure
						totalRun = streamEndMeasure - streamStartMeasure
						storage.failPoint = currentMeasure - streamStartMeasure
						storage.DeathMeasures = string.format("%s/%s", measuresCompleted, totalRun)
					end
				end
			end
		end
	end
}

return af