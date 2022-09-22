local MaxIndex = 4
local boxwidth = 260
local boxheight = 20
local YPosition = SCREEN_CENTER_Y - 30
local searchbox = 54

local holdingShift = 0
local EnterSearch = false

SearchCursorIndex = 1
SongSearchAnswer = ''
ArtistSearchAnswer = ''
ChartSearchAnswer = ''
MaxSearchLength = 32

local lowercaseSpecialCharacters = {
	period='.',
	space=' ',
	backslash='\\',
	comma=',',
	['KP 0']='0',
	['KP 1']='1',
	['KP 2']='2',
	['KP 3']='3',
	['KP 4']='4',
	['KP 5']='5',
	['KP 6']='6',
	['KP 7']='7',
	['KP 8']='8',
	['KP 9']='9',
	['KP /']='/',
	['KP *']='*',
	['KP -']='-',
	['KP +']='+',
	['KP .']='.',
	
}

local uppercaseSpecialCharacters = {
	period='>',
	space=' ',
	backslash='|',
	comma='<',
	['1']='!',
	['2']='@',
	['3']='#',
	['4']='$',
	['5']='%',
	['6']='^',
	['7']='&',
	['8']='*',
	['9']='(',
	['0']=')',
	['-']='_',
	['=']='+',
	['`']='~',
	['/']='?',
	['[']='{',
	[']']='}',
	[';']=':',
	["'"]='"',
	
}

local getLetterForButton = function(button)
	local buttonStr = tostring(button):sub(14)

	local characterTable
	if holdingShift > 0 then
		characterTable = uppercaseSpecialCharacters
	else
		characterTable = lowercaseSpecialCharacters
	end

	local letter = characterTable[buttonStr]
	if letter ~= nil then
		return letter
	end

	if buttonStr:len() == 1 then
		if holdingShift > 0 then
			return buttonStr:upper()
		else
			return buttonStr
		end
	end

	return nil
end

local updateAllText = function()
	MESSAGEMAN:Broadcast("UpdateSongSearchText")
	MESSAGEMAN:Broadcast("UpdateArtistSearchText")
	MESSAGEMAN:Broadcast("UpdateChartSearchText")
end

