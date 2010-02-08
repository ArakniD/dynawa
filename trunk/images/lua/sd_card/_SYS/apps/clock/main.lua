require("dynawa")

local run_id
local fonts

local function small_print(bitmap, chars, x)
	local width, height = 13, 25
	local y = 127 - height
	for i, char in ipairs(chars) do
		if char >= 0 then --negative char == space
			dynawa.bitmap.combine(bitmap, fonts.small[char], x, y)
		end
		x = x + width + 2
	end
	return x
end

local function full_render(time, full)
	local top = 40
	local bitmap = dynawa.bitmap.new(160,128,0,0,0)
	local b_combine = dynawa.bitmap.combine

	local sec1 = math.floor(time.sec / 10)
	local sec2 = time.sec % 10
	local min1 = math.floor(time.min / 10)
	local min2 = time.min % 10
	local hour1 = math.floor(time.hour / 10)
	local hour2 = time.hour % 10

	b_combine(bitmap,fonts.large[hour1], 0, top)
	b_combine(bitmap,fonts.large[hour2], 27, top)
	b_combine(bitmap,fonts.large[min1], 69, top)
	b_combine(bitmap,fonts.large[min2], 96, top)
	b_combine(bitmap,fonts.medium[sec1], 160 - 17 - 18, top)
	b_combine(bitmap,fonts.medium[sec2], 160 - 17, top)
	
	small_print(bitmap, {time.wday * 2 + 10, time.wday * 2 + 11}, 1) --day of week
	local day1 = math.floor(time.day / 10)
	local day2 = time.day % 10
	if day1 == 0 then
		day1 = -1
	end
	
	local month1 = -1 --space
	local month2 = time.month % 10
	if time.month >= 10 then
		month1 = 1
	end
	
	local year1 = math.floor((time.year % 100) / 10)
	local year2 = time.year % 10
	
	small_print(bitmap,{day1, day2, 10}, 42)
	small_print(bitmap,{month1, month2, 10}, 76)
	small_print(bitmap,{11, year1, year2}, 161 - (3*15))
	
	dynawa.bitmap.combine(bitmap,fonts.dot,58,40+11)
	dynawa.bitmap.combine(bitmap,fonts.dot,58,40+31)

	dynawa.event.send{type="display_bitmap",bitmap=bitmap}
end

local function remove_dots(event)
	if not my.app.in_front then
		return
	end
	local black = dynawa.bitmap.new(5,5,0,0,0)
	dynawa.event.send{type="display_bitmap", bitmap = black, at={58,40+11}}
	dynawa.event.send{type="display_bitmap", bitmap = black, at={58,40+31}}
end

local function tick(event)
	if (run_id ~= event.run_id) or (not my.app.in_front) then
		return
	end
	local sec,msec = dynawa.time.get()
	full_render(os.date("*t",sec), event.full_render)

--[[
	my.globals.count_t = ((my.globals.count_t or 0) + 1) % 60
	local t1,t3 = dynawa.time.get()
	t1 = t1 % 60
	local t2 = my.globals.count_t
	local t0 = t2 - t1
	if t0 < 0 then
		t0 = t0 + 60
	end
	log("Timers difference "..t0.." ("..t1.." + "..t3.." ms, "..t2..")")
]]
	
	local sec2,msec2 = dynawa.time.get()
	local when = 1100 - msec2
	if when >= 1000 or (sec ~= sec2) then 
		when = 800
	end
	dynawa.delayed_callback{time=when, callback=tick, run_id = run_id}
	if when > 600 then
		dynawa.delayed_callback{time=500, callback=remove_dots}
	end
end

local function to_front()
	run_id = dynawa.unique_id()
	tick{run_id = run_id, full_render = true}
end

local function to_back()
	run_id = nil
end

local function font_init()
	local bmap = assert(dynawa.bitmap.from_png_file(my.dir.."digits.png"))
	fonts={small={},medium={},large={}}
	local b_copy = dynawa.bitmap.copy
	for i=0,9 do
		fonts.large[i] = b_copy(bmap,i*26,70,24,47)
	end
	for i=0,9 do
		fonts.medium[i] = b_copy(bmap,i*18,30,16,31)
	end
	for i=0,25 do
		fonts.small[i] = b_copy(bmap,i*15,0,13,25)
	end
	fonts.dot = b_copy(bmap,0,65,5,5)
	fonts.black = b_copy(bmap,5,65,5,5)
end

my.app.name = "Default Clock"
my.app.priority = "A"
dynawa.task.start(my.dir.."clock_menu.lua")
font_init()
dynawa.time.set(1234567890)
dynawa.event.receive {event="you_are_now_in_front", callback=to_front}
dynawa.event.receive {event="you_are_now_in_back", callback=to_back}
dynawa.event.send("me_to_front")

