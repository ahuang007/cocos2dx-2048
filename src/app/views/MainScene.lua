
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local utils = require "utils"
local scheduler = require ("scheduler") -- 定时器
local json = require "json"
local Board = require "Board"
local Storage = require "Storage"
local GameConfig = require "GameConfig"
local UserProfile = require "UserProfile"
local GameMusic = require "GameMusic"

local BoardLayer 
local ScoreLayer
local MaxScoreLabel
local CurScoreLabel
local OverLabel
local soundBtn

local rankFlag = false
local rankLayer
local ranklist = {}
local myrank = 0
local MyRankLabel
local MusicFlag = true
local SettingFlag = false

local rectLen = display.height/4 -- 单元格长度
local Num2Color = GameConfig.Num2Color -- 数字颜色
local MaxScore = 0
local NumLabels = {} -- 数字组件

local function createNum(idx, idy)
	local cx = (idx-1)*rectLen +rectLen/2 
	local cy = (idy-1)*rectLen +rectLen/2 
	local label = cc.Label:createWithSystemFont("", "Arial", 40)
	label:move(cx, cy)
	label:addTo(BoardLayer) 	
	return label
end

local function createLine(x1, y1, x2, y2)	
	local draw = cc.DrawNode:create()
	draw:drawSegment(cc.p(x1, y1), cc.p(x2,y2), 4, cc.c4f(1,1,0,1)) --  ('起点' , '终点' , '半线宽' , '填充颜色')
	BoardLayer:addChild(draw)
end

local function InitNumLabels()
	for i = 1, 5 do -- 5竖
		createLine((i-1)*rectLen, 0, (i-1)*rectLen, display.height)
	end
	
	for j = 1, 5 do -- 5横
		createLine(0, (j-1)*rectLen, display.height, (j-1)*rectLen)
	end

	for i = 1, 4 do 
		NumLabels[i] = {}
		for j = 1, 4 do
			NumLabels[i][j] = createNum(i, j)
		end
	end
end	


function MainScene:DrawBoard()
	local boarddata = Board.GetBoardData()
	if not boarddata then return end 
	
	for i = 1, 4 do 
		for j = 1, 4 do 
			local num = boarddata[i][j]
			local numLabel = NumLabels[i][j]
			if num > 0 then 
				local rgbArr
				if num >= 4096 then 
					rgbArr = Num2Color[4096]
				else 
					rgbArr = Num2Color[num]
				end
				numLabel:setColor(cc.c4b(rgbArr[1], rgbArr[2], rgbArr[3], 100))
				numLabel:setString(tonumber(num))
			else 
				numLabel:setString("")
			end
		end
	end	
end

function MainScene:ResetBoard()
	if OverLabel then 
		OverLabel:setString("")
	end	
	Board.InitBoardData()
	self:AfterOperate(2, true)
end

function MainScene:AddNum(num)
	if Board.GetNumCount() < 16 then 
		Board.GenNewNum(num)
		self:DrawBoard()
	end
end

local function GetRankList()
	local xhr = cc.XMLHttpRequest:new()	--http请求
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON	--请求类型
	local url = string.format('http://%s:%d/GetRankList?appid=1&data={"uid":%d,"startindex":%d,"endindex":%d}', 
	GameConfig.RankSrvIp, GameConfig.RankSrvPort, UserProfile.uid, 1, 10)
	print("GetRankList url ", url)
	xhr:open("GET", url)
	local function onResponse()
		local str = xhr.response	--获得返回数据
		print("GetRankList resp", str)
		local data = json.decode(str)
		if data.status == 0 then 
			ranklist = data.lists
			for i, v in ipairs(ranklist) do 
				print("ranlist ", v.uid, v.rank, v.name, v.score)
				if v.uid == UserProfile.uid then 
					myrank = v.rank
					local str = (myrank == 0 and "未上榜" or tostring(myrank))
					MyRankLabel:setString(str)
				end
			end
		end 
	end
	xhr:registerScriptHandler(onResponse)	--注册脚本方式回调
	xhr:send()	--发送 
end 

local function CommitData2Server(score)
	local xhr = cc.XMLHttpRequest:new()	--http请求
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON	--请求类型
	local url = string.format('http://%s:%d/CommitData?appid=1&data={"uid":%d,"name":"%s","headIcon":"%s","score":%d}', 
	GameConfig.RankSrvIp, GameConfig.RankSrvPort, UserProfile.uid, UserProfile.name, UserProfile.headIcon, score)
	print("commitdata usrl ", url)
	xhr:open("GET", url)
	local function onResponse()
		local str = xhr.response	--获得返回数据
		print("CommitData2Server resp", str)
		local data = json.decode(str)
		if data.status == 0 then 
			print("commitdata ok!", score)
			GetRankList()
		end 
	end
	xhr:registerScriptHandler(onResponse)	--注册脚本方式回调
	xhr:send()	--发送
