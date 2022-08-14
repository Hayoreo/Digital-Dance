local MouseX
local MouseY
local XMax = SCREEN_WIDTH
local YMax = SCREEN_HEIGHT
local RefreshRate = PREFSMAN:GetPreference("RefreshRate")
local Refresh = 1/RefreshRate
local MaxMouseCounter = RefreshRate * 3
local HideMouseCounter = MaxMouseCounter

local af = Def.ActorFrame{
	Def.Sprite{
		Texture="./MouseCursor.png",
		Name="MouseCursor",
		InitCommand=function(self)
			MouseX = INPUTFILTER:GetMouseX()
			MouseY = INPUTFILTER:GetMouseY()
			self:visible(false)
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
			if PastMouseX == MouseX and PastMouseY == MouseY and HideMouseCounter < MaxMouseCounter then
				HideMouseCounter = HideMouseCounter + 1
			elseif HideMouseCounter == MaxMouseCounter and PastMouseX == MouseX and PastMouseY == MouseY then
				-- don't increment if we're already maxed i don't want to deal with potential overflow lol
			else
				HideMouseCounter = 0
			end
			
			-- If the mouse is out of bounds hide it. If the mouse has been stationary for more than 3 seconds also hide it.
			if (MouseX < 0 or MouseX > XMax) or (MouseY < 0 or MouseY > YMax) then
				self:visible(false)
			elseif HideMouseCounter >= MaxMouseCounter then
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