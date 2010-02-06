--included from widget/main.lua

my.globals.menu={}

local function parse_menu_item(text,font,color)
	local item = {text=assert(text)}
	local height
	item.bitmap, item.width, height = dynawa.bitmap.text_line(item.text,font,color)
	return item, height
end

local function full_redraw(widget)
	assert(widget.type=="menu")
	local b_combine = dynawa.bitmap.combine
	local b_new = dynawa.bitmap.new
	local menu = widget
	local border_color = {99,99,255}
	local highlight_color = {0,0,130}
	local bgbm = b_new(menu.size.width, menu.size.height, unpack(border_color))
	b_combine(bgbm,b_new(menu.raw_size.width+2,menu.raw_size.height+2,0,0,0),menu.raw_start.x-1, menu.raw_start.y-1)  --1px border around rawbm
	b_combine(bgbm, menu.banner.bitmap,1,1) --banner
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
	
	b_combine(bgbm, rawbm, menu.raw_start.x, menu.raw_start.y)
	widget.bitmap = bgbm
	--dynawa.debug.send{raw_start = menu.raw_start, raw_size = menu.raw_size, size = menu.size}
	return widget
end

my.globals.menu.new = function(args)
	local menu = {type="menu",items={},size={width=150,height=118}}
	menu.id = "menu_"..dynawa.unique_id()
	for i=1,20 do
		menu.items[i] = parse_menu_item("MENU ITEM #"..i.." oh yes >>")
	end
	menu.active_item = 2
	menu.top_item = 1
	local banner,h = parse_menu_item("MENU BANNER hahaha",nil,{0,0,0})
	menu.banner = banner
	menu.line_height = h
	menu.raw_start = {x=2,y=menu.line_height + 3}
	local size = menu.size
	local raw_size = {width = size.width - menu.raw_start.x - 2, height = size.height - menu.raw_start.y - 2}
	menu.raw_size = raw_size --raw_size and raw_start point to the area where menu items are displayed (minus menu border and banner)
	full_redraw(menu)
	return menu
end