end 

local function saveBoardData()
	Storage.setTable("boarddata", Board.GetBoardData())
	local curMaxScore = Board.GetTotalScore()
	if curMaxScore > MaxScore then 
		MaxScore = curMaxScore
		CommitData2Server(MaxScore)
	end	
	Storage.setInt("maxScore", MaxScore)
end

function MainScene:AfterOperate(num, move)
	if move then 
		self:DrawBoard()
		self:RefreshScoreLayer()
		-- 新出来的数字 延迟0.5s显示
		scheduler.performWithDelayGlobal(function() self:AddNum(num) end, 0.5) -- 定时器:只执行一次
	else 
		if Board.isBoardEnd() then -- todo: 重置确认弹框
			print("2048 game is over, Do you want to reset ? ")	
			if not OverLabel then 
				OverLabel = cc.Label:createWithSystemFont("GAME OVER", "Arial", 60)
				OverLabel:move(display.height/2, display.height/2)
				local color = cc.c4b(0, 0, 0, 100)
				OverLabel:setColor(color)
				OverLabel:addTo(BoardLayer)			
			else
				OverLabel:setString("GAME OVER")
			end
			
			local curScore = Board.GetTotalScore()
			if curScore >= MaxScore then 
				MaxScore = curScore
				saveBoardData()
				CommitData2Server(MaxScore)
			end
		end
	end
end

local function SetMusicSwitch(flag)
	GameMusic.setEffectSwitch(flag)
	GameMusic.setMusicSwitch(flag)
	if flag then 
		soundBtn:loadTextures("sound.png", "sound.png")
		GameMusic.resumeMusic()	
	else 
		soundBtn:loadTextures("sound_off.png", "sound_off.png")
		GameMusic.pauseMusic()	
	end	
	Storage.setBool("music", flag)
end	

function MainScene:LoadUserData()
	MaxScore = Storage.getInt("maxscore") -- todo: 增加用户注册登录后 如果没有取到 则到排行榜取
	local boarddata = Storage.getTable("boarddata")
	Board.SetBoardData(boarddata)
	MusicFlag = Storage.getBool("music", true) -- 首次打开是开启的
	SetMusicSwitch(MusicFlag)
end

function MainScene:RefreshScoreLayer()
	local curMaxScore = Board.GetTotalScore()
	if MaxScore < curMaxScore then 
		MaxScore = curMaxScore
	end	
	MaxScoreLabel:setString(tostring(MaxScore))
	CurScoreLabel:setString(tostring(curMaxScore))
end

local function InitScoreLayer()
	local MaxStaticLabel = cc.Label:createWithSystemFont("历史纪录", "Arial", 35)
	MaxStaticLabel:move((display.width - display.height)/2, display.height - 1*rectLen) -- 此处是相对scoreLayer左下角的位置
	MaxStaticLabel:addTo(ScoreLayer) 	
	
	MaxScoreLabel = cc.Label:createWithSystemFont(tostring(MaxScore), "Arial", 35)
	MaxScoreLabel:move((display.width - display.height)/2, display.height - 1.5*rectLen) 
	MaxScoreLabel:addTo(ScoreLayer) 	
	
	local CurStaticLabel = cc.Label:createWithSystemFont("当前分数", "Arial", 35)
	CurStaticLabel:move((display.width - display.height)/2, display.height - 2*rectLen) -- 此处是相对scoreLayer左下角的位置
	CurStaticLabel:addTo(ScoreLayer) 	

	CurScoreLabel = cc.Label:createWithSystemFont(tostring(Board.GetTotalScore()), "Arial", 35)
	CurScoreLabel:move((display.width - display.height)/2, display.height - 2.5*rectLen)
	CurScoreLabel:addTo(ScoreLayer)
	
	local MyRankStaticLable = cc.Label:createWithSystemFont("我的排名", "Arial", 35)
	MyRankStaticLable:move((display.width - display.height)/2, display.height - 3*rectLen) -- 此处是相对scoreLayer左下角的位置
	MyRankStaticLable:addTo(ScoreLayer) 
	
	MyRankLabel = cc.Label:createWithSystemFont("", "Arial", 35)
	MyRankLabel:move((display.width - display.height)/2, display.height - 3.5*rectLen) -- 此处是相对scoreLayer左下角的位置
	MyRankLabel:addTo(ScoreLayer) 
