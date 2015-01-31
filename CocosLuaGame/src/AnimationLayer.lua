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
    self.pressedDirectionKey = {[cc.KeyCode.KEY_W] = false, [cc.KeyCode.KEY_D] = false,
                           [cc.KeyCode.KEY_S] = false, [cc.KeyCode.KEY_A] = false}
    self.directionKeyNum = 0
end

function AnimationLayer:onEnter()
--    local leadingRole = cc.Sprite:create("roles/leading_role.png")
    local offsetUnit = 80
    local leadingRole = cc.Sprite:create("roles/leading_role_atlas.png", 
                        cc.rect(0, 1*offsetUnit, offsetUnit, offsetUnit))
    leadingRole:setPosition(self.visibleSize.height/2 ,self.visibleSize.width/5)
    self:addChild(leadingRole)
    -- keyboard event
    local function onKeyPressed(keyCode, event)
        local targetSprite = event:getCurrentTarget()
--        if keyCode == cc.KeyCode.KEY_W then --KEY_W is number
--            local jumpBy = cc.JumpBy:create(0.5, cc.p(0, 0), 80, 1)
--            targetSprite:runAction(jumpBy)
--        elseif keyCode == cc.KeyCode.KEY_D then
--            targetSprite:runAction(cc.MoveBy:create(1, cc.p(20, 0)))
--        elseif keyCode == cc.KeyCode.KEY_A then
--            targetSprite:runAction(cc.MoveBy:create(1, cc.p(-20, 0)))
--        elseif keyCode == cc.KeyCode.KEY_S then
--        end
        local pressedKey = self.pressedDirectionKey
        if keyCode == cc.KeyCode.KEY_J then -- jump
            if self.directionKeyNum == 1 then
                if pressedKey[cc.KeyCode.KEY_D] then -- forward
                    targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(20, 0), 80, 1))
                elseif pressedKey[cc.KeyCode.KEY_A] then --backward
                    targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(-20, 0), 80, 1))
                else
                    targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(0, 0), 80, 1))             
                end
            else
                targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(0, 0), 80, 1))
            end
        elseif keyCode == cc.KeyCode.KEY_K then -- attack 
--            if self.directionKeyNum == 1 then
--                if pressedKey[cc.KeyCode.KEY_D] then -- forward
--                    targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(20, 0), 80, 1))
--                elseif pressedKey[cc.KeyCode.KEY_A] then --backward
--                    targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(-20, 0), 80, 1))
--                else
--                    targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(0, 0), 80, 1))             
--                end
--            elseif self.directionKeyNum == 2 then
--                if pressedKey[cc.KeyCode.KEY_W] and pressedKey[cc.KeyCode.KEY_D] then
--                elseif pressedKey[cc.KeyCode.KEY_D] and pressedKey[cc.KeyCode.KEY_S] then
--                elseif pressedKey[cc.KeyCode.KEY_S] and pressedKey[cc.KeyCode.KEY_A] then
--                elseif pressedKey[cc.KeyCode.KEY_A] and pressedKey[cc.KeyCode.KEY_W] then
--                else
--                end
--            else
--    
--            end
        elseif pressedKeyCode[keyCode] ~= nil then
           pressedKeyCode[keyCode] = true
           self.directionKeyNum = self.directionKeyNum + 1
        end
    end
    
    local function onKeyReleased(keyCode, event)
        local targetSprite = event:getCurrentTarget()
        if keyCode == cc.KeyCode.KEY_W then --KEY_W is number
            local jumpBy = cc.JumpBy:create(0.5, cc.p(0, 0), 80, 1)
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