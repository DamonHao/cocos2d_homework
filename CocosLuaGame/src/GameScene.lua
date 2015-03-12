-- create class MainScene
local GameScene = class("GameScene",function()
--    return cc.Scene:create()
    return cc.Scene:createWithPhysics()
end)

-- return instance of GameScene, conformed with C++ form
function GameScene.create()
    local scene = GameScene.new()
    local AnimationLayer = require("AnimationLayer")
    local layer = AnimationLayer.create()
    scene:addChild(layer)
    
    local UILayer = require("GameUILayer")
    scene:addChild(UILayer.create())
    return scene
end

-- overwrite the ctor() in new(), used to create fields
function GameScene:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
end

return GameScene


