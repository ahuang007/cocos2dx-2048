
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
local SettingLayer
local TipsLayer

local MaxScoreLabel
local CurScoreLabel

local rankFlag = false
local rankLayer
local ranklist = {}
local rankItems = {} -- 排行榜列表控件
local rankLayouts = {}
local myrank = 0
local MyRankLabel
local MusicFlag = true
local EffectFlag = true
local SettingFlag = false

local rectLen = display.height/4 -- 单元格长度
local Num2Color = GameConfig.Num2Color -- 数字颜色
local MaxScore = 0 -- 历史最高分
local CurScore = 0 -- 当前分数 
local NumLabels = {} -- 数字组件
local NumBgRects = {} -- 数字背景色矩形框

local function createNum(idx, idy)
	local cx = (idx-1)*rectLen +rectLen/2 
	local cy = (idy-1)*rectLen +rectLen/2 
	local label = cc.Label:createWithSystemFont("", "Arial", 60)
	label:move(cx, cy)
	label:addTo(BoardLayer, 2) 	
	return label
end

local function createLine(x1, y1, x2, y2, linewidth)	
	local line = cc.DrawNode:create()
	-- rgba: cc.c4b(210, 180, 152, 255)
	line:drawSegment(cc.p(x1, y1), cc.p(x2,y2), linewidth, cc.c4f(0.82, 0.7, 0.6, 1)) --  ('起点' , '终点' , '半线宽' , '填充颜色')
	BoardLayer:addChild(line, 3)
end

local function creatRect(idx, idy)
	local rect = cc.DrawNode:create()
	-- rgba: cc.c4b(207, 198, 189, 255)
	rect:drawSolidRect(cc.p((idx-1)*rectLen, (idy-1)*rectLen), cc.p(idx*rectLen, idy*rectLen), cc.c4f(0.81, 0.776, 0.74, 1))
	BoardLayer:addChild(rect, 1) 
	return rect
end

local function InitNumLabels()
	for i = 1, 5 do -- 5竖
		local linewidth = 4
		if i == 1 or i == 5 then 
			linewidth = 8
		end
		createLine((i-1)*rectLen, 0, (i-1)*rectLen, display.height, linewidth)
	end
	
	for j = 1, 5 do -- 5横
		local linewidth = 4
		if j == 1 or j == 5 then 
			linewidth = 8
		end
		createLine(0, (j-1)*rectLen, display.height, (j-1)*rectLen, linewidth)
	end

	for i = 1, 4 do 
		NumLabels[i] = {}
		NumBgRects[i] = {}
		for j = 1, 4 do
			NumLabels[i][j] = createNum(i, j)
			NumBgRects[i][j] = creatRect(i, j)	
		end
	end
end	

function MainScene:DrawBoard()
	local boarddata = Board.GetBoardData()
	if not boarddata then return end 
	
	for i = 1, 4 do 
		for j = 1, 4 do 
			NumBgRects[i][j]:clear()
			local num = boarddata[i][j]
			local numLabel = NumLabels[i][j]
			if num > 0 then 
				local rgbArr
				if num >= 4096 then 
					rgbArr = Num2Color[4096]
				else 
					rgbArr = Num2Color[num]
				end
				numLabel:setString(tonumber(num))
				NumBgRects[i][j]:drawSolidRect(cc.p((i-1)*rectLen, (j-1)*rectLen), cc.p(i*rectLen, j*rectLen), cc.c4f(rgbArr[1]/255, rgbArr[2]/255, rgbArr[3]/255, 1))

				if num == 2 or num == 4 then 
					numLabel:setColor(cc.c4b(0, 0, 0, 255))
				else 
					numLabel:setColor(cc.c4b(255, 255, 255, 255))
				end 	 	
			else 
				numLabel:setString("")
				NumBgRects[i][j]:drawSolidRect(cc.p((i-1)*rectLen, (j-1)*rectLen), cc.p(i*rectLen, j*rectLen), cc.c4f(0.81, 0.776, 0.74, 1))
			end
		end
	end	
end

function MainScene:AddNum(num)
	if Board.GetNumCount() < 16 then 
		Board.GenNewNum(num)
	end
end

