local class = Class("BluetoothSocket")
class.is_bluetooth_socket = true

function class:_init(protocol)
	self.proto = assert(protocol)
	self.id = dynawa.unique_id()
	self._c = dynawa.devices.bluetooth.cmd:socket_new(self)
	self.state = "initialized"
	log("Initialized socket: "..self)
	return self
end

function class:close()
	dynawa.devices.bluetooth.cmd:socket_close(self._c)
	self:_delete()
end

function class:connect(bdaddr, channel)
	dynawa.devices.bluetooth.cmd:connect(self._c, bdaddr, channel)
end

function class:listen(channel)
	dynawa.devices.bluetooth.cmd:listen(self._c, channel)
end

function class:send(data)
	log(self.." sending data: "..tostring(data))
	dynawa.devices.bluetooth.cmd:send(self._c, data)
end

function class:handle_bt_event_connected(event)
	self.state = "connected"
	self.app:handle_event_socket_connected(self)
end

function class:handle_bt_event_disconnected(event)
	self.state = "disconnected"
	self.app:handle_event_socket_disconnected(self)
end

function class:handle_bt_event_accepted(event)
	error(self.." - error")
end

function class:handle_bt_event_data(event)
	self.app:handle_event_socket_data(self, assert(event.data))
end
    
function class:handle_bt_event_find_service_result(event)
	log (self.." - find service result")
	local channel = event.channel
	log ("Find_service_result channel = "..tostring(event.channel))
	if channel == 0 then
		error("No remote listening RFCOMM - "..self)
	end
	local activity = self.activity
	activity.channel = channel
	local socket = self.app:new_socket("rfcomm")
	socket.activity = activity
	activity.status = "connecting"
	socket:connect(activity.bdaddr, activity.channel)
	self:close()
end

function class:handle_bt_event_error(event)
	error(self.." - error")
end

return class

