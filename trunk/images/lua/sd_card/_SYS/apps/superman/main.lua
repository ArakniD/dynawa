----SuperMan

local function get_menu_for_location(url)
	assert(url)
	local where, rest = url:match("(.-):(.*)")
	local fn = my.globals.menus[where]
	assert(fn, "Unknown go_to address: "..where)
	return assert(fn(rest),"No menu returned for location "..url)
end


my.globals.show_menu = function(args)
	args = args or {}
	local location = args.location
	local menu
	if not location then --root menu
		menu = {}
		menu.items = {
			{text = "Adjust clock", location = "adjust_clock:"},
			{text = "File browser", location = "file_browser:/"},
			{text = "Nothing1"},
			{text = "Nothing2"},
		}
	else
		menu = get_menu_for_location(location)
	end
	
	local menu2 = {items={}}
	menu2.banner = menu.banner or "SuperMan"
	menu2.border_color = {200,200,0}
	menu2.fullscreen = true
	for i,item in ipairs(menu.items) do
		local item2 = {text = assert(item.text)}
		--log("Added SuperMan menu text: "..item2.text)
		if item.location then
			item2.value={go_to=item.location}
		end
		table.insert(menu2.items, item2)
	end
	assert(#menu2.items > 0, "No menu items in SuperMan menu")
	dynawa.event.send{type="new_widget", menu = menu2}
end

local function launch(event)
	my.globals.show_menu{location=nil}
end

local function widget_result(event)
	log("Superman got result")
	local val = event.value
	if not val then
		for i = 1,1000 do
			dynawa.busy()
		end
		return
	end
	if val.go_to then
		my.globals.show_menu{location = val.go_to}
		return
	end
	log("Confirmation value not handled by SuperMan")
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