local function showRankList(startindex, endIndex)
	assert(startindex < endIndex, "startindex over endindex")
	for i = startindex, endIndex do
		local userdata = ranklist[i]
		if userdata then 
			local index = i%50 == 0 and 50 or i%50
			local layout = rankLayouts[index]
			if userdata.uid == UserProfile.uid then 
				layout:setBackGroundColor(cc.c3b(0, 0, 0))
			else
				layout:setBackGroundColor(cc.c3b(181, 230, 29))
			end 

			for j = 1, 4 do 
				local label = rankItems[i][j]
				local color = cc.c4b(255, 255, 255, 255)
				if i == 1 then 
					color = cc.c4b(255, 0, 0, 255)
				elseif i == 2 then 
					color = cc.c4b(255, 255, 0, 255)
				elseif i == 3 then 
					color = cc.c4b(0, 0, 255, 255)
				end 	
				label:setColor(color)

				if j == 1 then 
					label:setString(tostring(i))
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
end 	

local function GetRankList(startindex, endIndex)
	startindex = startindex or 1 
	endIndex = endIndex or 50

	local xhr = cc.XMLHttpRequest:new()	--http请求
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON	--请求类型
	local url = string.format('http://%s:%d/GetRankList?appid=1&data={"uid":%d,"startindex":%d,"endindex":%d}', GameConfig.RankSrvIp, GameConfig.RankSrvPort, UserProfile.uid or 0, startindex, endIndex)
	print("GetRankList url ", url)
	xhr:open("GET", url)
	local function onResponse()
		local str = xhr.response	--获得返回数据
		print("GetRankList resp", str)
		local data = json.decode(str)
		if data.status == 0 then 
			for i, v in ipairs(data.lists) do 
				ranklist[v.rank] = v
				print("ranlist ", v.uid, v.rank, v.name, v.score)
				if v.uid == UserProfile.uid then 
					myrank = v.rank
					MyRankLabel:setString(tostring(myrank))
					if v.score > MaxScore then 
						MaxScore = v.score
						MaxScoreLabel:setString(tostring(MaxScore))
					end	
				end
			end

			showRankList(startindex, endIndex)
		end
	end
	xhr:registerScriptHandler(onResponse)	--注册脚本方式回调
	xhr:send()	--发送 
end 

-- exitFlag: true 退出游戏 false 不退出游戏 
local function CommitData2RankServer(score, exitFlag)
	local xhr = cc.XMLHttpRequest:new()	--http请求
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON	--请求类型
	local url = string.format('http://%s:%d/CommitData?appid=1&data={"uid":%d,"name":"%s","headIcon":"%s","score":%d}', GameConfig.RankSrvIp, GameConfig.RankSrvPort, UserProfile.uid, UserProfile.name, UserProfile.headIcon, score)
	print("CommitData2RankServer url ", url)
	xhr:open("GET", url)
	local function onResponse()
		local str = xhr.response	--获得返回数据
		print("CommitData2RankServer resp", str)
		local data = json.decode(str)
		if data.status == 0 then 
 		end
		if exitFlag then
			cc.Director:getInstance():endToLua() -- 为了让排行榜正常提交 在此结束游戏进程【因为网络进程和游戏进程不在同一个进程】
		end	
	end
	xhr:registerScriptHandler(onResponse)	--注册脚本方式回调
	xhr:send()	--发送
end 

function MainScene:ResetBoard()
	if CurScore >= MaxScore and CurScore > 0 then 
		MaxScore = CurScore
		CommitData2RankServer(MaxScore)
	end
	Board.InitBoardData()
	CurScore = 0
	self:AfterOperate(2, true)
end

local function ExitGame()
	TipsLayer:getChildByName("Text_tips"):setString("确定要离开游戏么")
	TipsLayer:setVisible(true)
	local btnYes = TipsLayer:getChildByName("btn_yes")
	btnYes:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			TipsLayer:setVisible(false)
			Storage.setTable("boarddata", Board.GetBoardData())	
			Storage.setInt("maxScore", MaxScore)
			Storage.setInt("curScore", CurScore)
			if CurScore >= MaxScore and UserProfile.uid then 
				MaxScore = CurScore
				CommitData2RankServer(MaxScore, true) -- todo: 设置超时时间 如果不能提交也要退出游戏
			else
				cc.Director:getInstance():endToLua()
			end	
		end
	end)
end

