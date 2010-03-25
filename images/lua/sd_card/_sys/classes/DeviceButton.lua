local Device = Class:get_by_name("Device")
local EventSource = Class:get_by_name("EventSource")

local class = Class:_new("DeviceButton", nil, Device, EventSource)

function class:_init(number)
	assert(type(number) == "number", "Button must have numeric id")
	Device._init(self, "button"..number)
	EventSource._init(self)
end

function class:handle_event(event)
	log(self.." received action "..event.type)
	self:generate_event({type = event.type, button_name = self.name, button_number = self.number})
end

Class:add_public(class)

return class
