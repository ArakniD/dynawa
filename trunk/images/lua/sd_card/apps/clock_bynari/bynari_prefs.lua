--Bynari Clock settings
require ("dynawa")

local after_select = {close_menu = true}

local menu_result = function(event)
	assert(event.value)
	if my.globals.prefs.style ~= event.value then
		my.globals.prefs.style = event.value
		dynawa.file.save_data(my.globals.prefs)
	end
	dynawa.event.send{type="open_popup", text="Color scheme changed"}
end

local open_your_menu = function(event)
	local menu = {
		banner = "Bynari color schemes",
		active_value = assert(my.globals.prefs.style),
		items = {
			{
				text = "Rainbow", value = "default", after_select = after_select
			},
			{
				text = "Planet Earth", value = "blue/green", after_select = after_select
			},
			{
				text = "Pure snow", value = "white", after_select = after_select
			},
			{
				text = "Inferno", value = "red", after_select = after_select
			},

			{
				text = "Rainbow", value = "default", after_select = after_select
			},
			{
				text = "Planet Earth", value = "blue/green", after_select = after_select
			},
			{
				text = "Pure snow", value = "white", after_select = after_select
			},
			{
				text = "Inferno", value = "red", after_select = after_select
			},
			{
				text = "Rainbow", value = "default", after_select = after_select
			},
			{
				text = "Planet Earth", value = "blue/green", after_select = after_select
			},
			{
				text = "Pure snow", value = "white", after_select = after_select
			},
			{
				text = "Inferno", value = "red", after_select = after_select
			},
			{
				text = "Rainbow"
			},
			{
				text = "Planet Earth"
			},
			{
				text = "Pure snow", value = "white", after_select = after_select
			},
			{
				bitmap = dynawa.bitmap.new(99,25,255,0,0), value = "red", after_select = after_select
			},
			{
				text = "Rainbow", value = "default", after_select = after_select
			},
			{
				text = "Planet Earth", value = "blue/green", after_select = after_select
			},
			{
				text = "Pure snow", value = "white", after_select = after_select
			},
			{
				text = "Inferno", value = "red", after_select = after_select
			},

		},
	}
	dynawa.event.send{type="open_my_menu", menu=menu}
end

dynawa.event.receive{event = "open_your_menu", callback = open_your_menu}
dynawa.event.receive{event = "menu_result", callback = menu_result}

--[[local function show_menu(event)
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
	assert(event.value)
	dynawa.event.send{type="new_widget", notification = {text="Color scheme changed", autoclose = true}}
	if my.globals.prefs.style ~= event.value then
		my.globals.prefs.style = event.value
		dynawa.file.save_data(my.globals.prefs)
	end
end]]

--dynawa.event.receive{event = "widget_result", callback = widget_done}

