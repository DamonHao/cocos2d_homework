-- create class MainScene
local MainScene = class("MainScene",function()
    return cc.Scene:create()
end)

-- return instance of MainScene, conformed with C++ form
function MainScene.create()
    local scene = MainScene.new()
    scene:addChild(scene:createBackgroundLayer())
    scene:addChild(scene:createAnimationLayer())
    return scene
end

-- overwrite ctor() for new()
function MainScene:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
end

-- 
function MainScene:playBgMusic()
end

-- create layer
function MainScene:createBackgroundLayer()
    local layer = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))
    return layer
end

function MainScene:createAnimationLayer()
    local leadingRole = cc.Sprite:create("roles/leading_role.png")
    leadingRole:setPosition(self.visibleSize.height/2 ,self.visibleSize.width/5)
    local animationLayer = cc.Layer:create()
    animationLayer:addChild(leadingRole)
    return animationLayer
end

return MainScene


