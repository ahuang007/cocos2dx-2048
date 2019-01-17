
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = false

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = true

-- for module display
CC_DESIGN_RESOLUTION = {
    width = 1280,
    height = 720,
    autoscale = "SHOW_ALL",
    -- autoscale = "FIXED_HEIGHT",
	-- autoscale = "FIXED_WIDTH",
    -- callback = function(framesize)
    --     local ratio = framesize.width / framesize.height
    --     if ratio > 1280/720 then
    --         if platform == "ios" then
    --             return {autoscale = "SHOW_ALL"} -- 暂时不考虑iPhone X
    --         else
    --             return {autoscale = "FIXED_HEIGHT"}
    --         end
    --     else
    --         return {autoscale = "FIXED_WIDTH"}
    --     end
    -- end
}
