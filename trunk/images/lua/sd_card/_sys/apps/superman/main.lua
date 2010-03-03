----SuperMan
--#todo: go_back after select!
my.globals.menus = {}
my.globals.results = {}

local function menu_ready(menu)
	assert (menu == my.globals.active_menu)
	my.globals.render(menu)
	dynawa.message.send{type="me_to_front"}
end

my.globals.do_hooks_and_render = function(menu)
	if not (menu.hooks and next(menu.hooks)) then
		menu_ready(menu)
		return
	end
end

local function open_my_menu(message)
	local app = assert(message.app or message.sender.app)
	local task = message.task or assert(message.sender)
	local menu = message.menu
	if not menu then
		menu = assert((app.menu_stack or {})[1],"Open_menu_for_app didn't specify the menu and "..app.name.."'s menu stack is empty")
	end
	local refreshed = false
	if type(menu) == "string" then
		menu = my.globals.get_menu_by_url(menu)
		refreshed = true
		if not menu then
			return
		end
	end
	if menu.always_refresh and not refreshed then
		assert(menu.url, "Menu with 'always_refresh' must have URL")
		menu = my.globals.get_menu_by_url(menu.url)
		if app.menu_stack then
			assert(app.menu_stack[1])
			app.menu_stack[1] = menu
		end
	end
	if not menu.app then
		menu.app = app
	end
	if not menu.task then
		menu.task = task
	end
	if not app.menu_stack then
		app.menu_stack = {menu}
	end
	if app.menu_stack[1] ~= menu then 
		table.insert(app.menu_stack,1,menu)
	end
	assert(type(menu)=="table", "Menu is not a table")
	my.globals.active_menu = menu
	my.globals.do_hooks_and_render(menu)
end

local function superman_hook_done(msg)
	local menu = assert(msg.menu)
	local hook = assert(msg.hook)
	assert(my.globals.active_menu == menu)
	assert(menu.hooks, "Got menu_hook_done but menu.hooks is nil")
	assert(menu.hooks[hook],"Got menu_hook_done for hook "..tostring(hook).." but menu is not waiting for this hook")
	menu.hooks[hook] = nil
	if not next(menu.hooks) then
		menu.hooks = nil
		menu_ready(menu)
		return
	else
		dynawa.busy()
	end
end

my.globals.get_menu_by_url = function(url)
	assert(type(url)=="string", "URL is "..tostring(url))
	local url1,args = url:match("(.+):(.*)")
	if not url1 then
		url1 = url
	end
	if args == "" then
		args = nil
	end
	local gen = assert(my.globals.menus[url1],"Cannot find SuperMan generator for menu with URL '"..url.."'")
	local menu = gen(args)
	if not menu then
		return nil
	end
	menu.url = url
	if menu.allow_shortcut then
		local text = menu.allow_shortcut
		if type(text)~="string" then
			text = menu.banner
			if type(text) ~= "string" then
				error("Cannot determine shortcut text")
			end
		end
		local url = menu.url
		assert(menu.url, "Menu allows shortcuts but has no URL")
		local scuts = assert(dynawa.settings.superman.shortcuts)
		local item
		if not scuts[url] then
			item = {text = "+ Add shortcut", value = {result="shortcut_add",url = url, text = text},
					after_select = {popup = 'Created shortcut "'..text..'"', refresh_menu = true}}
		else
			item = {text = "+ Delete shortcut pointing here", value = {result = "shortcut_delete", url = url},
					after_select = {popup = 'Deleted shortcut "'..scuts[url].text..'"', refresh_menu = true}} 
		end
		table.insert(menu.items,item)
	end
	return menu
end

my.globals.results.shortcut_add = function(msg)
	local scut = {text = assert(msg.text)}
	scut.timestamp = os.time()
	dynawa.settings.superman.shortcuts[msg.url] = scut
	dynawa.file.save_settings()
end

my.globals.results.shortcut_delete = function(msg)
	dynawa.settings.superman.shortcuts[msg.url] = nil
	dynawa.file.save_settings()
end

local function launch_superman(message)
	my.app.menu_stack = nil
	local menu = my.globals.get_menu_by_url("root")
	--dynawa.message.send{type = "me_to_front"}
	dynawa.message.send{type = "open_my_menu", menu = menu, task = my}
end

local function menu_result(message)
	assert (message.menu.app == my.app,"SuperMan's menu_result() got "..message.menu.app.name.."'s result")
	if message.menu.proxy then
		--This is a SuperMan's view of other app's menu. Let's re-route the result back to the original app.
		message.receiver = message.menu.proxy
		message.sender = nil
		dynawa.message.send(message)
		return
	end
	--assert (message.menu == my.globals.active_menu,"This is not SuperMan's active menu")
	local value = message.value
	if type(value)=="table" and value.result then
		assert(type(value.result)=="string", "Result key is not string")
		local call = my.globals.results[value.result]
		assert(call, "No call defined for SuperMan result '"..value.result.."'")
		call(value)
	end
