--create class AnimationLayer
local AnimationLayer = class("AnimationLayer", function()
	return cc.Layer:create()
end)

local TAG_FOWARD_ACTION = 1
local TAG_BACKWARD_ACTION = 2

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

    local offsetUnit = 80
    local cache = cc.Director:getInstance():getTextureCache()
    local leading_altas = cc.Sprite:create("roles/leading_role_atlas.png"):getTexture()
    -- cache animation
    local animCache = cc.AnimationCache:getInstance()
    local forwardFrames = {}
    for i = 1, 4 do
        forwardFrames[i] = cc.SpriteFrame:createWithTexture(leading_altas, 
            cc.rect((i-1)*offsetUnit, 1*offsetUnit, offsetUnit, offsetUnit))
    end
    -- -1 means infinite loop
    local animation1 = cc.Animation:createWithSpriteFrames(forwardFrames, 0.15, -1)
    animCache:addAnimation(animation1,"foward_walk")    
    
    -- cache sprite frame
    local frameCache = cc.SpriteFrameCache:getInstance()
    frameCache:addSpriteFrame(forwardFrames[1],"foward")
--    frameCache:addSpriteFrame(cc.SpriteFrame:create("attacks/leading_role_attack.png"),
--               "leading_role_attack")
    frameCache:addSpriteFrame(cc.Sprite:create("attacks/leading_role_attack.png"):getSpriteFrame(),
        "leading_role_attack")
    
    local leadingRole = cc.Sprite:createWithSpriteFrame(forwardFrames[1])  
--    leadingRole
--    local haha = leadingRole:getPosition()
--    print(type(haha))
    leadingRole:setPosition(self.visibleSize.height/2 ,self.visibleSize.width/5)
    self:addChild(leadingRole)
    
    -- keyboard event
    local function onKeyPressed(keyCode, event)
        local targetSprite = event:getCurrentTarget()
        local pressedKey = self.pressedDirectionKey
        if pressedKey[keyCode] ~= nil then
            self.directionKeyNum = self.directionKeyNum + 1
        end
        if keyCode == cc.KeyCode.KEY_D then -- foward move
            targetSprite:setFlippedX(false)
            local animation = cc.AnimationCache:getInstance():getAnimation("foward_walk")
            local walkAction = cc.Animate:create(animation)
            local moveBy = cc.MoveBy:create(5, cc.p(self.visibleSize.width, 0))
            local forward = cc.Spawn:create(walkAction, moveBy)
            forward:setTag(TAG_FOWARD_ACTION)
            targetSprite:runAction(forward)
            pressedKey[keyCode] = true
        elseif keyCode == cc.KeyCode.KEY_A then -- backward move
            targetSprite:setFlippedX(true)
            local animation = cc.AnimationCache:getInstance():getAnimation("foward_walk")
            local walkAction = cc.Animate:create(animation)
            local moveBy = cc.MoveBy:create(5, cc.p(-self.visibleSize.width, 0))
            local backward = cc.Spawn:create(walkAction, moveBy)
            backward:setTag(TAG_BACKWARD_ACTION)
            targetSprite:runAction(backward)
            pressedKey[keyCode] = true
        elseif keyCode == cc.KeyCode.KEY_J then -- jump
            if pressedKey[cc.KeyCode.KEY_D] and pressedKey[cc.KeyCode.KEY_A] then
                targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(0, 0), 80, 1))	
            elseif pressedKey[cc.KeyCode.KEY_D] then
                targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(30, 0), 80, 1))
            elseif pressedKey[cc.KeyCode.KEY_A] then
                targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(-30, 0), 80, 1))
            else
                targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(0, 0), 80, 1))
            end
        elseif keyCode == cc.KeyCode.KEY_K then -- attack
            local attack = cc.Sprite:createWithSpriteFrame(
                cc.SpriteFrameCache:getInstance():getSpriteFrame("leading_role_attack"))
            local lead_x, lead_y = targetSprite:getPosition()
            local leadSize = targetSprite:getContentSize()
            local attactPosi = cc.p(0, 0)
            local moveBy = nil
            if targetSprite:isFlippedX() then
            else
                attactPosi.x = lead_x + leadSize.width/2 + attack:getContentSize().width/2
                attactPosi.y = lead_y
            moveBy = cc.MoveBy:create(2, cc.p(self.visibleSize.width, 0))       
            end
            attack:runAction(moveBy)
            attack:setPosition(attactPosi)
            self:addChild(attack)
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
        end
    end
    
    local function onKeyReleased(keyCode, event)
        local pressedKey = self.pressedDirectionKey
        local targetSprite = event:getCurrentTarget()
        if pressedKey[keyCode] then
            if keyCode == cc.KeyCode.KEY_D then
                targetSprite:stopActionByTag(TAG_FOWARD_ACTION)
            elseif keyCode == cc.KeyCode.KEY_A then
                targetSprite:stopActionByTag(TAG_BACKWARD_ACTION)
            end
            pressedKey[keyCode] = false
            self.directionKeyNum = self.directionKeyNum - 1 
        end
    end

    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(onKeyPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
    listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
    local eventDispatcher = self:getEventDispatcher() -- every node has a event dispatcher
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, leadingRole)
    
end

return AnimationLayer