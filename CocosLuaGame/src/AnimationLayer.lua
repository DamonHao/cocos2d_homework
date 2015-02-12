
require("Helper")
--create class AnimationLayer
local AnimationLayer = class("AnimationLayer", function()
	return cc.Layer:create()
end)

local TAG_FOWARD_ACTION = 1
local TAG_BACKWARD_ACTION = 2
local TAG_MAP = 3
local KEY_W = cc.KeyCode.KEY_W
local KEY_D = cc.KeyCode.KEY_D
local KEY_S = cc.KeyCode.KEY_S
local KEY_A = cc.KeyCode.KEY_A
local KEY_J = cc.KeyCode.KEY_J
local KEY_K = cc.KeyCode.KEY_K
local JUMP_HEIGHT = 120



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
    -- Physics debug mode
    cc.Director:getInstance():getRunningScene():getPhysicsWorld():
        setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL)
    -- create world edge
    local nodeForWorldEdge = cc.Node:create()
    nodeForWorldEdge:setPhysicsBody(cc.PhysicsBody:createEdgeBox(cc.size(self.visibleSize.width, self.visibleSize.height)))
    nodeForWorldEdge:setPosition(self.visibleSize.width/2, self.visibleSize.height/2)
    nodeForWorldEdge:getPhysicsBody():setDynamic(false)
--    nodeForWorldEdge:getPhysicsBody():setCollisionBitmask(0x1)
    self:addChild(nodeForWorldEdge)
    
--    local stone = cc.Sprite:create("maps/stone.png")
--    stone:setPosition(self.visibleSize.width/2, 100)
--    stone:setPhysicsBody(cc.PhysicsBody:createBox(stone:getContentSize()))
--    stone:getPhysicsBody():setDynamic(false)
--    stone:getPhysicsBody():setTag(TAG_MAP)
--    self:addChild(stone)   
    
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
--    leadingRole:setAnchorPoint(0, 0)
--    leadingRole:setPosition(0 , 0)
    leadingRole:setPosition(self.visibleSize.width/5, self.visibleSize.height/2)
    leadingRole:setPhysicsBody(cc.PhysicsBody:createBox(leadingRole:getContentSize()))
    leadingRole:getPhysicsBody():setCategoryBitmask(1)
--    leadingRole:getPhysicsBody():setContactTestBitmask(1)
    leadingRole:getPhysicsBody():setCollisionBitmask(1)
    self:addChild(leadingRole)
    
    local testSprite = cc.Sprite:createWithSpriteFrame(forwardFrames[1]) 
    testSprite:setFlippedX(true)
    testSprite:setPosition(self.visibleSize.width*3/5, self.visibleSize.height/2)
    testSprite:setPhysicsBody(cc.PhysicsBody:createBox(cc.size( offsetUnit , offsetUnit)))
--    testSprite:getPhysicsBody():setContactTestBitmask(1)
    testSprite:getPhysicsBody():setCategoryBitmask(1)
    testSprite:getPhysicsBody():setCollisionBitmask(2)
    self:addChild(testSprite)
    
    -- keyboard event
    local function onKeyPressed(keyCode, event)
        local targetSprite = event:getCurrentTarget()
        local pressedKey = self.pressedDirectionKey
--        print(self.directionKeyNum)
        if pressedKey[keyCode] ~= nil then
            pressedKey[keyCode] = true 
            self.directionKeyNum = self.directionKeyNum + 1
        end
        if keyCode == KEY_D then -- foward move
            targetSprite:setFlippedX(false)
            local animation = cc.AnimationCache:getInstance():getAnimation("foward_walk")
            local walkAction = cc.Animate:create(animation)
            local moveBy = cc.MoveBy:create(5, cc.p(self.visibleSize.width, 0))
            local forward = cc.Spawn:create(walkAction, moveBy)
            forward:setTag(TAG_FOWARD_ACTION)
            targetSprite:runAction(forward)
        elseif keyCode == KEY_A then -- backward move
            targetSprite:setFlippedX(true)
            local animation = cc.AnimationCache:getInstance():getAnimation("foward_walk")
            local walkAction = cc.Animate:create(animation)
            local moveBy = cc.MoveBy:create(5, cc.p(-self.visibleSize.width, 0))
            local backward = cc.Spawn:create(walkAction, moveBy)
            backward:setTag(TAG_BACKWARD_ACTION)
            targetSprite:runAction(backward)
        elseif keyCode == KEY_J then -- jump
            if pressedKey[KEY_D] and pressedKey[KEY_A] then
                targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(0, 0), JUMP_HEIGHT, 1))	
            elseif pressedKey[KEY_D] then
                targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(80, 0), JUMP_HEIGHT, 1))
            elseif pressedKey[KEY_A] then
                targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(-80, 0), JUMP_HEIGHT, 1))
            else
                targetSprite:runAction(cc.JumpBy:create(0.5, cc.p(0, 0), JUMP_HEIGHT, 1))
            end
        elseif keyCode == KEY_K then -- attack
            local attack = cc.Sprite:createWithSpriteFrame(
                           cc.SpriteFrameCache:getInstance():getSpriteFrame("leading_role_attack"))
            attack:setPhysicsBody(cc.PhysicsBody:createBox(
                   cc.size(attack:getContentSize().width , attack:getContentSize().height)))
            attack:getPhysicsBody():setGravityEnable(false)
