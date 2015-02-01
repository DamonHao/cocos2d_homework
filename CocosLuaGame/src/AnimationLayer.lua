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
--    local leadingRole = cc.Sprite:create("roles/leading_role.png")
--    local cache = cc.SpriteFrameCache:getInstance()
    local offsetUnit = 80
    local cache = cc.Director:getInstance():getTextureCache()
--    local leadingTexture = cache:addImage("roles/leading_role_atlas.png")
--    cc.Image:initWithImageFile("roles/leading_role_atlas.png")
--    cc.Image:
    local leading_altas = cc.Sprite:create("roles/leading_role_atlas.png"):getTexture()
--    local cache = cc.SpriteFrameCache:getInstance()
    local animCache = cc.AnimationCache:getInstance()
    local forwardFrames = {}
    for i = 1, 4 do
        forwardFrames[i] = cc.SpriteFrame:createWithTexture(leading_altas, 
            cc.rect((i-1)*offsetUnit, 1*offsetUnit, offsetUnit, offsetUnit))
    end
    local animation = cc.Animation:createWithSpriteFrames(forwardFrames, 0.3, 100) --FIXME loop num??
    animCache:addAnimation(animation,"foward_walk")
  
    local leadingRole = cc.Sprite:createWithSpriteFrame(forwardFrames[1])
--    local animation = cc.Animation:createWithSpriteFrames(forwardFrames, 0.3)
--    local walkAction = cc.RepeatForever:create(cc.Animate:create(animation))
--    leadingRole:runAction(walkAction)
--    local leadingRole = cc.Sprite:create("roles/leading_role_atlas.png", 
--                        cc.rect(0, 1*offsetUnit, offsetUnit, offsetUnit))
    leadingRole:setPosition(self.visibleSize.height/2 ,self.visibleSize.width/5)
    self:addChild(leadingRole)
    
    -- keyboard event
    local function onKeyPressed(keyCode, event)
        local targetSprite = event:getCurrentTarget()
        local pressedKey = self.pressedDirectionKey
        if pressedKey[keyCode] ~= nil then
            self.directionKeyNum = self.directionKeyNum + 1
        end
        if keyCode == cc.KeyCode.KEY_D then
            local animation = cc.AnimationCache:getInstance():getAnimation("foward_walk")
            local walkAction = cc.Animate:create(animation)
--            local rotate = cc.RotateBy:create( 2, 720)
--            targetSprite:runAction(rotate)
--            local walkAction = cc.Animate:create(animation)
--            targetSprite:runAction(walkAction)
            local moveBy = cc.MoveBy:create(5, cc.p(self.visibleSize.width, 0))
            local forward = cc.Spawn:create(walkAction, moveBy)
            forward:setTag(TAG_FOWARD_ACTION)
            targetSprite:runAction(forward)
            pressedKey[keyCode] = true
        elseif keyCode == cc.KeyCode.KEY_A then
            local backward = cc.MoveBy:create(5, cc.p(-self.visibleSize.width, 0))
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