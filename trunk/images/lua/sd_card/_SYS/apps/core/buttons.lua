require("dynawa")

local switch
local screen = dynawa.bitmap.new (160,128,80,0,0)
local count = 0
--local line, width, height = dynawa.bitmap.text_line("blablabla TEST TEST TEST ?!@#$%")

local function scroll_line(text)
	local line, width, height = dynawa.bitmap.text_line(text)
	screen = dynawa.bitmap.copy(screen,0,height,160,128)
	local line2 = dynawa.bitmap.combine(dynawa.bitmap.new(160,height,math.random(200),math.random(200),math.random(200)),line,0,0)
	dynawa.bitmap.combine(screen,line2,0,128-height)
	dynawa.bitmap.show(screen)
end

local function receive(event)
	count = count + 1
	scroll_line(count..": "..event.button.." "..event.type)
	if event.button=="CONFIRM" and event.type=="button_hold" then
		switch = not switch
		if switch then
			dynawa.event.stop_receiving{event="button_down"}
		else
			dynawa.event.receive{event="button_down", callback=receive}
		end
	end
end

dynawa.event.receive{events={"button_up","button_down","button_hold"}, callback=receive}

