
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local utils = require "utils"
local scheduler = require ("scheduler") -- 定时器
local json -- todo cjson库
local layer 
local scoreLayer
local MaxScoreLabel
local CurScoreLabel

local rectLen = display.height/4

function MainScene:onKeyPressed(keyCode, event)
	if keyCode == cc.KeyCode.KEY_LEFT_ARROW then
		self:OnLeft()
		self:AfterOperate(1)
	end	

	if keyCode == cc.KeyCode.KEY_RIGHT_ARROW then
		self:OnRight()
		self:AfterOperate(1)
	end

	if keyCode == cc.KeyCode.KEY_UP_ARROW then
		self:OnUp()
		self:AfterOperate(1)
	end	

	if keyCode == cc.KeyCode.KEY_DOWN_ARROW then
		self:OnDown()
		self:AfterOperate(1)
	end
end

local MaxScore = 0
local BoardData = {} -- 面板数据
local NumLabels = {} -- 数字组件

local function createNum(layer, idx, idy, num)
	local cx = (idx-1)*rectLen +rectLen/2 
	local cy = (idy-1)*rectLen +rectLen/2 
	local numstr = num ~= 0 and tostring(num) or "" 
	local label = cc.Label:createWithSystemFont(numstr, "Arial", 40)
	label:move(cx, cy)
	label:addTo(layer) 	
	return label
end

local function InitBoardData(boarddata)
	for i = 1, 4 do 
		BoardData[i] = {}
		for j = 1, 4 do
			BoardData[i][j] = boarddata and boarddata[i][j] or 0
		end
	end
end

local function createLine(layer, x1, y1, x2, y2)	
	local draw = cc.DrawNode:create()
	draw:drawSegment(cc.p(x1, y1), cc.p(x2,y2), 5, cc.c4f(1,1,0,1)) --  ('起点' , '终点' , '半线宽' , '填充颜色')
	layer:addChild(draw)
end


local function InitNumLabels(boarddata)
	for i = 1, 4 do -- 4竖
		createLine(layer, (i-1)*rectLen, 0, (i-1)*rectLen, display.height)
	end
	
	for j = 1, 4 do -- 4横
		createLine(layer, 0, (j-1)*rectLen, display.height, (j-1)*rectLen)
	end

	for i = 1, 4 do 
		NumLabels[i] = {}
		for j = 1, 4 do
			local num = boarddata and boarddata[i][j] or 0
			NumLabels[i][j] = createNum(layer, i, j, num)
		end
	end
end	

local function GenNewNum(num)
	local emptypos = {}
	for i = 1, 4 do 
		for j = 1, 4 do 
			if BoardData[i][j] == 0 then 
				table.insert(emptypos, {i, j})
			end 	
		end	
	end
	local newArr = utils.get_random_sublist(emptypos, num)
	for _, v in ipairs(newArr) do 
		BoardData[v[1]][v[2]] =  2 -- todo: 当最大数增大 这个值会变化
	end
end 

function MainScene:DrawBoard(layer)
	for i = 1, 4 do 
		for j = 1, 4 do 
			local num = BoardData[i][j]
			local label = NumLabels[i][j]
			local str = num > 0 and tostring(num) or ""
			label:setString(str)
		end 
	end 		
end	

local function GetNumCount()
	local count = 0
	for i = 1, 4 do 
		for j = 1, 4 do 
			if BoardData[i][j] > 0 then 
				count = count + 1
			end 	
		end 
	end
	return count
end	

local function isBoardEnd()
	if GetNumCount() < 16 then 
		return false 
	end	

	local canMerge = false
	for i = 1, 4 do 
		for j = 1, 3 do 
			if BoardData[i][j] == BoardData[i][j+1] then 
				canMerge = true
				break
			end	
		end 
	end 	 

	for i = 1, 4 do 
		for j = 1, 3 do 
			if BoardData[j][i] == BoardData[j+1][i] then 
				canMerge = true
				break
			end	
		end 
	end 

	return (not canMerge)
end	

function MainScene:ResetBoard()
	InitBoardData()
	self:AfterOperate(2)
end

