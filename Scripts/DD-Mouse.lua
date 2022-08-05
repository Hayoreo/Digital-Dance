--- Is the mouse hovering over a quad/specific area?
--- We require the following information:
--  	- X position of quad
-- 		- Y Position of quad
-- 		- quad width
-- 		- quad height
-- 		- the quad's horizontal alignment (left, right, center)
-- 		- the quad's vertical alignment (top, bottom, middle)
IsMouseGucci = function(QuadX, QuadY, QuadWidth, QuadHeight, Horizontal, Vertical)
	local MouseX = INPUTFILTER:GetMouseX()
	local MouseY = INPUTFILTER:GetMouseY()
	local XMax = SCREEN_WIDTH
	local YMax = SCREEN_HEIGHT
	local IsXGucci = false
	local IsYGucci = false
	
	-- If the mouse is not in the SM window then don't check anything else.
	if (MouseX < 0 or MouseX > XMax) or (MouseY < 0 or MouseY > YMax) then return false end
	
	QuadX = QuadX
	QuadY = QuadY
	QuadWidth = QuadWidth
	QuadHeight = QuadHeight
	Horizontal = Horizontal or "center"
	Vertical = Vertical or "middle"
	
	-- Is the X Position gucci?
	if Horizontal == "center" then
		if MouseX >= (QuadX - (QuadWidth/2)) and MouseX <= (QuadX + (QuadWidth/2)) then
			IsXGucci = true
		else
			return false
		end
	elseif Horizontal == "left" then
		if MouseX >= QuadX and MouseX <= (QuadX + QuadWidth) then
			IsXGucci = true
		else
			return false
		end
	elseif Horizontal == "right" then
		if MouseX >= (QuadX - QuadWidth) and MouseX <= QuadX then
			IsXGucci = true
		else
			return false
		end
	end
	
	-- How about Y?
	if Vertical == "middle" then
		if MouseY <= QuadY + (QuadHeight/2) and MouseY >= QuadY - (QuadHeight/2) then
			IsYGucci = true
		else
			return false
		end
	elseif Vertical == "top" then
		if MouseY >= QuadY and MouseY <= QuadY + QuadHeight then
			IsYGucci = true
		else
			return false
		end
	elseif Vertical == "bottom" then
		if MouseY <= QuadY and MouseY >= QuadY - QuadHeight then
			IsYGucci = true
		end
	end
	
	if IsXGucci and IsYGucci then
		return true
	else
		return false
	end
end