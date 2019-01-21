
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local utils = require "utils"
local scheduler = require ("scheduler") -- 定时器
local json = require "json"
local Board = require "Board"
local Storage = require "storage"
local GameConfig = require "GameConfig"
local UserProfile = require "UserProfile"
local GameMusic = require "GameMusic"

local HomeScene
local LoginScene
local RegScene
local BoardLayer 
local ScoreLayer
local ResetLayer

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
local MaxScore = 0 -- 历史最高分
local CurScore = 0 -- 当前分数 
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
	BoardLayer:addChild(draw, 1)
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
	CurScore = 0 
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
	local url = string.format('http://%s:%d/GetRankList?appid=1&data={"uid":%d,"startindex":%d,"endindex":%d}', GameConfig.RankSrvIp, GameConfig.RankSrvPort, UserProfile.uid or 0, 1, 10)
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
					MyRankLabel:setString(tostring(myrank))
				end
			end
		end 
	end
	xhr:registerScriptHandler(onResponse)	--注册脚本方式回调
	xhr:send()	--发送 
end 

local function CommitData2RankServer(score)
	local xhr = cc.XMLHttpRequest:new()	--http请求
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON	--请求类型
	local url = string.format('http://%s:%d/CommitData?appid=1&data={"uid":%d,"name":"%s","headIcon":"%s","score":%d}', GameConfig.RankSrvIp, GameConfig.RankSrvPort, UserProfile.uid, UserProfile.name, UserProfile.headIcon, score)
	print("CommitData2RankServer usrl ", url)
	xhr:open("GET", url)
	local function onResponse()
		local str = xhr.response	--获得返回数据
		print("CommitData2RankServer resp", str)
		local data = json.decode(str)
		if data.status == 0 then 
			print("CommitData2RankServer ok!", score)
			GetRankList()
		end 
	end
	xhr:registerScriptHandler(onResponse)	--注册脚本方式回调
	xhr:send()	--发送
end 

local function saveBoardData()
	Storage.setTable("boarddata", Board.GetBoardData())
	if CurScore >= MaxScore then 
		MaxScore = CurScore
		if UserProfile.uid then 
			CommitData2RankServer(MaxScore)
		end 	
	end	
	Storage.setInt("maxScore", MaxScore)
	Storage.setInt("curScore", CurScore)
end

function MainScene:AfterOperate(num, move)
	if move then 
		self:DrawBoard()
		self:RefreshScoreLayer()
		-- 新出来的数字 延迟0.5s显示
		scheduler.performWithDelayGlobal(function() self:AddNum(num) end, 0.3) -- 定时器:只执行一次
	else 
		if Board.isBoardEnd() then -- 重置确认弹框
			if not ResetLayer then 	
				ResetLayer = cc.CSLoader:createNode("Reset.csb")
				ResetLayer:move(display.height/2 - 250, display.height/2 - 250)
				ResetLayer:addTo(self, 200)
			else 	
				ResetLayer:setVisible(true)
			end	

			local startBtn = ResetLayer:getChildByName("btn_start")
			startBtn:addTouchEventListener(function(sender,eventType)
				if eventType == ccui.TouchEventType.ended then
					self:ResetBoard()
					ResetLayer:setVisible(false)
				end
			end)
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
	local account =	Storage.getString("account")
	if account then 
		UserProfile.name = account 
	end 	
	local password = Storage.getString("password")
	if password then 
		UserProfile.password = password 
	end 
	
	if account and password then 
		HomeScene:setVisible(false)
		LoginScene:setVisible(true)
		LoginScene:getChildByName("TextField_account"):setString(account)
		LoginScene:getChildByName("TextField_password"):setString(password)
	end

	MaxScore = Storage.getInt("maxScore", 0) -- fixme: 增加用户注册登录后 如果没有取到 则取账号服数据
	CurScore = Storage.getInt("curScore", 0) -- 当前分数 取本地分数
	Board.SetBoardData(Storage.getTable("boarddata"))
	MusicFlag = Storage.getBool("music", true) -- 首次打开是开启的
	SetMusicSwitch(MusicFlag)
end

function MainScene:RefreshScoreLayer()
	if MaxScore < CurScore then 
		MaxScore = CurScore
	end	

	MaxScoreLabel:setString(tostring(MaxScore))
	CurScoreLabel:setString(tostring(CurScore))
end

