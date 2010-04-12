local class = Class("AppManager")

function class:_init()
	self.all_apps = {}
	self.app_in_front = false
	--#todo Button events should go thru Window Manager!
	dynawa.devices.buttons:register_for_events(self)
	dynawa.devices.buttons.virtual:register_for_events(self)
end

function class:app_to_front(app)
	assert(app.is_app)
	if self.app_in_front then
		self.app_in_front.in_front = nil
	end
	self.app_in_front = app
	app.in_front = true
end

function class:handle_event_button(event)
	if self.app_in_front then
		self.app_in_front:handle_event(event)
	end
end

function class:handle_event_do_superman()
--[[	local app = self.app_in_front
	if app then
		if app.showing_menu then
			dynawa.superman:virtual_button(assert(event.type), app)
			return
		end
		--#todo not in menu
	end]]
end

function class:handle_event_do_menu()
end

function class:handle_event_do_switch()
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
Aplikace:
Zobrazuje bitmapy, reaguje na tlacitka.

Zobrazi menu, prestava reagovat na tlacitka, ceka az se menu vrati.

Otevre jinou aplikaci, prestava reagovat na tlacitka, ceka az se jina aplikace vrati

Nasilne prevezme kontrolu.

Vrati kontrolu "predchozimu ve stacku".


]]

