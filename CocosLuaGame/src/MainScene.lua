-- create class MainScene
local MainScene = class("MainScene",function()
--    return cc.Scene:create()
    return cc.Scene:createWithPhysics()
end)

-- return instance of MainScene, conformed with C++ form
function MainScene.create()
    local scene = MainScene.new()
    local AnimationLayer = require("AnimationLayer")
    local layer = AnimationLayer.create()
    scene:addChild(layer)
    
    local UILayer = require("MainUILayer")
    scene:addChild(UILayer.create())
    return scene
end

-- overwrite the ctor() in new(), used to create fields
function MainScene:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
end

return MainScene


