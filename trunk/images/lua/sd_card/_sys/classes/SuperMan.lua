local class = Class("SuperMan")

function class:open_menu_by_url(url)
	local builder = self.menu_builders[url]
	if not builder then
		error("Cannot get builder for url: "..url)
	end
	local menu = Class.Menu(builder(self,url)) 	--#todo URL parameters
	menu:render()
	menu:hook_button_events()
	dynawa.window_manager:window_to_front(assert(menu.window))
end

function class:start()
	self:open_menu_by_url("root")
end

class.menu_builders = {}

function class.menu_builders:root()
	local menu_def = {
		banner = {
			text="SuperMan root menu"
			},
		items = {
			{text = "Shortcuts"},
			{text = "Apps"},
			{text = "File browser"},
			{text = "Adjust time and date"},
			{text = "Default font size"},
		},
	}
	return menu_def
end

return class

