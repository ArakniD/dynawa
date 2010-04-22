app.name = "Bluetooth Manager"
app.id = "dynawa.bluetooth_manager"

function app:start()
	self.hw = assert(dynawa.devices.bluetooth)
	self.hw:register_for_events(self)
end

local function all_bt_apps_iterator(apps, key0)
	log("iterating")
	local key, app = next(apps,key0)
	if key then
		if app:_class() == Class.BluetoothApp then
			log("matches:"..key)
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
				text = "BT off/on", value = {jump = "bt_off_on"},
			},
			{
				text = "BT off", value = {jump = "bt_off"},
			},
			{
				text = "Pairing", value = {jump = "pairing"},
			},
			{
				text = "Something else", value = {jump = "something_else"},
			},
		},
	}
	local menuwin = self:new_menuwindow(menu)
	menuwin.menu:render()
	menuwin:push()
end

function app:menu_item_selected(args)
	local value = assert(args.item.value)
	self["menu_action_"..value.jump](self,value)
end

function app:menu_action_bt_on(args)
	self.hw.cmd:open()
end

function app:menu_action_bt_off(args)
	self.hw.cmd:close()
end

function app:menu_action_bt_off_on(args)
	self:menu_action_bt_off(args)
	self:menu_action_bt_on(args)
end

function app:handle_event_bluetooth(event)
	log("subtype:"..tostring(event.subtype))
end

