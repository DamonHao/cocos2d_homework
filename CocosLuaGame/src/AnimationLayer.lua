local TAG_FORWARD_ACTION = 1
local TAG_BACKWARD_ACTION = 2
local TAG_JUMP_FORWARD_ACTION = 3
local TAG_JUMP_BACKWARD_ACTION = 4
local TAG_JUMP_ACTION = 5
local TAG_MAP = 103
local TAG_LEADING_ROLE = 104
local TAG_LEADING_ROLE_ATTACK = 105
local TAG_BOSS = 106
local TAG_ENEMY_ATTACK = 107
local TAG_DOUGHBOY = 108
local s_isEnemy = {[TAG_BOSS]=true, [TAG_DOUGHBOY]=true}

local KEY_UP = cc.KeyCode.KEY_W
local KEY_RIGHT = cc.KeyCode.KEY_D
local KEY_DOWN = cc.KeyCode.KEY_S
local KEY_LEFT = cc.KeyCode.KEY_A
local KEY_JUMP = cc.KeyCode.KEY_J
local KEY_ATTACK = cc.KeyCode.KEY_K
local JUMP_HEIGHT = 150
local GRAVITY_Y = -400
local JUMP_UP_SPEED = 350
local WALK_SPEED = 70
local ATTACK_SPEED = 110
local ALL_BIT_ONE = -1 -- 0xFFFFFFFF will overflow and set as -2147483648 = 0x80000000
local ATTACK_Y_THRESHOLD = 50

-- control direction
local RIGHT = 1
local DOWN = 2
local LEFT = 3
local UP = 4
local RIGHT_DOWN = 5
local LEFT_DOWN = 6
local LEFT_UP = 7
local RIGHT_UP = 8


local s_scheduler = cc.Director:getInstance():getScheduler()
local s_schedulerEntry1 = nil
local s_enemySimpleAI = nil
local ATTACK_DISTANCE_X = 180
local ATTACK_DISTANCE_X_FOR_UP = 50


require("Helper")
--create class AnimationLayer
local AnimationLayer = class("AnimationLayer", function()
    return cc.Layer:create()
end)

-- static method. return instance of MainScene, conformed with C++ form
function AnimationLayer.create()
    local layer = AnimationLayer.new()
--    local schedulerEntry1 = nil
    local function onNodeEvent(event) -- onEnter() and onExit() is node event 
        if event == "enter" then
            layer:onEnter()
            s_schedulerEntry1 = s_scheduler:scheduleScriptFunc(s_enemySimpleAI, 1.5, false)
        elseif event == "exit" then
            s_scheduler:unscheduleScriptEntry(s_schedulerEntry1)
        end
    end
    layer:registerScriptHandler(onNodeEvent)
    return layer
end

-- overwrite the ctor() in ClassName.new(), used to create fields
function AnimationLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.pressedDirectionKey = {[KEY_UP] = false, [KEY_RIGHT] = false,
                           [KEY_DOWN] = false, [KEY_LEFT] = false}
    self.directionKeyNum = 0
    self.isLeadingRoleOnTheGround = true
    self.bloodVolumeTable = {}
    self.curEnemyNum = 2
end

