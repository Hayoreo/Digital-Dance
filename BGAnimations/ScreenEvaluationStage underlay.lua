---- this is to calculate the average bpm/difficulty but not let it increment unless the song was finished. HELP ----
local SongInSet = SL.Global.Stages.PlayedThisGame
local SongsInSet = SongInSet + 1
local P1 = GAMESTATE:IsHumanPlayer(PLAYER_1)
local P2 = GAMESTATE:IsHumanPlayer(PLAYER_2)


-- insert more junk for calculating average difficulty here
local PlayerOneChart = GAMESTATE:GetCurrentSteps(0)
local PlayerTwoChart = GAMESTATE:GetCurrentSteps(1)


---------- Only do these if the player is currently active or else things will get messy. ----------
if P1 then
P1SongsInSet = P1SongsInSet + 1
end

if P2 then
P2SongsInSet = P2SongsInSet + 1
end

local song = GAMESTATE:GetCurrentSong()
-- Update stats
if GAMESTATE:IsPlayerEnabled(PLAYER_1) then
	DDStats.SetStat(PLAYER_1, 'LastSong', song:GetSongDir())
	DDStats.SetStat(PLAYER_1, 'LastDifficulty', PlayerOneChart:GetDifficulty())
	DDStats.Save(PLAYER_1)
end

if GAMESTATE:IsPlayerEnabled(PLAYER_2) then
	DDStats.SetStat(PLAYER_2, 'LastSong', song:GetSongDir())
	DDStats.SetStat(PLAYER_2, 'LastDifficulty', PlayerTwoChart:GetDifficulty())
	DDStats.Save(PLAYER_2)
end

return Def.ActorFrame { }
