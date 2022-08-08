local MouseX
local MouseY
local XMax = SCREEN_WIDTH
local YMax = SCREEN_HEIGHT
local RefreshRate = PREFSMAN:GetPreference("RefreshRate")
local Refresh = 1/RefreshRate
local HideMouseCounter = 0

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
			local PastMouseX = MouseX
			local PastMouseY = MouseY
			MouseX = INPUTFILTER:GetMouseX()
			MouseY = INPUTFILTER:GetMouseY()
			
			-- Check if the mouse has moved on this update, if it hasn't increase the counter.
			if PastMouseX == MouseX and PastMouseY == MouseY then
				HideMouseCounter = HideMouseCounter + 1
			else
				HideMouseCounter = 0
			end
			
			-- If the mouse is out of bounds hide it. If the mouse has been stationary for more than 5 seconds also hide it.
			if (MouseX < 0 or MouseX > XMax) or (MouseY < 0 or MouseY > YMax) then
				self:visible(false)
			elseif HideMouseCounter > RefreshRate * 5 then
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