function AnimationLayer:onEnter()
    -- Physics debug mode
    local physicsWorld = cc.Director:getInstance():getRunningScene():getPhysicsWorld()
    physicsWorld:setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL)
    physicsWorld:setGravity(cc.p(0, GRAVITY_Y))
    cclog("world gravity: %f", physicsWorld:getGravity().y)
    -- create world edge
    local nodeForWorldEdge = cc.Node:create()
    nodeForWorldEdge:setPhysicsBody(cc.PhysicsBody:createEdgeBox(cc.size(self.visibleSize.width, self.visibleSize.height)))
    nodeForWorldEdge:setPosition(self.visibleSize.width/2, self.visibleSize.height/2)
    nodeForWorldEdge:getPhysicsBody():setDynamic(false)
    nodeForWorldEdge:getPhysicsBody():setContactTestBitmask(ALL_BIT_ONE)
    nodeForWorldEdge:setTag(TAG_MAP)
    self:addChild(nodeForWorldEdge)
       
    local stone = cc.Sprite:create("maps/stone.png")
    stone:setPosition(self.visibleSize.width/2, 120)
    stone:setPhysicsBody(cc.PhysicsBody:createBox(stone:getContentSize()))
    stone:getPhysicsBody():setDynamic(false)
    stone:getPhysicsBody():setContactTestBitmask(ALL_BIT_ONE)
    stone:setTag(TAG_MAP)
    cclog("stonde category:%d", stone:getPhysicsBody():getCategoryBitmask())
    cclog("stonde contact test:%d", stone:getPhysicsBody():getContactTestBitmask())
    self:addChild(stone)   
    
    --set up leadingRole
    local offsetUnit = 64
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
    animCache:addAnimation(animation1,"leadingRole_forward_walk") 
    
    -- cache sprite frame
    local frameCache = cc.SpriteFrameCache:getInstance()

    frameCache:addSpriteFrame(cc.Sprite:create("attacks/leading_role_attack.png"):getSpriteFrame(),
        "leading_role_attack")
    frameCache:addSpriteFrame(cc.Sprite:create("attacks/boss_attack.png"):getSpriteFrame(),
        "boss_attack")
    
    local leadingRole = cc.Sprite:createWithSpriteFrame(forwardFrames[1])
--    leadingRole:setScale(0.8, 0.8)  
    leadingRole:setPosition(self.visibleSize.width/5, self.visibleSize.height/2)
    leadingRole:setPhysicsBody(cc.PhysicsBody:createBox(cc.size(
                leadingRole:getContentSize().width-15,leadingRole:getContentSize().height)))
    leadingRole:getPhysicsBody():setRotationEnable(false)
    leadingRole:getPhysicsBody():setCategoryBitmask(1)
    leadingRole:getPhysicsBody():setContactTestBitmask(8)
    leadingRole:getPhysicsBody():setCollisionBitmask(1)
    leadingRole:setTag(TAG_LEADING_ROLE)
    leadingRole:setAnchorPoint(0.5, 0.5)
    leadingRole:getPhysicsBody():getShape(0):setFriction(0)
    cclog("leadingRole category:%d", leadingRole:getPhysicsBody():getCategoryBitmask())
    cclog("leadingRole contact test", leadingRole:getPhysicsBody():getContactTestBitmask())
       
    self:addChild(leadingRole)
    self:setUpBloodVolumeForRoles(leadingRole)

    -- set up enemy
    local boss = self:setUpEnemy("roles/boss_atlas.png", TAG_BOSS,
        {width=55, height=75},{x=self.visibleSize.width*5/7, y= self.visibleSize.height/2})
    local doughboy = self:setUpEnemy("roles/doughboy_atlas.png", TAG_DOUGHBOY, 
        {width=55, height=77},{x=self.visibleSize.width*6/7, y= self.visibleSize.height/2})
    
    
    -- Simple AI
    s_enemySimpleAI = function ()  --FIXME Simple AI
        -- set if condition in case it will pause the action that delete the sprite
        if self:getBloodVolumeInfo(boss).curBlood > 0 then
            self:executeAIForEnemy(boss, leadingRole, "boss_attack")
        end
        if self:getBloodVolumeInfo(doughboy).curBlood > 0 then
            self:executeAIForEnemy(doughboy, leadingRole, "boss_attack")
        end
    end
    
    -- keyboard event
    local function onKeyPressed(keyCode, event)
        local targetSprite = event:getCurrentTarget()
        -- in case the keyboard event will refer to the dead leadingRole and cause error
        if self:getBloodVolumeInfo(targetSprite).curBlood <= 0 then return end
        
        local targetBody = targetSprite:getPhysicsBody()
        local pressedKey = self.pressedDirectionKey
        if pressedKey[keyCode] ~= nil then
            pressedKey[keyCode] = true 
            self.directionKeyNum = self.directionKeyNum + 1
        end
        
        if keyCode == KEY_RIGHT then -- foward move
            targetSprite:setFlippedX(false)
            if self.isLeadingRoleOnTheGround == false then return end
            if pressedKey[KEY_LEFT] then -- contrary direction and stop
                targetBody:setVelocity(cc.p(0, 0))
                targetSprite:stopActionByTag(TAG_BACKWARD_ACTION)
                return
            end
            targetBody:setVelocity(cc.p(WALK_SPEED, 0))
            local animation = cc.AnimationCache:getInstance():getAnimation("leadingRole_forward_walk")
            local forward = cc.Animate:create(animation)
            forward:setTag(TAG_FORWARD_ACTION)
            targetSprite:runAction(forward)
