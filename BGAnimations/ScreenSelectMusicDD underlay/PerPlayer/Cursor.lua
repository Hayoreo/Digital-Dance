local player = ...
local pn = ToEnumShortString(player)
local P1 = GAMESTATE:IsHumanPlayer(PLAYER_1)
local P2 = GAMESTATE:IsHumanPlayer(PLAYER_2)	

-- I feel like this surely must be the wrong way to do this...
local GlobalOffsetSeconds = PREFSMAN:GetPreference("GlobalOffsetSeconds")
local GetStepsToDisplay = LoadActor("../StepsDisplayList/StepsToDisplay.lua")

local RowIndex = 1
local Initialize = false

if GAMESTATE:IsCourseMode() then
return Def.ActorFrame { }
end

return Def.Sprite{
	Texture=THEME:GetPathB("ScreenSelectMusicDD","underlay/PerPlayer/highlight.png"),
	Name="Cursor"..pn,
	InitCommand=function(self)
		self:visible(GAMESTATE:IsHumanPlayer(player))
		self:y( IsUsingWideScreen() and 302.5 or 194)
		-- diffuse with white to make it less #OwMyEyes
		local color = PlayerColor(player)
		color[4] = 1
		color[1] = 0.8 * color[1] + 0.2
		color[2] = 0.8 * color[2] + 0.2
		color[3] = 0.8 * color[3] + 0.2
		self:diffuse(color)
		self:effectmagnitude(-6,0,6)
	end,
	CurrentSongChangedMessageCommand=function(self)
		if not Initialize then 
			self:queuecommand("Set")
		else  
			self:stoptweening():sleep(0.2):queuecommand("Set") 
		end
	end,
	CurrentCourseChangedMessageCommand=function(self) 				self:stoptweening():sleep(0.2):queuecommand("Set") end,
	["CurrentSteps"..pn.."ChangedMessageCommand"]=function(self) 	self:stoptweening():sleep(0.2):queuecommand("Set") end,
	["CurrentTrail"..pn.."ChangedMessageCommand"]=function(self) 	self:stoptweening():sleep(0.2):queuecommand("Set") end,
	SongIsReloadingMessageCommand=function(self)					self:stoptweening():sleep(0.2):queuecommand("Set") end,
	CloseThisFolderHasFocusMessageCommand=function(self) 			self:stoptweening():sleep(0.2):queuecommand("Dissappear") end,
	
	SetCommand=function(self)
		local song = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse()) or GAMESTATE:GetCurrentSong()
		if GAMESTATE:IsHumanPlayer(player) then
			if song then
				self:playcommand( "Appear" .. pn)
			else
				self:playcommand("Dissappear")
			end
		end
		if song then
			
			steps = (GAMESTATE:IsCourseMode() and song:GetAllTrails()) or SongUtil.GetPlayableSteps( song )
			
			if steps then
				StepsToDisplay = GetStepsToDisplay(steps)
				self:playcommand("StepsHaveChanged", {Steps=StepsToDisplay, Player=player})
			end
		end
		Initialize = true
	end,


	PlayerJoinedMessageCommand=function(self, params)
		if params.Player == player then
			self:playcommand( "Appear" .. pn)
		end
	end,
	PlayerUnjoinedMessageCommand=function(self, params)
		if params.Player == player then
			self:visible(false)
		end
	end,

	["Appear" .. pn .. "Command"]=function(self) self:visible(true) end,
	DissappearCommand=function(self) self:visible(false) end,

	StepsHaveChangedCommand=function(self, params)

		if params and params.Player == player then
			-- if we have params, but no steps
			-- it means we're on hovering on a group
			if not params.Steps then
				-- so, since we're on a group, no charts should be specifically available
				-- making any row on the grid temporarily able-to-be-moved-to
				RowIndex = RowIndex + params.Direction

			else
				-- otherwise, we have been passed steps
				for index,chart in pairs(params.Steps) do
					if GAMESTATE:IsCourseMode() then
						if chart == GAMESTATE:GetCurrentTrail(player) then
							RowIndex = index
							break
						end
					else
						if chart == GAMESTATE:GetCurrentSteps(player) then
							RowIndex = index
							break
						end
					end
				end
			end

			-- keep within reasonable limits
			if RowIndex > 5 then RowIndex = 5
			elseif RowIndex < 1 then RowIndex = 1
			end

			-- update cursor x position
			local sdl = self:GetParent():GetParent():GetChild("StepsDisplayList")
			if sdl then
				self:x(pn == "P1" and (RowIndex * 56) - 25.5 or (_screen.w/3 * 2) - 25.5 + (RowIndex * 56))
			end
		end
	end
}
