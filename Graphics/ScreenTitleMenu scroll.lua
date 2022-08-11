local index = Var("GameCommand"):GetIndex()
local VirtualIndex = 1
local MaxIndex = 4
local Scroller

local InputHandler = function(event)

	-- if (somehow) there's no event, bail
	if not event then return end

	if event.type == "InputEventType_FirstPress" and  event.type ~= "InputEventType_Release" then
		
		if event.DeviceInput.button == "DeviceButton_mousewheel up" or event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
			if VirtualIndex == 1 then
				VirtualIndex = MaxIndex
			else
				VirtualIndex = VirtualIndex - 1
			end
			MESSAGEMAN:Broadcast("UpdateScroll")
			-- the engine will already play this with the menu buttons, so we only need to do it for the mouse.
			if event.DeviceInput.button == "DeviceButton_mousewheel up" then
				SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg"), true )
			end
		end
		
		if event.DeviceInput.button == "DeviceButton_mousewheel down" or event.GameButton == "MenuRight" or event.GameButton == "MenuDown" then
			if VirtualIndex == MaxIndex then
				VirtualIndex = 1
			else
				VirtualIndex = VirtualIndex + 1
			end
			MESSAGEMAN:Broadcast("UpdateScroll")
			-- the engine will already play this with the menu buttons, so we only need to do it for the mouse.
			if event.DeviceInput.button == "DeviceButton_mousewheel down" then
				SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "change.ogg"), true )
			end
		end
		
		
		-- Advance to the next screen on enter.
		if event.GameButton == "Start" then
			if VirtualIndex == 1 then
				SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg"), true )
				SCREENMAN:SetNewScreen("ScreenSelectProfile")
			elseif VirtualIndex == 2 then
				SCREENMAN:SetNewScreen("ScreenEditMenu")
			elseif VirtualIndex == 3 then
				SCREENMAN:SetNewScreen("ScreenOptionsService")
			elseif VirtualIndex == 4 then
				SCREENMAN:SetNewScreen("ScreenExit")
			end
		end
		
		-- or a left click
		if event.DeviceInput.button == "DeviceButton_left mouse button" and event.type ~= "InputEventType_Release" and event.type == "InputEventType_FirstPress"then
			-- check which choice is selected to determine the zoom.
			if IsMouseGucci(_screen.cx-2,_screen.cy-81, 670, 105, "center", "middle", VirtualIndex ==1 and 0.4 or 0.3) then
				SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg"), true )
				SCREENMAN:SetNewScreen("ScreenSelectProfile")
			elseif IsMouseGucci(_screen.cx-3,_screen.cy-21, 688, 105, "center", "middle", VirtualIndex ==2 and 0.4 or 0.3) then
				SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg"), true )
				SCREENMAN:SetNewScreen("ScreenEditMenu")
			elseif IsMouseGucci(_screen.cx-3,_screen.cy+37, 515, 106, "center", "middle", VirtualIndex ==3 and 0.4 or 0.3) then
				SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg"), true )
				SCREENMAN:SetNewScreen("ScreenOptionsService")
			elseif IsMouseGucci(_screen.cx-2,_screen.cy+97, 282, 106, "center", "middle", VirtualIndex ==4 and 0.4 or 0.3) then
				SOUND:PlayOnce( THEME:GetPathS("Common", "start.ogg"), true )
				SCREENMAN:SetNewScreen("ScreenExit")
			end
		end
		
	end

end

local t = Def.ActorFrame{
	OnCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		screen:AddInputCallback(InputHandler)
		Scroller = screen:GetChild("Scroller")
	end,
	
	UpdateScrollMessageCommand=function(self)
		Scroller:playcommand("LoseFocus")
		Scroller:SetDestinationItem(VirtualIndex)
		Scroller:GetChild("ScrollChoice"..VirtualIndex):playcommand("GainFocus")
	end,
}