--            targetBody:applyImpulse(cc.p(WALK_SPEED* targetBody:getMass(), 0))
        elseif keyCode == KEY_LEFT then -- backward move
            targetSprite:setFlippedX(true)
            if self.isLeadingRoleOnTheGround == false then return end
            if pressedKey[KEY_RIGHT] then -- contrary direction and stop
                targetBody:setVelocity(cc.p(0, 0))
                targetSprite:stopActionByTag(TAG_FORWARD_ACTION)
                return
            end
            targetBody:setVelocity(cc.p(-1*WALK_SPEED, 0))
            local animation = cc.AnimationCache:getInstance():getAnimation("leadingRole_forward_walk")
            local backward = cc.Animate:create(animation)
            backward:setTag(TAG_BACKWARD_ACTION)
            targetSprite:runAction(backward)
        elseif keyCode == cc.KeyCode.KEY_U and self.isLeadingRoleOnTheGround then -- test jump
            local jump = cc.JumpBy:create(0.5, cc.p(0, 0), JUMP_HEIGHT, 1)
            targetSprite:runAction(jump)
        elseif keyCode == KEY_JUMP and self.isLeadingRoleOnTheGround then -- jump
            targetSprite:stopAllActions() -- stop all action
            targetSprite:getPhysicsBody():applyImpulse(cc.p(0, 
                         JUMP_UP_SPEED* targetSprite:getPhysicsBody():getMass()))
                         
        elseif keyCode == KEY_ATTACK then -- attack
            local attack = cc.Sprite:createWithSpriteFrame(
                           cc.SpriteFrameCache:getInstance():getSpriteFrame("leading_role_attack"))
            attack:setPhysicsBody(cc.PhysicsBody:createBox(
                   cc.size(attack:getContentSize().width , attack:getContentSize().height)))
            attack:getPhysicsBody():setGravityEnable(false)
            attack:getPhysicsBody():setCategoryBitmask(4)
            attack:getPhysicsBody():setContactTestBitmask(2)
            attack:getPhysicsBody():setCollisionBitmask(0)
            attack:setTag(TAG_LEADING_ROLE_ATTACK)

            local function rightOrLeftAttack()
                if targetSprite:isFlippedX() then
                    self:setUpAttackForSprite(targetSprite, attack, LEFT)
                else
                    self:setUpAttackForSprite(targetSprite, attack, RIGHT)
                end
            end
            if self.directionKeyNum == 1 then
                if pressedKey[KEY_UP] then -- up
                    self:setUpAttackForSprite(targetSprite, attack, UP)
                elseif pressedKey[KEY_DOWN] then --down
                    self:setUpAttackForSprite(targetSprite, attack, DOWN)
                else
                    rightOrLeftAttack()
                end        
            elseif self.directionKeyNum == 2 then
                if pressedKey[KEY_UP] and pressedKey[KEY_RIGHT] then -- up right
                    self:setUpAttackForSprite(targetSprite, attack, RIGHT_UP)
                elseif pressedKey[KEY_RIGHT] and pressedKey[KEY_DOWN] then -- down right
                    self:setUpAttackForSprite(targetSprite, attack, RIGHT_DOWN)
                elseif pressedKey[KEY_LEFT] and pressedKey[KEY_DOWN] then -- down left
                    self:setUpAttackForSprite(targetSprite, attack, LEFT_DOWN)
                elseif pressedKey[KEY_LEFT] and pressedKey[KEY_UP] then -- up left
                    self:setUpAttackForSprite(targetSprite, attack, LEFT_UP)
                else
                rightOrLeftAttack()
                end
            else
                rightOrLeftAttack()
            end
        cclog("Aniamtion layer child nums: %d", self:getChildrenCount())
        end
    end
        
    local function onKeyReleased(keyCode, event)
        local targetSprite = event:getCurrentTarget()
        -- in case the keyboard event will refer to the dead leadingRole and cause error
        if self:getBloodVolumeInfo(targetSprite).curBlood <= 0 then return end
        
        local targetBody = targetSprite:getPhysicsBody()
        local pressedKey = self.pressedDirectionKey
        if pressedKey[keyCode] then
            if keyCode == KEY_RIGHT and self.isLeadingRoleOnTheGround then
                if pressedKey[KEY_LEFT] then
                    targetSprite:setFlippedX(true)
                    targetBody:setVelocity(cc.p(-1*WALK_SPEED, 0))
                    local animation = cc.AnimationCache:getInstance():getAnimation("leadingRole_forward_walk")
                    local backward = cc.Animate:create(animation)
                    backward:setTag(TAG_BACKWARD_ACTION)
                    targetSprite:runAction(backward)
                else
                    targetSprite:stopActionByTag(TAG_FORWARD_ACTION)
                    targetBody:setVelocity(cc.p(0, 0))
                end
            elseif keyCode == KEY_LEFT and self.isLeadingRoleOnTheGround then
                if pressedKey[KEY_RIGHT] then
                    targetSprite:setFlippedX(false)
                    targetBody:setVelocity(cc.p(WALK_SPEED, 0))
                    local animation = cc.AnimationCache:getInstance():getAnimation("leadingRole_forward_walk")
                    local forward = cc.Animate:create(animation)
                    forward:setTag(TAG_FORWARD_ACTION)
                    targetSprite:runAction(forward)
                else
                    targetSprite:stopActionByTag(TAG_BACKWARD_ACTION)
                    targetBody:setVelocity(cc.p(0, 0))
                end
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
        local a = contact:getShapeA():getBody():getNode()
        local b = contact:getShapeB():getBody():getNode()
        cclog("contact in a tag: %d, b tag: %d", a:getTag(), b:getTag()) 
        if a:getTag() == TAG_MAP or b:getTag() == TAG_MAP then
            local map, dynamicSprite
            local isSwapped = false
            if a:getTag() == TAG_MAP then
                map = a 
                dynamicSprite = b    
            else
                map = b 
                dynamicSprite = a
                isSwapped = true  
            end
            if dynamicSprite:getTag() == TAG_LEADING_ROLE then
                local contactNormal = contact:getContactData().normal
                local dynamicSpriteBody = dynamicSprite:getPhysicsBody()
                local velocity = dynamicSpriteBody:getVelocity()
                cclog("velocity before contact x, y:  %f, %f", velocity.x, velocity.y)
                cclog("onContactBegin original normal x, y:  %f, %f", contactNormal.x, contactNormal.y)
                if contactNormal.y >= 0.1 or contactNormal.y <= -0.1 then -- vertical touch
                    if isSwapped then -- set the normal emit from map
                        contactNormal.y = -1 * contactNormal.y 
                end
                cclog("onContactBegin current normal y: %f",  contactNormal.y)
                if contactNormal.y >= 0.1 then -- touch the ground
                    self.isLeadingRoleOnTheGround = true
                        local velocity_x = 0
                        local pressedKey = self.pressedDirectionKey
                        if pressedKey[KEY_RIGHT] and pressedKey[KEY_LEFT] then
                            dynamicSpriteBody:setVelocity(cc.p(0, 0))
                        elseif pressedKey[KEY_RIGHT] then
                            dynamicSprite:setFlippedX(false)
                            dynamicSpriteBody:setVelocity(cc.p(WALK_SPEED, 0))
                            local animation = cc.AnimationCache:getInstance():getAnimation("leadingRole_forward_walk")
                            local forward = cc.Animate:create(animation)
                            forward:setTag(TAG_FORWARD_ACTION)
                            dynamicSprite:runAction(forward)
                        elseif pressedKey[KEY_LEFT] then
                            dynamicSprite:setFlippedX(true)
                            dynamicSpriteBody:setVelocity(cc.p(-1*WALK_SPEED, 0))
                            local animation = cc.AnimationCache:getInstance():getAnimation("leadingRole_forward_walk")
                            local backward = cc.Animate:create(animation)
                            backward:setTag(TAG_BACKWARD_ACTION)
                            dynamicSprite:runAction(backward)
                        else
                            dynamicSpriteBody:setVelocity(cc.p(0, 0))
                        end
                    else -- touch the roof
                        dynamicSpriteBody:setVelocity(cc.p(velocity.x, -0.2*velocity.y))
                    end            
                else -- horizontal touch
                    dynamicSpriteBody:setVelocity(cc.p(0, velocity.y))
                end
                velocity = dynamicSprite:getPhysicsBody():getVelocity()
                cclog("velocity after contact x, y: %f, %f", velocity.x, velocity.y)
            elseif dynamicSprite:getTag() == TAG_LEADING_ROLE_ATTACK or 
                   dynamicSprite:getTag() == TAG_ENEMY_ATTACK then
                self:removeChild(dynamicSprite, true)
            end
        elseif s_isEnemy[a:getTag()] or s_isEnemy[b:getTag()] then
            local enemy, dynamicSprite
            if s_isEnemy[a:getTag()] then
                enemy = a 
                dynamicSprite = b    
            else
                enemy = b 
                dynamicSprite = a
            end
            if dynamicSprite:getTag() == TAG_LEADING_ROLE_ATTACK then
                self:removeChild(dynamicSprite, true)
                local curBlood = 0
                if enemy:getTag() == TAG_BOSS then
                    curBlood = self:changeBloodVolume(enemy, -10)
                elseif  enemy:getTag() == TAG_DOUGHBOY then 
                    curBlood = self:changeBloodVolume(enemy, -30) 
                end
                if curBlood <= 0 then --FIXME CURRENT
                    self:deathEffect(enemy)
                    if self.curEnemyNum > 1 then
                        self.curEnemyNum = self.curEnemyNum - 1
                    else -- win!
                        self:showConclusion("Win !")
                    end
                    --cancle the timer in case it will pause the action that delete the sprite
