local class = Class("App")
class.is_app = true

function class:_init(id)
	self.id = assert(id)
end

function class:start(id)
end

function class:new_window()
	local win = Class.Window()
	win.app = self
	return win
end

function class:new_menuwindow(menudef)
	local win = Class.Window()
	win.app = self
	local menu = Class.Menu(menudef)
	menu.window = win
	win.menu = menu
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

--[[function class:window_in_front(window)
end]]

function class:switching_to_front()
	dynawa.popup:open{text=self.." generated no graphical output. You must override its 'switching_to_front' method.",style="warning"}
end

function class:switching_to_back()
	local win = dynawa.window_manager:pop_and_delete_menuwindows()
	if win then
		assert(win:pop().app == self, "The first popped non-menu window does not belong to this app.")
	end
	local peek = dynawa.window_manager:peek()
	assert (not peek or peek.app ~= self, "After popping one non-menu window, there are still other windows of mine on stack")
end

function class:handle_event_button()
end

function class:handle_event_do_menu()
end

function class:menu_cancelled(menu)
	local peek = dynawa.window_manager:peek()
	assert (menu.window == peek, "Top menu window mismatch ("..menu.window.."/"..peek..")")
	--[[if #dynawa.window_manager.stack == 1 then --This is the ONLY window on stack
		return
	end]]
	local win = menu.window:pop()
	win:_delete()
end

function class:load_data()
	return dynawa.file.load_data(self.dir.."my.data")
end

function class:save_data(data)
	return dynawa.file.save_data(data, self.dir.."my.data")
end

return class

