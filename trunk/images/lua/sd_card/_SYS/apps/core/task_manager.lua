require("dynawa")

local apps = {
	dynawa.app.start(dynawa.dir.sys.."apps/clock/"),
	dynawa.app.start(dynawa.dir.apps.."button_test/"),
}

local app_index = 1

local function receive(event)
	if event.button == "SWITCH" then
		app_index = app_index + 1
		if app_index > #apps then
			app_index = 1
		end
		dynawa.app.to_front(apps[app_index])
	end
end

dynawa.event.receive{event="button_down", callback=receive}
