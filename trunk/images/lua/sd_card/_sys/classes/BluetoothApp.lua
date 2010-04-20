local class = Class("BluetoothApp", Class.App)
class.is_bluetooth_app = true

function class:_init()
end

--[[function class:handle_event_bluetooth(event)
	event.subtype = assert(events[event.subtype],"Unknown BT event: "..event.subtype)
	self:generate_event(event)
end]]

return class

