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
		menu = Class.Menu(menu)
	end
	menu.url = url
	self:open_menu(menu)
	return menu
end

function app:open_menu(menu)
	--self.window = menu.window
	menu.window.menu = menu
	--menu:render()
	self:push_window(menu.window)
	return menu
end

function app:menu_item_selected(args)
	local menu = args.menu
	assert (menu.window.app == self)
	log("selected item "..args.item)
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

function app:do_cancel() --Go to previous menu
	error("#todo")
	--local menu = assert(self.showing_menu)
	local app = menu.app
	local prevmenu = menu.previous
	menu:_delete()
	if prevmenu then
		return self:open_menu(prevmenu)
	end
	error("#todo Last SuperMan menu closed")
end

function app:virtual_button(button, app)
	local menu = self.showing_menu
	assert(app.showing_menu == menu)
	assert(menu.app == app)
	--#todo ?
end

function app:start()
	self.showing_menu = false
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

return app