end

function MainScene:InitBoard()
	local color = cc.c4b(255, 255, 0, 50)
    BoardLayer = cc.LayerColor:create(color)
	BoardLayer:setContentSize(cc.size(display.height, display.height))
	BoardLayer:setPosition(cc.p(0, 0))
	self:addChild(BoardLayer, 1)
	
	local color1 = cc.c4b(255, 255, 0, 100)
    ScoreLayer = cc.LayerColor:create(color1)
	ScoreLayer:setContentSize(cc.size(display.width - display.height, display.height))
	ScoreLayer:setPosition(cc.p(display.height, 0))
	self:addChild(ScoreLayer)

	InitNumLabels()
	InitScoreLayer()	
	self:DrawBoard()
	if not Board.GetBoardData() then 
		self:ResetBoard()
	end
	
	GetRankList()
	
	GameMusic.playMusic("music_bg.mp3", true)
end

local firstX = 0
local firstY = 0
function MainScene:onTouchBegan(touch, event)
	-- 纪录触摸起始点坐标
	local beginPoint = touch:getLocation()
	firstX = beginPoint.x
	firstY = beginPoint.y
	if rankFlag then return false end 
	return true
end 

function MainScene:onTouchMoved(touch, event)
	return true
end 


function MainScene:onTouchEnded(touch, event)
	-- 纪录触摸终点坐标
	local endPoint = touch:getLocation()
	local endX = firstX - endPoint.x
	local endY = firstY - endPoint.y

	-- 看是横向移动大还是纵向滑动大
	local flag = false -- 滑动后发现有合并的 则新增数字
	local beforeMaxNum = Board.GetMaxNum()
	if math.abs(endX) > math.abs(endY) then 
		if math.abs(endX) > 5 then -- 滑动太少不算
			if endX > 0 then 
				 flag = Board.OnLeft()
			else 
				flag = Board.OnRight()
			end
		end		
	else 
		if math.abs(endY) > 5 then -- 滑动太少不算
			if endY > 0 then 
				flag = Board.OnDown()
			else 
				flag = Board.OnUp()
			end	
		end	
	end
	
	if flag then 
		local afterMaxNum = Board.GetMaxNum() 
		if afterMaxNum > beforeMaxNum and afterMaxNum >= 128 then 
			GameMusic.playEffect("merge_special.mp3")
		else
			GameMusic.playEffect("merge_normal.mp3")
		end
	end
	
	self:AfterOperate(1, flag)
end

function MainScene:onTouchCancelled(touch, event)
end

local function onRelease(keyCode, event)
	if keyCode == cc.KeyCode.KEY_BACK then	
		saveBoardData()
		cc.Director:getInstance():endToLua()
	elseif keyCode == cc.KeyCode.KEY_HOME or keyCode == cc.KeyCode.KEY_BACKSPACE then
		saveBoardData()
	elseif keyCode == cc.KeyCode.KEY_Q then
		saveBoardData()
		cc.Director:getInstance():endToLua()
	end
end

