--Clock settings
require ("dynawa")

local function show_menu(event)
	local menu = {
		banner = "Clock settings",
		items = {
			"Set time zone",
			"Adjust clock",
			"Very long string 1234567890 really very long, WOW it's totally huge line!",
		}
	}
	for i = 1, 20 do
		table.insert(menu.items,"Dummy item #"..i)
	end
	dynawa.event.send{type="new_widget", menu = menu}
end

dynawa.event.receive{event = "show_menu", callback = show_menu}

