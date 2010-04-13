local class = Class("Window")

function class:_init()
	self.is_window = true
	self.bitmap = false --#todo
	self.id = dynawa.unique_id()
	self:force_full_update()
	dynawa.window_manager:register_window(self)
	self.size = assert(dynawa.devices.display.size)
end

function class:_del()
	dynawa.window_manager:unregister_window(self)
	if self.menu  then
		self.menu.window = false
		self.menu:_delete()
	end
	self.bitmap = false
end

function class:show_bitmap(bitmap)
	local w,h = dynawa.bitmap.info(bitmap)
	assert(w == self.size.w and h == self.size.h, "Bitmap is not fullwindow")
	self.bitmap = bitmap
	self:force_full_update()
end

function class:show_bitmap_at(bitmap,x,y)
	assert(x and y)
	assert(self.bitmap, "show_bitmap_at() called on empty bitmap") --#todo Default background??
	dynawa.bitmap.combine(self.bitmap, bitmap, x, y)
	if self.updates.full then
		return
	end
	local w,h = dynawa.bitmap.info(bitmap)
	--Add region for show_partial
	table.insert(self.updates.regions,{x = x, y = y, w = w, h = h})
	self.updates.pixels_remain = self.updates.pixels_remain - w * h
	if #self.updates.regions >= self.updates.max_regions or self.updates.pixels_remain <= 0 then
		self.updates.full = true
	end
end

function class:allow_partial_update()
	self.updates = {regions = {}, max_regions = 9, 
	pixels_remain = math.floor(self.size.w * self.size.h * 0.95)}
end

function class:force_full_update()
	self.updates = {full = true}
end

function class:handle_event_button(ev)
	if self.menu then
		return self.menu:handle_event_button(ev)
	end
	assert(self.app)
	self.app:handle_event_button(ev)
end

function class:you_are_now_in_front()
	if self.menu then
		self.menu:render()
	end
end

return class