--            print(attack:getPhysicsBody():getMass())

            local lead_x, lead_y = targetSprite:getPosition()
            local leadSize = targetSprite:getContentSize()
            local attackPosi = cc.p(0, 0)
            local moveBy = nil
            local function forwardAndBackwardAttack()
                if targetSprite:isFlippedX() then
                    attack:setFlippedX(true)
                    attackPosi.x = lead_x - leadSize.width/2 - attack:getContentSize().width/2
                    attackPosi.y = lead_y
                    moveBy = cc.MoveBy:create(2, cc.p(-self.visibleSize.width, 0))
                else
                    attack:setFlippedX(false)
                    attackPosi.x = lead_x + leadSize.width/2 + attack:getContentSize().width/2
                    attackPosi.y = lead_y
                    moveBy = cc.MoveBy:create(2, cc.p(self.visibleSize.width, 0))       
                end                
            end
            
            if self.directionKeyNum == 1 then
                if pressedKey[KEY_W] then -- up
--                    attack:setFlippedX(false)
                    attack:setRotation(-90)
                    attackPosi.x = lead_x
                    attackPosi.y = lead_y + leadSize.height/2 + attack:getContentSize().height/2
                    moveBy = cc.MoveBy:create(2, cc.p(0, self.visibleSize.height))
                elseif pressedKey[KEY_S] then --down
                    attack:setRotation(90)
                    attackPosi.x = lead_x
                    attackPosi.y = lead_y - leadSize.height/2 - attack:getContentSize().height/2
                    moveBy = cc.MoveBy:create(2, cc.p(0, -self.visibleSize.height))
                else
                    forwardAndBackwardAttack()
                end        
            elseif self.directionKeyNum == 2 then
                local maxLenght =  math.max(self.visibleSize.width, self.visibleSize.height)
                if pressedKey[KEY_W] and pressedKey[KEY_D] then -- up right
                    attack:setRotation(-45)
                    attackPosi.x = lead_x + leadSize.width/2 + 
                                   math.cos(45)*attack:getContentSize().width/2
                    attackPosi.y = lead_y + leadSize.height/2 +
                                   math.sin(45)*attack:getContentSize().width/2
                    
                    moveBy = cc.MoveBy:create(2, cc.p(maxLenght, maxLenght))
                elseif pressedKey[KEY_D] and pressedKey[KEY_S] then -- down right 
                    attack:setRotation(45)
                    attackPosi.x = lead_x + leadSize.width/2 + 
                                   math.cos(45)*attack:getContentSize().width/2
                    attackPosi.y = lead_y - leadSize.height/2 -
                                   math.sin(45)*attack:getContentSize().width/2
                    moveBy = cc.MoveBy:create(2, cc.p(maxLenght, -maxLenght))
                elseif pressedKey[KEY_A] and pressedKey[KEY_S] then -- down left
                    attack:setRotation(135)
                    attackPosi.x = lead_x - leadSize.width/2 - 
                                   math.cos(45)*attack:getContentSize().width/2
                    attackPosi.y = lead_y - leadSize.height/2 -
                                   math.sin(45)*attack:getContentSize().width/2
                    moveBy = cc.MoveBy:create(2, cc.p(-maxLenght, -maxLenght))
                elseif pressedKey[KEY_A] and pressedKey[KEY_W] then -- up left
                    attack:setRotation(-135)
                    attackPosi.x = lead_x - leadSize.width/2 - 
                                   math.cos(45)*attack:getContentSize().width/2 
                    attackPosi.y = lead_y + leadSize.height/2 +
                                   math.sin(45)*attack:getContentSize().width/2
                    moveBy = cc.MoveBy:create(2, cc.p(-maxLenght, maxLenght))
                else
                    forwardAndBackwardAttack()                 
                end
            else
                forwardAndBackwardAttack()     
            end

            local function cleanupAttack()
                self:removeChild(attack, true)
            end
            local callfunc = cc.CallFunc:create(cleanupAttack)
            attack:runAction(cc.Sequence:create(moveBy, callfunc))
            attack:setPosition(attackPosi)
            self:addChild(attack)
            cclog("Aniamtion layer child nums: %d", self:getChildrenCount())
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

    local keyboardListener = cc.EventListenerKeyboard:create()
    keyboardListener:registerScriptHandler(onKeyPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
    keyboardListener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
    local eventDispatcher = self:getEventDispatcher() -- every node has a event dispatcher
    eventDispatcher:addEventListenerWithSceneGraphPriority(keyboardListener, leadingRole)
    
    -- contact event
    local function onContactBegin(contact)
        local a = contact:getShapeA():getBody()
        local b = contact:getShapeB():getBody()
        print("contact") 
--        if a:getTag() == TAG_MAP or b:getTag() == TAG_MAP then
--            print("contact")    
--        end
    	return true
    end
    
    local contactListener = cc.EventListenerPhysicsContact:create()
--    local contactListener = cc.EventListenerPhysicsContactWithBodies:create(leadingRole:getPhysicsBody(), 
--                            testSprite:getPhysicsBody())
    contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    eventDispatcher:addEventListenerWithSceneGraphPriority(contactListener, self)
    
end

return AnimationLayer