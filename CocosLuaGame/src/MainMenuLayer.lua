local MainMenuLayer = class("MainMenuLayer", function()
    return cc.Layer:create()
end)

function MainMenuLayer.create()
    local layer = MainMenuLayer.new()
    local function onNodeEvent(event) -- onEnter() and onExit() is node event 
        if event == "enter" then
                layer:onEnter()
        elseif event == "exit" then
        end
    end
    layer:registerScriptHandler(onNodeEvent)
    return layer
end

function MainMenuLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
end


function MainMenuLayer:onEnter()
    local function changeGameScene(tag, sender)
        local sceneCls = require("MainScene")
        local newScene = sceneCls.create()
        cc.Director:getInstance():replaceScene(newScene)
    end
    
    local function exitGame(tag, sender)
        cc.Director:getInstance():endToLua()
    end

    local startGameButton = cc.MenuItemImage:create("ui/begin_game.png", "ui/begin_game.png")
    startGameButton:registerScriptTapHandler(changeGameScene)
    startGameButton:setPosition(self.visibleSize.width/2, self.visibleSize.height/2+20)
    startGameButton:setScale(0.6)

    local exitGameButton = cc.MenuItemImage:create("ui/exit_game.png", "ui/exit_game.png")
    exitGameButton:registerScriptTapHandler(exitGame)
    exitGameButton:setPosition(self.visibleSize.width/2, self.visibleSize.height/2-20)
    exitGameButton:setScale(0.6)

    local menu = cc.Menu:create(startGameButton, exitGameButton)
    menu:setPosition(0, 0) -- default value
    menu:setAnchorPoint(cc.p(0,0))
    self:addChild(menu)
end


return MainMenuLayer