--                    s_scheduler:unscheduleScriptEntry(s_schedulerEntry1)  
                end
            end
        elseif a:getTag() == TAG_LEADING_ROLE or b:getTag() == TAG_LEADING_ROLE then
            local leadingRole, dynamicSprite
            if a:getTag() == TAG_LEADING_ROLE then
                leadingRole = a 
                dynamicSprite = b    
            else
                leadingRole = b 
                dynamicSprite = a
            end
            if dynamicSprite:getTag() == TAG_ENEMY_ATTACK then --FIXME add audio
                self:removeChild(dynamicSprite, true)
                local curBlood = self:changeBloodVolume(leadingRole, -10)
                if curBlood <= 0 then
                    self:deathEffect(leadingRole)
                    self:showConclusion("Game Over !")
                    -- remove enemy AI timer
                    s_scheduler:unscheduleScriptEntry(s_schedulerEntry1)
                end
            end
        end
    	return true
    end
    
    local function onContactEnd(contact)
        local a = contact:getShapeA():getBody():getNode()
        local b = contact:getShapeB():getBody():getNode()
        if a == nil or b == nil then return end
        if a:getTag() == TAG_MAP or b:getTag() == TAG_MAP then
            local map, dynamicSprite
            local isSwapped = false
            cclog("contact end")
            if a:getTag() == TAG_MAP then
                map = a 
                dynamicSprite = b    
            else
                map = b 
                dynamicSprite = a
                isSwapped = true  
            end
            if dynamicSprite:getTag() == TAG_LEADING_ROLE then
                cclog("stop all action of leadingRole when contact end") 
                dynamicSprite:stopAllActions()
                local contactNormal = contact:getContactData().normal
                cclog("onContactEnd original normal x, y: %f, %f", contactNormal.x, contactNormal.y)
                if contactNormal.y >= 0.1 or contactNormal.y <= -0.1 then
                    dynamicSprite:stopAllActions() 
                    if isSwapped then -- set the normal emit from map
                        contactNormal.y = -1 * contactNormal.y 
                    end
                    cclog("onContactEnd current normal y: %f",  contactNormal.y)
                    if contactNormal.y >= 0.1 then
                        self.isLeadingRoleOnTheGround = false
                    end
                end
            end
        end
        return true
    end
    local contactListener = cc.EventListenerPhysicsContact:create()
