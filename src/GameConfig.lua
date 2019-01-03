
local GameConfig = {
    -- 排行榜服务
    RankSrvIp   = '47.106.34.35', 
    RankSrvPort = 7100,   
}

-- 数字颜色
GameConfig.Num2Color = {
	[2] 	= {238, 228, 218},
	[4] 	= {236, 224, 200},
	[8] 	= {242, 177, 121},
	[16] 	= {245, 149, 99},
	[32] 	= {247, 123, 97},
	[64] 	= {246, 93,	 59},
	[128] 	= {239, 206, 113},
	[256] 	= {237, 205, 96}, 
	[512] 	= {236, 200, 80}, 
	[1024] 	= {237, 197, 63},
	[2048] 	= {238, 194, 46},
	[4096] 	= {0,   0,   0},
}

return GameConfig