t[#t+1] = LoadFont("_edit undo brk")..{
	Name="Choice"..index,
	Text=THEME:GetString( 'ScreenTitleMenu', Var("GameCommand"):GetText() ),

	OnCommand=cmd(diffusealpha,0; sleep,index * 0.075; linear,0.2; diffusealpha,1),
	OffCommand=cmd(sleep,index * 0.075; linear,0.18; diffusealpha, 0),

	GainFocusCommand=cmd(stoptweening; zoom,0.4; x,1; y,1; accelerate,0.1; diffuse, color("#000000"); glow,{1,1,1,0.5}; decelerate,0.05; glow,{1,1,1,0.0}; shadowlength,0.5),
	LoseFocusCommand=cmd(stoptweening; zoom,0.3; x,1; y,1; accelerate,0.1; diffuse, color("#000000"); glow,{1,1,1,0}; shadowlength,0)
}

t[#t+1] = LoadFont("_edit undo brk")..{
	Name="Choice"..index,
	Text=THEME:GetString( 'ScreenTitleMenu', Var("GameCommand"):GetText() ),

	OnCommand=cmd(diffusealpha,0; sleep,index * 0.075; linear,0.2; diffusealpha,1),
	OffCommand=cmd(sleep,index * 0.075; linear,0.18; diffusealpha, 0),

	GainFocusCommand=cmd(stoptweening; zoom,0.4; x,-1; y,1; accelerate,0.1; diffuse, color("#000000"); glow,{1,1,1,0.5}; decelerate,0.05; glow,{1,1,1,0.0}; shadowlength,0.5),
	LoseFocusCommand=cmd(stoptweening; zoom,0.3; x,-1; y,1; accelerate,0.1; diffuse, color("#000000"); glow,{1,1,1,0}; shadowlength,0)
}

t[#t+1] = LoadFont("_edit undo brk")..{
	Name="Choice"..index,
	Text=THEME:GetString( 'ScreenTitleMenu', Var("GameCommand"):GetText() ),

	OnCommand=cmd(diffusealpha,0; sleep,index * 0.075; linear,0.2; diffusealpha,1),
	OffCommand=cmd(sleep,index * 0.075; linear,0.18; diffusealpha, 0),

	GainFocusCommand=cmd(stoptweening; zoom,0.4; x,1; y,-1; accelerate,0.1; diffuse, color("#000000"); glow,{1,1,1,0.5}; decelerate,0.05; glow,{1,1,1,0.0}; shadowlength,0.5),
	LoseFocusCommand=cmd(stoptweening; zoom,0.3; x,1; y,-1; accelerate,0.1; diffuse, color("#000000"); glow,{1,1,1,0}; shadowlength,0)
}

t[#t+1] = LoadFont("_edit undo brk")..{
	Name="Choice"..index,
	Text=THEME:GetString( 'ScreenTitleMenu', Var("GameCommand"):GetText() ),

	OnCommand=cmd(diffusealpha,0; sleep,index * 0.075; linear,0.2; diffusealpha,1),
	OffCommand=cmd(sleep,index * 0.075; linear,0.18; diffusealpha, 0),

	GainFocusCommand=cmd(stoptweening; zoom,0.4; x,-1; y,-1; accelerate,0.1; diffuse, color("#000000"); glow,{1,1,1,0.5}; decelerate,0.05; glow,{1,1,1,0.0}; shadowlength,0.5),
	LoseFocusCommand=cmd(stoptweening; zoom,0.3; x,-1; y,-1; accelerate,0.1; diffuse, color("#000000"); glow,{1,1,1,0}; shadowlength,0)
}

t[#t+1] = LoadFont("_edit undo brk")..{
	Name="Choice"..index,
	Text=THEME:GetString( 'ScreenTitleMenu', Var("GameCommand"):GetText() ),

	OnCommand=cmd(diffusealpha,0; sleep,index * 0.075; linear,0.2; diffusealpha,1),
	OffCommand=cmd(sleep,index * 0.075; linear,0.18; diffusealpha, 0),

	GainFocusCommand=cmd(stoptweening; zoom,0.4; accelerate,0.1; diffuse, color("#ff51b9"); glow,{1,1,1,0.5}; decelerate,0.05; glow,{1,1,1,0.0}; shadowlength,0.5),
	LoseFocusCommand=cmd(stoptweening; zoom,0.3; accelerate,0.1; diffuse, color("#afafaf"); glow,{1,1,1,0}; shadowlength,0)
}

return t