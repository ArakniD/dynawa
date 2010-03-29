local Object = Class:get_by_name("Object")
local class = Class("SuperMan",nil,Object)

function class:_init()
	Object._init(self)
end


function class:menu_test()
	local menu_def = {
		banner = {
			text="Test menu with loooong title"
			},
		items = {
			{text = "Menu line 1"},
			{text = "Menu line 2"},
			{text = "Menu line 3"},
			{text = "Menu line 4"},
			{text = "Menu line 5"},
			{text = "Menu line 6"},
			{text = "Menu line 7"},
			{text = "Menu line 8"},
			{text = "Menu line 9"},
			{text = "Menu line 10"},
			{text = "This is the eleventh line of this menu and it's longer!"},
			{text = "Menu line 12"},
			{text = "Menu line 13"},
			{text = "Menu line 14"},
			{text = "Menu line 15"},
			{text = "Menu line 16"},
			{text = "Menu line 17"},
			{text = "Menu line 18"},
			{text = "Menu line 19"},
			{text = "Menu line 20"},
		},
	}
	local menu = Class:get_by_name("Menu")(menu_def)
	menu:render()
	dynawa.tch.window_manager:window_to_front(assert(menu.window))
	dynawa.tch.window_manager:update_display()
end

function class:start()
	self.input_manager = Class:get_by_name("InputManager")()
	self:menu_test()
end

Class:add_public(class)
return class

