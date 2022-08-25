local quadwidth = 400
local quadheight = 160
local quadborder = 6
local boxwidth = 260
local boxheight = 20
local YPosition = SCREEN_CENTER_Y - 30
local searchBlink = false

local SearchLabel = {
	THEME:GetString("ScreenSelectMusicDD", "Song"),
	THEME:GetString("ScreenSelectMusicDD", "Artist"),
	THEME:GetString("ScreenSelectMusicDD", "Chart"),
}

local t = Def.ActorFrame{
	OnCommand=function(self)
	end,
	
	--- Dim background for song search ------
	Def.Quad{
		Name="DimBg",
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
			self:zoomx(SCREEN_RIGHT)
			self:zoomy(SCREEN_BOTTOM)
			self:diffuse(color("#000000"))
			self:diffusealpha(0.9)
		end,
	},
	
	--- white border for song search ------
	Def.Quad{
		Name="DimBg",
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
			self:zoomx(quadwidth+quadborder)
			self:zoomy(quadheight+quadborder)
			self:diffuse(color("#FFFFFF"))
			self:diffusealpha(1)
		end,
	},
	
	--- BG quad for song search ------
	Def.Quad{
		Name="DimBg",
		InitCommand=function(self)
			self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y)
			self:zoomx(quadwidth)
			self:zoomy(quadheight)
			self:diffuse(color("#111111"))
			self:diffusealpha(1)
		end,
	},
	
	--------------- Here be the quads for the text on the right side of the search menu ---------------
		----- Song Search box -----
		Def.Quad{
			Name="Box1",
			InitCommand=function(self)
					self:xy(SCREEN_CENTER_X + 180,YPosition)
					self:draworder(0)
					self:diffuse(color("#3b3b3b"))
					self:zoomx(boxwidth)
					self:zoomy(boxheight)
					self:visible(true)
					self:horizalign(right)
			end,
		},
		
		----- Artist Search box -----
		Def.Quad{
			Name="Box2",
			InitCommand=function(self)
					self:xy(SCREEN_CENTER_X + 180,YPosition + 30)
					self:draworder(0)
					self:diffuse(color("#3b3b3b"))
					self:zoomx(boxwidth)
					self:zoomy(boxheight)
					self:visible(true)
					self:horizalign(right)
			end,
		},
		
		----- Chart Search box -----
		Def.Quad{
			Name="Box3",
			InitCommand=function(self)
					self:xy(SCREEN_CENTER_X + 180,YPosition + 60)
					self:draworder(0)
					self:diffuse(color("#3b3b3b"))
					self:zoomx(boxwidth)
					self:zoomy(boxheight)
					self:visible(true)
					self:horizalign(right)
			end,
		},
		-- top text
		Def.BitmapText{
			Font="Miso/_miso",
			InitCommand=function(self)
				self:diffuse(color("#FFFFFF"))
				self:horizalign(center)
				self:x(SCREEN_CENTER_X)
				self:y(YPosition - 30)
				self:zoom(1.25)
				self:settext(THEME:GetString("ScreenSelectMusicDD", "SongSearch"))
			end,
		},
		
		-----Search Button -----
		Def.Quad{
			Name="MenuBackground",
			InitCommand=function(self)
					self:xy(SCREEN_CENTER_X,YPosition + 90)
					self:draworder(0)
					self:diffuse(color("#a10000"))
					self:zoomx(54)
					self:zoomy(20)
					self:visible(true)
			end,
			InitializeSearchMenuMessageCommand=function(self)
				self:diffuse(color("#a10000"))
			end,
			UpdateSearchButtonMessageCommand=function(self)
				if SongSearchAnswer ~= "" or ArtistSearchAnswer ~= "" or ChartSearchAnswer ~= "" then
					self:diffuse(color("#22a33a"))
				else
					self:diffuse(color("#a10000"))
				end
			end,
		},
		
		-- search button text
		Def.BitmapText{
			Font="Miso/_miso",
			InitCommand=function(self)
				self:diffuse(color("#FFFFFF"))
				self:horizalign(center)
				self:x(SCREEN_CENTER_X)
				self:y(YPosition + 90)
				self:zoom(1)
				self:settext("EXIT")
			end,
			InitializeSearchMenuMessageCommand=function(self)
				self:settext(THEME:GetString("ScreenSelectMusicDD", "Exit"))
			end,
			UpdateSearchButtonMessageCommand=function(self)
				if SongSearchAnswer ~= "" or ArtistSearchAnswer ~= "" or ChartSearchAnswer ~= "" then
					self:settext(THEME:GetString("ScreenSelectMusicDD", "Search"))
				else
					self:settext(THEME:GetString("ScreenSelectMusicDD", "Exit"))
				end
			end,
		},

		Def.Actor {
			InitCommand=function(self)
				self:queuecommand('Blink')
			end,
			BlinkCommand=function(self)
				searchBlink = not searchBlink
				if SearchCursorIndex == 1 then
					MESSAGEMAN:Broadcast("UpdateSongSearchText")
				elseif SearchCursorIndex == 2 then
					MESSAGEMAN:Broadcast("UpdateArtistSearchText")
				elseif SearchCursorIndex == 3 then
					MESSAGEMAN:Broadcast("UpdateChartSearchText")
				end
				self:sleep(0.5):queuecommand('Blink')
			end,
		},

		-- song search input text
		Def.BitmapText{
			Font="Miso/_miso",
			InitCommand=function(self)
				self:diffuse(color("#FFFFFF"))
				self:horizalign(center)
				self:xy(SCREEN_CENTER_X-75,YPosition)
				self:maxwidth(250)
				self:horizalign(left)
				self:zoom(1)
				self:settext("")
			end,
			InitializeSearchMenuMessageCommand=function(self)
				self:settext("")
			end,
			UpdateSongSearchTextMessageCommand=function(self)
				if SearchCursorIndex == 1 and searchBlink and SongSearchAnswer:len() ~= MaxSearchLength then
					self:settext(SongSearchAnswer .. '_')
				else
					self:settext(SongSearchAnswer)
				end
			end,
		},
		
		-- artist search input text
		Def.BitmapText{
			Font="Miso/_miso",
			InitCommand=function(self)
				self:diffuse(color("#FFFFFF"))
				self:horizalign(center)
				self:xy(SCREEN_CENTER_X-75,YPosition+30)
				self:maxwidth(250)
				self:horizalign(left)
				self:zoom(1)
				self:settext("")
			end,
			InitializeSearchMenuMessageCommand=function(self)
				self:settext("")
			end,
			UpdateArtistSearchTextMessageCommand=function(self)
				if SearchCursorIndex == 2 and searchBlink and ArtistSearchAnswer:len() ~= MaxSearchLength then
					self:settext(ArtistSearchAnswer .. '_')
				else
					self:settext(ArtistSearchAnswer)
				end
			end,
		},
		
		-- chart search input text
		Def.BitmapText{
			Font="Miso/_miso",
			InitCommand=function(self)
				self:diffuse(color("#FFFFFF"))
				self:horizalign(center)
				self:xy(SCREEN_CENTER_X-75,YPosition+60)
				self:maxwidth(250)
				self:horizalign(left)
				self:zoom(1)
				self:settext("")
			end,
			InitializeSearchMenuMessageCommand=function(self)
				self:settext("")
			end,
			UpdateChartSearchTextMessageCommand=function(self)
				if SearchCursorIndex == 3 and searchBlink and ChartSearchAnswer:len() ~= MaxSearchLength then
					self:settext(ChartSearchAnswer .. '_')
				else
					self:settext(ChartSearchAnswer)
				end
			end,
		},
		
		Def.BitmapText{
			Font="Common Normal",
			InitCommand=function(self)
				self:settext(THEME:GetString("ScreenSelectMusicDD", "SearchMenuHelpText"))
				self:xy(_screen.cx, _screen.h-120):zoom(1.1) 
			end,
		},

	SongSearchSSMDDMessageCommand = function(self)
	end,
	
	ReloadScreenCommand=function(self)
		screen:SetNextScreenName("ScreenReloadSSMDD")
		screen:StartTransitioningScreen("SM_GoToNextScreen")
	end,
}

for i,SearchText in ipairs(SearchLabel) do
	t[#t+1] = Def.BitmapText{
		Font="Miso/_miso",
		InitCommand=function(self)
			self:diffuse(color("#FFFFFF"))
			self:horizalign(right)
			self:x(SCREEN_CENTER_X - 90)
			self:y(YPosition - 32 + 30*i)
			self:zoom(1.25)
			self:settext(SearchText)
		end,
	}
end

return t