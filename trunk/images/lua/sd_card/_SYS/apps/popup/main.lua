local function open_popup(event)
	local bgbmp = event.background
	if type(bgbmp) == "table" then
		bgbmp = dynawa.bitmap.new(dynawa.display.size.width, dynawa.display.size.height, unpack(bgbmp))
	end
	if not bgbmp then
		bgbmp = event.sender.app.screen
		log("Sender screen = "..tostring(event.sender.screen))
	end
	my.globals.sender = event.sender.app
	
	local bgcolor = {0,40,0}
	if event.style == "error" then
		bgcolor = {128,0,0}
	end
	local textbmp = dynawa.bitmap.text_line(event.text,nil)
	local txtw,txth = dynawa.bitmap.info(textbmp)
	local w,h = txtw + 8, txth + 8
	local bmp = dynawa.bitmap.new(w,h, unpack(bgcolor))
	dynawa.bitmap.border(bmp,2,{255,255,255})
	dynawa.bitmap.border(bmp,1,{0,0,0})
	dynawa.bitmap.combine(bmp, textbmp, 4, 4)
	local start = {math.floor((dynawa.display.size.width - w) / 2), math.floor((dynawa.display.size.height - h) / 2)}
	local screen
	if bgbmp then
		screen = dynawa.bitmap.combine(bgbmp, bmp, start[1], start[2], true)
	else --We don't have active screen, fall back to black background
		screen = dynawa.bitmap.combine(dynawa.bitmap.new(dynawa.display.size.width, dynawa.display.size.height, 0,0,0), bmp, start[1], start[2])
	end
	dynawa.event.send {type = "display_bitmap", bitmap = screen}
	dynawa.event.send {type = "me_to_front"}
end

local function button(event)
	if event.type == "button_down" then
		local sender = my.globals.sender
		assert (sender ~= my.app)
		if sender.screen then
			dynawa.event.send{type = "app_to_front", app=sender}
		else
			dynawa.event.send{type = "default_app_to_front"}
		end
		dynawa.event.send {type = "popup_done"}
		dynawa.event.send {type = "display_bitmap", bitmap = nil}
	end
end

my.app.name = "Popup"
dynawa.event.send{type = "set_flags", flags = {ignore_app_switch = true, ignore_menu_open = true}}
dynawa.event.receive{event="open_popup",callback=open_popup}
dynawa.event.receive{events={"button_down","button_up","button_hold"}, callback = button}