--    local contactListener = cc.EventListenerPhysicsContactWithBodies:create(leadingRole:getPhysicsBody(), 
--                            testSprite:getPhysicsBody())
    contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    contactListener:registerScriptHandler(onContactEnd, cc.Handler.EVENT_PHYSICS_CONTACT_SEPERATE)
    eventDispatcher:addEventListenerWithSceneGraphPriority(contactListener, self)
    
end

function AnimationLayer:setUpAttackForSprite(targetSprite, attack, directoinNum) 
    attack:getPhysicsBody():setGravityEnable(false)
    local lead_x, lead_y = targetSprite:getPosition()
    local leadSize = targetSprite:getContentSize()
    local attackPosi = cc.p(0, 0)
    local velocity = cc.p(0, 0)
    local ATTACK_OFFSET = 30
    if directoinNum == RIGHT then
        attack:setFlippedX(false)
        attackPosi.x = lead_x + leadSize.width/2 + attack:getContentSize().width/2 - ATTACK_OFFSET
        attackPosi.y = lead_y
        velocity = cc.p(ATTACK_SPEED, 0)  
    elseif directoinNum == DOWN then
        attack:setRotation(90)
        attackPosi.x = lead_x
        attackPosi.y = lead_y - leadSize.height/2 - attack:getContentSize().height/2 + ATTACK_OFFSET
        velocity = cc.p(0, -1*ATTACK_SPEED)
    elseif directoinNum == LEFT then
        attack:setFlippedX(true)
        attackPosi.x = lead_x - leadSize.width/2 - attack:getContentSize().width/2 + ATTACK_OFFSET
        attackPosi.y = lead_y
        velocity = cc.p(-1*ATTACK_SPEED, 0)
    elseif directoinNum == UP then
        attack:setRotation(-90)
        attackPosi.x = lead_x
        attackPosi.y = lead_y + leadSize.height/2 + attack:getContentSize().height/2
        velocity = cc.p(0, ATTACK_SPEED)
    elseif directoinNum == RIGHT_UP then
        attack:setRotation(-45)
        attackPosi.x = lead_x + leadSize.width/2 + 
            math.cos(45)*attack:getContentSize().width/2 - ATTACK_OFFSET*0.707
        attackPosi.y = lead_y + leadSize.height/2 +
            math.sin(45)*attack:getContentSize().width/2 - ATTACK_OFFSET*0.707
        velocity = cc.p(0.707*ATTACK_SPEED  , 0.707*ATTACK_SPEED) 
    elseif directoinNum == RIGHT_DOWN then
        attack:setRotation(45)
        attackPosi.x = lead_x + leadSize.width/2 + 
            math.cos(45)*attack:getContentSize().width/2 - ATTACK_OFFSET*0.707
        attackPosi.y = lead_y - leadSize.height/2 -
            math.sin(45)*attack:getContentSize().width/2 + ATTACK_OFFSET*0.707
        velocity = cc.p(0.707*ATTACK_SPEED  , -0.707*ATTACK_SPEED) 
    elseif directoinNum == LEFT_DOWN then
        attack:setRotation(135)
        attackPosi.x = lead_x - leadSize.width/2 - 
            math.cos(45)*attack:getContentSize().width/2 + ATTACK_OFFSET*0.707
        attackPosi.y = lead_y - leadSize.height/2 -
            math.sin(45)*attack:getContentSize().width/2 + ATTACK_OFFSET*0.707
        velocity = cc.p(-0.707*ATTACK_SPEED  , -0.707*ATTACK_SPEED) 
    elseif directoinNum == LEFT_UP then
        attack:setRotation(-135)
        attackPosi.x = lead_x - leadSize.width/2 - 
            math.cos(45)*attack:getContentSize().width/2 + ATTACK_OFFSET*0.707
        attackPosi.y = lead_y + leadSize.height/2 +
            math.sin(45)*attack:getContentSize().width/2 - ATTACK_OFFSET*0.707
        velocity = cc.p(-0.707*ATTACK_SPEED  , 0.707*ATTACK_SPEED) 
    end
    attack:getPhysicsBody():setVelocity(velocity) 
    attack:setPosition(attackPosi)
    self:addChild(attack) 
