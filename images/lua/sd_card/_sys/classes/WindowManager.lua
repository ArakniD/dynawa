local class = Class("WindowManager")

function class:_init()
	self._windows = {}
	self.front_window = false
	self._last_displayed_window = false
end

function class:register_window(window)
	assert (not self._windows[window], "Window already registered")
	self._windows[window] = true --#todo more info
end

function class:unregister_window(window)
	assert (self._windows[window], "Window not registered")
	if window == self.front_window then
		self.front_window = false
	end
	self._windows[window] = nil
end

function class:window_to_front(window)
	assert(window)
	if self.front_window == window then
		error(window.." is already in front")
	end
	--#todo send Events
	self.front_window = window
end

function class:update_display()
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

return class

