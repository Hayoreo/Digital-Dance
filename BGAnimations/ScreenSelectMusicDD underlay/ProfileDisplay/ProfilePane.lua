local player = ...
local pn = ToEnumShortString(player)

local border = 5
local padding = 20
local width = (_screen.w/3) - border - padding
local height = 122

-- player avatar
local avatar_path = GetPlayerAvatarPath(player)
-- load default if not present
local default_avatar = THEME:GetPathG("","/Default Avatar.png")
-- profile name
local player_name = PROFILEMAN:GetPlayerName(pn)

local GuestP1 = false
local GuestP2 = false

if player_name == "" and pn == "P1" then
	GuestP1 = true
elseif player_name == "" and pn == "P2" then
	GuestP2 = true
end

local af = Def.ActorFrame{
	InitCommand=function(self) self:visible(GAMESTATE:IsPlayerEnabled(pn)) end,
}

-- Outline
af[#af+1] = Def.Quad{
	Name="ProfileOutline"..pn,
	InitCommand=function(self)
		local color = PlayerColor(player)
		color[4] = 1
		color[1] = 0.8 * color[1] + 0.2
		color[2] = 0.8 * color[2] + 0.2
		color[3] = 0.8 * color[3] + 0.2
		self:diffuse(color):zoomto(width+border, height + border):vertalign(top):horizalign(left)
			:x(pn == "P1" and padding/2 or _screen.w - (_screen.w/3) + padding/2)
			:y(padding/2)
	end,

}

-- Main Profile Pane
af[#af+1] = Def.Quad{
	Name="ProfilePane"..pn,
	InitCommand=function(self)
		self:diffuse(color("#1e282f")):zoomto(width, height):vertalign(top):horizalign(left)
			:x(pn == "P1" and padding/2 + border/2 or _screen.w - (_screen.w/3 - padding/2 - border/2))
			:y(padding/2 + border/2)
	end,

}

-- Horizontal pane separator
af[#af+1] = Def.Quad{
	Name="HPaneSeparator"..pn,
	InitCommand=function(self)
		local color = PlayerColor(player)
		color[4] = 1
		color[1] = 0.8 * color[1] + 0.2
		color[2] = 0.8 * color[2] + 0.2
		color[3] = 0.8 * color[3] + 0.2
		self:diffuse(color):zoomto(width-100, border/2):vertalign(top):horizalign(right)
			:x(pn == "P1" and padding/2 + border/2 + width or _screen.w - (_screen.w/3 - padding/2 - border/2 - width))
			:y(padding/2 + border/2 + 55)
			-- don't show this if the player doesn't have a profile
			if pn == "P1" and GuestP1 then
				self:visible(false)
			elseif pn == "P2" and GuestP2 then
				self:visible(false)
			end
	end,

}

-- Horizontal pane separator 2
af[#af+1] = Def.Quad{
	Name="H2PaneSeparator"..pn,
	InitCommand=function(self)
		local color = PlayerColor(player)
		color[4] = 1
		color[1] = 0.8 * color[1] + 0.2
		color[2] = 0.8 * color[2] + 0.2
		color[3] = 0.8 * color[3] + 0.2
		self:diffuse(color):zoomto(100, border/2):vertalign(bottom):horizalign(left)
			:x(pn == "P1" and padding/2 + border/2 or _screen.w - (_screen.w/3 - padding/2 - border/2))
			:y(padding/2 + border/2 + (height-100))
	end,

}

-- Vertical pane separator
af[#af+1] = Def.Quad{
	Name="VPaneSeparator"..pn,
	InitCommand=function(self)
		local color = PlayerColor(player)
		color[4] = 1
		color[1] = 0.8 * color[1] + 0.2
		color[2] = 0.8 * color[2] + 0.2
		color[3] = 0.8 * color[3] + 0.2
		self:diffuse(color):zoomto(border/2, height):vertalign(top):horizalign(left)
			:x(pn == "P1" and padding/2 + border/2 + 100 or _screen.w - (_screen.w/3 - padding/2 - border/2 - 100))
			:y(padding/2 + border/2)
	end,

}

-- Avatar outline
af[#af+1] = Def.Quad{
	Name="AvatarOutline"..pn,
	InitCommand=function(self)
		self:diffuse(color("#000000")):zoomto(100, 100):vertalign(bottom):horizalign(left)
			:x(pn == "P1" and padding/2 + border/2 or _screen.w - (_screen.w/3 - padding/2 - border/2))
			:y(padding/2 + border/2 + height)
	end,

}

-- player avatar
af[#af+1] = Def.Sprite{
	Texture=avatar_path or default_avatar,
	Name="PlayerAvatar"..pn,
	InitCommand=function(self)
		self:horizalign(left):vertalign(bottom)
			:zoomto(96,96)
			:x(pn == "P1" and padding/2 + border/2 + 2 or _screen.w - padding/2 - border/2 - width + 2)
			:y(padding/2 + border/2 + height - 2)
	end,
}

-- player name
af[#af+1] = Def.BitmapText{
	Font="Miso/_miso",
	Name="PlayerName"..pn,
	InitCommand=function(self)
		local zoom = 0.8
		self:horizalign(center):vertalign(bottom):shadowlength(1)
			:x(pn == "P1" and padding/2 + border/2 + 100/2 or _screen.w - padding/2 - border/2 - width + 100/2)
			:y(padding/2 + border/2 + 15)
			:maxwidth(94/zoom)
			:zoom(zoom)
			if pn == "P1" and GuestP1 then
				self:settext("Player 1")
			elseif pn == "P2" and GuestP2 then
				self:settext("Player 2")
			else
				self:settext(player_name)
			end
	end,
}

return af