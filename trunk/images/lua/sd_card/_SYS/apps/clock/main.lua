require("dynawa")

local mem_min,mem_max = 9999999, 0
local bg = dynawa.bitmap.from_png_file(my.dir.."neo.png")
log(bg)
local count = 0
local tick_interval = 333

local function tick()
	count = count + 1
	local mem = collectgarbage("count")*1024
	if mem > mem_max then
		mem_max = mem
	end
	if mem < mem_min then
		mem_min = mem
	end
	local scr = dynawa.bitmap.combine(bg,dynawa.bitmap.text_line(string.format("TICKS %s / MEM %s",count,mem)),0,50,true)
	dynawa.bitmap.combine(scr,dynawa.bitmap.text_line(string.format("min %s / max %s",mem_min,mem_max),nil,{255,99,255}),0,80)
	dynawa.display.app_screen(scr)
	local when = tick_interval - (dynawa.ticks() % tick_interval)
	dynawa.delayed_callback{time=when,callback=tick}
end

tick()
