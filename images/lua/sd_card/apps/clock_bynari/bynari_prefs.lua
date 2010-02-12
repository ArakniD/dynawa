--Clock settings
require ("dynawa")

local function show_menu(event)
	local menu = {
		banner = "Bynari colors:",
		active_value = assert(my.globals.prefs.style),
		items = {
			{text = "Rainbow", value = "default"},
			{text = "Planet Earth", value = "blue/green"},
			{text = "Pure white", value = "white"},
			{text = "Inferno", value = "red"},
		}
	}
	dynawa.event.send{type="new_widget", menu = menu}
end

local function widget_done (event)
	if event.status ~= "confirmed" then
		return
	end
	assert(event.item.value)
	--log(event.item.value)
	dynawa.event.send{type="new_widget", notification = {text="Color scheme changed", autoclose = true}}
	if my.globals.prefs.style ~= event.item.value then
		my.globals.prefs.style = event.item.value
		dynawa.file.save_data(my.globals.prefs)
	end
end

dynawa.event.receive{event = "show_menu", callback = show_menu}
dynawa.event.receive{event = "widget_result", callback = widget_done}

