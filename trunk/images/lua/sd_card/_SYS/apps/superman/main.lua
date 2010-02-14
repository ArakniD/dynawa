----SuperMan

my.globals.show_menu = function(args)
	args = args or {}
	local location = args.location
	local menu
	if not location then --root menu
		menu = {
			{text = "Adjust clock", location = "adjust_clock:"},
			{text = "File browser", location = "file_browser:"},
			{text = "Nothing1"},
			{text = "Nothing2"},
		}
	else
		error("Unknown SuperMan location")
	end
	
	local menu2 = {items={}}
	menu2.banner = menu.banner or "SuperMan"
	menu2.border_color = {200,200,0}
	menu2.fullscreen = true
	for i,item in ipairs(menu) do
		local item2 = {text = assert(item.text)}
		if item.location then
			item2.value={go_to=item.location}
		end
		table.insert(menu2.items, item2)
	end
	dynawa.event.send{type="new_widget", menu = menu2}
end

local function launch(event)
	my.globals.show_menu{location=nil}
end

local function widget_result(event)
	log("Superman got result")
	for i = 1,1000 do
		dynawa.busy()
	end
	--dynawa.event.send{type="close_widget"}
end

local function me_in_front(event)
	dynawa.event.send{type="default_app_to_front"}
end

my.app.name = "SuperMan"
dynawa.dofile(my.dir.."menus.lua")
dynawa.event.receive{event="launch_superman",callback=launch}
dynawa.event.receive{event="widget_result",callback=widget_result}
dynawa.event.receive{event="you_are_now_in_front",callback=me_in_front}

