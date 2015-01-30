
local GameScene = class("GameScene",function()
    return cc.Scene:create()
end)

function GameScene.create()
    local scene = GameScene.new()
    scene:addChild(scene:createLayer())
    return scene
end


function GameScene:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
end

function GameScene:playBgMusic()
end

-- create layer
function GameScene:createLayer()
    local rootNode = cc.CSLoader:createNode("MainScene.csb")

    local menuPopup, menuTools, effectID

    local function menuCallbackClose()
        cc.Director:getInstance():endToLua()
    end

    -- add handler for close item
    local menuToolsItem = rootNode:getChildByName("Button_1")
    menuToolsItem:addTouchEventListener(menuCallbackClose)

    return rootNode
end

return GameScene
