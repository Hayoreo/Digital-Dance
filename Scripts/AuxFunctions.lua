-- Modified from Zarzob/Zankoku SL fork for personal use

-- Returns an array of songLengths for each song in a course
-- used in BGAnimations/ScreenGameplay overlay/TrackFailTime.lua
getCourseSongLengthArray=function(player)
	local songLengths = {}
	if GAMESTATE:IsCourseMode() then
		local currentRatemod = SL.Global.ActiveModifiers.MusicRate
		local seconds = 0
		local trail = GAMESTATE:GetCurrentTrail(player)
	
		if trail then
			local entries = trail:GetTrailEntries()
			for i, entry in ipairs(entries) do
				seconds = seconds + (entry:GetSong():MusicLengthSeconds() / currentRatemod)
				table.insert(songLengths, seconds)
			end
		end
		return songLengths
	end
end

-- Return the total length of the current song or course in seconds
getTotalSongOrCourseLength=function(player)
	local totalSeconds = 0
	if GAMESTATE:IsCourseMode() then
		local trail = GAMESTATE:GetCurrentTrail(player)
		if trail then
			totalSeconds = trail:GetLengthSeconds()
		end
	else
		local currentSong = GAMESTATE:GetCurrentSong()
		if currentSong then
			totalSeconds = currentSong:GetLastSecond()
		end
	end

	-- total_seconds is initialized in the engine as -1
	-- https://github.com/stepmania/stepmania/blob/6a645b4710/src/Song.cpp#L80
	-- and might not have ever been set to anything meaningful in edge cases
	-- e.g. ogg file is 5 seconds, ssc file has 1 tapnote occuring at beat 0
	if totalSeconds < 0 then totalSeconds = 0 end

	local currentRatemod = SL.Global.ActiveModifiers.MusicRate
	totalSeconds = totalSeconds / currentRatemod

	return totalSeconds
end

-- Return the current time of the course or song, in seconds
getCurrentTimePlayed=function(player)
	local playerState = GAMESTATE:GetPlayerState(player)	
	local timePlayed = 0
	local currentRatemod = SL.Global.ActiveModifiers.MusicRate

	-- This doesn't work for course mode yet, it isn't called
	if GAMESTATE:IsCourseMode() then
		-- Find out what song in the course
		local courseIndex = GAMESTATE:GetCourseSongIndex()

		-- cumulative song length array
		local totalSongTime = getCourseSongLengthArray(player)

		-- Add up all the previous songs
		for i=1,courseIndex do
			timePlayed = timePlayed + totalSongTime[courseIndex]
		end

		-- Now add on the current song's timer
		local currentSongTimer = playerState:GetSongPosition():GetMusicSecondsVisible()
		currentSongTimer = currentSongTimer / currentRatemod
		timePlayed = timePlayed + currentSongTimer
	else
		timePlayed = playerState:GetSongPosition():GetMusicSecondsVisible()  / currentRatemod
	end

	return timePlayed
end

-- Return a color based on how many measures were done
-- Used in Graphs.lua
getFailMeasureColor=function(measureCount)
	local fontColor
	if (measureCount < 32) then
		fontColor = Color.Red
	elseif (measureCount >= 32 and measureCount < 100) then
		fontColor = Color.Green
	elseif (measureCount >= 100) then
		fontColor = Color.Yellow
	end

	return fontColor
end