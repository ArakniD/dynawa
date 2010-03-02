--Text Input
require("dynawa")

local function render()
	
end

local function open_text_input(message)
	my.globals.sender_message = message
	dynawa.message.send {type = "display_bitmap", bitmap = dynawa.bitmap.new(dynawa.display.size.width, dynawa.display.size.height, 0,0,0)}
	my.globals.string = message.string or ""
	my.globals.cursor = #my.globals.cursor
	render()
end

--[[
	local bgbmp = message.background
	if type(bgbmp) == "table" then
		bgbmp = dynawa.bitmap.new(dynawa.display.size.width, dynawa.display.size.height, unpack(bgbmp))
	end
	if not bgbmp then
		bgbmp = message.sender.app.screen
		--log("Sender screen = "..tostring(message.sender.screen))
	end
	my.globals.sender = message.sender.app
	log("Popup sender = "..my.globals.sender.name)
	
	local bgcolor = {0,40,0}
	if message.style == "error" then
		bgcolor = {128,0,0}
	end
	local textbmp = dynawa.bitmap.text_lines{width = math.floor(dynawa.display.size.width * 0.8), autoshrink = true, center = true, text = message.text}
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
	dynawa.message.send {type = "display_bitmap", bitmap = screen}
	dynawa.message.send {type = "me_to_front"}
end]]

local function button(message)
	if message.type == "button_down" then
		local sender = my.globals.sender
		assert (sender ~= my.app)
		if sender.screen then
			dynawa.message.send{type = "app_to_front", app=sender}
		else
			dynawa.message.send{type = "default_app_to_front"}
		end
		dynawa.message.send {type = "text_input_done"}
		if my.globals.sender_message.callback then
			dynawa.message.send {task = assert(my.globals.sender_message.sender), callback = my.globals.sender_message.callback, string = my.globals.string}
		end
		dynawa.message.send {type = "display_bitmap", bitmap = nil}
	end
end

local function init()
	local font7 = "/_sys/fonts/default7.png"
	local font10 = "/_sys/fonts/default10.png"
	local menus = {
		{"Accept text","Delete char","Move <<","Move >>","DELETE ALL"},
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
		"abcdefghijklmnopqrstuvwxyz",
		"0123456789",
		" .,@?!+-*/:;()[]{}<=>#$%^&_|\\'~",
	}
	my.globals.menus = {}
	for menu_n, menu0 in ipairs(menus) do
		local menu = {}
		for item_n = 1, #menu0 do
			local item
			if menu_n == 1 then
				item = menu0[item_n]
			else
				--log("menu0="..menu0)
				item = menu0:sub(item_n, item_n)
			end
			table.insert(menu, item)
		end
		menu.index = 1
		table.insert(my.globals.menus, menu)
		dynawa.busy()
	end
	my.globals.menus.active = 2
end

my.app.name = "Text Input"
dynawa.message.send{type = "set_flags", flags = {ignore_app_switch = true, ignore_menu_open = true}}
dynawa.message.receive{message="open_text_input",callback=open_text_input}
dynawa.message.receive{messages={"button_down","button_up","button_hold"}, callback = button}
init()