end

function AnimationLayer:executeAIForEnemy(enemy, leadingRole, attackSpriteFrameName) 
    local enemyBody = enemy:getPhysicsBody()
    local leadingRole_x, leadingRole_y = leadingRole:getPosition()
    local enemy_x, enemy_y = enemy:getPosition()
    local distance_x = leadingRole_x - enemy_x
    local distance_x_abs = math.abs(distance_x)
    local actionManager = cc.Director:getInstance():getActionManager()
    if distance_x >= 0 then
        enemy:setFlippedX(false)
    else
        enemy:setFlippedX(true)
    end
    if distance_x_abs > ATTACK_DISTANCE_X then -- move closer
        actionManager:resumeTarget(enemy)
        if distance_x >= 0 then
            enemyBody:setVelocity(cc.p(WALK_SPEED, 0))
        else
            enemyBody:setVelocity(cc.p(-1*WALK_SPEED, 0))
        end  
        
    else -- attack 
        enemyBody:setVelocity(cc.p(0, 0))
        actionManager:pauseTarget(enemy)
        local attack = cc.Sprite:createWithSpriteFrame(
            cc.SpriteFrameCache:getInstance():getSpriteFrame(attackSpriteFrameName))
        attack:setPhysicsBody(cc.PhysicsBody:createBox(
            cc.size(attack:getContentSize().width , attack:getContentSize().height)))
        attack:getPhysicsBody():setCategoryBitmask(8)
        attack:getPhysicsBody():setContactTestBitmask(1)
        attack:getPhysicsBody():setCollisionBitmask(0)
        attack:setTag(TAG_ENEMY_ATTACK)
        local distance_y_abs = math.abs(leadingRole_y - enemy_y)
        cclog("dis x: %f, dis y: %f", distance_x_abs, distance_y_abs)
        if distance_y_abs <=  ATTACK_Y_THRESHOLD then
            if distance_x >= 0 then
                self:setUpAttackForSprite(enemy, attack, RIGHT) 
            else
                self:setUpAttackForSprite(enemy, attack, LEFT) 
            end              
        else
            if enemy:getTag() == TAG_BOSS then
                if distance_x_abs <= ATTACK_DISTANCE_X_FOR_UP then
                    self:setUpAttackForSprite(enemy, attack, UP)
                else
                    if distance_x >= 0 then
                        self:setUpAttackForSprite(enemy, attack, RIGHT_UP) 
                    else
                        self:setUpAttackForSprite(enemy, attack, LEFT_UP) 
                    end 
                end
            end
        end                                                       
    end