local function InitScoreLayer()
	local MaxStaticLabel = cc.Label:createWithSystemFont("历史纪录", "Arial", 35)
	MaxStaticLabel:move((display.width - display.height)/2, display.height - 1*rectLen) -- 此处是相对scoreLayer左下角的位置
	MaxStaticLabel:addTo(ScoreLayer) 	
	
	MaxScoreLabel = ccui.TextBMFont:create()
    MaxScoreLabel:move((display.width - display.height)/2, display.height - 1.5*rectLen)
    MaxScoreLabel:addTo(ScoreLayer)
	MaxScoreLabel:setFntFile("font_number.fnt")
	MaxScoreLabel:setString(tostring(MaxScore))

	local CurStaticLabel = cc.Label:createWithSystemFont("当前分数", "Arial", 35)
	CurStaticLabel:move((display.width - display.height)/2, display.height - 2*rectLen) -- 此处是相对scoreLayer左下角的位置
	CurStaticLabel:addTo(ScoreLayer) 	

	CurScoreLabel = ccui.TextBMFont:create()
    CurScoreLabel:move((display.width - display.height)/2, display.height - 2.5*rectLen)
    CurScoreLabel:addTo(ScoreLayer)
	CurScoreLabel:setFntFile("font_number.fnt")
	CurScoreLabel:setString(tostring(CurScore))
	
	local MyRankStaticLable = cc.Label:createWithSystemFont("我的排名", "Arial", 35)
	MyRankStaticLable:move((display.width - display.height)/2, display.height - 3*rectLen) -- 此处是相对scoreLayer左下角的位置
	MyRankStaticLable:addTo(ScoreLayer) 
	
	MyRankLabel = ccui.TextBMFont:create()
    MyRankLabel:move((display.width - display.height)/2, display.height - 3.5*rectLen)
    MyRankLabel:addTo(ScoreLayer)
	MyRankLabel:setFntFile("font_number.fnt")
	MyRankLabel:setString(tostring(0))
end

function MainScene:InitBoard()
	local color = cc.c4b(130, 36, 94, 255)
    BoardLayer = cc.LayerColor:create(color)
	BoardLayer:setContentSize(cc.size(display.height, display.height))
	BoardLayer:setPosition(cc.p(0, 0))
	BoardLayer:setVisible(false)
	self:addChild(BoardLayer, 1)
	
    ScoreLayer = cc.LayerColor:create(color)
	ScoreLayer:setContentSize(cc.size(display.width - display.height, display.height))
	ScoreLayer:setPosition(cc.p(display.height, 0))
	ScoreLayer:setVisible(false)
	self:addChild(ScoreLayer, 1)

	InitNumLabels()
	InitScoreLayer()	
	self:DrawBoard()
	if not Board.GetBoardData() then 
		self:ResetBoard()
	end
	
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
	local mergeScore = 0
	local beforeMaxNum = Board.GetMaxNum()
	if math.abs(endX) > math.abs(endY) then 
		if math.abs(endX) > 5 then -- 滑动太少不算
			if endX > 0 then 
				 flag, mergeScore = Board.OnLeft()
			else 
				flag, mergeScore = Board.OnRight()
			end
		end		
	else 
		if math.abs(endY) > 5 then -- 滑动太少不算
			if endY > 0 then 
				flag, mergeScore = Board.OnDown()
			else 
				flag, mergeScore = Board.OnUp()
			end	
		end	
	end
	
	if flag then 
		local afterMaxNum, idx, idy = Board.GetMaxNum() 
		if afterMaxNum > beforeMaxNum and afterMaxNum >= 4 then 
			--local particle = cc.ParticleSystemQuad:create("defaultParticle.plist") --自定义粒子效果
			local particle = cc.ParticleExplosion:create() -- 默认粒子效果
			local cx = (idx-1)*rectLen +rectLen/2 
			local cy = (idy-1)*rectLen +rectLen/2 
			particle:move(cx, cy)
			BoardLayer:addChild(particle)
			scheduler.performWithDelayGlobal(function() particle:removeFromParent() end, 1) -- 定时器:只执行一次

			GameMusic.playEffect("merge_special.mp3")
		else
			GameMusic.playEffect("merge_normal.mp3")
		end
	end

	CurScore = CurScore + mergeScore -- 分数增加
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