function MainScene:onCreate()
	local welcomeSprite = display.newSprite("welcome.jpg")
    welcomeSprite:move(display.center)
    welcomeSprite:addTo(self, 100)
	scheduler.performWithDelayGlobal(function() welcomeSprite:removeFromParent(true) end, 1.5) -- 欢迎界面1s消失

	local MainScene = cc.CSLoader:createNode("MainScene.csb")
	local RegScene
	local LoginScene
	MainScene:move(0,0)
	MainScene:addTo(self, 110)
	local regBtn = MainScene:getChildByName("btn_reg")
	regBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			MainScene:setVisible(false)
			RegScene = cc.CSLoader:createNode("Reg.csb")
			RegScene:move(0,0)
			RegScene:addTo(self, 110)
		end
	end)
	local loginBtn = MainScene:getChildByName("btn_login")
	loginBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			MainScene:setVisible(false)
			LoginScene = cc.CSLoader:createNode("Login.csb")
			LoginScene:move(0,0)
			LoginScene:addTo(self, 110)
		end
	end)

	
	local resetBtn = ccui.Button:create("reset.png", "reset2.png", "reset.png")
	resetBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			self:ResetBoard()
		end
    end)
	resetBtn:setPosition(display.width - 35, display.height - 105)
	resetBtn:setVisible(false)
	resetBtn:addTo(self)
	
	local rankBtn = ccui.Button:create("rank_open.png", "rank_open.png", "rank_open.png")
	rankBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			if not rankFlag then 
				rankFlag = true 
			
				if not rankLayer then 
					local color = cc.c4b(255, 0, 255, 255)
					rankLayer = cc.LayerColor:create(color)
					rankLayer:setContentSize(cc.size(display.height, display.height))
					rankLayer:setPosition(cc.p(0, 0))
					self:addChild(rankLayer, 10)
					
					for i = 1, 11 do
						for j = 1, 4 do 
							local label = cc.Label:createWithSystemFont("", "Arial", 25)
							label:setContentSize(cc.size(display.height/4, display.height/11))
							label:setPosition(cc.p((j-1)*(display.height/4) + display.height/8, (11-i)*(display.height/11) + display.height/22))
							rankLayer:addChild(label)
							
							if i == 1 then
								if j == 1 then 
									label:setString("排名")
								elseif j == 2 then 
									label:setString("ID")
								elseif j == 3 then 
									label:setString("昵称")
								elseif j == 4 then 
									label:setString("分数")
								end 
							else
								local userdata = ranklist[i-1]
								if userdata.uid == UserProfile.uid then 
									local color = cc.c4b(0, 0, 0, 255)
									label:setColor(color)
								end	

								if j == 1 then 
									label:setString(tostring(i-1))
								elseif j == 2 then 
									label:setString(tostring(userdata.uid))
								elseif j == 3 then 
									label:setString(tostring(userdata.name))
								elseif j == 4 then 
									label:setString(tostring(userdata.score))
								end 							
							end							
						end
					end
				else
					rankLayer:setVisible(true)
				end 
				
				rankBtn:loadTextures("rank_close.png", "rank_close.png");
			else
				rankFlag = false 
				rankLayer:setVisible(false)
				rankBtn:loadTextures("rank_open.png", "rank_open.png");
			end 
		end
    end)
	rankBtn:setPosition(display.width - 35, display.height - 175)
	rankBtn:setVisible(false)
	rankBtn:addTo(self)
	
	soundBtn = ccui.Button:create("sound.png", "sound_off.png", "sound.png")
	soundBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			if MusicFlag then 
				MusicFlag = false 				
			else
				MusicFlag = true 
			end 
			SetMusicSwitch(MusicFlag)
		end
    end)
	soundBtn:setPosition(display.width - 35, display.height - 245)
	soundBtn:setVisible(false)
	soundBtn:addTo(self)

	local settingBtn = ccui.Button:create("btn_setting.png", "btn_setting.png", "btn_setting.png")
	settingBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			if not SettingFlag then 
				SettingFlag = true
				resetBtn:setVisible(true)
				rankBtn:setVisible(true)
				soundBtn:setVisible(true)
			else 
				SettingFlag = false	
				resetBtn:setVisible(false)
				rankBtn:setVisible(false)
				soundBtn:setVisible(false)
			end
		end
    end)
	settingBtn:setPosition(display.width - 35, display.height - 35)
	settingBtn:addTo(self)
	
	self:LoadUserData()
	self:InitBoard()
	
	local dispatcher = cc.Director:getInstance():getEventDispatcher()

	-- 键盘事件
	local listener = cc.EventListenerKeyboard:create()
	listener:registerScriptHandler(onRelease, cc.Handler.EVENT_KEYBOARD_RELEASED) -- 响应安卓返回键
	dispatcher:addEventListenerWithSceneGraphPriority(listener, self)
		
	-- 触摸事件
	local listener1 = cc.EventListenerTouchOneByOne:create()
	listener1:registerScriptHandler(function(touch, event) return self:onTouchBegan(touch, event) end, cc.Handler.EVENT_TOUCH_BEGAN)
	listener1:registerScriptHandler(function(touch, event) return self:onTouchMoved(touch, event) end, cc.Handler.EVENT_TOUCH_MOVED)
	listener1:registerScriptHandler(function(touch, event) return self:onTouchEnded(touch, event) end, cc.Handler.EVENT_TOUCH_ENDED)
	listener1:registerScriptHandler(function(touch, event) return self:onTouchCancelled(touch, event) end, cc.Handler.EVENT_TOUCH_CANCELLED)
	dispatcher:addEventListenerWithSceneGraphPriority(listener1, self)
end

return MainScene