end

function AnimationLayer:setUpBloodVolumeForRoles(targetSprite)
    local targetSize = targetSprite:getContentSize()
    local bloodBackGround = cc.Sprite:create("roles/blood_background.png")
    bloodBackGround:setPosition(targetSize.width/2 , targetSize.height+10)
    bloodBackGround:setScale(0.8, 0.6)
    targetSprite:addChild(bloodBackGround)
    local bloodVolume = cc.ProgressTimer:create(cc.Sprite:create("roles/blood_foreground.png"))
    bloodVolume:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    bloodVolume:setMidpoint(cc.p(0, 0))
    bloodVolume:setBarChangeRate(cc.p(1, 0))
    local to1 = cc.ProgressTo:create(0, 100)
    bloodVolume:runAction(to1)
    bloodVolume:setScale(0.8, 0.6)
    bloodVolume:setPosition(targetSize.width/2 , targetSize.height+10)
    targetSprite:addChild(bloodVolume)
    self.bloodVolumeTable[targetSprite] = {["progressTimer"] = bloodVolume, ["curBlood"] = 100}
end

function AnimationLayer:getBloodVolumeInfo(targetSprite)
    return self.bloodVolumeTable[targetSprite]
end

function AnimationLayer:changeBloodVolume(targetSprite, delta)
    local bloodVolumeInfo = self:getBloodVolumeInfo(targetSprite)
    local to1 = cc.ProgressFromTo:create(1, bloodVolumeInfo.curBlood,
        bloodVolumeInfo.curBlood+ delta)
    bloodVolumeInfo.curBlood = bloodVolumeInfo.curBlood+delta          
    bloodVolumeInfo.progressTimer:runAction(to1)
    return bloodVolumeInfo.curBlood
