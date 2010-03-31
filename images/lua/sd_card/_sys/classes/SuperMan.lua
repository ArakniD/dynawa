local class = Class("SuperMan")

function class:menu_test()
	local menu_def = {
		banner = {
			text="Test menu with loooong title"
			},
		items = {
			{text = "Menu item 1"},
			{text = "Menu item 2"},
			{text = "Menu item 3 is multiline because it's longer"},
			{text = "Menu item 4"},
			{text = "Menu item 5"},
			{text = "Menu item 6"},
			{text = "Menu item 7"},
			{text = "Menu item 8"},
			{text = "Menu item 9"},
			{text = "Menu item 10"},
			{text = "This is the eleventh item of this menu and it's longer!"},
			{text = "Menu item 12"},
			{text = "Menu item 13"},
			{text = "Menu item 14"},
			{text = "Menu item 15"},
			{text = "Menu item 16"},
			{text = "Menu item 17"},
			{text = "Menu item 18"},
			{text = "Menu item 19"},
			{text = "Menu item 20"},
		},
	}
	local menu = Class.Menu(menu_def)
	menu:render()
	menu:hook_button_events()
	dynawa.window_manager:window_to_front(assert(menu.window))
end

function class:start()
	self:menu_test()
end

return class

