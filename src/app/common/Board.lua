local utils = require "utils"

local Board = {}

local BoardData

local function MergeArr(arr)
	local canMerge = false 
	if #arr <= 1 then 
		return arr, canMerge 
	elseif #arr >= 2 then 	
		local markIndex = 0
		local tmpArr = {}
		for i = 1, #arr do 
			if i >= markIndex then
				if arr[i] == arr[i+1] then 
					canMerge = true
					table.insert(tmpArr, arr[i] + arr[i+1])
					markIndex = i+2
				else
					table.insert(tmpArr, arr[i]) 
					markIndex = i+1
				end
			end
		end
		return tmpArr, canMerge
	end	
end

--[[
function Board.encodedata(boarddata)
	boarddata = boarddata or BoardData
	local arr = {}
	for i = 1, 4 do 
		for j = 1, 4 do 
			table.insert(arr, boarddata[i][j])
		end 
	end 	
	return table.concat(arr, ",")
end 

function Board.decodedata(str)
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
--]]

function Board.GetTotalScore(boarddata)
	boarddata = boarddata or BoardData
	if not boarddata then 
		return 0 
	end
	
	local totalScore = 0
	for i = 1, 4 do 
		for j = 1, 4 do 
			totalScore = totalScore + BoardData[i][j]
		end 
	end 
	return totalScore
end

function Board.GetMaxNum()
	if not BoardData then return 0 end 
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

function Board.InitBoardData()
	BoardData = {}
	for i = 1, 4 do 
		BoardData[i] = {}
		for j = 1, 4 do
			BoardData[i][j] = 0
		end
	end
end

function Board.SetBoardData(data)
	if (not data) or (type(data) == "table" and #data ~= 4) then
		BoardData = nil
	else
		BoardData = data
	end
end

function Board.GetBoardData()
	return BoardData
end

local function isSameArr(oldArr, newArr)
	assert(#oldArr == #newArr)
	local flag = true
	for i = 1, #oldArr do 
		if oldArr[i] ~= newArr[i] then 
			flag = false 
			break 
		end 	
	end
	return flag
end

function Board.OnLeft()
	local move = false
	for i = 1, 4 do
		local oldArr = {}
		local arr = {}
		for j = 1, 4 do
			if BoardData[j][i] > 0 then
				table.insert(arr, BoardData[j][i])
			end	
			table.insert(oldArr, BoardData[j][i])
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
		
		local newArr = {}
		for j = 1, 4 do 
			table.insert(newArr, BoardData[j][i])
		end 
		
		if not isSameArr(oldArr, newArr) then 
			move = true 
		end	
	end
	return move
end 

function Board.OnRight()
	local move = false
	for i = 1, 4 do
		local oldArr = {}
		local arr = {}
		for j = 4, 1, -1 do
			if BoardData[j][i] > 0 then
				table.insert(arr, BoardData[j][i])
			end	
			table.insert(oldArr, BoardData[j][i])
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
		
		local newArr = {}
		for j = 4, 1, -1 do 
			table.insert(newArr, BoardData[j][i])
		end 
		
		if not isSameArr(oldArr, newArr) then 
			move = true 
		end	
	end
	return move
end 

function Board.OnUp()
	local move = false
	for i = 1, 4 do
		local oldArr = {}
		local arr = {}
		for j = 4, 1, -1 do
			if BoardData[i][j] > 0 then
				table.insert(arr, BoardData[i][j])
			end	
			table.insert(oldArr, BoardData[i][j])
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
		
		local newArr = {}
		for j = 4, 1, -1 do 
			table.insert(newArr, BoardData[i][j])
		end 
		
		if not isSameArr(oldArr, newArr) then 
			move = true 
		end	
	end
	return move
end 

function Board.OnDown()
	local move = false
	for i = 1, 4 do
		local oldArr = {}
		local arr = {}
		for j = 1, 4 do
			if BoardData[i][j] > 0 then
				table.insert(arr, BoardData[i][j])
			end	
			table.insert(oldArr, BoardData[i][j])
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
		
		local newArr = {}
		for j = 1, 4 do 
			table.insert(newArr, BoardData[i][j])
		end 
		
		if not isSameArr(oldArr, newArr) then 
			move = true 
		end	
	end
	return move
end 

function Board.GetNumCount()
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

function Board.GenNewNum(num)
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
		BoardData[v[1]][v[2]] =  2 -- todo: ����������� ���ֵ��仯
	end
end 

function Board.isBoardEnd()
	if Board.GetNumCount() < 16 then 
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

return Board