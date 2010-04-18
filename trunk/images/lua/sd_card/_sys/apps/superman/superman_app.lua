app.name = "SuperMan"
app.id = "dynawa.superman"

function app:open_menu_by_url(url)
	local url0, urlarg = url:match("(.+):(.*)")
	if not urlarg then
		url0 = url
	end
	if urlarg == "" then
		urlarg = nil
	end
	local builder = self.menu_builders[url0]
	if not builder then
		error("Cannot get builder for url: "..url)
	end
	local menu = builder(self,urlarg)
	if not menu.is_menu then
		menu = self:new_menuwindow(menu).menu
	end
	menu.url = url
	self:open_menu(menu)
	return menu
end

function app:open_menu(menu)
	assert(menu.window)
	self:push_window(menu.window)
	menu:render()
	return menu
end

function app:menu_cancelled(menu)
	local popwin = dynawa.window_manager:pop()
	assert (popwin == menu.window)
	popwin:_delete()
	local window = dynawa.window_manager:peek()
	if window then
		window.menu:render()
	else
		dynawa.window_manager:show_default()
	end
end

function app:switching_to_front()
	self:open_menu_by_url("root")
end

function app:switching_to_back()
	dynawa.window_manager:pop_and_delete_menuwindows()
end

function app:menu_item_selected(args)
	local menu = args.menu
	assert (menu.window.app == self)
--	log("selected item "..args.item)
	local on_select = args.item.on_select
	if not on_select then
		return
	end
	if on_select.go_to_url then
		menu:clear_cache()
		local newmenu = self:open_menu_by_url(on_select.go_to_url)
		return
	end
end

function app:start()
	dynawa.superman = self
end

app.menu_builders = {}

function app.menu_builders:root()
	local menu_def = {
		banner = {
			text="SuperMan root menu"
			},
		items = {
			{text = "Shortcuts", on_select = {go_to_url = "shortcuts"}},
			{text = "Apps", on_select = {go_to_url = "apps"}},
			{text = "File browser", on_select = {go_to_url = "file_browser"}},
			{text = "Adjust time and date", on_select = {go_to_url = "adjust_time_date"}},
			{text = "Default font size", on_select = {go_to_url = "default_font_size"}},
		},
	}
	return menu_def
end

function app.menu_builders:file_browser(dir)
	if not dir then
		dir = "/"
	end
	--log("opening dir "..dir)
	local dirstat = dynawa.file.dir_stat(dir)
	local menu = {banner = "File browser: "..dir, items={}, always_refresh = true, allow_shortcut = "Dir: "..dir}
	if not dirstat then
		table.insert(menu.items,{text="[Invalid directory]"})
	else
		if next(dirstat) then
			for k,v in pairs(dirstat) do
				local txt = k.." ["..v.." bytes]"
				local sort = "2"..txt
				if v == "dir" then 
					txt = "= "..k
					sort = "1"..txt
				end
				--log("Adding dirstat item: "..txt)
				local location = "file:"..dir..k
				if v == "dir" then
					location = "file_browser:"..dir..k.."/"
				end
				table.insert(menu.items,{text = txt, sort = sort, on_select={go_to_url = location}})
			end
			table.sort(menu.items,function(it1,it2)
				return it1.sort < it2.sort
			end)
		else
			table.insert(menu.items,{text="[Empty directory]"})
		end
	end
	return menu
end

local adjust_time_selected = function(self,args)
	local menu = args.menu
	assert(menu == self)
	local value = assert(args.item.value)

	local date = assert(os.date("*t"))
	date[value.what] = value.number
	if value.what == "min" then
		date.sec = 0
	end
	local secs = assert(os.time(date))
	dynawa.time.set(secs)
	
	menu.window:pop()
	menu:_delete()
	local win = dynawa.window_manager:pop()
	win:_delete()
	dynawa.superman:open_menu_by_url("adjust_time_date")
	local msg = "Adjusted "..value.name
	if value.what == "min" then
		msg = msg.." and set seconds to zero."
	else
		msg = msg.."."
	end
	dynawa.popup:open{text = msg}
end

function app.menu_builders:adjust_time_date(what)
	local date = assert(os.date("*t"))
	--log("what = "..tostring(what))
	if not what then
		local menu = {banner = "Adjust time & date"}
		menu.items = {
			{text = "Day of month: "..date.day, on_select = {go_to_url="adjust_time_date:day"}},
			{text = "Month: "..date.month, on_select = {go_to_url="adjust_time_date:month"}},
			{text = "Year: "..date.year, on_select = {go_to_url="adjust_time_date:year"}},			
			{text = "Hours: "..date.hour, on_select = {go_to_url="adjust_time_date:hour"}},
			{text = "Minutes: "..date.min, on_select = {go_to_url="adjust_time_date:min"}},			
		}
		return menu
	end
	local limit = {from=2001, to=2060, name = "year"} --year
	if what=="month" then
		limit = {from = 1, to = 12, name = "month"}
	elseif what=="day" then
		limit = {from = 1, to = 31, name = "day of month"}
	elseif what == "hour" then
		limit = {from = 0, to = 23, name = "hours"}
	elseif what == "min" then
		limit = {from = 0, to = 59, name = "minutes"}
	end
	local menu = {banner = "Please adjust the "..limit.name.." value", items = {}, item_selected = adjust_time_selected}
	for i = limit.from, limit.to do
		local item = {text = tostring(i), value = {what = what, number = i, name = limit.name}}
		table.insert(menu.items,item)
		if i == date[what] then
			menu.active_value = item.value
		end
	end
	return menu
end

return app

