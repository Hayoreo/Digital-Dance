local MouseX
local MouseY
local XMax = SCREEN_WIDTH
local YMax = SCREEN_HEIGHT
local Refresh = 1/PREFSMAN:GetPreference("RefreshRate")

local af = Def.ActorFrame{
	Def.Sprite{
		Texture="./MouseCursor.png",
		Name="MouseCursor",
		InitCommand=function(self)
			MouseX = INPUTFILTER:GetMouseX()
			MouseY = INPUTFILTER:GetMouseY()
			if (MouseX < 0 or MouseX > XMax) or (MouseY < 0 or MouseY > YMax) then
				self:visible(false)
			else
				self:visible(true)
			end
			self:vertalign(top)
			self:horizalign(left)
			self:xy(MouseX,MouseY)
			self:zoom(0.06)
			self:playcommand("UpdateMouse")
		end,
		UpdateMouseCommand=function(self)
			self:stoptweening()
			MouseX = INPUTFILTER:GetMouseX()
			MouseY = INPUTFILTER:GetMouseY()
			if (MouseX < 0 or MouseX > XMax) or (MouseY < 0 or MouseY > YMax) then
				self:visible(false)
			else
				self:visible(true)
			end
			self:xy(MouseX,MouseY)
			self:sleep(Refresh):queuecommand("UpdateMouse")
		end,
		HideMouseMessageCommand=function(self)
			self:stoptweening()
			self:visible(false)
		end,
		ShowMouseMessageCommand=function(self)
			self:stoptweening()
			self:visible(true)
			self:playcommand("UpdateMouse")
		end,
	}
}
return af