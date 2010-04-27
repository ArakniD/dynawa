local class = Class("BluetoothSocket")
class.is_bluetooth_socket = true

function class:_init(protocol)
	self.protocol = assert(protocol)
	self.id = dynawa.unique_id()
	self._c = dynawa.devices.bluetooth.cmd:socket_new(self)
	self.state = "initialized"
	log("Initialized socket: "..self)
	return self
end

function class:handle_bt_event_connected(event)
	error(self.." - error")
end

function class:handle_bt_event_disconnected(event)
	error(self.." - error")
end

function class:handle_bt_event_accepted(event)
	error(self.." - error")
end

function class:handle_bt_event_data(event)
	error(self.." - error")
end
    
function class:handle_bt_event_find_service_result(event)
	log (self.." - find service result")
	log ("channel = "..tostring(event.channel))
end

function class:handle_bt_event_error(event)
	error(self.." - error")
end

return class