function MainScene:AddNum(num)
	if not isBoardEnd() then 
		if GetNumCount() < 16 then 
			GenNewNum(num)
			self:DrawBoard(layer)
		end	
	else
		-- todo: 重置确认弹框
		print("2048 game is over, Do you want to reset ? ")	
		self:ResetBoard()
	end
end

function MainScene:AfterOperate(num)
	self:DrawBoard(layer)
	self:RefreshScoreLayer()
	-- 新出来的数字 延迟0.5s显示
	scheduler.performWithDelayGlobal(function() self:AddNum(num) end, 0.5) -- 定时器:只执行一次
end

local function MergeArr(arr)
	if #arr <= 1 then 
		return arr 
	elseif #arr >= 2 then 	
		local markIndex = 0
		local tmpArr = {}
		for i = 1, #arr do 
			if i >= markIndex then
				if arr[i] == arr[i+1] then 
					table.insert(tmpArr, arr[i] + arr[i+1])
					markIndex = i+2
				else
					table.insert(tmpArr, arr[i]) 
					markIndex = i+1
				end
			end
		end
		return tmpArr
	end	
end


local function encodedata(boarddata)
	local arr = {}
	for i = 1, 4 do 
		for j = 1, 4 do 
			table.insert(arr, boarddata[i][j])
		end 
	end 	
	return table.concat(arr, ",")
end 

local function decodedata(str)
	local boarddata = {}
	local arr = utils.split(str, ",")
	for i = 1, 4 do 
		boarddata[i] = {}
		for j = 1, 4 do 
			table.insert(boarddata[i], tonumber(arr[(i-1)*4+j]))
		end 
	end 
	return boarddata
end 

local function GetMaxScore(boardData)
	boardData = boardData or BoardData
	local maxScore = 0
	for i = 1, 4 do 
		for j = 1, 4 do 
			if BoardData[i][j] > maxScore then 
				maxScore = BoardData[i][j]
			end 	
		end 
	end 
	return maxScore
end

local function saveBoardData()
	local curMaxScore = GetMaxScore(BoardData)
	local str = encodedata(BoardData)
	cc.UserDefault:getInstance():setStringForKey("boarddata", str); 
	if curMaxScore > MaxScore then 
		MaxScore = curMaxScore
	end	
	cc.UserDefault:getInstance():setStringForKey("maxscore", MaxScore);
end

local function loadBoardData()
	local str = cc.UserDefault:getInstance():getStringForKey("boarddata");
	local str2 = cc.UserDefault:getInstance():getStringForKey("maxscore");
	if str2 and str2 ~= "" then 
		MaxScore = tonumber(str2)
	end 
	
	if str and str ~= "" then 
		return decodedata(str)
	else
		return nil
	end
end

local function GenMaxScoreStr(score)
	return "历史最高分：" .. tostring(score)
end 

local function GenCurMaxScoreStr(score)
    return "当前最高分：" .. tostring(score)
end 

function MainScene:RefreshScoreLayer()
	local curMaxScore = GetMaxScore(BoardData)
	if MaxScore < curMaxScore then 
		MaxScore = curMaxScore
	end	
	MaxScoreLabel:setString(GenMaxScoreStr(MaxScore))
	CurScoreLabel:setString(GenCurMaxScoreStr(curMaxScore))
end

local function InitScoreLayer()
	MaxScoreLabel = cc.Label:createWithSystemFont(GenMaxScoreStr(MaxScore), "Arial", 35)
	MaxScoreLabel:move((display.width - display.height)/2, display.height - rectLen) -- 此处是相对scoreLayer左下角的位置
	MaxScoreLabel:addTo(scoreLayer) 	

	CurScoreLabel = cc.Label:createWithSystemFont(GenCurMaxScoreStr(GetMaxScore(BoardData)), "Arial", 35)
	CurScoreLabel:move((display.width - display.height)/2, display.height - 2*rectLen)
	CurScoreLabel:addTo(scoreLayer)
end

