--Bynari Clock settings
require ("dynawa")

local after_select = {popup = "Color scheme changed"}

local menu_result = function(event)
	assert(event.value)
	if my.globals.prefs.style ~= event.value then
		my.globals.prefs.style = event.value
		dynawa.file.save_data(my.globals.prefs)
	end
--	dynawa.event.send{type="open_popup", text="Color scheme changed"}
end

local your_menu = function(event)
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
	return menu
	--dynawa.event.send{type="open_my_menu", menu=menu}
end

dynawa.event.receive{event = "your_menu", callback = your_menu}
dynawa.event.receive{event = "menu_result", callback = menu_result}