local InputHandler = function( event )
	if not event or EnterSearch then return end
	
	if IsSearchMenuVisible then
		if event.type == "InputEventType_FirstPress" then
			if event.DeviceInput.button == "DeviceButton_left shift" or event.DeviceInput.button == "DeviceButton_right shift" then
				holdingShift = holdingShift + 1
			end
			
			-- move cursor up/down
			if event.DeviceInput.button == "DeviceButton_pgup" or event.DeviceInput.button == "DeviceButton_up" or event.DeviceInput.button == "DeviceButton_left" or event.DeviceInput.button == "DeviceButton_mousewheel up" then
				MESSAGEMAN:Broadcast("MoveSearchCursorUp")
				updateAllText()
			elseif event.DeviceInput.button == "DeviceButton_pgdn" or event.DeviceInput.button == "DeviceButton_down" or event.DeviceInput.button == "DeviceButton_right" or event.DeviceInput.button == "DeviceButton_mousewheel down" then
				MESSAGEMAN:Broadcast("MoveSearchCursorDown")
				updateAllText()
			elseif event.DeviceInput.button == "DeviceButton_tab" then
				MESSAGEMAN:Broadcast("MoveSearchCursorDown")
				updateAllText()
			end
			
			-- jump cursor to target based on mouse location.
			if ThemePrefs.Get("MouseInput") then
				if event.DeviceInput.button == "DeviceButton_left mouse button" then
					for i=1, 3 do
						if IsMouseGucci(SCREEN_CENTER_X + 180,(YPosition-30) + 30*i ,boxwidth, boxheight, "right") then
							if i ~= SearchCursorIndex then
								MESSAGEMAN:Broadcast("MoveSearchCursorMouse",{TargetPosition = i})
								updateAllText()
							end
						end
					end
					if IsMouseGucci(SCREEN_CENTER_X,YPosition + 90,searchbox, boxheight, "center") then
						if i ~= SearchCursorIndex then
							if SongSearchAnswer ~= "" or ArtistSearchAnswer ~= "" or ChartSearchAnswer ~= "" then
								EnterSearch = true
								SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
							else
								SOUND:PlayOnce( THEME:GetPathS("ScreenPlayerOptions", "cancel all.ogg") )
							end
							MESSAGEMAN:Broadcast("SongSearchSSMDD")
						end
					end
				end
			end
			
			if event.DeviceInput.button == "DeviceButton_enter" then
				if SongSearchAnswer ~= "" or ArtistSearchAnswer ~= "" or ChartSearchAnswer ~= "" then
					SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg") )
					EnterSearch = true
				else
					SOUND:PlayOnce( THEME:GetPathS("ScreenPlayerOptions", "cancel all.ogg") )
				end
				MESSAGEMAN:Broadcast("SongSearchSSMDD")
			end	
		end
		
		-- Handle keyboard input for text entry
		if event.type == "InputEventType_FirstPress" or event.type == "InputEventType_Repeat" then
			if event.DeviceInput.device == "InputDevice_Key" then
				if SearchCursorIndex == 1 then
					if event.DeviceInput.button == 'DeviceButton_backspace' and SongSearchAnswer:len() > 0 then
						SOUND:PlayOnce( THEME:GetPathS("ScreenTextEntry", "backspace.ogg") )
						SongSearchAnswer = SongSearchAnswer:sub(1, SongSearchAnswer:len()-1)
						MESSAGEMAN:Broadcast("UpdateSongSearchText")
						MESSAGEMAN:Broadcast("UpdateSearchButton")
					elseif SongSearchAnswer:len() < MaxSearchLength then
						local letter = getLetterForButton(event.DeviceInput.button)
						if letter ~= nil then
							SOUND:PlayOnce( THEME:GetPathS("ScreenTextEntry", "type.ogg") )
							SongSearchAnswer = SongSearchAnswer .. letter
							MESSAGEMAN:Broadcast("UpdateSongSearchText")
							MESSAGEMAN:Broadcast("UpdateSearchButton")
						end
					end
				elseif SearchCursorIndex == 2 then
					if event.DeviceInput.button == 'DeviceButton_backspace' and ArtistSearchAnswer:len() > 0 then
						SOUND:PlayOnce( THEME:GetPathS("ScreenTextEntry", "backspace.ogg") )
						ArtistSearchAnswer = ArtistSearchAnswer:sub(1, ArtistSearchAnswer:len()-1)
						MESSAGEMAN:Broadcast("UpdateArtistSearchText")
						MESSAGEMAN:Broadcast("UpdateSearchButton")
					elseif ArtistSearchAnswer:len() < MaxSearchLength then
						local letter = getLetterForButton(event.DeviceInput.button)
						if letter ~= nil then
							SOUND:PlayOnce( THEME:GetPathS("ScreenTextEntry", "type.ogg") )
							ArtistSearchAnswer = ArtistSearchAnswer .. letter
							MESSAGEMAN:Broadcast("UpdateArtistSearchText")
							MESSAGEMAN:Broadcast("UpdateSearchButton")
						end
					end
				elseif SearchCursorIndex == 3 then
					if event.DeviceInput.button == 'DeviceButton_backspace' and ChartSearchAnswer:len() > 0 then
						SOUND:PlayOnce( THEME:GetPathS("ScreenTextEntry", "backspace.ogg") )
						ChartSearchAnswer = ChartSearchAnswer:sub(1, ChartSearchAnswer:len()-1)
						MESSAGEMAN:Broadcast("UpdateChartSearchText")
						MESSAGEMAN:Broadcast("UpdateSearchButton")
					elseif ChartSearchAnswer:len() < MaxSearchLength then
						local letter = getLetterForButton(event.DeviceInput.button)
						if letter ~= nil then
							SOUND:PlayOnce( THEME:GetPathS("ScreenTextEntry", "type.ogg") )
							ChartSearchAnswer = ChartSearchAnswer .. letter
							MESSAGEMAN:Broadcast("UpdateChartSearchText")
							MESSAGEMAN:Broadcast("UpdateSearchButton")
						end
					end
				end
			end
		elseif event.type == "InputEventType_Release" then
			if event.DeviceInput.button == "DeviceButton_left shift" or event.DeviceInput.button == "DeviceButton_right shift" then
				holdingShift = holdingShift - 1
			end
		end
	end

