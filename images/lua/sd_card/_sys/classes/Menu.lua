local class = Class("Menu")

function class:_init(desc)
	self.banner = assert(desc.banner)
	if self.banner.text then
		self.name = self.banner.text
	end
	self.items = {}
	self:clear_cache()
	for item_n, item_desc in ipairs(desc.items) do
		local menuitem = Class.MenuItem(item_desc)		
		table.insert(self.items, menuitem)
	end
	self.active_item = self.items[1]
	self.active_item_y = 0
	self.window = Class.Window()
end

function class:clear_cache()
	self.cache = {items = {}, outer_bitmap = false}
end

function class:_del()
	for i, item in ipairs(self.items) do
		item:_delete()
	end
	self.window:_delete()
end

function class:render()
	if not self.cache.outer_bitmap then
		--will have to re-render everything because inner size could be different after changing menu banner	
		self:clear_cache()
		self.window:show_bitmap(self:_render_outer())
		self.cache.outer_bitmap = true
	end
	self:_render_inner()
end

function class:_show_bmp_inner_at(bmp, x, y)
	self.window:show_bitmap_at(bmp, self.cache.inner_at.x + x, self.cache.inner_at.y + y)
end

function class:_render_inner()
	local act_i = 1
	while assert(self.items[act_i]) ~= self.active_item do
		act_i = act_i + 1
	end
	local aitembmp = self:_bitmap_of_item(self.active_item)
	local aw,ah = dynawa.bitmap.info(aitembmp)
	local above = self.cache.above_active or 0
	if above < 0 then
		above = 0
	end
	local inner_size = assert(self.cache.inner_size)
	if above + ah > inner_size.h
		then above = inner_size.h - ah
	end
	self.cache.above_active = above
	aitembmp = dynawa.bitmap.combine(dynawa.bitmap.new(inner_size.w,ah,0,0,99), aitembmp, 0, 0)
	self:_show_bmp_inner_at(aitembmp, 0, above)
	local y = above + ah
	local i = act_i + 1
	while self.items[i] and y < inner_size.h do
		local bitmap = self:_bitmap_of_item(self.items[i])
		local w,h = dynawa.bitmap.info(bitmap)
		if y + h > inner_size.h then --Only top part of item is visible
			h = inner_size.h - y
		end
		local bg = dynawa.bitmap.new(inner_size.w, h, 0,0,0)
		dynawa.bitmap.combine(bg, bitmap, 0, 0)
		self:_show_bmp_inner_at(bg, 0, y)
		y = y + h
		i = i + 1
	end
	if y < inner_size.h then --empty bottom of screen
		local black = dynawa.bitmap.new(inner_size.w, inner_size.h-y, 0,0,0)
		self:_show_bmp_inner_at(black, 0, y)
	end
	--Now the items ABOVE the active item
	if above > 0 then
		i = act_i
		local y = above
		repeat
			i = i - 1
			local bitmap = self:_bitmap_of_item(self.items[i])
			local w,h = dynawa.bitmap.info(bitmap)
			local y = y - h
			local realh = h
			if y < 0 then --Only bottom part of item is visible
				realh = h + y
			end
			local bg = dynawa.bitmap.new(inner_size.w, realh, 0,0,0)
			dynawa.bitmap.combine(bg, bitmap, 0, y)
			self:_show_bmp_inner_at(bg, 0, 0)
		until y <= 0
	end
end

--[[function class:adjust_viewport()
	local act_i = 1
		while assert(self.items[act_i]) ~= self.active_item do
			act_i + 1
		end
	end
	local active_item_y = self.cache.active_item_y or 0
	
	local aitembmp = self:_bitmap_of_item(self.active_item)
	local aw,ah = dynawa.bitmap.info(aitembmp)
end]]

function class:_bitmap_of_item(menuitem)
	local bitmap = self.cache.items[assert(menuitem)]
	if not bitmap then
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

return class

