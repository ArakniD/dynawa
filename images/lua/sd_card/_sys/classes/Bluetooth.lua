local class = Class("Bluetooth", Class.EventSource)

function class:_init()
	Class.EventSource._init(self,"bluetooth")
end

local events = {
    [1] = "STARTED",
    [5] = "STOPPED",
    [10] = "LINK_KEY_NOT",
    [11] = "LINK_KEY_REQ",
    [15] = "CONNECTED",
    [16] = "DISCONNECTED",
    [17] = "ACCEPTED",
    [20] = "DATA",
    [30] = "FIND_SERVICE_RESULT",
    [100] = "ERROR",
}

function class:handle_hw_event(event)
	event.subtype = assert(events[event.subtype],"Unknown BT event: "..event.subtype)
	self:generate_event(event)
end

return class

