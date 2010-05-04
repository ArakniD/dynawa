local class = Class("BluetoothSocket")
class.is_bluetooth_socket = true

function class:_init(protocol)
	self.proto = assert(protocol)
	self.id = dynawa.unique_id()
	self._c = dynawa.devices.bluetooth.cmd:socket_new(self)
	self.state = "initialized"
	log("Initialized new socket: "..self)
	return self
end

function class:close()
	local dbgtxt = "Closed and deleted "..self
	dynawa.devices.bluetooth.cmd:socket_close(self._c)
	self:_delete()
	log(dbgtxt)
end

function class:connect(bdaddr, channel)
	log(self.." connecting at channel "..channel)
	dynawa.devices.bluetooth.cmd:connect(self._c, bdaddr, channel)
end

function class:listen(channel)
	dynawa.devices.bluetooth.cmd:listen(self._c, channel)
end

function class:send(data)
	log(self.." sending data: "..string.format("%q",tostring(data)))
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
	if event.data then
		self.app:handle_event_socket_data(self, assert(event.data))
	else
		log("!!!Socket incoming data event's data is nil!!!")
	end
end

function class:handle_bt_event_find_service_result(event)
	local channel = event.channel
	local app = self.app
	app:handle_event_socket_find_service_result(self,channel)
	self:close()
end

function class:handle_bt_event_error(event)
	error(self.." - error")
end

return class

