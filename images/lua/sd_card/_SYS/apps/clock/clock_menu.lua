--Clock settings
require ("dynawa")

local function show_menu(event)
	local menu = {
		banner = "Clock settings",
		items = {
			{text="Blah",value="no"},
			{text="Blah2",value="no"},
			{text="Blah3",value="no"},
			{text="Very long string 1234567890 really very long, WOW it's totally huge line!",value="no"},
			{text="BlahCCC",value="no"},
			{text="Blah2",value="no"},
			{text="Blah3",value="no"},
			{text="Blah4",value="no"},
			{text="Blah5",value="no"},
		}
	}
	for i = 1, 20 do
		table.insert(menu.items,{text="Dummy item #"..i,value="no"})
	end
	dynawa.event.send{type="new_widget", menu = menu}
end

dynawa.event.receive{event = "show_menu", callback = show_menu}

