local t = {}

local function getScreenNameWriteActor(screenName)
    return Def.Actor {
        ModuleCommand = function(self)
            local f = RageFileUtil.CreateRageFile()
            if f:Open("Save/CurrentScreen.txt", 2) then
                f:Write(screenName)
            else
                -- do nothing
            end
            f:destroy()
        end
    }
end

t["ScreenTitleMenu"] = getScreenNameWriteActor("ScreenTitleMenu")
t["ScreenSelectMusic"] = getScreenNameWriteActor("ScreenSelectMusic")
t["ScreenGameplay"] = getScreenNameWriteActor("ScreenGameplay");
t["ScreenEvaluationStage"] = getScreenNameWriteActor("ScreenEvaluationStage")
t["ScreenEvaluationSummary"] = getScreenNameWriteActor("ScreenEvaluationSummary")

return t