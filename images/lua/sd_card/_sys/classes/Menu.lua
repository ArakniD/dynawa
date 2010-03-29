local Object = Class:get_by_name("Object")
local class = Class("Menu",nil,Object)

function class:_init(desc)
	Object._init(self)
	self.banner = assert(desc.banner)
	if self.banner.text then
		self.name = self.banner.text
	end
	self.items = {}
	self:clear_cache()
	local MenuItem = Class:get_by_name("MenuItem")
	for item_n, item_desc in ipairs(desc.items) do
		table.insert(self.items, MenuItem(item_desc))
	end
	self.window = Class:get_by_name("Window")()
end

function class:clear_cache()
	self.cache = {items = {}, outer_bitmap = false}
end

function class:_del()
	self.window:_delete()
end

function class:render()
	if not self.cache.outer_bitmap then
		--will have to re-render everything because inner size could be different after changing menu banner	
		self:clear_cache()
		self.window:show_bitmap(self:_render_outer())
		self.cache.outer_bitmap = true
	end
	--#todo full inner render
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

Class:add_public(class)

return class

