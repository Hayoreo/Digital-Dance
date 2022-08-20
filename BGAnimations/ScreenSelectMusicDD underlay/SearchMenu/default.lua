local t = Def.ActorFrame {
	InitCommand=function(self)
	self:draworder(150)
	self:visible(false)
	end,
	
	--- Let's the songwheel input know if it's Open/Closed so it can stop input.
	ToggleSearchMenuMessageCommand=function(self)
		if self:GetVisible() then
			self:stoptweening()
			self:sleep(0.1):visible(false):queuecommand("UpdateVisibility")
		else
			self:stoptweening()
			self:sleep(0.1):visible(true):queuecommand("UpdateVisibility")
		end
	end,
	
	UpdateVisibilityCommand=function(self)
		if IsSearchMenuVisible == true then
			IsSearchMenuVisible = false
		elseif IsSearchMenuVisible == false then
			IsSearchMenuVisible = true
		end
	end,
	
	
	-- The menu skeleton with the text.
	LoadActor("./menu.lua"),
	-- The cursor and the custom text entry handling
	LoadActor("./cursor.lua"),
	-- Handles the player entered text for the search
	LoadActor("./SongSearch.lua"),
}

return t