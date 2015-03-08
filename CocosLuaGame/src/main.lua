
cc.FileUtils:getInstance():addSearchPath("src")
cc.FileUtils:getInstance():addSearchPath("res")

-- CC_USE_DEPRECATED_API = true
require "cocos.init"
require("Helper")

-- cclog
--local cclog = function(...)
--    print(string.format(...))
--end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
    return msg
end

local function test()
    Hello = class("Hello")
    function Hello:ctor()
        self.name = 'aaaa'
        self.age = 21
    end
    hello = Hello.new()
    print(hello.name)
    print(hello.age)
end

local function main()
    
--    test()
    
    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    -- initialize director
    local director = cc.Director:getInstance()

    --turn on display FPS
--    director:setDisplayStats(true)

    --set FPS. the default value is 1.0/60 if you don't call this
    director:setAnimationInterval(1.0 / 60)
    
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(480, 320, 0)
    
--    local openglView = cc.Director:getInstance():getOpenGLView()
--    print(openglView:getVisibleSize().height)
--    print(openglView:getVisibleSize().width)
    
    --create scene 
--    local scene = require("GameScene")
--    local scene = require("MainScene")
    local scene = require("MainMenuScene")
    local gameScene = scene.create()
    
    if cc.Director:getInstance():getRunningScene() then
        cc.Director:getInstance():replaceScene(gameScene)
    else
        cc.Director:getInstance():runWithScene(gameScene)
    end

end


local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end
