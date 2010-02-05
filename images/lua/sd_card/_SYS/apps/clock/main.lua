require("dynawa")

local mem_min,mem_max = 9999999, 0
local bg = dynawa.bitmap.from_png_file(my.dir.."mockup.png")
local count = 0
local tick_interval = 333
local sleeping = true

local function tick()
	if sleeping then
		return
	end
	count = count + 1
	local mem = collectgarbage("count")*1024
	if mem > mem_max then
		mem_max = mem
	end
	if mem < mem_min then
		mem_min = mem
	end
	local scr = dynawa.bitmap.combine(bg,dynawa.bitmap.text_line(string.format("TICKS %s / MEM %s",count,mem)),0,0,true)
	dynawa.bitmap.combine(scr,dynawa.bitmap.text_line(string.format("min %s / max %s",mem_min,mem_max),nil,{255,99,255}),0,11)
	dynawa.event.send{type="display_bitmap",bitmap=scr}
	local when = tick_interval - (dynawa.ticks() % tick_interval)
	dynawa.delayed_callback{time=when,callback=tick}
end

local function to_front()
	sleeping = false
	tick()
end

local function to_back()
	sleeping = true
end

dynawa.event.receive {event="you_are_now_in_front", callback=to_front}
dynawa.event.receive {event="you_are_now_in_back", callback=to_back}
dynawa.event.send("me_to_front")

