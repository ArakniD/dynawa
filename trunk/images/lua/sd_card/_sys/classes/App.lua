local class = Class("App")

function class:_init(id)
	self.id = assert(id)
	self.is_app = true
end

function class:start(id)
	log("Start method not defined for "..self)
end

function class:new_window()
	local win = Class.Window()
	win.app = self
	return win
end

function class:push_window(window)
	assert(window.is_window,"Not a window")
	window.app = self
	return dynawa.window_manager:push(window)
end

function class:_del()
	error("Attempt to delete an App: "..self)
end

function class:window_in_front(window)
end

function class:switched_to_front()
end

function class:handle_event_button()
end

return class

