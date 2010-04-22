local class = Class("BluetoothApp", Class.App)

function class:_init(...)
	Class.App._init(self,...)
end

--[[function class:handle_event_bluetooth(event)
	event.subtype = assert(events[event.subtype],"Unknown BT event: "..event.subtype)
	self:generate_event(event)
end]]

return class

