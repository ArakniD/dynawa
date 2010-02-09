require("dynawa")

local run_id
local fonts

local function display(bitmap, x, y)
	assert(bitmap)
	assert(x)
	assert(y)
	dynawa.event.send{type="display_bitmap", bitmap = bitmap, at={x,y}}
end

local function small_print(chars, x)
	local width, height = 13, 25
	local y = 127 - height
	for i, char in ipairs(chars) do
		if char >= 0 then --negative char == space
			display(fonts.small[char], x, y)
		end
		x = x + width + 2
	end
	return x
end

local function render_date(time)
	small_print({time.wday * 2 + 10, time.wday * 2 + 11}, 1) --day of week
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

	small_print({day1, day2, 10}, 42)
	small_print({month1, month2, 10}, 76)
	small_print({11, year1, year2}, 161 - (3*15))
end

local function render(time, full)
	if full == "no_time" then
		render_date(time)
		return
	end
	local top = 40
	local sec1 = math.floor(time.sec / 10)
	local sec2 = time.sec % 10
	local mm_hh = full

	display(fonts.medium[sec2], 160 - 17, top)
	display(fonts.dot,58,40+11)
	display(fonts.dot,58,40+31)
	if full or sec2 == 0 then
		display(fonts.medium[sec1], 160 - 17 - 18, top)
		if sec1 == 0 then
			mm_hh = true
		end
	end
	
	if mm_hh or full then
		local min1 = math.floor(time.min / 10)
		local min2 = time.min % 10
		local hour1 = math.floor(time.hour / 10)
		local hour2 = time.hour % 10
		display(fonts.large[hour1], 0, top)
		display(fonts.large[hour2], 27, top)
		display(fonts.large[min1], 69, top)
		display(fonts.large[min2], 96, top)
		if time.hour + time.min == 0 then --Midnight
			full = true
		end
	end
	
	if full then
		render_date(time)
	end
	
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
	render(os.date("*t",sec), event.full_render)

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
	local when = 1000 - msec2
	if event.full_render == "no_time" then
		event.full_render = true
	elseif event.full_render then
		event.full_render = nil
	end
	dynawa.delayed_callback{time=when, callback=tick, run_id = run_id, full_render = event.full_render}
	if when > 700 then
		dynawa.delayed_callback{time=666, callback=remove_dots}
	end
end

local function to_front()
	run_id = dynawa.unique_id()
	display(dynawa.bitmap.new(160,128,0,0,0),0,0)
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
dynawa.time.set(1234569580)
dynawa.event.receive {event="you_are_now_in_front", callback=to_front}
dynawa.event.receive {event="you_are_now_in_back", callback=to_back}
dynawa.event.send("me_to_front")

