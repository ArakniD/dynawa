local bmp_button_hold

if false then
	bmp_button_hold = dynawa.bitmap.from_png_file("test_test.png");
else
	local f = assert(io.open("test_test.png", "r"))
	png = f:read("*all")
	f:close()
	bmp_button_hold = dynawa.bitmap.from_png(png);
end

bmp = {
	[0] = dynawa.bitmap.new(160, 128, 0, 0, 255);
	--dynawa.bitmap.new(160, 128, 255, 0, 0);
	dynawa.bitmap.copy(bmp_button_hold, 80, 64, 160, 128),
	dynawa.bitmap.new(160, 128, 0, 255, 0);
	dynawa.bitmap.new(160, 128, 255, 255, 0, 0);
	dynawa.bitmap.new(160, 128, 0, 255, 255)
}

timer1 = dynawa.timer.start(700, false)
--print("timerX "..tostring(timer1))
timer2 = dynawa.timer.start(1000, false)
dynawa.timer.cancel(timer1)

dynawa.bitmap.copy(bmp_button_hold, 16, 24, 8, 16)

dynawa.bitmap.copy(bmp_button_hold, -8, -16, 16, 24)
dynawa.bitmap.copy(bmp_button_hold, 155, -16, 16, 24)
dynawa.bitmap.copy(bmp_button_hold, -8, 120, 16, 24)
dynawa.bitmap.copy(bmp_button_hold, 155, 120, 16, 24)

dynawa.bitmap.copy(bmp_button_hold, -8, -16, 200, 200)

dynawa.bitmap.copy(bmp_button_hold, -8, -16, 4, 7)

dynawa.bitmap.copy(bmp_button_hold, -8, -8, 165, 1)
dynawa.bitmap.copy(bmp_button_hold, -8, -16, 1, 400)
dynawa.bitmap.copy(bmp_button_hold, 165, -16, 1, 400)
dynawa.bitmap.copy(bmp_button_hold, -8, 140, 165, 1)

--dynawa.bitmap.show(dynawa.bitmap.combine(bmp_button_hold, dynawa.bitmap.copy(bmp_button_hold, 80, 64, 80, 64), 20, 20))
--dynawa.bitmap.show(dynawa.bitmap.combine(bmp_button_hold, dynawa.bitmap.copy(bmp_button_hold, 80, 64, 80, 64), -4, -8))
--dynawa.bitmap.show(dynawa.bitmap.combine(bmp_button_hold, dynawa.bitmap.copy(bmp_button_hold, 80, 64, 80, 64), 100, 100, true))

mask = dynawa.bitmap.copy(bmp_button_hold, 80, 64, 80, 64);
masked_bmp = dynawa.bitmap.mask(bmp_button_hold, mask, -4, -4)
dynawa.bitmap.show(dynawa.bitmap.combine(bmp_button_hold, masked_bmp, 10, 10))

--[[repeat
	local ch = io.read(1)
	io.write("ch="..ch.."("..string.byte(ch)..")\n")
until ch == "X"]]

local i = 0
while true do
	local line=io.read("*l")
	if line then
		print(i.." ("..#line.." chars): "..tostring(line).."\n")
	end
	i=i+1
	dynawa.bitmap.show(bmp[i%4])
end

function event_loop(event)
	print("ev type " .. event.type)
	if event.type == 1 then
		print("button " .. event.button)
		dynawa.bitmap.show(bmp[event.button])
	elseif event.type == 2 then
		print("button hold " .. event.button)
		dynawa.bitmap.show(bmp_button_hold)
	end
end
