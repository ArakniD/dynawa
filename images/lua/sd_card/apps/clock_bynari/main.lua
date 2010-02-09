require("dynawa")

local clock
local gfx = {}
local dot_size = {w=25,h=17}

local function random_color()
	return {math.random(200)+55, math.random(200)+55, math.random(200)+55}
end

local function convert_coords(x,y)
	local xx = x * 27
	local yy = y * 19
	if y > 2 then
		yy = yy + 16
	end
	return xx,yy
end

local function display(bitmap, x, y)
	assert(bitmap)
	assert(x)
	assert(y)
	dynawa.event.send{type="display_bitmap", bitmap = bitmap, at={x,y}}
end

local function change_dot(x, y, gf, color)
	local recolor = dynawa.bitmap.new(dot_size.w,dot_size.h,unpack(color))
	local fg = dynawa.bitmap.mask(recolor, gfx[gf], 0, 0)
	local dot = dynawa.bitmap.combine(gfx.black, fg, 0, 0, true)
	display(dot, convert_coords(x,y))
end

local function text(time)
	local font = "/_sys/fonts/default10.png"
	local ticks = dynawa.bitmap.text_line(tostring(time.raw),font,{0,0,0})
	local mem, w, h = dynawa.bitmap.text_line(collectgarbage("count") * 1024 .." "..time.wday,font,{0,0,0})
	local bg = dynawa.bitmap.new (160, h, 200,200,200)
	dynawa.bitmap.combine(bg, ticks, 1, 1)
	dynawa.bitmap.combine(bg, mem, 159 - w, 1)
	local y = math.floor(64 - h / 2)
	display(bg, 0, y)
end

local function to_bin (num)
	local result = {}
	for i=5,0,-1 do
		result[i] = num % 2
		num = math.floor(num / 2)
	end
	return result
end

local function update_dots(time, status)
	local new = {}
	local clk = clock.state
	new[0] = to_bin(time.hour)
	new[1] = to_bin(time.min)
	new[2] = to_bin(time.sec)
	new[3] = to_bin(time.day)
	new[4] = to_bin(time.month)
	new[5] = to_bin(math.min(time.year % 100, 63))
	for i = 0, 5 do
		for j = 0, 5 do
			if clk[i][j].gfx ~= new[i][j] then
				local dot = clk[i][j]
				dot.gfx = new[i][j]
				if status ~= "first" then
					dot.color = {255,255,255}
				end
				change_dot(j,i,dot.gfx,dot.color)
			end
		end
	end
	local i = math.random(6) - 1
	local j = math.random(6) - 1
	local color = random_color()
	change_dot(j,i,clk[i][j].gfx,color)
	clk[i][j].color = color
end

local function tick(event)
	if not my.app.in_front or event.run_id ~= run_id then
		return
	end
	local time_raw, msec = dynawa.time.get()
	local time = os.date("*t", time_raw)
	time.raw = time_raw
	update_dots(time,event.status)
	text(time)
	local sec, msec = dynawa.time.get()
	local when = 1100 - msec
	dynawa.delayed_callback{time = when, callback = tick, run_id = event.run_id}
end

local function start()
	clock = {state={}}
	dynawa.event.send{type="display_bitmap", bitmap = dynawa.bitmap.new(160,128,0,0,0)}
	for i = 0, 5 do
		clock.state[i] = {}
		for j = 0, 5 do
			clock.state[i][j] = {gfx = "empty", color = random_color()}
			--change_dot(i,j,"empty",color)
		end
	end
	clock.run_id = dynawa.unique_id()
	tick{run_id = run_id, status = "first"}
end

local function to_front()
	start()
end

local function to_back()
	clock = {}
end

local function gfx_init()
	local bmap = assert(dynawa.bitmap.from_png_file(my.dir.."gfx.png"))
	local b_copy = dynawa.bitmap.copy
	gfx[0] = b_copy(bmap,0,0,dot_size.w,dot_size.h)
	gfx[1] = b_copy(bmap,25,0,dot_size.w,dot_size.h)
	gfx.empty = b_copy(bmap,50,0,dot_size.w,dot_size.h)
	gfx.black = dynawa.bitmap.new(dot_size.w,dot_size.h,0,0,0)
end

my.app.name = "Bynari Clock"
my.app.priority = "B"
gfx_init()
dynawa.time.set(1234569580)
dynawa.event.receive {event="you_are_now_in_front", callback=to_front}
dynawa.event.receive {event="you_are_now_in_back", callback=to_back}
dynawa.event.send{type="display_bitmap", bitmap = dynawa.bitmap.new(160,128,255,0,0)}