end

function AnimationLayer:deathEffect(targetSprite)
--    targetSprite:getPhysicsBody():setDynamic(false)
    targetSprite:getPhysicsBody():setContactTestBitmask(1)
    targetSprite:stopAllActions()
    local action1 = cc.Blink:create(1, 3)
    local function deleteSprite()
        self:removeChild(targetSprite, true)	
    end
    local callfunc = cc.CallFunc:create(deleteSprite)
    local sequence = cc.Sequence:create(action1, callfunc)
    targetSprite:runAction(sequence)  
end

function AnimationLayer:setUpEnemy(filePath,spriteTag, spriteSize, intialSpritePosi)
    local enemy_altas = cc.Sprite:create(filePath):getTexture()
    local enemyForwardFrames = {}
    for i = 1, 4 do
        enemyForwardFrames[i] = cc.SpriteFrame:createWithTexture(enemy_altas, 
            cc.rect((i-1)*spriteSize.width, 2*spriteSize.height, spriteSize.width, spriteSize.height))
    end
    local enemy = cc.Sprite:createWithSpriteFrame(enemyForwardFrames[1])
    enemy:setFlippedX(true)
    enemy:setPosition(intialSpritePosi.x, intialSpritePosi.y)
    enemy:setTag(spriteTag)
    enemy:setPhysicsBody(cc.PhysicsBody:createBox(enemy:getContentSize()))
    local enemyBody =  enemy:getPhysicsBody()
    enemyBody:setRotationEnable(false)
    enemyBody:setCategoryBitmask(2)
    enemyBody:setContactTestBitmask(4)
    enemyBody:setCollisionBitmask(4)
    enemyBody:getShape(0):setFriction(0)
    --add run action 
    local animation = cc.Animation:createWithSpriteFrames(enemyForwardFrames, 0.15, -1)
    local forward = cc.Animate:create(animation)
    enemy:runAction(forward)
    local actionManager = cc.Director:getInstance():getActionManager()
    actionManager:pauseTarget(enemy)
    self:addChild(enemy)
    self:setUpBloodVolumeForRoles(enemy)
    return enemy
end

function AnimationLayer:showConclusion(wordStr)
    local label = cc.LabelBMFont:create(wordStr, "fonts/bitmapFontTest.fnt")
    label:setPosition(cc.p(self.visibleSize.width/2, self.visibleSize.height/2+20) )
    label:setAnchorPoint(cc.p(0.5, 0.5))
    local scale = cc.ScaleBy:create(2, 1.5)
    label:runAction(scale)
    self:addChild(label)
end

return AnimationLayer