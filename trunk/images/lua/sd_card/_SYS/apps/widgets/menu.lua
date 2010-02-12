--included from widget/main.lua

my.globals.menu={}
local highlight_color = {0,0,130}
local b_combine = dynawa.bitmap.combine
local b_new = dynawa.bitmap.new
local scroll_interval = 70 --ms
local scroll_max_speed = 6
local scroll_id = nil

local function scrolling(event)
	assert(event.id)
	if event.id ~= scroll_id or not my.app.in_front then
		return
	end
	local menu = event.menu
	local w,h = menu.raw_size.width, menu.line_height
	local x = menu.start.x + menu.raw_start.x
	local y = menu.start.y + menu.raw_start.y + (menu.active_item - menu.top_item) * h
	local lbitmap = menu.items[menu.active_item].bitmap
	local lw = menu.items[menu.active_item].width
	menu.scroll.position = menu.scroll.position + math.max(math.floor(menu.scroll.speed),0)
	if menu.scroll.speed < scroll_max_speed then
		menu.scroll.speed = menu.scroll.speed + 0.15
	end
	local delay = scroll_interval
	if menu.scroll.position + w > lw then
		menu.scroll.position = lw - w
		delay = delay * 20
	end
	
	local bitmap = b_new(w,h,unpack(highlight_color))
	b_combine (bitmap, lbitmap, 0-menu.scroll.position, 0)
	dynawa.event.send{type="display_bitmap", bitmap=bitmap, at={x,y}}
	
	if delay > scroll_interval then -- end of line, start again
		menu.scroll.speed = -1
		menu.scroll.position = 0
	end
	
	dynawa.delayed_callback {callback = scrolling, time = delay, id = menu.scroll.id, menu = menu}
end

local function maybe_start_scrolling(menu)
	scroll_id = nil
	menu.scroll={}
	local item = menu.items[menu.active_item]
	if item.width <= menu.raw_size.width then
		return
	end
	--start scrolling!
	local scroll = {id = dynawa.unique_id(), speed = 1, position = 0}
	menu.scroll = scroll
	scroll_id = scroll.id
	dynawa.delayed_callback {callback = scrolling, time = scroll_interval*10, id = scroll.id, menu = menu}
end

local function parse_menu_item(text,font,color)
	local item = {text=assert(text)}
	local height
	item.bitmap, item.width = dynawa.bitmap.text_line(item.text,font,color)
	return item
end

local function raw_render(menu) --only the area with menu items, NOT borders / banner!
	assert(menu.type=="menu")	
	local rawbm = b_new(menu.raw_size.width, menu.raw_size.height, 0,0,0)
	
	local item_n = assert(menu.top_item)
	local y = 0
	repeat
		local item = menu.items[item_n]
		if item_n == menu.active_item then --highlight active item
			b_combine(rawbm, b_new(menu.raw_size.width,menu.line_height,unpack(highlight_color)),0,y)
		end
		b_combine(rawbm, item.bitmap, 0, y)
		y = y + menu.line_height
		item_n = item_n + 1
	until (y >= menu.raw_size.height) or (not menu.items[item_n])
	
	--dynawa.debug.send{raw_start = menu.raw_start, raw_size = menu.raw_size, size = menu.size}
	return rawbm
end


local function widget_render(menu)
	assert(menu.type=="menu")
	local border_color = {99,99,255}
	local bgbm = b_new(menu.size.width, menu.size.height, unpack(border_color))
	b_combine(bgbm,b_new(menu.raw_size.width+2,menu.raw_size.height+2,0,0,0),menu.raw_start.x-1, menu.raw_start.y-1)  --1px border around rawbm
	b_combine(bgbm, menu.banner.bitmap,1,1) --banner
	
	local rawbm = raw_render(menu)
	b_combine(bgbm, rawbm, menu.raw_start.x, menu.raw_start.y)
	menu.bitmap = bgbm
	--dynawa.debug.send{raw_start = menu.raw_start, raw_size = menu.raw_size, size = menu.size}
	return menu
end

local function full_redraw(menu)
	local bgbmp = assert(menu.app.screen)
	bgbmp = dynawa.bitmap.combine(bgbmp,my.globals.inactive_mask,0,0,true)
	widget_render(menu)
	dynawa.bitmap.combine(bgbmp,menu.bitmap,menu.start.x,menu.start.y)
	dynawa.event.send{type="display_bitmap", bitmap=bgbmp}
	return menu
