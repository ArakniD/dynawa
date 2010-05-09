app.name = "Bluetooth Manager"
app.id = "dynawa.bluetooth_manager"

function app:start()
	dynawa.bluetooth_manager = self
	self.prefs = self:load_data() or {devices = {}}
	self.devices = assert(self.prefs.devices)
	self.hw = assert(dynawa.devices.bluetooth)
	self.hw:register_for_events(self)
	self.hw_status = "off"
end

local function all_bt_apps_iterator(apps, key0)
	--log("iterating")
	local key, app = next(apps,key0)
	if key then
		if app:_class() == Class.BluetoothApp then
			--log("matches:"..key)
			return key, app
		else
			return all_bt_apps_iterator(apps, key)
		end
	end
end

function app:all_bt_apps() --iterator
	return all_bt_apps_iterator, assert(dynawa.app_manager.all_apps), nil
end

function app:menu_action_bt_apps(args)
	local menu = {banner = "Bluetooth Apps:", items = {}}
	local items = {}
	for app_id, app in self:all_bt_apps() do
		table.insert(items,app.name)
	end
	table.sort(items)
	for i,item in ipairs(items) do
		table.insert(menu.items, {text = item})
	end
	local menuwin = self:new_menuwindow(menu)
	menuwin.menu:render()
	menuwin:push()
end

function app:switching_to_front()
	local menu = {
		banner = "Bluetooth debug menu",
		items = {
			{
				text = "Bluetooth apps", value = {jump = "bt_apps"},
			},
			{
				text = "Known connections", value = {jump = "bt_connections"},
			},
			{
				text = "BT on", value = {jump = "bt_on"},
			},
			{
				text = "BT off", value = {jump = "bt_off"},
			},
			{
				text = "Send #12345", value = {jump = "send_openwatch_12345"},
			},
			{
				text = "Send Hello World", value = {jump = "send_openwatch_helloworld"},
			},
			{
				text = "Send complex hash", value = {jump = "send_openwatch_hash1"},
			},
			{
				text = "Delete all pairings", value = {jump = "delete_pairings"},
			},
		},
	}
	local menuwin = self:new_menuwindow(menu)
	menuwin.menu:render()
	menuwin:push()
end

--[[
function app:menu_cancelled(menu)
	menu.window:pop()
end
]]

function app:send_openwatch(args)
	local data = assert(args.data)
	local app = dynawa.app_manager:app_by_id("dynawa.bt.openwatch")
	app:send_data_test({command = "echo", data=data})
end

function app:menu_action_send_openwatch_hash1()
	local data = {string = "Hello world", number = 666, TRUE = true, FALSE = false, array = {1,2,"three",4,5}, 
			subhash = {key1 = "val1", key2 = "val2"}}
	self:send_openwatch{data=data}
end

function app:menu_action_send_openwatch_12345()
	self:send_openwatch{data=12345}
end

function app:menu_action_send_openwatch_helloworld()
	self:send_openwatch{data="Hello World"}
end

function app:menu_item_selected(args)
	local value = assert(args.item.value)
	self["menu_action_"..value.jump](self,value)
end

function app:menu_action_delete_pairings()
	self.prefs.devices = {}
	self:save_data(self.prefs)
	dynawa.popup:info("All pairings deleted")
end

function app:menu_action_bt_on(args)
	if self.hw_status ~= "off" then
		dynawa.popup:open({style="error", text="Bluetooth is currently not OFF so it cannot be turned ON"})
		return
	end
	self.hw_status = "opening"
	log("Opening BT hardware NOW")
	self.hw.cmd:open()
	log("Opened BT hardware")
end

function app:menu_action_bt_off(args)
	if self.hw_status ~= "on" then
		dynawa.popup:open({style="error", text="Bluetooth is currently not ON so it cannot be turned OFF"})
		return
	end
	for app_id, app in self:all_bt_apps() do
		app:handle_bt_event_turning_off()
	end
	self.hw_status = "closing"
	self.hw.cmd:close()
end

function app:handle_event_bluetooth(event)
	log("---BT event received:")
	for k,v in pairs(event) do
		if k ~= "source" and k ~= "type" then
			log(tostring(k).." = "..tostring(v))
		end
	end
	self["handle_bt_event_"..event.subtype](self,event)
end

function app:handle_bt_event_started(event)
	self.hw_status = "on"
	log("BT on")
	for app_id, app in self:all_bt_apps() do
		app:handle_bt_event_turned_on()
	end
end

function app:handle_bt_event_stopped(event)
	if self.hw_status == "restarting" then
		self.hw_status = "opening"
		self.hw.cmd:open()
		return
	end
	self.hw_status = "off"
	log("BT off")
end
	
function app:handle_bt_event_link_key_req(event)
	local bdaddr = assert(event.bdaddr)
	local link_key
	if self.prefs.devices[bdaddr] then
		link_key = self.prefs.devices[bdaddr].link_key
	end
	if link_key then
		self.hw.cmd:set_link_key(bdaddr, link_key)
	else
		error("I don't have the link key!")
	end
end

function app:handle_bt_event_link_key_not(event)
	local bdaddr = assert(event.bdaddr)
	local link_key = assert(event.link_key)
	if not self.prefs.devices[bdaddr] then
		local name = string.format("MAC %02x:%02x:%02x:%02x:%02x:%02x", string.byte(bdaddr, 1, -1))
		self.prefs.devices[bdaddr] = {name = name}
	end
	if self.prefs.devices[bdaddr].link_key ~= link_key then
		self.prefs.devices[bdaddr].link_key = link_key
		self:save_data(self.prefs)
	end
end
