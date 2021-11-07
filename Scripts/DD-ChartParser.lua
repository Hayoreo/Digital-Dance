local GetSimfileString = function(steps)
	-- steps:GetFilename() returns the filename of the sm or ssc file, including path, as it is stored in SM's cache
	local filename = steps:GetFilename()
	if not filename then return end

	-- get the file extension like "sm" or "SM" or "ssc" or "SSC" or "sSc" or etc.
	-- convert to lowercase
	local filetype = filename:match("[^.]+$"):lower()
	-- if file doesn't match "ssc" or "sm", it was (hopefully) something else (.dwi, .bms, etc.)
	-- that isn't supported by SL-ChartParser
	if not (filetype=="ssc" or filetype=="sm") then return end

	-- create a generic RageFile that we'll use to read the contents
	-- of the desired .ssc or .sm file
	local f = RageFileUtil.CreateRageFile()
	local contents

	-- the second argument here (the 1) signals
	-- that we are opening the file in read-only mode
	if f:Open(filename, 1) then
		contents = f:Read()
	end

	-- destroy the generic RageFile now that we have the contents
	f:destroy()
	return contents, filetype
end

-- ----------------------------------------------------------------
-- We use our own BinaryToHex function as it seems like the current
-- implementation from the engine doesn't handle sequential zeroes correctly.
local Bin2Hex = function(s)
	local hex_bytes = {}
	for i = 1, string.len(s), 1 do
		hex_bytes[#hex_bytes+1] = string.format('%02x', string.byte(s, i))
	end
	return table.concat(hex_bytes, '')
end

-- Reduce the chart to it's smallest unique representable form.
local MinimizeChart = function(ChartString)
	local function MinimizeMeasure(measure)
		local minimal = false
		-- We can potentially minimize the chart to get the most compressed
		-- form of the actual chart data.
		-- NOTE(teejusb): This can be more compressed than the data actually
		-- generated by StepMania. This is okay because the charts would still
		-- be considered equivalent.
		-- E.g. 0000                      0000
		--      0000  -- minimized to -->
		--      0000
		--      0000
		--      StepMania will always generate the former since quarter notes are
		--      the smallest quantization.
		while not minimal and #measure % 2 == 0 do
			-- If every other line is all 0s, we can minimize the measure.
			local allZeroes = true
			for i=2, #measure, 2 do
				-- Check if the row is NOT all zeroes (thus we can't minimize).
				if measure[i] ~= string.rep('0', measure[i]:len()) then
					allZeroes = false
					break
				end
			end

			if allZeroes then
				-- To remove every other element while keeping the
				-- indices valid, we iterate from [2, len(t)/2 + 1].
				-- See the example below (where len(t) == 6).

				-- index: 1 2 3 4 5 6  -> remove index 2
				-- value: a b a b a b

				-- index: 1 2 3 4 5    -> remove index 3
				-- value: a a b a b

				-- index: 1 2 3 4      -> remove index 4
				-- value: a a a b

				-- index: 1 2 3
				-- value: a a a
				for i=2, #measure/2+1 do
					table.remove(measure, i)
				end
			else
				minimal = true
			end
		end
	end

	local finalChartData = {}
	local curMeasure = {}
	for line in ChartString:gmatch('[^\n]+') do
		-- If we hit a comma, that denotes the end of a measure.
		-- Try to minimize it, and then add it to the final chart data with
		-- the delimiter.
		-- Note: The ending semi-colon has been stripped out.
		if line == ',' then
			MinimizeMeasure(curMeasure)

			for row in ivalues(curMeasure) do
				table.insert(finalChartData, row)
			end
			table.insert(finalChartData, ',')
			-- Just keep removing the first element to clear the table.
			-- This way we don't need to wait for the GC to cleanup the unused values.
			for i=1, #curMeasure do
				table.remove(curMeasure, 1)
			end
		else
			table.insert(curMeasure, line)
		end
	end

	-- Add the final measure.
	if #curMeasure > 0 then
		MinimizeMeasure(curMeasure)

		for row in ivalues(curMeasure) do
			table.insert(finalChartData, row)
		end
	end

	return table.concat(finalChartData, '\n')
end

local NormalizeFloatDigits = function(param)
	local function NormalizeDecimal(decimal)
		-- Remove any control characters from the string to prevent conversion failures.
		decimal = decimal:gsub("%c", "")
		local rounded = tonumber(decimal)

		-- Round to 3 decimal places
		local mult = 10^3
		rounded = (rounded * mult + 0.5 - (rounded * mult + 0.5) % 1) / mult
		return string.format("%.3f", rounded)
	end

	local paramParts = {}
	for beat_bpm in param:gmatch('[^,]+') do
		local beat, bpm = beat_bpm:match('(.+)=(.+)')
		table.insert(paramParts, NormalizeDecimal(beat) .. '=' .. NormalizeDecimal(bpm))
	end
	return table.concat(paramParts, ',')
end

-- ----------------------------------------------------------------
-- ORIGINAL SOURCE: https://github.com/JonathanKnepp/SM5StreamParser

-- GetSimfileChartString() accepts four arguments:
--    SimfileString - the contents of the ssc or sm file as a string
--    StepsType     - a string like "dance-single" or "pump-double"
--    Difficulty    - a string like "Beginner" or "Challenge" or "Edit"
--    Filetype      - either "sm" or "ssc"
--
-- GetSimfileChartString() returns two value:
--    NoteDataString, a substring from SimfileString that contains the just the requested (minimized) note data
--    BPMs, a substring from SimfileString that contains the BPM string for this specific chart

local GetSimfileChartString = function(SimfileString, StepsType, Difficulty, StepsDescription, Filetype)
	local NoteDataString = nil
	local BPMs = nil

	-- ----------------------------------------------------------------
	-- StepMania uses each steps' "Description" attribute to uniquely
	-- identify Edit charts. (This is important, because there can be more
	-- than one Edit chart.)
	--
	-- SSC files use a dedicated #DESCRIPTION for this purpose
	-- SM files use the 3rd spot in the #NOTES field for this purpose
	-- ----------------------------------------------------------------

	if Filetype == "ssc" then
		local topLevelBpm = NormalizeFloatDigits(SimfileString:match("#[Bb][Pp][Mm][Ss]:(.-);"):gsub("%s+", ""))
		-- SSC File
		-- Loop through each chart in the SSC file
		for noteData in SimfileString:gmatch("#[Nn][Oo][Tt][Ee][Dd][Aa][Tt][Aa].-#[Nn][Oo][Tt][Ee][Ss]2?:[^;]*") do
			-- Normalize all the line endings to '\n'
			local normalizedNoteData = noteData:gsub('\r\n?', '\n')

			-- WHY? Why does StepMania allow the same fields to be defined multiple times
			-- in a single NOTEDATA stanza.
			-- We'll just use the first non-empty one.
			-- TODO(teejsub): Double check the expected behavior even though it is
			-- currently sufficient for all ranked charts on GrooveStats.
			local stepsType = ''
			for st in normalizedNoteData:gmatch("#[Ss][Tt][Ee][Pp][Ss][Tt][Yy][Pp][Ee]:(.-);") do
				if stepsType == '' and st ~= '' then
					stepsType = st
					break
				end
			end
			stepsType = stepsType:gsub("%s+", "")

			local difficulty = ''
			for diff in normalizedNoteData:gmatch("#[Dd][Ii][Ff][Ff][Ii][Cc][Uu][Ll][Tt][Yy]:(.-);") do
				if difficulty == '' and diff ~= '' then
					difficulty = diff
					break
				end
			end
			difficulty = difficulty:gsub("%s+", "")

			local description = ''
			for desc in normalizedNoteData:gmatch("#[Dd][Ee][Ss][Cc][Rr][Ii][Pp][Tt][Ii][Oo][Nn]:(.-);") do
				if description == '' and desc ~= '' then
					description = desc
					break
				end
			end

			-- Find the chart that matches our difficulty and game type.
			if (stepsType == StepsType and difficulty == Difficulty) then
				-- Ensure that we've located the correct edit stepchart within the SSC file.
				-- There can be multiple Edit stepcharts but each is guaranteed to have a unique #DESCIPTION tag
				if (difficulty ~= "Edit" or description == StepsDescription) then
					-- Get chart specific BPMS (if any).
					local splitBpm = normalizedNoteData:match("#[Bb][Pp][Mm][Ss]:(.-);") or ''
					splitBpm = splitBpm:gsub("%s+", "")

					if #splitBpm == 0 then
						BPMs = topLevelBpm
					else
						BPMs = NormalizeFloatDigits(splitBpm)
					end
					-- Get the chart data, remove comments, and then get rid of all non-'\n' whitespace.
					NoteDataString = normalizedNoteData:match("#[Nn][Oo][Tt][Ee][Ss]2?:[\n]*([^;]*)\n?$"):gsub("//[^\n]*", ""):gsub('[\r\t\f\v ]+', '')
					NoteDataString = MinimizeChart(NoteDataString)
					break
				end
			end
		end
	elseif Filetype == "sm" then
		-- SM FILE
		BPMs = NormalizeFloatDigits(SimfileString:match("#[Bb][Pp][Mm][Ss]:(.-);"):gsub("%s+", ""))
		-- Loop through each chart in the SM file
		for noteData in SimfileString:gmatch("#[Nn][Oo][Tt][Ee][Ss]2?[^;]*") do
			-- Normalize all the line endings to '\n'
			local normalizedNoteData = noteData:gsub('\r\n?', '\n')
			-- Split the entire chart string into pieces on ":"
			local parts = {}
			for part in normalizedNoteData:gmatch("[^:]+") do
				parts[#parts+1] = part
			end

			-- The pieces table should contain at least 7 numerically indexed items
			-- 2, 4, (maybe 3) and 7 are the indices we care about for finding the correct chart
			-- Index 2 will contain the steps_type (like "dance-single")
			-- Index 4 will contain the difficulty (like "challenge")
			-- Index 3 will contain the description for Edit charts
			if #parts >= 7 then
				local stepsType = parts[2]:gsub("[^%w-]", "")
				local difficulty = parts[4]:gsub("[^%w]", "")
				local description = parts[3]:gsub("^%s*(.-)", "")
				-- Find the chart that matches our difficulty and game type.
				if (stepsType == StepsType and difficulty == Difficulty) then
					-- Ensure that we've located the correct edit stepchart within the SSC file.
					-- There can be multiple Edit stepcharts but each is guaranteed to have a unique #DESCIPTION tag
					if (difficulty ~= "Edit" or description == StepsDescription) then
						NoteDataString = parts[7]:gsub("//[^\n]*", ""):gsub('[\r\t\f\v ]+', '')
						NoteDataString = MinimizeChart(NoteDataString)
						break
					end
				end
			end
		end
	end

	return NoteDataString, BPMs
end

-- Figure out which measures are considered a stream of notes
local GetMeasureInfo = function(Steps, measuresString)
	-- Stream Measures Variables
	-- Which measures are considered a stream?
	local notesPerMeasure = {}
	local measureCount = 1
	local notesInMeasure = 0

	-- NPS and Density Graph Variables
	local NPSperMeasure = {}
	local NPSForThisMeasure, peakNPS = 0, 0
	local timingData = Steps:GetTimingData()

	-- Loop through each line in our string of measures, trimming potential leading whitespace (thanks, TLOES/Mirage Garden)
	for line in measuresString:gmatch("[^%s*\r\n]+") do
		-- If we hit a comma or a semi-colon, then we've hit the end of our measure
		if(line:match("^[,;]%s*")) then
			-- Does the number of notes in this measure meet our threshold to be considered a stream?
			table.insert(notesPerMeasure, notesInMeasure)

			-- NPS Calculation
			durationOfMeasureInSeconds = timingData:GetElapsedTimeFromBeat(measureCount * 4) - timingData:GetElapsedTimeFromBeat((measureCount-1)*4)

			-- FIXME: We subtract the time at the current measure from the time at the next measure to determine
			-- the duration of this measure in seconds, and use that to calculate notes per second.
			--
			-- Measures *normally* occur over some positive quantity of seconds.  Measures that use warps,
			-- negative BPMs, and negative stops are normally reported by the SM5 engine as having a duration
			-- of 0 seconds, and when that happens, we safely assume that there were 0 notes in that measure.
			--
			-- This doesn't always hold true.  Measures 48 and 49 of "Mudkyp Korea/Can't Nobody" use a properly
			-- timed negative stop, but the engine reports them as having very small but positive durations
			-- which erroneously inflates the notes per second calculation.
			if durationOfMeasureInSeconds == 0 then
				NPSForThisMeasure = 0
			else
				NPSForThisMeasure = notesInMeasure/durationOfMeasureInSeconds
			end

			NPSperMeasure[measureCount] = NPSForThisMeasure

			-- determine whether this measure contained the PeakNPS
			if NPSForThisMeasure > peakNPS then
				peakNPS = NPSForThisMeasure
			end

			-- Reset iterative variables
			notesInMeasure = 0
			measureCount = measureCount + 1
		else
			-- Is this a note? (Tap, Hold Head, Roll Head)
			if(line:match("[124]")) then
				notesInMeasure = notesInMeasure + 1
			end
		end
	end

	return notesPerMeasure, peakNPS, NPSperMeasure
end

local MaybeCopyFromOppositePlayer = function(pn, filename, stepsType, difficulty, description)
	local opposite_player = pn == "P1" and "P2" or "P1"

	-- Check if we already have the data stored in the opposite player's cache.
	if (SL[opposite_player].Streams.Filename == filename and
			SL[opposite_player].Streams.StepsType == stepsType and
			SL[opposite_player].Streams.Difficulty == difficulty and
			SL[opposite_player].Streams.Description == description) then
		-- If so then just copy everything over.
		SL[pn].Streams.NotesPerMeasure = SL[opposite_player].Streams.NotesPerMeasure
		SL[pn].Streams.PeakNPS = SL[opposite_player].Streams.PeakNPS
		SL[pn].Streams.NPSperMeasure = SL[opposite_player].Streams.NPSperMeasure
		SL[pn].Streams.Hash = SL[opposite_player].Streams.Hash

		SL[pn].Streams.Filename = SL[opposite_player].Streams.Filename
		SL[pn].Streams.StepsType = SL[opposite_player].Streams.StepsType
		SL[pn].Streams.Difficulty = SL[opposite_player].Streams.Difficulty
		SL[pn].Streams.Description = SL[opposite_player].Streams.Description

		return true
	else
		return false
	end
end
		
ParseChartInfo = function(steps, pn)
	-- The filename for these steps in the StepMania cache 
	local filename = steps:GetFilename()
	-- StepsType, a string like "dance-single" or "pump-double"
	local stepsType = ToEnumShortString( steps:GetStepsType() ):gsub("_", "-"):lower()
	-- Difficulty, a string like "Beginner" or "Challenge"
	local difficulty = ToEnumShortString( steps:GetDifficulty() )
	-- An arbitary but unique string provided by the stepartist, needed here to identify Edit charts
	local description = steps:GetDescription()

	-- If we've copied from the other player then we're done.
	if MaybeCopyFromOppositePlayer(pn, filename, stepsType, difficulty, description) then
		return
	end

	-- Only parse the file if it's not what's already stored in SL Cache.
	if (SL[pn].Streams.Filename ~= filename or
			SL[pn].Streams.StepsType ~= stepsType or
			SL[pn].Streams.Difficulty ~= difficulty or
			SL[pn].Streams.Description ~= description) then
		local simfileString, fileType = GetSimfileString( steps )
		if simfileString then
			-- Parse out just the contents of the notes
			local chartString, BPMs = GetSimfileChartString(simfileString, stepsType, difficulty, description, fileType)
			if chartString ~= nil and BPMs ~= nil then
				-- We use 16 characters for the V3 GrooveStats hash.
				local Hash = Bin2Hex(CRYPTMAN:SHA1String(chartString..BPMs)):sub(1, 16)

				-- Append the semi-colon at the end so it's easier for GetMeasureInfo to get the contents
				-- of the last measure.
				chartString = chartString .. ';'
				-- Which measures have enough notes to be considered as part of a stream?
				-- We can also extract the PeakNPS and the NPSperMeasure table info in the same pass.
				local NotesPerMeasure, PeakNPS, NPSperMeasure = GetMeasureInfo(steps, chartString)

				-- Which sequences of measures are considered a stream?
				SL[pn].Streams.NotesPerMeasure = NotesPerMeasure
				SL[pn].Streams.PeakNPS = PeakNPS
				SL[pn].Streams.NPSperMeasure = NPSperMeasure
				SL[pn].Streams.Hash = Hash

				SL[pn].Streams.Filename = filename
				SL[pn].Streams.StepsType = stepsType
				SL[pn].Streams.Difficulty = difficulty
				SL[pn].Streams.Description = description
			end
		end
	end
end