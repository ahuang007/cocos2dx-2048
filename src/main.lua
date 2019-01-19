
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")
cc.FileUtils:getInstance():addSearchPath("src/app/common/")
cc.FileUtils:getInstance():addSearchPath("src/app/games/2048/")
cc.FileUtils:getInstance():addSearchPath("res/Default/")
cc.FileUtils:getInstance():addSearchPath("res/csb/")
cc.FileUtils:getInstance():addSearchPath("res/image/")
cc.FileUtils:getInstance():addSearchPath("res/music/")

require "config"
require "cocos.init"

local function main()
    require("app.MyApp"):create():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
