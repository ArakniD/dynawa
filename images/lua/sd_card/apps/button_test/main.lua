require("dynawa")

my.app.name = "Button Test App"
local switch
local screen = dynawa.bitmap.new (160,128,80,0,0)
local count = 0

local function scroll_line(text)
	local line, width, height = dynawa.bitmap.text_line(text)
	screen = dynawa.bitmap.copy(screen,0,height,160,128)
	local line2 = dynawa.bitmap.combine(dynawa.bitmap.new(160,height,math.random(200),math.random(200),math.random(200)),line,0,0)
	dynawa.bitmap.combine(screen,line2,0,128-height)
	dynawa.message.send{type="display_bitmap",bitmap=screen}
end

local function receive(msg)
	count = count + 1
	scroll_line(count..": "..msg.button.." "..msg.type)
	if msg.button=="CONFIRM" and msg.type=="button_hold" then
		switch = not switch
		if switch then
			dynawa.message.stop_receiving{message="button_down"}
		else
			dynawa.message.receive{message="button_down", callback=receive}
		end
	end
end

scroll_line("BUTTONS+SCROLLING TEST APP :)")
dynawa.message.receive{messages={"button_up","button_down","button_hold"}, callback=receive}

