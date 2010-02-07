require("dynawa")

local apps,app_index

local function _app_to_front(new_app)
	local previous_app = dynawa.app.in_front --Can be nil immediately after boot!
	dynawa.app.in_front = new_app
	if previous_app == new_app then --do nothing
		return
	end
	new_app.in_front = true
	if previous_app then
		previous_app.in_front = nil
		dynawa.event.send{type="you_are_now_in_back",receiver=previous_app}
	end
	dynawa.event.send{type="you_are_now_in_front",receiver=new_app}
end

local function button_down(event)
	if event.button == "SWITCH" then
		repeat
			app_index = app_index + 1
			if app_index > #apps then
				app_index = 1
			end
		until apps[app_index].screen
		local new_app = assert(apps[app_index])
		_app_to_front(new_app)
	end
end

local function button_hold(event)
	if event.button == "CANCEL" then --application menu
		local app = dynawa.app.in_front
		if app then
			dynawa.event.send{type="show_menu", receiver=app}
		end
	end
end

local function app_to_front(event)
	local app = assert(event.app)
	assert(app.tasks,"This is not an app - it has no tasks")
	_app_to_front(app)
end

local function sender_to_front(event)
	local task = assert(event.sender,"No sender found in app_to_front event")
	local app = assert(task.app)
	_app_to_front(app)
end

local function init()
	dynawa.event.receive{event="button_down", callback=button_down}
	dynawa.event.receive{event="button_hold", callback=button_hold}
	dynawa.event.receive{event="me_to_front", callback=sender_to_front}
	dynawa.event.receive{event="app_to_front", callback=app_to_front}
	apps = {
		dynawa.app.start(dynawa.dir.sys.."apps/clock/"),
		dynawa.app.start(dynawa.dir.sys.."apps/widgets/"),
		dynawa.app.start(dynawa.dir.apps.."button_test/"),
	}
	app_index = 1
end

dynawa.delayed_callback{time = 0, callback=init}

