self.name = "SuperMan"

function self:open_menu_by_url(url)
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
		menu = Class.Menu(menu)
	end
	menu.app = self
	menu.url = url
	return self:open_menu(menu)
end

function self:open_menu(menu)
	self.showing_menu = menu
	self.window = menu.window
	menu:render()
	return menu
end

function self:menu_item_selected(args)
	local menu = args.menu
	assert (menu.app == self)
	log("selected item "..args.item)
	local on_select = args.item.on_select
	if not on_select then
		return
	end
	if on_select.go_to_url then
		--menu:clear_cache()
		local newmenu = self:open_menu_by_url(on_select.go_to_url)
		newmenu.previous = menu
		return
	end
end

function self:do_cancel() --Go to previous menu
	local menu = assert(self.showing_menu)
	local app = menu.app
	local prevmenu = menu.previous
	menu:_delete()
	if prevmenu then
		return self:open_menu(prevmenu)
	end
	error("Last SuperMan menu closed")
end

function self:handle_event_button(event)
	assert(self.showing_menu)
	if event.action == "button_down" and event.button == "cancel" then
		return self:do_cancel()
	end
	self.showing_menu:handle_event_button(event)
end

function self:virtual_button(button, app)
	local menu = self.showing_menu
	assert(app.showing_menu == menu)
	assert(menu.app == app)
end

function self:start()
	self.showing_menu = false
	self:open_menu_by_url("root")
end

self.menu_builders = {}

function self.menu_builders:root()
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

function self.menu_builders:file_browser(dir)
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

return self

