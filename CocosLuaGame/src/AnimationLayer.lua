--create class AnimationLayer
local AnimationLayer = class("AnimationLayer", function()
	return cc.Layer:create()
end)

-- static method.return instance of MainScene, conformed with C++ form
function AnimationLayer.create()
    local layer = AnimationLayer.new()
    local function onNodeEvent(event) -- onEnter() and onExit() is node event 
        if event == "enter" then
            layer:onEnter()
        elseif event == "exit" then
        end
    end
    layer:registerScriptHandler(onNodeEvent)
    return layer
end

-- overwrite the ctor() in ClassName.new(), used to create fields
function AnimationLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
end

function AnimationLayer:onEnter()
    
    local leadingRole = cc.Sprite:create("roles/leading_role.png")
    leadingRole:setPosition(self.visibleSize.height/2 ,self.visibleSize.width/5)
    self:addChild(leadingRole)
    -- keyboard event
    local function onKeyPressed(keyCode, event)
        local targetSprite = event:getCurrentTarget()
        if keyCode == cc.KeyCode.KEY_W then --KEY_W is number
            local jumpBy = cc.JumpBy:create(0.5, cc.p(0, 0), 30, 1)
            targetSprite:runAction(jumpBy)
        elseif keyCode == cc.KeyCode.KEY_D then
            targetSprite:runAction(cc.MoveBy:create(1, cc.p(20, 0)))
        elseif keyCode == cc.KeyCode.KEY_A then
            targetSprite:runAction(cc.MoveBy:create(1, cc.p(-20, 0)))
        elseif keyCode == cc.KeyCode.KEY_S then
        end
    end

    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(onKeyPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
    local eventDispatcher = self:getEventDispatcher() -- every node has a event dispatcher
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, leadingRole)
    
end

return AnimationLayer