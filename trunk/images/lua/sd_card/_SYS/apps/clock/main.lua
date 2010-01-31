require("dynawa")

local function tick()
	log("Tick... "..collectgarbage("count"))
end

tick()
dynawa.delayed_callback{time=200,callback=tick,autorepeat=true}