function MainScene:AfterOperate(num, move)
	if move then 
		self:DrawBoard()
		self:RefreshScoreLayer()
		-- 新出来的数字 延迟0.5s显示
		self:AddNum(num)
		scheduler.performWithDelayGlobal(function() self:DrawBoard() end, 0.3) -- 定时器:只执行一次
	else 
		if Board.isBoardEnd() then -- 重置确认弹框
			if CurScore >= MaxScore then 
				MaxScore = CurScore
				CommitData2RankServer(MaxScore)
				GetRankList() -- 排行榜数据刷新
			end	

			TipsLayer:getChildByName("Text_tips"):setString("GAME OVER\n 重新开始")
			TipsLayer:setVisible(true)

			local resetBtn = TipsLayer:getChildByName("btn_yes")
			resetBtn:addTouchEventListener(function(sender,eventType)
				if eventType == ccui.TouchEventType.ended then
					self:ResetBoard()
					TipsLayer:setVisible(false)
				end
			end)
		end
	end
end

local function SetMusicSwitch(flag)
	GameMusic.setMusicSwitch(flag)
	local MusicBtn = SettingLayer:getChildByName("btn_music")
	if flag then 
		MusicBtn:loadTextures("btn_on.png", "btn_on.png")
		GameMusic.resumeMusic()	
	else 
		MusicBtn:loadTextures("btn_off.png", "btn_off.png")
		GameMusic.pauseMusic()	
	end	
	Storage.setBool("music", flag)
end	

local function SetEffectSwitch(flag)
	GameMusic.setEffectSwitch(flag)
	local EffectBtn = SettingLayer:getChildByName("btn_effect")
	if flag then 
		EffectBtn:loadTextures("btn_on.png", "btn_on.png")
	else 
		EffectBtn:loadTextures("btn_off.png", "btn_off.png")
	end	
	Storage.setBool("effect", flag)
end

function MainScene:LoadUserData()
	local account =	Storage.getString("account", "")
	if account ~= "" then 
		UserProfile.name = account 
	end 	
	local password = Storage.getString("password", "")
	if password ~= "" then 
		UserProfile.password = password 
	end 
	
	if account ~= "" and password ~= "" then 
		HomeScene:setVisible(false)
		LoginScene:setVisible(true)
		LoginScene:getChildByName("TextField_account"):setString(account)
		LoginScene:getChildByName("TextField_password"):setString(password)
	end

	MaxScore = Storage.getInt("maxScore", 0) -- fixme: 增加用户注册登录后 如果没有取到 则取账号服数据
	CurScore = Storage.getInt("curScore", 0) -- 当前分数 取本地分数
	Board.SetBoardData(Storage.getTable("boarddata"))
	MusicFlag = Storage.getBool("music", true) -- 首次打开是开启的
	EffectFlag = Storage.getBool("effect", true) -- 首次打开是开启的
	SetMusicSwitch(MusicFlag)
	SetEffectSwitch(EffectFlag)
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
	MaxStaticLabel:move((display.width - display.height)/2, display.height - 0.6*rectLen) 
	MaxStaticLabel:addTo(ScoreLayer) 	
	
	MaxScoreLabel = ccui.TextBMFont:create()
    MaxScoreLabel:move((display.width - display.height)/2, display.height - 1.2*rectLen)
    MaxScoreLabel:addTo(ScoreLayer)
	MaxScoreLabel:setFntFile("font_number.fnt")
	MaxScoreLabel:setString(tostring(MaxScore))

	local CurStaticLabel = cc.Label:createWithSystemFont("当前分数", "Arial", 35)
	CurStaticLabel:move((display.width - display.height)/2, display.height - 1.8*rectLen) 
	CurStaticLabel:addTo(ScoreLayer) 	

	CurScoreLabel = ccui.TextBMFont:create()
    CurScoreLabel:move((display.width - display.height)/2, display.height - 2.4*rectLen)
    CurScoreLabel:addTo(ScoreLayer)
	CurScoreLabel:setFntFile("font_number.fnt")
	CurScoreLabel:setString(tostring(CurScore))
	
	local MyRankStaticLable = cc.Label:createWithSystemFont("我的排名", "Arial", 35)
	MyRankStaticLable:move((display.width - display.height)/2, display.height - 3*rectLen) 
	MyRankStaticLable:addTo(ScoreLayer) 
	
	MyRankLabel = ccui.TextBMFont:create()
    MyRankLabel:move((display.width - display.height)/2, display.height - 3.6*rectLen)
    MyRankLabel:addTo(ScoreLayer)
	MyRankLabel:setFntFile("font_number.fnt")
	MyRankLabel:setString(tostring(0))
