----SuperMan
--#todo: go_back after select!
local function open_my_menu(event)
	local app = assert(event.app or event.sender.app)
	local menu = event.menu
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
	if not app.menu_stack then
		app.menu_stack = {menu}
	end
	if app.menu_stack[1] ~= menu then 
		table.insert(app.menu_stack,1,menu)
	end
	assert(type(menu)=="table", "Menu is not a table")
	my.globals.active_menu = menu
	my.globals.render(menu)
	dynawa.event.send{type="me_to_front"}
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
	return menu
end

local function launch_superman(event)
	my.app.menu_stack = nil
	local menu = my.globals.get_menu_by_url("root")
	--dynawa.event.send{type = "me_to_front"}
	dynawa.event.send{type = "open_my_menu", menu = menu}
end

local function menu_result(event)
	assert (event.menu.app == my.app,"SuperMan's menu_result() got "..event.menu.app.name.."'s result")
	if event.menu.proxy then
		--This is a SuperMan's view of other app's menu. Let's re-route the result back to the original app.
		event.receiver = event.menu.proxy
		event.sender = nil
		dynawa.event.send(event)
		return
	end
	--assert (event.menu == my.globals.active_menu,"This is not SuperMan's active menu")
	local value = event.value
	if type(value)=="table" and value.result then
		assert(type(value.result)=="string", "Result key is not string")
		local call = my.globals.results[value.result]
		assert(call, "No call defined for SuperMan result '"..value.result.."'")
		call(value)
	end
end

local autorepeating = false

local function autorepeat_do(event)
	if not autorepeating then
		return
	end
	my.globals.move_cursor(assert(event.direction))
	dynawa.delayed_callback{time = 100, callback=autorepeat_do, direction = event.direction}
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
		dynawa.event.send{type="app_to_front", app=app}
	else
		dynawa.event.send{type="default_app_to_front"}
	end
	dynawa.event.send{type="display_bitmap", bitmap = nil}
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
		dynawa.event.send("close_active_menu")
	else
		dynawa.event.send{type="open_my_menu"}
	end
end

local function confirm_pressed2(event) --Continues here after the optional popup is dismissed
	local menu = assert(my.globals.active_menu)
	local app = assert(menu.app)
	local item = assert(menu.items[menu.active_item])	
	if item.after_select.go_to then
		dynawa.event.send{type = "open_my_menu", menu = item.after_select.go_to}
	end
	if item.after_select.close_menu then
		dynawa.event.send("close_active_menu")
	end	
end

local function confirm_pressed()
	local menu = my.globals.active_menu
	assert (menu, "Menu confirm received but there is no active menu")
	local app = assert(menu.app)
	local item = menu.items[menu.active_item]
	if not (next(item.after_select) or item.value) then
		return --Non-clickable (yellow text)
	end
	dynawa.event.send{type = "menu_result", receiver = app, value = item.value, menu = menu}
	if item.after_select.popup then
		dynawa.event.send{type="open_popup",text = item.after_select.popup, callback = confirm_pressed2}
	else
		confirm_pressed2()
	end
end

local function button(event)
	if event.type == "button_down" then
		if event.button == "TOP" then
			my.globals.move_cursor(-1)
		elseif event.button == "BOTTOM" then
			my.globals.move_cursor(1)
		elseif event.button == "CANCEL" then
			cancel_pressed()
		elseif event.button == "CONFIRM" then
			confirm_pressed()
		end
	elseif event.type == "button_hold" then
		if event.button == "TOP" then
			autorepeat_start(-1)
		elseif event.button == "BOTTOM" then
			autorepeat_start(1)
		elseif event.button == "CANCEL" then
			dynawa.event.send("close_active_menu")
		end
	elseif event.type == "button_up" then
		if event.button == "TOP" or event.button == "BOTTOM" then
			autorepeating = false
		end
	end
end

my.app.name = "SuperMan"
my.app.priority = "z"
dynawa.event.send{type = "set_flags", flags = {ignore_app_switch = true, ignore_menu_open = true}}
dynawa.dofile(my.dir.."render.lua")
dynawa.dofile(my.dir.."menus.lua")
dynawa.event.receive{event="launch_superman",callback=launch_superman}
dynawa.event.receive{event="menu_result",callback=menu_result}
dynawa.event.receive{event="open_my_menu",callback=open_my_menu}
dynawa.event.receive{event="close_active_menu",callback=close_active_menu}
dynawa.event.receive{events={"button_down","button_up","button_hold"}, callback = button}
