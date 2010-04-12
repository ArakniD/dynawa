app.name = "Window Manager"
app.id = "dynawa.window_manager"

function app:start()
	self._windows = {}
	self.front_window = false
	self._last_displayed_window = false
	self.stack = {}
end

function app:show_default()
	dynawa.superman:open_menu_by_url("root")
end

function app:push(x)
	assert(x.is_menu) --#todo
	table.insert(self.stack,1,x)
end

function app:pop()
	local x = assert(table.remove(self.stack[1]),"Nothing to pop from stack")
	assert(x.is_menu) --#todo
	
end

function app:register_window(window)
	assert (not self._windows[window], "Window already registered")
	self._windows[window] = true --#todo more info
end

function app:unregister_window(window)
	assert (self._windows[window], "Window not registered")
	if window == self.front_window then
		self.front_window = false
	end
	self._windows[window] = nil
end

function app:window_to_front(window)
	log("error") -------------------#todo
	assert(window)
	if self.front_window == window then
		error(window.." is already in front")
	end
	--#todo send Events
	self.front_window = window
end

function app:update_display()
	local app = dynawa.app_manager.app_in_front
	if not app then
		return
	end
	local window = app.window
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

return app