end

function MainScene:InitBoard()
	local color = cc.c4b(207, 198, 189, 0)
    BoardLayer = cc.LayerColor:create(color)
	BoardLayer:setContentSize(cc.size(display.height, display.height))
	BoardLayer:setPosition(cc.p(0, 0))
	BoardLayer:setVisible(false)
	self:addChild(BoardLayer, 1)
	
	local color1 = cc.c4b(130, 36, 94, 255)
    ScoreLayer = cc.LayerColor:create(color1)
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
	local mergePos = {} -- 合并数字的位置
	if math.abs(endX) > math.abs(endY) then 
		if math.abs(endX) > 5 then -- 滑动太少不算
			if endX > 0 then 
				 flag, mergeScore, mergePos = Board.OnLeft()
			else 
				flag, mergeScore, mergePos = Board.OnRight()
			end
		end		
	else 
		if math.abs(endY) > 5 then -- 滑动太少不算
			if endY > 0 then 
				flag, mergeScore, mergePos = Board.OnDown()
			else 
				flag, mergeScore, mergePos = Board.OnUp()
			end	
		end	
	end
	
	if flag then 
		for i, v in ipairs(mergePos) do 
			local label = NumLabels[v[1]][v[2]]
			local action1 = cc.ScaleTo:create(0.3,1.5)
			local action2 = cc.ScaleTo:create(0.3,1)
			label:runAction(cc.Sequence:create(action1,action2))  -- 先放大再缩小
		end 	

		local afterMaxNum, idx, idy = Board.GetMaxNum() 
		if afterMaxNum > beforeMaxNum and afterMaxNum >= 4 then 
			local particle = cc.ParticleExplosion:create() -- 爆炸粒子效果
			local cx = (idx-1)*rectLen +rectLen/2 
			local cy = (idy-1)*rectLen +rectLen/2 
			particle:move(cx, cy)
			BoardLayer:addChild(particle, 5)
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
	if keyCode == cc.KeyCode.KEY_BACK or keyCode == cc.KeyCode.KEY_Q then	-- KEY_BACK android / KEY_Q windows
		ExitGame()
	elseif keyCode == cc.KeyCode.KEY_HOME then
		-- ExitGame()
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

			if Storage.getString("account", "") ~= account then 
				Storage.setString("account", account)
				Storage.setString("password", password)
			end

			if not UserProfile.uid then -- 打开游戏后首次登陆
				UserProfile.uid = data.uid
				UserProfile.name = account
				LoginScene:setVisible(false)
				BoardLayer:setVisible(true)
				ScoreLayer:setVisible(true)
			elseif UserProfile.uid == data.uid then -- 登陆旧账号
				LoginScene:setVisible(false)
				BoardLayer:setVisible(true)
				ScoreLayer:setVisible(true)
			elseif UserProfile.uid ~= data.uid then -- 登陆新账号
				UserProfile.uid = data.uid
				UserProfile.name = account
				MaxScore = 0 
				CurScore = 0
				LoginScene:setVisible(false)
				BoardLayer:setVisible(true)
				ScoreLayer:setVisible(true)
				MainScene:ResetBoard()
			end
			GetRankList()
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

			-- 新玩家注册 重置所有数据
			MaxScore = 0
			CurScore = 0
			MaxScoreLabel:setString(MaxScore)
			CurScoreLabel:setString(CurScore)
			MainScene:ResetBoard()
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

	SettingLayer = cc.CSLoader:createNode("Setting.csb")
	SettingLayer:setVisible(false)
	SettingLayer:move(display.width/2 - 320, display.height/2 - 150)
	SettingLayer:addTo(self, 120)

	TipsLayer = cc.CSLoader:createNode("Tips.csb")
	TipsLayer:setVisible(false)
	TipsLayer:move(display.width/2 - 250, display.height/2 - 150)
	TipsLayer:addTo(self, 120)

	local color = cc.c4b(112, 146, 190, 255)
	rankLayer = cc.LayerColor:create(color)
	rankLayer:setContentSize(cc.size(display.height, display.height))
	rankLayer:setPosition(cc.p(0, 0))
	rankLayer:setVisible(false)
	self:addChild(rankLayer, 10)
	for j = 1, 4 do -- 排行榜表头
		local label = cc.Label:createWithSystemFont("", "Arial", 25)
		label:setContentSize(cc.size(display.height/4, display.height/11))
		label:setPosition(cc.p((j-1)*(display.height/4) + display.height/8, 10*(display.height/11) + display.height/22))
		rankLayer:addChild(label)
	
		if j == 1 then 
			label:setString("排名")
		elseif j == 2 then 
			label:setString("ID")
		elseif j == 3 then 
			label:setString("昵称")
		elseif j == 4 then 
			label:setString("分数")
		end 
	end

	-- 排行榜listview
	local listView = ccui.ListView:create();
	listView:setPosition(cc.p(0, 0));
	listView:setContentSize(cc.size(720, 654));
	listView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL);
	listView:setBounceEnabled(true);
	listView:setItemsMargin(4)
	
	for i = 1, 50 do
		rankItems[i] = {}
		local layout = ccui.Layout:create();
		layout:setContentSize(cc.size(720, 62));
		layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
		layout:setBackGroundColor(cc.c3b(181, 230, 29));
		for j = 1, 4 do 
			local label = cc.Label:createWithSystemFont("", "Arial", 25)
			label:setContentSize(cc.size(180, 60))
			label:setPosition(90 + (j-1)*180, 30)
			layout:addChild(label)
			rankItems[i][j] = label
		end	
		listView:pushBackCustomItem(layout);
		rankLayouts[i] = layout
	end
	rankLayer:addChild(listView);

	local TipsBtn_Close = TipsLayer:getChildByName("btn_close")
	TipsBtn_Close:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			TipsLayer:setVisible(false)
		end
	end)
	
	local TipsBtn_No = TipsLayer:getChildByName("btn_no")
	TipsBtn_No:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			TipsLayer:setVisible(false)
		end
	end)

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
	resetBtn:setPosition(display.width - 60, display.height - 160)
	resetBtn:setVisible(true)
	resetBtn:addTo(self, 10)
	
	local rankBtn = ccui.Button:create("rank_open.png", "rank_open.png", "rank_open.png")
	rankBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			if not rankFlag then 
				rankFlag = true 
				rankLayer:setVisible(true)
				rankBtn:loadTextures("rank_close.png", "rank_close.png");
			else
				rankFlag = false 
				rankLayer:setVisible(false)
				rankBtn:loadTextures("rank_open.png", "rank_open.png");
			end 
		end
    end)
	rankBtn:setPosition(display.width - 60, display.height - 260)
	rankBtn:setVisible(true)
	rankBtn:addTo(self, 10)

	local settingBtn = ccui.Button:create("btn_setting.png")
	settingBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			if not SettingLayer:isVisible() then -- 设置面板可见 则不可点击设置按钮
				if not SettingFlag then 
					SettingFlag = true
					SettingLayer:setVisible(true)
				else 
					SettingFlag = false	
					SettingLayer:setVisible(false)
				end
			end 		
		end
    end)
	settingBtn:setPosition(display.width - 60, display.height - 60)
	settingBtn:addTo(self, 10)

	local SettingBtn_Close = SettingLayer:getChildByName("btn_close")
	SettingBtn_Close:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			SettingLayer:setVisible(false)
			SettingFlag = false
		end
	end)

	local musicBtn = SettingLayer:getChildByName("btn_music")
	musicBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			if not MusicFlag then 
				MusicFlag = true 
			else
				MusicFlag = false
			end
			SetMusicSwitch(MusicFlag)
		end
    end)

	local effectBtn = SettingLayer:getChildByName("btn_effect")
	effectBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			if not EffectFlag then 
				EffectFlag = true 
			else
				EffectFlag = false
			end
			SetEffectSwitch(EffectFlag)
		end
	end)
	
	local accountBtn = SettingLayer:getChildByName("btn_account")
	accountBtn:addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			SettingLayer:setVisible(false)
			SettingFlag = false
			HomeScene:setVisible(true)
		end
	end)
	
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
