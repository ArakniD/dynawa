require("dynawa")

my.name = "Default Clock"
local run_id
local fonts

local function full_render0(time)
	local bg = dynawa.bitmap.new(160,128,0,80,0)
	dynawa.bitmap.combine(bg,dynawa.bitmap.text_line(time.min.."-"..time.sec),60,60)
	return bg
end

local function small_print(bitmap, chars, x)
	local width, height = 13, 25
	local y = 127 - height
	for i, char in ipairs(chars) do
		dynawa.bitmap.combine(bitmap, fonts.small[char], x, y)
		x = x + width + 2
	end
	return x
end

local function full_render(time)
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
	
	return bitmap
end

local function dots_blink(event)
	if not my.app.in_front then
		return
	end
	dynawa.event.send{type="display_bitmap",bitmap=assert(event.bitmap)}
end

local function tick(event)
	if (run_id ~= event.run_id) or (not my.app.in_front) then
		return
	end
	local ts = os.date()
	local no_dots = full_render(os.date("*t"))

	local with_dots = dynawa.bitmap.combine(no_dots,fonts.dot,58,40+11,true)
	dynawa.bitmap.combine(with_dots,fonts.dot,58,40+31)

	dynawa.event.send{type="display_bitmap",bitmap=with_dots}
	
	local t1,t2 = os.date("*t").sec, math.floor(dynawa.ticks()/1000) % 60
	local t0 = t2 - t1
	if t0 < 0 then
		t0 = t0 + 60
	end
	log("Timers difference "..t0.." ("..t1.." "..t2..")")
	
	local when = 1000 - (dynawa.ticks() % 1000)
	dynawa.delayed_callback{time=when, callback=tick, run_id = run_id}
	if when > 500 then
		dynawa.delayed_callback{time=when-500, callback=dots_blink, bitmap = no_dots}
	end
end

local function to_front()
	run_id = dynawa.unique_id()
	tick{run_id = run_id}
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
end

font_init()
dynawa.time.set(1000000000)

dynawa.event.receive {event="you_are_now_in_front", callback=to_front}
dynawa.event.send("me_to_front")

