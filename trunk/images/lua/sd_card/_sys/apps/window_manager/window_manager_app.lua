app.name = "Window Manager"
app.id = "dynawa.window_manager"

function app:start()
	dynawa.window_manager = self
	self._windows = {}
	self.front_window = false
	self._last_displayed_window = false
	self.stack = {}
	dynawa.devices.buttons:register_for_events(self)
	dynawa.devices.buttons.virtual:register_for_events(self)
end

function app:show_default()
	local app_id = dynawa.settings.switchable[1]
	if not app_id then
		dynawa.superman:switching_to_front()
	else
		local app = dynawa.app_manager:app_by_id(app_id)
		assert(app, "This app is not running: "..app_id)
		--log("Switching to front: "..app)
		app:switching_to_front()
	end
end

function app:push(x)
	assert(x.is_window)
	for i,w in ipairs(self.stack) do
		if w==x then
			error(x.." is already present in window stack")
		end
	end
	if self.stack[1] then
		self.stack[1].in_front = nil
	end
	table.insert(self.stack,1,x)
	--self:window_to_front(x)
	x.in_front = true
	log("Pushed "..x)
end

function app:pop()
	local x = assert(table.remove(self.stack,1),"Nothing to pop from stack")
	assert(x.is_window, "Should be window")
	assert(x.in_front, "Should be front window")
	log("Popped "..x)
	x.in_front = nil
	if self.stack[1] then
		self.stack[1].in_front = true
	end
	return x
end

--This is a powerful but potentially dangerous method that pops all menuwindows from top of the stack
--and automatically deletes all of them (i.e. they should not be referenced from anywhere else at this point!).
--It stops at first window with no menu and returns this window (or nil, if there is no such window).
function app:pop_and_delete_menuwindows()
	while true do
		local window = self:peek()
		if not window then
			return nil
		end
		if window.menu then
			self:pop():_delete()
		else
			return window
		end
	end
end

function app:peek()
	return (self.stack[1])
end

function app:pop_allXXXXXXXXXXXXXX()
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
	self._windows[window] = window.id or true
	--log("Registered "..window)
end

function app:unregister_window(window)
	assert (self._windows[window], "Window not registered")
	self._windows[window] = nil
	--log("Unregistered "..window)
end

function app:window_to_front(window)
	error("to_front called")
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
	local window = self:peek()
	if not window then --No windows in stack
		return
	end
	if window.updates.full or self._last_displayed_window ~= window then
		--log("showing window "..window)
		if not window.bitmap then
			window.bitmap = dynawa.bitmap.new(dynawa.devices.display.size.w,dynawa.devices.display.size.h,255,0,0)
			dynawa.bitmap.combine(window.bitmap, dynawa.bitmap.text_lines{text=window.." has no bitmap!"},1,20)
		end
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
	local win = self:peek()
	if win then
		win:handle_event_button(event)
	end
end

function app:handle_event_do_switch()
	local win0 = self:peek()
	self:stack_cleanup()
	local switchable = dynawa.settings.switchable
	if not win0 or #switchable <= 1 then
		return self:show_default()
	end
	local id1 = assert(win0.app.id)
	local index1 = nil
	for i,id in ipairs(switchable) do
		if id == id1 then
			index1 = i
			break
		end
	end
	if not index1 then --The active app is not present in 'switchable'
		return self:show_default()
	end
	local index2 = index1 + 1
	if index2 > #switchable then
		index2 = 1
	end
	local id2 = switchable[index2]
	local app = dynawa.app_manager:app_by_id(id2)
	assert(app, "This app is not running: "..id2)
	app:switching_to_front()
end

function app:handle_event_do_superman()
	self:stack_cleanup()
	dynawa.superman:switching_to_front()
end

--Calls 'switching_to_back' on all apps referenced in stack, effectively clearing the stack.
function app:stack_cleanup()
	local last = "?"
	while true do
		local peekwin = self:peek()
		if not peekwin then
			return
		end
		if peekwin.app == last then
			error(peekwin.app.." did not remove all its windows from stack during 'switching_to_back', "..peekwin.." is on top")
		end
		last = peekwin.app
		last:switching_to_back(peekwin)
	end
end

function app:handle_event_do_menu()
	local win0 = self:peek()
	if win0 then
		return win0.app:handle_event_do_menu(win0)
	end
end

return app

