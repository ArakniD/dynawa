local class = Class("AppManager")

function class:_init()
	self.all_apps = {}
end

function class:start_app(filename)
	dynawa.busy()
	local chunk = assert(loadfile(filename))
	local app = Class.App(filename)
	rawset(_G, "app", app)
	chunk()
	rawset(_G, "app", nil)
	assert(not self.all_apps[app.id], "App with id "..app.id.." is already running")
	self.all_apps[app.id] = app
	app:start(app)
	return app
end

return class

--[[
Bynari_app.lua:

function app:start()
	init gfx
end

function app:my_window()
	self.window = self:render()
	return self.window
end

function app:my_menu(url)
	assert(url == "root")
	local def = {
		banner = "Select color scheme",
		items = {
			{text = "Rainbow", result = {style = "rainbow"}},
			{text = "Black & White", result = {style = "black_white"}},
		}
	}
	return Class.MenuWindow(def)
end
------------------------------
Remote BD controller.app

function app:start()
	dynawa.bt_manager.evetnts.unknown_device:register_for_events(self)
end

function handle_event_unknown_bt_device(args)
	--analyze
	dynawa.bt_manager:register_device(blabla)
end

app:my_window()
	self.window = self:render()
	return self.window
end

app:button_event()
	--do something
	self:update()
end

-------------------------------------
Aplikace:
Zobrazuje bitmapy, reaguje na tlacitka.

Zobrazi menu, prestava reagovat na tlacitka, ceka az se menu vrati.

Otevre jinou aplikaci, prestava reagovat na tlacitka, ceka az se jina aplikace vrati

Nasilne prevezme kontrolu.

Vrati kontrolu "predchozimu ve stacku".


]]

