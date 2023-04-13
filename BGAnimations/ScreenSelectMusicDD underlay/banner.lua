local SongOrCourse
local CurrentGroup
local BannerWidth = SCREEN_WIDTH/3
local BannerRatio = 418/164
local BannerHeight = BannerWidth/BannerRatio

local t = Def.ActorFrame{
	OnCommand=function(self)
		if IsUsingWideScreen() then
			if GAMESTATE:IsCourseMode() then
				self:zoom(0.7655)
				self:xy(164 - 5, WideScale(62,62.75))
			else
				self:xy(_screen.cx, 0)
			end
		else
			self:zoom(0.75)
			self:xy(_screen.cx - 166, 61)
		end
	end,
	
	-- Just keep the fallback banner loaded in.
	Def.ActorFrame{
		LoadActor("default banner")..{
			Name="FallbackBanner",
			OnCommand=cmd(setsize,BannerWidth,BannerHeight;vertalign,top)
		},
	},
	
	-- Song/Course Banner
	Def.Sprite{
		Name="LoadFromSong",
		InitCommand=function(self) self:playcommand("UpdateSongBanner") end,
		CurrentSongChangedMessageCommand=function(self) 	self:stoptweening():sleep(0.2):queuecommand("UpdateSongBanner") end,
		CurrentCourseChangedMessageCommand=function(self) 	self:stoptweening():sleep(0.2):queuecommand("UpdateSongBanner") end,
		SwitchFocusToSongsMessageCommand=function(self) 	self:stoptweening():sleep(0.2):queuecommand("UpdateSongBanner") end,
		SongIsReloadingMessageCommand=function(self)		self:stoptweening():sleep(0.2):queuecommand("UpdateSongBanner") end,
		SwitchFocusToGroupsMessageCommand=function(self) self:visible(false) end,
		CloseThisFolderHasFocusMessageCommand=function(self) self:stoptweening():sleep(0.25):queuecommand("UpdateVisibility") end,
		UpdateVisibilityCommand=function(self)
			self:visible(false)
		end,
		UpdateSongBannerCommand=function(self)
			SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
			CurrentGroup = NameOfGroup
			if SongOrCourse and SongOrCourse:HasBanner() then
				self:LoadFromSongBanner(SongOrCourse)
				self:zoomto(BannerWidth,BannerHeight):vertalign(top)
				self:visible(true)
			else
				self:visible(false)
			end
		end,
	},
	
	-- Group Banner
	Def.Banner{
		Name="LoadFromGroup",
		InitCommand=function(self) 
			if GetMainCourseSortPreference() ~= 1 then
				self:visible(false)
			else
				self:LoadFromSongGroup(CurrentGroup)
				self:zoomto(BannerWidth,BannerHeight):vertalign(top)
				self:visible(false)
			end
		end,
		CurrentSongChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):queuecommand("UpdateVisibility") end,
		CurrentCourseChangedMessageCommand=function(self) self:visible(false) end,
		SwitchFocusToGroupsMessageCommand=function(self) CurrentGroup = NameOfGroup self:playcommand("UpdateGroupBanner") end,
		GroupsHaveChangedMessageCommand=function(self) CurrentGroup = NameOfGroup self:stoptweening():sleep(0.2):queuecommand("UpdateGroupBanner") end,
		CloseThisFolderHasFocusMessageCommand=function(self) self:stoptweening():sleep(0.2):queuecommand("UpdateGroupBanner") end,
		UpdateVisibilityCommand=function(self)
			self:visible(false)
		end,
		UpdateGroupBannerCommand=function(self)
			if GetMainCourseSortPreference() ~= 1 then
				self:visible(false)
			else
				self:LoadFromSongGroup(CurrentGroup)
				self:zoomto(BannerWidth,BannerHeight)
				self:visible(true)
			end
		end,
	},
	
	-- the MusicRate Quad and text
	Def.ActorFrame{
		InitCommand=function(self)
			self:visible( SL.Global.ActiveModifiers.MusicRate ~= 1 ):y(BannerHeight)
		end,

		--quad behind the music rate text
		Def.Quad{
			InitCommand=function(self) self:diffuse( color("#1E282FCC") ):zoomto(BannerWidth,14):vertalign(bottom) end
		},

		--the music rate text
		LoadFont("Miso/_miso")..{
			InitCommand=function(self) self:shadowlength(1):zoom(0.7):vertalign(bottom):y(-1) end,
			OnCommand=function(self)
				self:settext(("%g"):format(SL.Global.ActiveModifiers.MusicRate) .. "x " .. THEME:GetString("OptionTitles", "MusicRate"))
			end
		}
	},
	
	--- Add text on top of the fallback banner when Main Sort isn't set to Groups.
	Def.ActorFrame{
		InitCommand=function(self) self:visible(false) end,
		CloseThisFolderHasFocusMessageCommand=function(self) self:stoptweening():sleep(0.2):queuecommand("Set"):queuecommand("UpdateVisibility") end,
		CurrentSongChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):visible(false) end,
		CurrentCourseChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):visible(false) end,
		SwitchFocusToGroupsMessageCommand=function(self) self:stoptweening():sleep(0.2):visible(GetMainSortPreference() ~= 1):queuecommand("Set") end,
		GroupsHaveChangedMessageCommand=function(self) self:stoptweening():sleep(0.2):visible(GetMainSortPreference() ~= 1):queuecommand("Set") end,
		UpdateVisibilityCommand=function(self) self:visible(GetMainSortPreference() ~= 1) end,
		
		--- diffuse black bg to make more legible
		Def.Quad{
			InitCommand=function(self) 
				self:diffuse( color("#000000") )
				self:zoomto(BannerWidth,80)
				self:diffusealpha(0.5)
				self:y(BannerHeight/2)
			end,
		},
		
		--- group "name" text
		LoadFont("Wendy/_wendy white")..{
			OnCommand=function(self)
				self:shadowlength(2):zoom(1):y(BannerHeight/2):maxwidth(BannerWidth)
				self:playcommand("Set")
			end,
			SetCommand=function(self)
				self:stoptweening()
				self:settext(NameOfGroup)
				if GetMainSortPreference() == 4 then
					self:zoom(0.6):maxwidth(BannerWidth/0.6)
				elseif GetMainSortPreference() == 5 then
					self:zoom(0.9):maxwidth(BannerWidth/0.9)
				end
				if NameOfGroup == "#" then
					self:settext("NUMBER")
				end
			end,
		}
	}
}

return t