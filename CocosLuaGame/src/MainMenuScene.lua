-- create class MainScene
local MainMenuScene = class("MainMenuScene",function()
    return cc.Scene:create()
end)

-- return instance of MainScene, conformed with C++ form
function MainMenuScene.create()
    local scene = MainMenuScene.new()
    local MainMenuLayer = require("MainMenuLayer")
    local layer = MainMenuLayer.create()
    scene:addChild(layer)
    return scene
end

-- overwrite the ctor() in new(), used to create fields
function MainMenuScene:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
end

return MainMenuScene