end

local autorepeating = false

local function autorepeat_do(message)
	if not autorepeating then
		return
	end
	my.globals.move_cursor(assert(message.direction))
	dynawa.delayed_callback{time = 100, callback=autorepeat_do, direction = message.direction}
end

local function autorepeat_start(dir)
	autorepeating = true
	autorepeat_do{direction = dir}
end

local function close_active_menu()
	local menu = assert(my.globals.active_menu)
	local app = assert(menu.app)
	log("close active menu: app="..app.name)
	my.globals.active_menu = nil
	app.menu_stack = nil
	if app.screen and app ~= my.app then
		dynawa.message.send{type="app_to_front", app=app}
	else
		dynawa.message.send{type="default_app_to_front"}
	end
	dynawa.message.send{type="display_bitmap", bitmap = nil}
end

local function cancel_pressed()
	local menu = my.globals.active_menu
	assert (menu, "Menu cancel received but there is no active menu")
	local app = assert(menu.app)
	assert (app.menu_stack)
	--log("SM cancel pressed. Menus on stack = "..#app.menu_stack)
	assert (menu == app.menu_stack[1])
	table.remove(app.menu_stack,1)
	if #app.menu_stack == 0 then
		dynawa.message.send("close_active_menu")
	else
		dynawa.message.send{type="open_my_menu"}
	end
end

local function confirm_pressed2(message) --Continues here after the optional popup is dismissed
	local menu = assert(my.globals.active_menu)
	local app = assert(menu.app)
	local item = assert(menu.items[menu.active_item])	
	if item.after_select.go_to then
		dynawa.message.send{type = "open_my_menu", menu = item.after_select.go_to}
	elseif item.after_select.close_menu then
		dynawa.message.send("close_active_menu")
	elseif item.after_select.go_back then
		cancel_pressed()
	elseif item.after_select.delete_item then
		local act = menu.active_item
		if act > 1 then
			menu.active_item = act - 1
		end
		table.remove(menu.items, act)
		my.globals.do_hooks_and_render(menu)
	elseif item.after_select.refresh_menu then
		log("triggering refresh_menu")
		local act = menu.active_item
		assert (menu == my.app.menu_stack[1])
		local menu = my.globals.get_menu_by_url(menu.url)
		menu.active_item = act
		my.app.menu_stack[1] = menu
		my.globals.active_menu = menu
		menu.app = my.app
		my.globals.do_hooks_and_render(menu)
	end
end

local function confirm_pressed()
	local menu = my.globals.active_menu
	assert (menu, "Menu confirm received but there is no active menu")
	local app = assert(menu.app)
	local item = menu.items[menu.active_item]
	if not (next(item.after_select) or item.value or item.callback) then
		return --Non-clickable (yellow text)
	end
	dynawa.message.send{type = "menu_result", receiver = app, value = item.value, menu = menu}
	if item.callback then
		dynawa.call_task_function(menu.task or my, item.callback,{})
	end
	if item.after_select.popup then
		dynawa.message.send{type="open_popup",text = item.after_select.popup, callback = confirm_pressed2}
	else
		confirm_pressed2()
	end
end

local function button(message)
	if message.type == "button_down" then
		if message.button == "TOP" then
			my.globals.move_cursor(-1)
		elseif message.button == "BOTTOM" then
			my.globals.move_cursor(1)
		elseif message.button == "CANCEL" then
			cancel_pressed()
		elseif message.button == "CONFIRM" then
			confirm_pressed()
		end
	elseif message.type == "button_hold" then
		if message.button == "TOP" then
			autorepeat_start(-1)
		elseif message.button == "BOTTOM" then
			autorepeat_start(1)
		elseif message.button == "CANCEL" then
			dynawa.message.send("close_active_menu")
		end
	elseif message.type == "button_up" then
		if message.button == "TOP" or message.button == "BOTTOM" then
			autorepeating = false
		end
	end
end

my.app.name = "SuperMan"
my.app.priority = "z"
dynawa.message.send{type = "set_flags", flags = {ignore_app_switch = true, ignore_menu_open = true}}
dynawa.dofile(my.dir.."render.lua")
dynawa.dofile(my.dir.."menus.lua")
dynawa.dofile(my.dir.."apps.lua")
dynawa.message.receive{message="launch_superman",callback=launch_superman}
dynawa.message.receive{message="menu_result",callback=menu_result}
dynawa.message.receive{message="open_my_menu",callback=open_my_menu}
dynawa.message.receive{message="close_active_menu",callback=close_active_menu}
dynawa.message.receive{messages={"button_down","button_up","button_hold"}, callback = button}
dynawa.message.receive{message="superman_hook_done", callback = superman_hook_done}

