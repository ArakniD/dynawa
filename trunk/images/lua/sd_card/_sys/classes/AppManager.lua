local class = Class("AppManager")

function class:_init()
	self.all_apps = {}
	self.waiting_for = {}
end

function class:start_app(filename)
	--dynawa.busy()
	local dir = filename:match("(.*/).*%.lua$")
	if not dir then
		error("Cannot extract directory name from App filename: "..filename)
	end
	local chunk = assert(loadfile(filename))
	local app
	if filename:match("_bt_app%.lua$") then
		app = Class.BluetoothApp(filename)
	else
		app = Class.App(filename)
	end
	app.dir = dir
	app.filename = filename
	rawset(_G, "app", app)
	chunk()
	rawset(_G, "app", nil)
	assert(not self.all_apps[app.id], "App with id "..app.id.." is already running")
	self.all_apps[app.id] = app
	app:start(app)
	if self.waiting_for[app.id] then
		for i,func in ipairs(self.waiting_for[app.id]) do
			func(app)
		end
		self.waiting_for[app.id] = nil
	end
	return app
end

function class:app_by_id(id)
	return self.all_apps[id]
end

--Executes func only after the app "id" has been started
function class:after_app_start(id,func)
	local app = self:app_by_id(id)
	if app then
		return func(app)
	end
	if not self.waiting_for[id] then
		self.waiting_for[id] = {}
	end
	table.insert(self.waiting_for[id],func)
end

function class:start_everything()
	local apps = {
		"/_sys/apps/window_manager/window_manager_app.lua",
		"/_sys/apps/superman/superman_app.lua",
		"/_sys/apps/popup/popup_app.lua",
		"/_sys/apps/bluetooth_manager/bt_manager_app.lua",
--		"/_sys/apps/sandman/sandman_app.lua",
	}
	
	for i,app in ipairs(dynawa.settings.autostart) do
		table.insert(apps, app)
	end
	
	for i, app in ipairs(apps) do
		dynawa.busy(i / 2 / #apps + 0.5)
		self:start_app(app)
	end
	
	if next(self.waiting_for) then
		error("After starting all Apps, there is still someone waiting for the start of "..(next(self.waiting_for)))
	end

	dynawa.window_manager:show_default()
end

return class

