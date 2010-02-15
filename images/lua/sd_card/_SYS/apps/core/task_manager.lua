require("dynawa")

local function _app_to_front(new_app)
	assert(new_app)
	--log("Putting "..new_app.name.." to front")
	local previous_app = dynawa.app.in_front --Can be nil immediately after boot!
	if previous_app == new_app then --do nothing
		return
	end
	dynawa.app.in_front = new_app
	--assert(new_app.screen,"App '"..new_app.name.."' cannot get to front because it has no screen")
	new_app.in_front = true
	if previous_app then
		previous_app.in_front = nil
		dynawa.event.send{type="you_are_now_in_back",receiver=previous_app}
	end
	dynawa.event.send{type="you_are_now_in_front",receiver=new_app}
	new_app.screen_updates = {full=true} --This app MUST do full screen update
end

local function app_switch(args)
	args = args or {}
	local apps = {}
	for app_id,app in pairs(dynawa.apps) do
		if app.screen then
			if not app.priority then
				app.priority = "ZZZ"..dynawa.unique_id()
				--log("Setting priority of '"..app.name.."' to "..app.priority)
			end
			table.insert(apps,app)
		end
	end
	
	assert(#apps > 0, "Attempt to switch apps when no app has screen")
	
	table.sort(apps, function(a,b)
		return (a.priority < b.priority)
	end)
	
	local cur_app_n = 0
	local in_front = dynawa.app.in_front
	
	if in_front and in_front.flags.ignore_app_switch and not args.default_to_front then --App overrides standard SWITCH button press
		--log("App switch override")
		return
	end
	
	if in_front then
		for i,app in ipairs(apps) do
			if in_front == app then
				cur_app_n = i
			end
		end
	end
	
	local new_app_n = 1 --default to front
	if not args.default_to_front then
		new_app_n = cur_app_n + 1
		if new_app_n > #apps then
			new_app_n = 1
		end
	end
		
	local new_app = assert(apps[new_app_n])
	_app_to_front(new_app)
end

local function button_down(event)
	if event.button == "SWITCH" then
		app_switch()
	end
end
	
local function button_hold(event)
	if event.button == "CANCEL" then --application menu
		local app = dynawa.app.in_front
		if app then
			dynawa.event.send{type="show_menu", receiver=app}
		end
	elseif event.button == "SWITCH" then --SuperMan
		dynawa.event.send{type="launch_superman"}
	end
end

local function app_to_front(event)
	local app = assert(event.app)
	assert(app.tasks,"This is not an app - it has no tasks")
	_app_to_front(app)
end

local function default_app_to_front(event) --Puts the app with the lowest priority to front
	app_switch{default_to_front = true}
end

local function sender_to_front(event)
	local task = assert(event.sender,"No sender found in app_to_front event")
	local app = assert(task.app)
	_app_to_front(app)
end

local function app_flags(event)
	local flags = event.flags
	assert (flags, "No flags specified")
	assert (type(flags)=="table", "Flags collection is not a table")
	local task = assert(event.sender,"No sender found in my_flags event")
	local app = assert(task.app)
	for k,v in pairs(flags) do
		assert(type(k) == "string", "The id of flag '"..tostring(k).."' is not a string")
	end
	app.flags = flags
end

local function init()
	dynawa.event.receive{event="button_down", callback=button_down}
	dynawa.event.receive{event="button_hold", callback=button_hold}
	dynawa.event.receive{event="me_to_front", callback=sender_to_front}
	dynawa.event.receive{event="app_to_front", callback=app_to_front}
	dynawa.event.receive{event="default_app_to_front", callback=default_app_to_front}
	dynawa.event.receive{event="set_flags", callback=app_flags}
	dynawa.app.start(dynawa.dir.sys.."apps/widgets/")
	dynawa.app.start(dynawa.dir.sys.."apps/clock/")
	dynawa.app.start(dynawa.dir.sys.."apps/bluetooth/")
	dynawa.app.start(dynawa.dir.sys.."apps/superman/")
	dynawa.app.start(dynawa.dir.apps.."clock_bynari/")
	dynawa.app.start(dynawa.dir.apps.."button_test/")
	dynawa.event.send{type = "default_app_to_front"}
end

dynawa.delayed_callback{time = 0, callback=init}

