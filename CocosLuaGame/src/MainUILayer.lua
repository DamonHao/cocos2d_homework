local s_simpleAudioEngine = cc.SimpleAudioEngine:getInstance()


local MainUILayer = class("MainUILayer", function()
    return cc.Layer:create()
end)

function MainUILayer.create()
    local layer = MainUILayer.new()
    local function onNodeEvent(event) -- onEnter() and onExit() is node event 
        if event == "enter" then
            layer:onEnter()
    elseif event == "exit" then
    end
    end
    layer:registerScriptHandler(onNodeEvent)
    return layer
end

function MainUILayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
end


function MainUILayer:onEnter()
    local function changeGameScene(tag, sender)
        s_simpleAudioEngine:stopMusic()
        s_simpleAudioEngine:stopAllEffects()
        local sceneCls = require("MainMenuScene")
        local newScene = sceneCls.create()
        cc.Director:getInstance():replaceScene(newScene)
    end
    
    local returnButton = cc.MenuItemImage:create("ui/back_game.png", "ui/back_game.png")
    returnButton:registerScriptTapHandler(changeGameScene)
    returnButton:setScale(0.4)
    returnButton:setPosition(self.visibleSize.width-50, self.visibleSize.height-20)
    
    local menu = cc.Menu:create(returnButton)
    menu:setPosition(0, 0) -- default value
    menu:setAnchorPoint(cc.p(0,0))
    self:addChild(menu)
end

return MainUILayer