local class = Class("Bluetooth", Class.EventSource)

function class:_init()
	Class.EventSource._init(self,"bluetooth")
	local cmd = {
		open = 1,
		close = 2,
		set_link_key = 3,
		inquiry = 4,
		socket_new = 100,
		socket_close = 101,
		socket_bind = 102,
		find_service = 200,
		listen = 300,
		connect = 301,
		send = 400,
	}
	self.cmd = {}
	for key, val in pairs(cmd) do
		self.cmd[key] = function(self, ...)
			return dynawa.bt.cmd(val, ...)
		end
	end
end

local events = {
    [1] = "started",
    [5] = "stopped",
    [10] = "link_key_not",
    [11] = "link_key_req",
    [15] = "connected",
    [16] = "disconnected",
    [17] = "accepted",
    [20] = "data",
    [30] = "find_service_result",
    [100] = "error",
}

function class:handle_hw_event(event)
	event.subtype = assert(events[event.subtype],"Unknown BT event: "..event.subtype)
	self:generate_event(event)
end

return class

