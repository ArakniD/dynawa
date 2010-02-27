-- SuperMan rendering
local display_w,display_h = dynawa.display.size.width, dynawa.display.size.height

local function adjust_viewport(menu)
	assert(menu)
	local last_item = assert(menu.items[#menu.items])
	local active_item = assert(menu.items[menu.active_item])
	local max_vp = math.max(0, last_item.y_pos + last_item.size.h - menu.inner_size.h)
	if max_vp == 0 then
		menu.viewport_y = 0
		return
	end
	local vp = menu.viewport_y
	local leeway = 15 --Top / bottom leeway in pixels
	if vp > active_item.y_pos - leeway then
		vp = active_item.y_pos - leeway
	end
	if vp + menu.inner_size.h < active_item.y_pos + active_item.size.h + leeway then
		vp = active_item.y_pos + active_item.size.h + leeway - menu.inner_size.h
	end
	if vp > max_vp then
		vp = max_vp
	end
	if vp < 0 then
		vp = 0
	end
	menu.viewport_y = vp
	return menu
end

local function parse(menu)
	if not menu.skin then
		menu.skin = {}
	end
	if not menu.skin.border_color then
		if menu.app and menu.app == dynawa.apps["/_sys/apps/superman/"] then
			menu.skin.border_color = {255,99,255}
		else
			menu.skin.border_color = {99,99,255}
		end
	end
	if not menu.skin.highlight_color then
		menu.skin.highlight_color = {0,0,128}
	end
	if not menu.skin.infotext_color then
		menu.skin.infotext_color = {255,255,0}
	end
	if not menu.banner then
		menu.banner = "Untitled menu"
	end
	if type(menu.banner) == "string" then
		menu.banner = {text = menu.banner}
	end
	if not menu.banner.bitmap then
		menu.banner.bitmap = dynawa.bitmap.text_lines{text=menu.banner.text,font = nil,color = {0,0,0}, width = dynawa.display.size.width - 2}
	end
	menu.banner.size = {}
	menu.banner.size.w, menu.banner.size.h = dynawa.bitmap.info(menu.banner.bitmap)
	assert(menu.items)
	if #menu.items == 0 then
		table.insert(menu.items,{text="[This menu is empty]"})
	end
	for i, item in ipairs(menu.items) do
		if not item.after_select then
			item.after_select = {}
		end
		if not item.bitmap then
			local color = nil
			if not (item.value or next(item.after_select)) then
				color = menu.skin.infotext_color
			end
			assert(item.text,"Menu item has no bitmap and no text")
			item.bitmap = dynawa.bitmap.text_lines{text = item.text,font = nil,color = color}
		end
		item.size = {}
		item.size.w, item.size.h = dynawa.bitmap.info(item.bitmap)
		if i == 1 then
			item.y_pos = 0
		else
			item.y_pos = menu.items[i-1].y_pos + menu.items[i-1].size.h
		end
		if (not menu.active_item) and menu.active_value and (menu.active_value == item.value) then
			menu.active_item = i
		end
	end
	if not menu.active_item then
		menu.active_item = 1
	end
	menu.inner_corner = {x = 2, y = 3 + menu.banner.size.h}
	menu.inner_size = {w = display_w - 2*menu.inner_corner.x, h = display_h - menu.inner_corner.y - 2}
	menu.bitmap = dynawa.bitmap.new(display_w, display_h, unpack(menu.skin.border_color))
	dynawa.bitmap.combine(menu.bitmap, menu.banner.bitmap, 1,1)
	dynawa.bitmap.combine(menu.bitmap, dynawa.bitmap.new(menu.inner_size.w+2, menu.inner_size.h+2, 0,0,0), menu.inner_corner.x-1, menu.inner_corner.y-1)
	menu.viewport_y = 0
	adjust_viewport(menu)
	return menu
end

local function inner_bitmap(menu)
	local bitmap = dynawa.bitmap.new(menu.inner_size.w, menu.inner_size.h, 0,0,0)
	local active_item = assert(menu.items[menu.active_item])
	assert(active_item.y_pos >= menu.viewport_y)
	assert(active_item.y_pos + active_item.size.h <= menu.viewport_y + menu.inner_size.h)
	local item_n = 1
	while menu.items[item_n].y_pos + menu.items[item_n].size.h - 1 < menu.viewport_y do --find first item to draw
		item_n = item_n + 1
	end
	local items_drawn = 0
	while menu.items[item_n] and menu.items[item_n].y_pos < menu.viewport_y + menu.inner_size.h do --draw items
		local item = assert(menu.items[item_n])
		local real_y = item.y_pos - menu.viewport_y
		assert(real_y < menu.inner_size.h)
		if item_n == menu.active_item then
			dynawa.bitmap.combine(bitmap,dynawa.bitmap.new(menu.inner_size.w,item.size.h,unpack(menu.skin.highlight_color)),0,real_y)
		end
		dynawa.bitmap.combine(bitmap,item.bitmap,0,real_y)
		item_n = item_n + 1
		items_drawn = items_drawn + 1
	end
	--assert (items_drawn >= 2,"Less than 2 items rendered in menu")
	return bitmap
end

my.globals.render = function(menu)
	if not menu.bitmap then
		parse(menu)
		assert(menu.bitmap)
	end
	dynawa.message.send{type="display_bitmap", bitmap = menu.bitmap}
	dynawa.message.send{type="display_bitmap", bitmap = inner_bitmap(menu), at={menu.inner_corner.x, menu.inner_corner.y}}
end

my.globals.move_cursor = function(dir)
	local menu = my.globals.active_menu
	if not menu then 
		return
	end
	local old_n = menu.active_item
	local new_n = old_n + dir
	if new_n > #menu.items then
		new_n = 1
	end
	if new_n < 1 then
		new_n = #menu.items
	end
	if old_n == new_n then
		return
	end
	menu.active_item = new_n
	adjust_viewport(menu)
	dynawa.message.send{type="display_bitmap", bitmap = inner_bitmap(menu), at={menu.inner_corner.x, menu.inner_corner.y}}
end
