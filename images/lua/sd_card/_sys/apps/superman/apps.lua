--Various Apps menus for SuperMan

local function system_app(app_id)
	assert(type(app_id) == "string")
	log("matching "..app_id.." with ^"..dynawa.dir.sys)
	return (app_id:match("^"..dynawa.dir.sys))
end

my.globals.menus.apps = function(dir)
	local menu = {banner = "Apps", allow_shortcut = true}
	menu.items = {
		{text = "Running apps", after_select = {go_to="apps_running:"}},
		{text = "Stopped apps"},
		{text = "Configure app directories"},
	}
	return menu
end

local function overview_received(message)
	if message.reply then
		local bitmap = message.reply
		assert(dynawa.bitmap.info(bitmap))
		local app = assert(message.original_message.receiver)
		my.globals.overviews.bitmaps[app] = bitmap
	end
	local apps = assert(my.globals.overviews.apps)
	apps[app] = nil
	if next(apps) then 
		return -- Someone still has not responded
	end
	local over = my.globals.overviews
	my.globals.overviews = nil
	callback{menu = over.menu, bitmaps = over.bitmaps}
end

local function get_overviews(args)
	local apps0 = assert(args.apps)
	local callback = assert(args.callback)
	local menu = assert(args.menu)
	local apps = {}
	my.globals.overviews = {apps = apps, bitmaps = {}, callback = callback, menu = menu}
	for i, app in ipairs(apps0) do
		apps[app] = true
		dynawa.message.send{type="your_overview", receiver = app, reply_callback = overview_received}
	end
end

my.globals.menus.apps_running = function(dir)
	local menu = {banner = "Running apps", items = {}, allow_shortcut = true, always_refresh = true, hooks = {}}
	local apps = {}
	for key, val in pairs(dynawa.apps) do
		table.insert(apps, val)
		--log("app:"..val.id)
	end
	table.sort(apps, function (a,b)
		return (a.name < b.name)
	end)
	for i, app in ipairs(apps) do
		local item = {text = app.name, after_select = {go_to="app:"..app.id}}
		table.insert(menu.items,item)
		menu.hooks[app] = true
		dynawa.message.send{type = "your_overview", receiver = app, reply_callback = function(msg)
			if msg.reply then
				local bitmap = msg.reply
				item.text = nil
				item.bitmap = bitmap
			end
			dynawa.message.send{type = "superman_hook_done", hook = app, menu = menu}
		end}
	end
	return menu
end

my.globals.menus.apps_stopped = function(dir)
	local menu = {banner = "Stopped apps", items = {}, allow_shortcut = true}
	local apps = {}
	for key, val in pairs(dynawa.apps) do
		table.insert(apps, val)
		--log("app:"..val.id)
	end
	table.sort(apps, function (a,b)
		return (a.id < b.id)
	end)
	for i, app in ipairs(apps) do
		local item = {text = app.name, after_select = {go_to="app:"..app.id}}
		table.insert(menu.items,item)
	end
	return menu
end

my.globals.menus.app = function (app_id)
	assert(app_id)
	local app = assert(dynawa.apps[app_id])
	local menu = {banner = "App: "..app.name, allow_shortcut = true, always_refresh = true, items = {}}
	local function additem (item)
		table.insert(menu.items, item)
	end
	additem{text = "Directory: "..app.id, after_select = {go_to="file_browser:"..app.id}}
	if app.priority then
		additem {text = "Priority: "..app.priority}
	end
	if system_app(app.id) then
		additem {text = "System app (unstoppable)"}
	else
		additem {text = "User app"}
	end
	additem {text = "Try opening its menu", after_select = {go_to="app_menu:"..app.id}}
	menu.hooks = {bitmap = true}
	dynawa.message.send{type = "your_overview", receiver = app, reply_callback = function(msg)
		if msg.reply then
			local item = {bitmap = msg.reply}
			table.insert(menu.items, 1, item)
		end
		dynawa.message.send{type = "superman_hook_done", hook = "bitmap", menu = menu}
	end}
	return menu
end