end

local t = Def.ActorFrame{
	Name="SearchMenuCursor",
	OnCommand=function(self)
		screen = SCREENMAN:GetTopScreen()
		screen:AddInputCallback(InputHandler)
		if SongSearchSSMDD == true then
			SongSearchSSMDD = false
			SongSearchAnswer = ''
			ArtistSearchAnswer = ''
			ChartSearchAnswer = ''
		end	
	end,
	InitCommand=function(self)
	end,
	UpdateSearchInputMessageCommand=function(self)
		EnterSearch = false
	end,
	
	Def.Quad{
		Name="Cursor",
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X + 180,YPosition)
			self:diffuse(color("#FFFFFF"))
			self:zoomx(boxwidth)
			self:zoomy(boxheight)
			self:diffusealpha(0.5)
			self:horizalign(right)
			self:visible(true)
			self:queuecommand("FadeOut")
		end,
		
		InitializeSearchMenuMessageCommand=function(self)
			self:stoptweening()
			self:xy(SCREEN_CENTER_X + 180,YPosition)
			self:diffuse(color("#FFFFFF"))
			self:zoomx(boxwidth)
			self:zoomy(boxheight)
			self:diffusealpha(0.5)
			self:horizalign(right)
			self:visible(true)
			self:queuecommand("FadeOut")
			SearchCursorIndex = 1
			SongSearchAnswer = ''
			ArtistSearchAnswer = ''
			ChartSearchAnswer = ''
		end,
		
		FadeInCommand=function(self)
			self:stoptweening()
			self:linear(0.7):diffusealpha(0.5)
			self:queuecommand("FadeOut")
		end,
		
		FadeOutCommand=function(self)
			self:stoptweening()
			self:linear(0.7):diffusealpha(0.2)
			self:queuecommand("FadeIn")
		end,
		
		-- Wraps the cursor if it gets to the top or bottom and stops it
		-- if selected an option that needs to navigate left/right to select.
			MoveSearchCursorUpMessageCommand=function(self)
				if IsSearchMenuVisible then
					if SearchCursorIndex == 1 then
						SearchCursorIndex = MaxIndex
						self:playcommand("UpdateSearchCursor")
					else
						SearchCursorIndex = SearchCursorIndex - 1
						self:playcommand("UpdateSearchCursor")
					end
				end
				SOUND:PlayOnce( THEME:GetPathS("", "_prev row.ogg") )
			end,
			
			MoveSearchCursorDownMessageCommand=function(self)
				if IsSearchMenuVisible then
					if SearchCursorIndex == MaxIndex then
						SearchCursorIndex = 1
						self:playcommand("UpdateSearchCursor")
					else
						SearchCursorIndex = SearchCursorIndex + 1
						self:playcommand("UpdateSearchCursor")
					end
					SOUND:PlayOnce( THEME:GetPathS("", "_next row.ogg") )
				end
			end,
			MoveSearchCursorMouseMessageCommand=function(self, param)
				if param.TargetPosition > SearchCursorIndex then
					SOUND:PlayOnce( THEME:GetPathS("", "_next row.ogg") )
				elseif param.TargetPosition < SearchCursorIndex then
					SOUND:PlayOnce( THEME:GetPathS("", "_prev row.ogg") )
				end
				SearchCursorIndex = param.TargetPosition
				self:playcommand("UpdateSearchCursor")
			end,
			
			---- This is telling the cursor where to go for each movement.
			UpdateSearchCursorCommand=function(self)
				self:stoptweening()
				self:decelerate(0.2)
				for i=1, 3 do
					if SearchCursorIndex == i then
						self:xy(SCREEN_CENTER_X + 180,(YPosition - 30) + 30*i)
						self:zoomx(boxwidth)
					end
				end
				if SearchCursorIndex == 4 then
					self:xy(SCREEN_CENTER_X + (searchbox/2),YPosition + 90)
					self:zoomx(searchbox)
				end
				self:queuecommand("FadeOut")
			end,
	},
}

return t