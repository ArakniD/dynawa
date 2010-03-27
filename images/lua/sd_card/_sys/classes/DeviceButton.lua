local Device = Class:get_by_name("Device")

local class = Class("DeviceButton", nil, Device)
local EventSource = Class:get_by_name("EventSource")

function class:_init(number)
	assert(type(number) == "number", "Button must have numeric id")
	Device._init(self,"button"..number)
	self.event_source = EventSource()
end

function class:handle_event(event)
	log(self.." received action "..event.type)
	self.event_source:generate_event({type = event.type, button_name = self.name, button_number = self.number})
end

Class:add_public(class)

return class