function MainScene:InitBoard(boarddata)
	local color = cc.c4b(255, 255, 0, 50)
    layer = cc.LayerColor:create(color)
	layer:setContentSize(cc.size(display.height, display.height))
	layer:setPosition(cc.p(0, 0))
	self:addChild(layer)
	
	local color1 = cc.c4b(255, 255, 0, 100)
    scoreLayer = cc.LayerColor:create(color1)
	scoreLayer:setContentSize(cc.size(display.width - display.height, display.height))
	scoreLayer:setPosition(cc.p(display.height, 0))
	self:addChild(scoreLayer)
	
	InitBoardData(boarddata)
	InitNumLabels(boarddata)
	InitScoreLayer()
	if not boarddata then 
		self:AfterOperate(2)
	end
end

function MainScene:OnLeft()
	for i = 1, 4 do
		local arr = {}
		for j = 1, 4 do
			if BoardData[j][i] > 0 then
				table.insert(arr, BoardData[j][i])
			end	
		end
		arr = MergeArr(arr)
		if #arr > 0 then 
			for k = 1, #arr do 
				BoardData[k][i] = arr[k]
			end

			for k = #arr+1, 4 do 
				BoardData[k][i] = 0
			end
		end
	end
end	

function MainScene:OnRight()
	for i = 1, 4 do
		local arr = {}
		for j = 4, 1, -1 do
			if BoardData[j][i] > 0 then
				table.insert(arr, BoardData[j][i])
			end	
		end
		arr = MergeArr(arr)
		if #arr > 0 then 
			for k = 4, 4-#arr+1, -1 do 
				BoardData[k][i] = arr[4-k+1]
			end

			for k = 4-#arr, 1, -1 do 
				BoardData[k][i] = 0
			end
		end
	end
end

function MainScene:OnUp()
	for i = 1, 4 do
		local arr = {}
		for j = 4, 1, -1 do
			if BoardData[i][j] > 0 then
				table.insert(arr, BoardData[i][j])
			end	
		end
		arr = MergeArr(arr)
		if #arr > 0 then 
			for k = 4, 4-#arr+1, -1 do 
				BoardData[i][k] = arr[4-k+1]
			end

			for k = 4-#arr, 1, -1 do 
				BoardData[i][k] = 0
			end
		end
	end
end	

function MainScene:OnDown()
	for i = 1, 4 do
		local arr = {}
		for j = 1, 4 do
			if BoardData[i][j] > 0 then
				table.insert(arr, BoardData[i][j])
			end	
		end
		arr = MergeArr(arr)
		if #arr > 0 then 
			for k = 1, #arr do 
				BoardData[i][k] = arr[k]
			end

			for k = #arr+1, 4 do 
				BoardData[i][k] = 0
			end
		end
	end
end	

local firstX = 0
local firstY = 0
function MainScene:onTouchBegan(touch, event)
	-- 纪录触摸起始点坐标
	local beginPoint = touch:getLocation()
	firstX = beginPoint.x
	firstY = beginPoint.y
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

	if math.abs(endX) > math.abs(endY) then -- 看是横向移动大还是纵向移动大
		if endX > 0 then 
			self:OnLeft()
		else 
			self:OnRight()
		end	
	else 
		if endY > 0 then 
			self:OnDown()
		else 
			self:OnUp()
		end	
	end
	self:AfterOperate(1)
end 

function MainScene:onTouchCancelled(touch, event)
end

local function onRelease(keyCode, event)
	if keyCode == cc.KeyCode.KEY_BACK then	
		saveBoardData()
		cc.Director:getInstance():endToLua()
	elseif keyCode == cc.KeyCode.KEY_HOME then
		saveBoardData()
		--cc.Director:getInstance():endToLua()
	elseif keyCode == cc.KeyCode.KEY_Q then
		saveBoardData()
		cc.Director:getInstance():endToLua()
	end	
end

function MainScene:onCreate()
	-- todo: 增加logo界面 间隔1s消失掉
    --add background image
	--[[
    display.newSprite("HelloWorld.png")
        :move(display.center)
        :addTo(self)
	--]]
	local olddata, oldMaxScore = loadBoardData()
	self:InitBoard(olddata)
	local dispatcher = cc.Director:getInstance():getEventDispatcher()
	-- 键盘事件
	local listener = cc.EventListenerKeyboard:create()
	listener:registerScriptHandler(function(keyCode, event) self:onKeyPressed(keyCode, event) end, cc.Handler.EVENT_KEYBOARD_PRESSED)
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
