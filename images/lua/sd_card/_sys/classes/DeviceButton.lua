local Device = Class:get_by_name("Device")
local EventSource = Class:get_by_name("EventSource")

local class = Class:_new("DeviceButton", nil, Device, EventSource)

function class:_init(args)
	assert(type(args.number) == "number", "Button must have numeric id")
	args.name = "button"..args.number
	coroutine.yield()
end

function class:handle_event(event)
	log(self.." received action "..event.type)
	self:generate_event({type = event.type, button_name = self.name, button_number = self.number})
end

Class:add_public(class)

return class
