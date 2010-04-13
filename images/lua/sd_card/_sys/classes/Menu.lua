local class = Class("Menu")

function class:_init(desc)
	self.is_menu = true
	self.banner = assert(desc.banner)
	if type(self.banner) == "string" then
		self.banner = {text = self.banner}
	end
	if self.banner.text then
		self.name = self.banner.text
	end
	self.items = {}
	self:clear_cache()
	for item_n, item_desc in ipairs(desc.items) do
		local menuitem = Class.MenuItem(item_desc)
		table.insert(self.items, menuitem)
	end
	self.active_item = assert(self.items[1],"No items in menu")
	self.window = Class.Window()
end

function class:clear_cache()
	self.cache = {items = {}, outer_bitmap = false}
	if self.window then
		self.window.bitmap = false
	end
end

function class:render()
	if not self.cache.outer_bitmap then
		self:clear_cache()
		self.window:show_bitmap(self:_render_outer())
		self.cache.outer_bitmap = true
	end
	self:_render_inner()
end

function class:_show_bmp_inner_at(bmp, x, y)
	dynawa.bitmap.combine(self.cache.inner_bmp, bmp, x, y)
end

function class:active_item_index()
	return self:item_index(self.active_item)
end

function class:item_index(item)
	local act_i = 1
	while assert(self.items[act_i]) ~= item do
		act_i = act_i + 1
	end
	return act_i
end

function class:_render_inner()
	self.cache.inner_bmp =  dynawa.bitmap.new(self.cache.inner_size.w, self.cache.inner_size.h, 0,0,0)
	local margin = math.floor(dynawa.fonts[dynawa.settings.default_font].height / 2)
	local act_i = self:active_item_index()
	local aitembmp = self:_bitmap_of_item(self.active_item)
	local aw,ah = dynawa.bitmap.info(aitembmp)
	local above = self.above_active or 0
	if act_i == 1 then
		above = 0
	elseif above < margin then
		above = margin
	end
	local inner_size = assert(self.cache.inner_size)
	if above + ah > inner_size.h - margin then
		above = inner_size.h - ah - margin
	end
	self.above_active = above
	aitembmp = dynawa.bitmap.combine(dynawa.bitmap.new(inner_size.w,ah,0,0,99), aitembmp, 0, 0)
	self:_show_bmp_inner_at(aitembmp, 0, above)
	local y = above + ah
	local i = act_i + 1
	while self.items[i] and y < inner_size.h do
		local bitmap = self:_bitmap_of_item(self.items[i])
		local w,h = dynawa.bitmap.info(bitmap)
		self:_show_bmp_inner_at(bitmap, 0, y)
		y = y + h
		i = i + 1
	end
	if above > 0 then
		i = act_i
		local y = above
		repeat
			i = i - 1
			local bitmap = self:_bitmap_of_item(self.items[i])
			local w,h = dynawa.bitmap.info(bitmap)
			y = y - h
			self:_show_bmp_inner_at(bitmap, 0, y)
		until y <= 0
	end
	self.window:show_bitmap_at(self.cache.inner_bmp, self.cache.inner_at.x, self.cache.inner_at.y)
end

function class:_bitmap_of_item(menuitem)
	local bitmap = self.cache.items[assert(menuitem)]
	if not bitmap then
		--log("Rendering menu item "..menuitem)
		bitmap = menuitem:render{max_size = self.cache.inner_size}
		local w,h = dynawa.bitmap.info(bitmap)
		if not (w <= self.cache.inner_size.w and h <= self.cache.inner_size.w) then
			error("MenuItem bitmap too large: "..w.."x"..h)
		end
		self.cache.items[menuitem] = bitmap
	end
	return bitmap
end

--render outer menu border and banner
function class:_render_outer()
	local outer_color = {99,99,255}
	local display_w, display_h = self.window.size.w, self.window.size.h
	local bgbmp = dynawa.bitmap.new(display_w, display_h,unpack(outer_color))
	local banner_bmp, _, banner_h  = dynawa.bitmap.text_lines{text=assert(self.banner.text),
			font = nil, color = {0,0,0}, width = display_w - 2}
	self.cache.inner_at = {x = 2, y = 3 + banner_h}
	self.cache.inner_size = {w = display_w - 2 * self.cache.inner_at.x, h = display_h - self.cache.inner_at.y - 2}
	dynawa.bitmap.combine(bgbmp, banner_bmp, 1, 1)
	local inner_black =  dynawa.bitmap.new(self.cache.inner_size.w + 2, self.cache.inner_size.h + 2, 0,0,0)
	dynawa.bitmap.combine(bgbmp, inner_black, self.cache.inner_at.x - 1, self.cache.inner_at.y - 1)
	return bgbmp
end

function class:scroll(button)
	local ind = self:active_item_index()
	if button == "top" then
		ind = ind - 1
		if ind < 1 then
			ind = #self.items
			self.above_active = 999
			local above = 0
			for i = 1, ind do
				local w,h = dynawa.bitmap.info(self:_bitmap_of_item(self.items[i]))
				if i == ind and above + h <= self.cache.inner_size.h then
					self.above_active = above
					break
				end
				above = above + h
				if above >= self.cache.inner_size.h then
					break
				end
			end
		else
			local w,h = dynawa.bitmap.info(self:_bitmap_of_item(self.items[ind]))
			self.above_active = self.above_active - h
		end
	else --bottom
		local w,h = dynawa.bitmap.info(self:_bitmap_of_item(self.active_item))
		self.above_active = self.above_active + h
		ind = ind + 1
		if ind > #self.items then
			ind = 1
			self.above_active = 0
		end
	end
	self.active_item = self.items[ind]
	--local t0 = dynawa.ticks()
	self:_render_inner()
	--log("Menu updated in "..dynawa.ticks() - t0)
end

function class:handle_event_button(event)
	if event.action == "button_down" then
		if event.button == "top" or event.button == "bottom" then
			self:scroll(event.button)
		elseif event.button == "confirm" then
			self.active_item:selected({item_index = self:active_item_index(), menu = self, item = self.active_item})
		elseif event.button == "cancel" then
			local window = dynawa.window_manager:pop()
			assert(window == self.window)
			assert(window.menu == self)
			self:_delete()
		end
	elseif event.action == "button_hold" then
		if event.button == "top" or event.button == "bottom" then
			self._scroll = event.button
			dynawa.devices.timers:timed_event{delay = 200, receiver = self, direction = event.button}
			self:scroll(event.button)
		end
	elseif event.action == "button_up" then
		self._scroll = nil
	end
end

function class:handle_event_timed_event(event)
	if self._scroll == event.direction then
		dynawa.devices.timers:timed_event{delay = 200, receiver = self, direction = event.direction}
		self:scroll(event.direction)
	end
end

function class:_del()
	self:clear_cache()
	if self.window then
		self.window.menu = false
		self.window:_delete()
	end
	for i, item in ipairs(self.items) do
		item:_delete()
	end
end

return class