end

local function raw_redraw(menu)
	local rawbmp = raw_render(menu)
	local x = menu.start.x + menu.raw_start.x
	local y = menu.start.y + menu.raw_start.y
	dynawa.event.send{type="display_bitmap", bitmap=rawbmp, at={x,y}}
	return menu
end

my.globals.menu.new = function(menu0)
	local menu = {type="menu",items={},scroll={},id=menu0.id}
	menu.app = assert(menu0.app)
	menu.items = {}
	local banner = parse_menu_item(menu0.banner,nil,{0,0,0})
	menu.banner = banner
	local w,h = assert(dynawa.bitmap.info(menu.banner.bitmap))
	menu.banner.height = h --Height of text only
	
	local max_width = menu.banner.width
	for i,item0 in ipairs(menu0.items) do
		assert(item0.text)
		local item = parse_menu_item(item0.text)
		assert(item0.value)
		item.value = item0.value
		if menu0.active_value and menu0.active_value == item.value then
			menu.active_item = i
		end
		if item.width > max_width then
			max_width = item.width
		end
		menu.items[i] = item
	end

	if not menu.active_item then
		menu.active_item = 1
	end	
	
	menu.top_item = 1
	local w,h = assert(dynawa.bitmap.info(menu.items[1].bitmap))
	menu.line_height = h
	
	local raw_size = {width = max_width, height = #menu.items * menu.line_height}
	local size = {width = raw_size.width + 4, height = raw_size.height + menu.banner.height + 5}
	local new_width = math.min(size.width,dynawa.display.size.width - 6)
	local new_height = math.min(size.height,dynawa.display.size.height - 6)
	raw_size = {width = raw_size.width + new_width - size.width, height = raw_size.height + new_height - size.height}
	--log("raw_size: "..raw_size.width.."x"..raw_size.height)
	size = {width = new_width, height = new_height}
	--log("size: "..size.width.."x"..size.height)
	
	local start = {x =  math.floor((dynawa.display.size.width - size.width) / 2), y = math.floor((dynawa.display.size.height - size.height) / 2)}
	local raw_start = {x = 2, y = menu.banner.height + 3}
	
	menu.raw_start = raw_start
	menu.raw_size = raw_size
	menu.start = start
	menu.size = size

	menu.rows_fit = menu.raw_size.height / menu.line_height --How many rows fit into the raw bitmap (non-integer!)
	assert(menu.rows_fit >= 3, "Menu too small. At least 3 items must fit in the window")
	if menu.top_item < menu.active_item - math.floor(menu.rows_fit) + 1 then
		menu.top_item = menu.active_item - math.floor(menu.rows_fit) + 1
	end
	full_redraw(menu)
	maybe_start_scrolling(menu)
	return menu
end

local function cursor_move(menu,offset)
	assert(type(offset)=="number")
	local new_item = menu.active_item + offset
	if new_item > #menu.items then
		new_item = #menu.items
	end
	if new_item < 1 then
		new_item = 1
	end
	if new_item == menu.active_item then
		return 
	end
	if menu.top_item >= new_item then
		menu.top_item = math.max(new_item - 1, 1)
	end
	if menu.top_item < new_item - math.floor(menu.rows_fit) + 1 then
		menu.top_item = new_item - math.floor(menu.rows_fit) + 1
	end
	menu.active_item = new_item
	raw_redraw(menu)
	maybe_start_scrolling(menu)
end

local function confirmation(menu)
	local item = menu.items[menu.active_item]
	local event = {status = "confirmed", item_n = menu.active_item, item = item}
	my.globals.widget_done(menu,event)
end

my.globals.menu.button_event = function(menu, event)
	if event.type == "button_down" then
		if event.button == "CONFIRM" then
			confirmation(menu)
			return
		elseif event.button == "TOP" then
			cursor_move(menu,-1)
			return
		elseif event.button == "BOTTOM" then
			cursor_move(menu,1)
			return
		end
	elseif event.type == "button_hold" then
		local jump = math.floor(menu.rows_fit)
		if event.button == "TOP" then
			cursor_move(menu, 0-jump)
			return
		elseif event.button == "BOTTOM" then
			cursor_move(menu, jump)
			return
		end
	end
end

