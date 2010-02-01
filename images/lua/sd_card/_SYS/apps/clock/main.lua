require("dynawa")

local mem_min,mem_max = 9999999, 0

local function tick()
	local mem = collectgarbage("count")*1024
	if mem > mem_max then
		mem_max = mem
	end
	if mem < mem_min then
		mem_min = mem
	end
	log(string.format("Tick... MEM=%s / %s / %s",mem,mem_min,mem_max))
	local when = 200 - (dynawa.ticks() % 200)
	when = 100 ---
	dynawa.delayed_callback{time=when,callback=tick}
end

--tick()