local function LoginCommit2AccountServer(account, password)
	local xhr = cc.XMLHttpRequest:new()	--http请求
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON	--请求类型
	local url = string.format('http://%s:%d/login?appid=1&data={"account":"%s","password":"%s"}', GameConfig.AccountSrvIp, GameConfig.AccountSrvPort, account, password)
	print("LoginCommit2AccountServer url ", url)
	xhr:open("GET", url)
	local function onResponse()
		local str = xhr.response	--获得返回数据
		print("LoginCommit2AccountServer resp", str)
		local data = json.decode(str)
		if data.status == 0 then 
			print("Login ok!", account, data.session)
			UserProfile.uid = data.uid
			UserProfile.name = account
			if not Storage.getString("account") then 
				Storage.setString("account", account)
			end 
			if not Storage.getString("password") then 
				Storage.setString("password", password)
			end
			LoginScene:setVisible(false)
			GetRankList()
			BoardLayer:setVisible(true)
			ScoreLayer:setVisible(true)
		end
	end
	xhr:registerScriptHandler(onResponse)	--注册脚本方式回调
	xhr:send()	--发送
end

local function RegCommit2AccountServer(account, password)
	local xhr = cc.XMLHttpRequest:new()	--http请求
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON	--请求类型
	local url = string.format('http://%s:%d/register?appid=1&data={"account":"%s","password":"%s"}', GameConfig.AccountSrvIp, GameConfig.AccountSrvPort, account, password)
	print("RegCommit2AccountServer url ", url)
	xhr:open("GET", url)
	local function onResponse()
		local str = xhr.response	--获得返回数据
		print("RegCommit2AccountServer resp", str)
		local data = json.decode(str)
		if data.status == 0 then 
			print("Reg ok!", account, password)
			UserProfile.name = account
			Storage.setString("account", account)
			LoginScene:getChildByName("TextField_account"):setString(account)
			Storage.setString("password", password)
			LoginScene:getChildByName("TextField_password"):setString(password)
			RegScene:setVisible(false)
			LoginScene:setVisible(true)
		end
	end
	xhr:registerScriptHandler(onResponse)	--注册脚本方式回调
	xhr:send()	--发送
end

function MainScene:onCreate()
	HomeScene = cc.CSLoader:createNode("Home.csb")
	HomeScene:move(0,0)
	HomeScene:addTo(self, 110)
	
	RegScene = cc.CSLoader:createNode("Reg.csb")
	RegScene:setVisible(false)
	RegScene:move(0,0)
	RegScene:addTo(self, 110)
	
	LoginScene = cc.CSLoader:createNode("Login.csb")
	LoginScene:setVisible(false)
	LoginScene:move(0,0)
	LoginScene:addTo(self, 110)

	local regBtn = HomeScene:getChildByName("btn_reg")
	regBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			HomeScene:setVisible(false)
			RegScene:setVisible(true)
		end
	end)

	local loginBtn = HomeScene:getChildByName("btn_login")
	loginBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			HomeScene:setVisible(false)
			LoginScene:setVisible(true)
		end
	end)

	local loginConfirmBtn = LoginScene:getChildByName("btn_confirm")
	loginConfirmBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			local account = LoginScene:getChildByName("TextField_account"):getString() -- trim / check
			local password = LoginScene:getChildByName("TextField_password"):getString() -- trim / check
			LoginCommit2AccountServer(account, password)
		end
	end)

	local regConfirmBtn = RegScene:getChildByName("Panel_5"):getChildByName("btn_confirm")
	regConfirmBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			RegScene:getChildByName("Panel_5"):getChildByName("Text_2"):setVisible(false) -- 目前放这 后续改到填完密码的回调
			local account = RegScene:getChildByName("Panel_5"):getChildByName("TextField_account"):getString() -- trim / check
			local password = RegScene:getChildByName("Panel_5"):getChildByName("TextField_password"):getString() -- trim / check
			local password2 = RegScene:getChildByName("Panel_5"):getChildByName("TextField_password2"):getString() -- trim / check
			if password ~= password2 then 
				RegScene:getChildByName("Panel_5"):getChildByName("Text_2"):setVisible(true)
			else 
				RegCommit2AccountServer(account, password)
			end	
		end
	end)

	local loginBackBtn = LoginScene:getChildByName("btn_back")
	loginBackBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			HomeScene:setVisible(true)
			LoginScene:setVisible(false)
		end
	end)

	local regBackBtn = RegScene:getChildByName("btn_back")
	regBackBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			HomeScene:setVisible(true)
			RegScene:setVisible(false)
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
	resetBtn:addTo(self, 10)
	
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
	rankBtn:addTo(self, 10)
	
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
	soundBtn:addTo(self, 10)

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
	settingBtn:addTo(self, 10)
	
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
