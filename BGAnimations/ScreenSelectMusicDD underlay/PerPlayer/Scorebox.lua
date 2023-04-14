local player = ...
local pn = ToEnumShortString(player)
local CurrentTab = 1

if SL[pn].ApiKey == "" then
	return
end

local n = player==PLAYER_1 and "1" or "2"

local border = 5
local width = SCREEN_WIDTH/3 - 5
local height = 120 - 5

local cur_style = 0
local num_styles = 4
local num_scores = 6

local GrooveStatsBlue = color("#007b85")
local RpgYellow = color("1,0.972,0.792,1")
local ItlPink = color("1,0.2,0.406,1")
local MachinePurple = color("#4d0057")

local isRanked = false
local IsVisible = false

local style_color = {
	[0] = GrooveStatsBlue,
	[1] = RpgYellow,
	[2] = ItlPink,
	[3] = MachinePurple,
}

local self_color = color("#a1ff94")
local rival_color = color("#c29cff")

local loop_seconds = 5
local transition_seconds = 1

local all_data = {}

local ResetAllData = function()
	for i=1,num_styles do
		local data = {
			["has_data"]=false,
			["scores"]={}
		}
		local scores = data["scores"]
		for i=1,num_scores do
			scores[#scores+1] = {
				["rank"]="",
				["name"]="",
				["score"]="",
				["isSelf"]=false,
				["isRival"]=false,
				["isFail"]=false
			}
		end
		all_data[#all_data + 1] = data
	end
end

-- Initialize the all_data object.
ResetAllData()

-- Checks to see if any data is available.
local HasData = function(idx)
	return all_data[idx+1] and all_data[idx+1].has_data
end

local SetScoreData = function(data_idx, score_idx, rank, name, score, isSelf, isRival, isFail)
	all_data[data_idx].has_data = true

	local score_data = all_data[data_idx]["scores"][score_idx]
	score_data.rank = rank..((#rank > 0) and "." or "")
	score_data.name = name
	score_data.score = score
	score_data.isSelf = isSelf
	score_data.isRival = isRival
	score_data.isFail = isFail
end

local LeaderboardRequestProcessor = function(res, master)
	if res == nil or res["status"] == "disabled" or res["status"] == "fail" then
		local text = "Timed Out"
		if res ~= nil then
			if res["status"] == "disabled" then
				text = "Leaderboard Disabled"
			end
			if res["status"] == "fail" then
				text = "Failed to Load 😞"
			end
		end
		SetScoreData(1, 1, "", text, "", false, false)
		master:queuecommand("CheckScorebox")
		return
	end

	local playerStr = "player"..n
	local data = res["status"] == "success" and res["data"] or nil

	-- First check to see if the leaderboard even exists.
	if data and data[playerStr] then
		-- These will get overwritten if we have any entries in the leaderboard below.
		if data[playerStr]["isRanked"] then
			isRanked = true
			cur_style = 0
			SetScoreData(1, 1, "", "No Scores", "", false, false, false)
		else
			isRanked = true
			all_data[1].has_data = false
			cur_style = 1
			if (not (data[playerStr]["rpg"] and data[playerStr]["rpg"]["rpgLeaderboard"]) and
			not (data[playerStr]["itl"] and data[playerStr]["itl"]["itlLeaderboard"])) then
				all_data[2].has_data = false
				all_data[3].has_data = false
				SetScoreData(1, 1, "", "Chart Not Ranked", "", false, false, false)
				isRanked = false
			end
		end

		if data[playerStr]["isRanked"] and data[playerStr]["gsLeaderboard"] then
			local entryCount = 0
			for entry in ivalues(data[playerStr]["gsLeaderboard"]) do
				entryCount = entryCount + 1
				SetScoreData(1, entryCount,
								tostring(entry["rank"]),
								entry["name"],
								string.format("%.2f", entry["score"]/100),
								entry["isSelf"],
								entry["isRival"],
								entry["isFail"])
			end
			entryCount = entryCount + 1
			if entryCount > 1 then
				for i=entryCount,num_scores,1 do
					SetScoreData(1, i,
									"",
									"",
									"",
									false,
									false,
									false)
				end
			end
		end

		if data[playerStr]["rpg"] then
			local entryCount = 0
			SetScoreData(2, 1, "", "No Scores", "", false, false, false)

			if data[playerStr]["rpg"]["rpgLeaderboard"] then
				for entry in ivalues(data[playerStr]["rpg"]["rpgLeaderboard"]) do
					entryCount = entryCount + 1
					SetScoreData(2, entryCount,
									tostring(entry["rank"]),
									entry["name"],
									string.format("%.2f", entry["score"]/100),
									entry["isSelf"],
									entry["isRival"],
									entry["isFail"]
								)
				end
				entryCount = entryCount + 1
				for i=entryCount,num_scores,1 do
					SetScoreData(2, i,
									"",
									"",
									"",
									false,
									false,
									false)
				end
			end
		end

		if data[playerStr]["itl"] then
			local numEntries = 0
			SetScoreData(3, 1, "", "No Scores", "", false, false, false)

			if data[playerStr]["itl"]["itlLeaderboard"] then
				for entry in ivalues(data[playerStr]["itl"]["itlLeaderboard"]) do
					if entry["isSelf"] then
						UpdateItlExScore(player, SL[pn].Streams.Hash, entry["score"])
						SL["P"..n].itlScore = entry["score"]
						local stepartist = SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("PerPlayer"):GetChild("StepArtistAF_P"..n)
						if stepartist ~= nil then
						  stepartist:queuecommand("ITL")
						end
					end
					numEntries = numEntries + 1
					SetScoreData(3, numEntries,
									tostring(entry["rank"]),
									entry["name"],
									string.format("%.2f", entry["score"]/100),
									entry["isSelf"],
									entry["isRival"],
									entry["isFail"]
								)
				end
				numEntries = numEntries + 1
				for i=numEntries,num_scores,1 do
					SetScoreData(3, i,
									"",
									"",
									"",
									false,
									false,
									false)
				end
			end
		end
		
 	end
	master:queuecommand("CheckScorebox")
	master:queuecommand("SetScorebox")
end

local af = Def.ActorFrame{
	Name="ScoreBox"..pn,
	InitCommand=function(self)
		self:xy((player==PLAYER_1 and (SCREEN_WIDTH/3)/2 or _screen.w - (SCREEN_WIDTH/3)/2), _screen.h - 32 - 60):visible(false)
		self.isFirst = true
	end,
	CheckScoreboxCommand=function(self)
		self:queuecommand("LoopScorebox")
	end,
	CurrentSongChangedMessageCommand=function(self)
		self.isFirst = true
		self:stoptweening():sleep(0.2):queuecommand("Reset")
	end,
	["TabClicked"..player.."MessageCommand"]=function(self, TabClicked)
		if TabClicked[1] == CurrentTab then
		elseif TabClicked[1] == "1" then
			CurrentTab = TabClicked[1]
			self:visible(false)
			IsVisible = false
		else
			CurrentTab = TabClicked[1]
			self:visible(true)
			IsVisible = true
			cur_style = TabClicked[1] - 2
			self:queuecommand("UpdateScorebox")
		end
	end,
	LoopScoreboxCommand=function(self)
		self:visible(IsVisible)
		local has_data = false
		if #all_data == 0 then return end
		for i=1,num_styles do
			if all_data[i].has_data then
				has_data = true
			end
		end
		if not has_data then return end

		self:finishtweening()
		
		for i=1, num_scores do
			self:GetChild("Rank"..i):visible(true)
			self:GetChild("Name"..i):visible(true)
			self:GetChild("Score"..i):visible(true)
		end
		self:GetChild("GrooveStatsLogo"):stopeffect()
		self:GetChild("SRPG6Logo"):visible(true)
		self:GetChild("ITLLogo"):visible(true)
		self:GetChild("MachineLogo"):visible(true)
		
		local start = cur_style

		cur_style = (cur_style + 1) % num_styles
		if cur_style ~= start or self.isFirst then
			-- Make sure we have the next set of data.
			while cur_style ~= start do
				if HasData(cur_style) then
					-- If this is the first time we're looping, update the start variable
					-- since it may be different than the default
					if self.isFirst then
						start = cur_style
						self.isFirst = false
						-- Continue looping to figure out the next style.
					else
						break
					end
				end
				cur_style = (cur_style + 1) % num_styles
			end
		end
	end,
	RequestResponseActor("Leaderboard", loop_seconds, 0, 0)..{
		OnCommand=function(self)
			self:queuecommand("MakeRequest")
			-- Create variables for both players, even if they're not currently active.
			self.IsParsing = {false, false}
		end,
		-- Broadcasted from ./PerPlayer/DensityGraph.lua
		P1ChartParsingMessageCommand=function(self)	self.IsParsing[1] = true end,
		P2ChartParsingMessageCommand=function(self)	self.IsParsing[2] = true end,
		P1ChartParsedMessageCommand=function(self)
			self.IsParsing[1] = false
			if pn == "P1" then
				self:queuecommand("ChartParsed")
			end
		end,
		P2ChartParsedMessageCommand=function(self)
			self.IsParsing[2] = false
			if pn == "P2" then
				self:queuecommand("ChartParsed")
			end
		end,
		ChartParsedCommand=function(self)
			self:queuecommand("MakeRequest")
		end,
		ResetCommand=function(self)
			if not self.isFirst then
				ResetAllData()
			end
		end,
		MakeRequestCommand=function(self)
			local sendRequest = false
			local data = {
				action="groovestats/player-leaderboards",
				maxLeaderboardResults=num_scores,
			}
			if SL[pn].ApiKey ~= "" then
				data["player"..n] = {
					chartHash=SL[pn].Streams.Hash,
					apiKey=SL[pn].ApiKey
				}
				sendRequest = true
			end

			-- We technically will send two requests in ultrawide versus mode since
			-- both players will have their own individual scoreboxes.
			-- Should be fine though.
			if sendRequest then
				if self.IsParsing[1] or self.IsParsing[2] then return end
				RemoveStaleCachedRequests()
				ResetAllData()
				
				self:GetParent():visible(IsVisible)
				for i=1, num_scores do
					self:GetParent():GetChild("Name"..i):settext(""):visible(false)
					self:GetParent():GetChild("Score"..i):settext(""):visible(false)
					self:GetParent():GetChild("Rank"..i):diffusealpha(0):visible(false)
				end
				self:GetParent():GetChild("GrooveStatsLogo"):diffusealpha(0.5):glowshift({color("#C8FFFF"), color("#6BF0FF")})
				self:GetParent():GetChild("SRPG6Logo"):diffusealpha(0):visible(false)
				self:GetParent():GetChild("ITLLogo"):diffusealpha(0):visible(false)
				self:GetParent():GetChild("MachineLogo"):diffusealpha(0):visible(false)
				MESSAGEMAN:Broadcast("Leaderboard", {
					data=data,
					args=self:GetParent(),
					callback=LeaderboardRequestProcessor
				})
			end
		end
	},

	-- Outline
	Def.Quad{
		Name="Outline",
		InitCommand=function(self)
			self:diffuse(GrooveStatsBlue):setsize(width + border, height + border)
		end,
		UpdateScoreboxCommand=function(self)
			self:stoptweening():linear(transition_seconds/2):diffuse(style_color[cur_style])
		end
	},
	-- Main body
	Def.Quad{
		Name="Background",
		InitCommand=function(self)
			self:diffuse(color("#000000")):setsize(width, height)
		end,
	},
	-- GrooveStats Logo
	Def.Sprite{
		Texture=THEME:GetPathG("", "GrooveStats.png"),
		Name="GrooveStatsLogo",
		InitCommand=function(self)
			self:zoom(0.6):diffusealpha(0.5):x(80)
		end,
		UpdateScoreboxCommand=function(self)
			if cur_style == 0 then
				self:linear(transition_seconds/2):diffusealpha(0.5)
			else
				self:linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},
	-- SRPG Logo
	Def.Sprite{
		Texture=THEME:GetPathG("", "SRPG/SRPG6 Logo (doubleres).png"),
		Name="SRPG6Logo",
		InitCommand=function(self)
			self:diffusealpha(0.4):zoom(0.18):diffusealpha(0):x(80)
		end,
		UpdateScoreboxCommand=function(self)
			if cur_style == 1 then
				self:linear(transition_seconds/2):diffusealpha(0.5)
			else
				self:linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},
	-- ITL Logo
	Def.Sprite{
		Texture=THEME:GetPathG("", "ITL.png"),
		Name="ITLLogo",
		InitCommand=function(self)
			self:diffusealpha(0.2):zoom(0.3):diffusealpha(0):x(80)
		end,
		UpdateScoreboxCommand=function(self)
			if cur_style == 2 then
				self:linear(transition_seconds/2):diffusealpha(0.2)
			else
				self:linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},
	-- Machine Logo
	Def.Sprite{
		Texture=THEME:GetPathG("", "Machine.png"),
		Name="MachineLogo",
		InitCommand=function(self)
			self:diffusealpha(0.2):zoom(0.18):diffusealpha(0):x(80):y(7)
		end,
		UpdateScoreboxCommand=function(self)
			if cur_style == 3 then
				self:linear(transition_seconds/2):diffusealpha(0.5)
			else
				self:linear(transition_seconds/2):diffusealpha(0)
			end
		end
	},
}

for i=1,num_scores do
	local y = -height/2 + 16 * i + 8
	local zoom = 0.87

	-- Rank 1 gets a crown.
	if i == 1 then
		af[#af+1] = Def.Sprite{
			Name="Rank"..i,
			Texture=THEME:GetPathG("", "crown.png"),
			InitCommand=function(self)
				self:zoom(0.09):xy(-width/2 + 14, y):diffusealpha(0)
			end,
			UpdateScoreboxCommand=function(self)
				self:linear(transition_seconds/2):diffusealpha(0):queuecommand("SetScorebox")
			end,
			SetScoreboxCommand=function(self)
				local score = all_data[cur_style+1]["scores"][i]
				if score.rank ~= "" then
					self:linear(transition_seconds/2):diffusealpha(1)
				end
			end
		}
	else
		af[#af+1] = LoadFont("Common Normal")..{
			Name="Rank"..i,
			Text="",
			InitCommand=function(self)
				self:diffuse(Color.White):xy(-width/2 + 27, y):maxwidth(30):horizalign(right):zoom(zoom)
				end,
			UpdateScoreboxCommand=function(self)
				self:linear(transition_seconds/2):diffusealpha(0):queuecommand("SetScorebox")
			end,
			SetScoreboxCommand=function(self)
				local score = all_data[cur_style+1]["scores"][i]
				local clr = Color.White
				if score.isSelf then
					clr = self_color
				elseif score.isRival then
					clr = rival_color
				end
				if score.rank ~= "" then
					self:settext(score.rank)
				else
					self:settext("")
				end
				self:linear(transition_seconds/2):diffusealpha(1):diffuse(clr)
			end,
		}
	end

	af[#af+1] = LoadFont("Common Normal")..{
		Name="Name"..i,
		Text="",
		InitCommand=function(self)
			self:diffuse(Color.White):xy(-width/2 + 30, y):maxwidth(NoteFieldIsCentered and 60 or 100):horizalign(left):zoom(zoom)
		end,
		UpdateScoreboxCommand=function(self)
			self:linear(transition_seconds/2):diffusealpha(0):queuecommand("SetScorebox")
		end,
		SetScoreboxCommand=function(self)
			local score = all_data[cur_style+1]["scores"][i]
			local clr = Color.White
			if score.isSelf then
				clr = self_color
			elseif score.isRival then
				clr = rival_color
			end
			self:settext(score.name)
			self:linear(transition_seconds/2):diffusealpha(1):diffuse(clr)
		end,
	}

	af[#af+1] = LoadFont("Common Normal")..{
		Name="Score"..i,
		Text="",
		InitCommand=function(self)
			self:diffuse(Color.White):xy(NoteFieldIsCentered and -width/2 + 130 or -width/2 + 160, y):horizalign(right):zoom(zoom)
		end,
		UpdateScoreboxCommand=function(self)
			self:linear(transition_seconds/2):diffusealpha(0):queuecommand("SetScorebox")
		end,
		SetScoreboxCommand=function(self)
			local score = all_data[cur_style+1]["scores"][i]
			local clr = Color.White
			if score.isFail then
				clr = Color.Red
			elseif score.isSelf then
				clr = self_color
			elseif score.isRival then
				clr = rival_color
			end
			self:settext(score.score)
			self:linear(transition_seconds/2):diffusealpha(1):diffuse(clr)
		end
	}
end
return af