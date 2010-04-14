app.name = "Window Manager"
app.id = "dynawa.window_manager"

function app:start()
	self._windows = {}
	self.front_window = false
	self._last_displayed_window = false
	self.stack = {}
	dynawa.devices.buttons:register_for_events(self)
	dynawa.devices.buttons.virtual:register_for_events(self)
	dynawa.settings.switchable = {"dynawa.clock_bynari"}
	dynawa.app_manager:start_app(dynawa.dir.apps.."clock_bynari/bynari_app.lua")
end

function app:handle_event_do_switch()
	self:pop_all()
	local switchable = dynawa.settings.switchable
	if #switchable <= 1 then
		return self:show_default()
	end
end

function app:show_default()
	local app_id = dynawa.settings.switchable[1]
	if not app_id then
		dynawa.superman:open_menu_by_url("root")
	else
		local app = dynawa.app_manager:app_by_id(app_id)
		assert(app, "This app is not running: "..app_id)
		--log("Switching to front: "..app)
		app:switched_to_front()
	end
end

function app:push(x)
	assert(x.is_window)
	for i,w in ipairs(self.stack) do
		if w==x then
			error(x.." is already present in window stack")
		end
	end
	table.insert(self.stack,1,x)
	self:window_to_front(x)
	log("Pushed "..x)
end

function app:pop()
	local x = assert(table.remove(self.stack,1),"Nothing to pop from stack")
	assert(x.is_window)
	log("Popped "..x)
	if next(self.stack) then
		self:window_to_front(self.stack[1])
	else
		self:show_default()
	end
	return x
end

function app:pop_all()
	for i,window in ipairs(self.stack) do
		if window.app == dynawa.superman then
			window:_delete()
		end
	end
	self.stack = {}
	self.front_window = false
	log("Popped all windows")
end

function app:register_window(window)
	assert (not self._windows[window], "Window already registered")
	self._windows[window] = true --#todo more info
	--log("Registered "..window)
end

function app:unregister_window(window)
	assert (self._windows[window], "Window not registered")
	if window == self.front_window then
		self.front_window = false
	end
	self._windows[window] = nil
	--log("Unregistered "..window)
end

function app:window_to_front(window)
	assert(window.is_window)
	if self.front_window then
		if self.front_window == window then
			error(window.." is already in front")
		end
		self.front_window.in_front = false
	end
	self.front_window = window
	window.in_front = true
	window:you_are_now_in_front()
end

function app:update_display()
	local window = self.front_window
	if not window then
		return
	end
	if window.updates.full or self._last_displayed_window ~= window then
		dynawa.bitmap.show(window.bitmap,dynawa.devices.display.flipped)
	else
		for _, region in ipairs(window.updates.regions) do
			dynawa.bitmap.show_partial(window.bitmap,region.x,region.y,region.w,region.h,region.x,region.y,
					dynawa.devices.display.flipped)
			--log("Display_update "..region.x..","..region.y..","..region.w..","..region.h)
		end
	end
	window:allow_partial_update()
	self._last_displayed_window = window
end

function app:handle_event_button(event)
	if self.front_window then
		self.front_window:handle_event_button(event)
	end
end

function app:handle_event_do_superman()
	self:pop_all()
	dynawa.superman:open_menu_by_url("root")
end

function app:handle_event_do_menu()
end

return app

