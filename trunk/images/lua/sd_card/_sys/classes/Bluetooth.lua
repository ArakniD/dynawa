local class = Class("Bluetooth", Class.EventSource)

function class:_init()
	Class.EventSource._init(self,"bluetooth")
	local cmd = {
		OPEN = 1,
		CLOSE = 2,
		SET_LINK_KEY = 3,
		INQUIRY = 4,
		SOCKET_NEW = 100,
		SOCKET_CLOSE = 101,
		SOCKET_BIND = 102,
		FIND_SERVICE = 200,
		LISTEN = 300,
		CONNECT = 301,
		SEND = 400,
	}
	self.cmd = {}
	for key, val in pairs(cmd) do
		self.cmd[key] = function(self, ...)
			return dynawa.bt.cmd(val, ...)
		end
	end
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

