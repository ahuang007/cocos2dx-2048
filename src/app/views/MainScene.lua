
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local utils = require "utils"
local scheduler = require ("scheduler") -- 定时器
local layer 

function MainScene:onKeyPressed(keyCode, event)
	if keyCode == cc.KeyCode.KEY_SPACE then
		self:InitBoard()
	end

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

local BoardData = {} -- 面板数据
local NumLabels = {} -- 数字组件

local function createNum(layer, idx, idy)
	local cx = (idx-1)*150 +75 
	local cy = (idy-1)*150 +75 
	local label = cc.Label:createWithSystemFont("", "Arial", 40)
	label:move(cx, cy)
	label:addTo(layer) 	
	return label
end

local function InitBoardData()
	for i = 1, 4 do 
		BoardData[i] = {}
		for j = 1, 4 do
			BoardData[i][j] = 0
		end
	end
end

local function InitNumLabels()
	for i = 1, 4 do 
		NumLabels[i] = {}
		for j = 1, 4 do
			NumLabels[i][j] = createNum(layer, i, j)
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

local function createRect(layer, x1, y1, x2, y2)
    local rect = cc.rect(x1,y1,x2,y2)
    local draw = cc.DrawNode:create()
    draw:drawRect(cc.p(rect.x+rect.width,rect.y+rect.height), cc.p(rect.x,rect.y), cc.c4f(1,1,0,1))
    layer:addChild(draw)
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
	-- 新出来的数字 延迟显示
	scheduler.performWithDelayGlobal(function() -- 定时器:只执行一次
		self:AddNum(num)
	end, 0.2)
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

function MainScene:InitBoard()
	local color = cc.c4b(255, 255, 0, 50)
    layer = cc.LayerColor:create(color)
	layer:setContentSize(cc.size(600, 600))
	layer:setPosition(cc.p(0, 0))
	self:addChild(layer)
	
	for i = 1, 4 do 
		for j = 1, 4 do
			createRect(layer, (i-1)*150, (j-1)*150, i*150, j*150)
		end
	end

	InitBoardData()
	InitNumLabels()
	self:AfterOperate(2)
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

function MainScene:onCreate()
	--[[
    --add background image
    display.newSprite("HelloWorld.png")
        :move(display.center)
        :addTo(self)
	-- todo: 增加logo界面
	--]]

	local dispatcher = cc.Director:getInstance():getEventDispatcher()
	local listener = cc.EventListenerKeyboard:create()
	listener:registerScriptHandler(function(keyCode, event) self:onKeyPressed(keyCode, event) end, cc.Handler.EVENT_KEYBOARD_PRESSED)
	dispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	-- todo : 手机触摸事件
	--[[
		local listener1 = cc.EventListenerTouchOneByOne:create()
		listener1:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
		listener1:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
		listener1:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
		listener1:registerScriptHandler(onTouchCancelled, cc.Handler.EVENT_TOUCH_CANCELLED)
		self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener1, self)
	--]]
end

return MainScene
