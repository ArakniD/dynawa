local class = Class("BluetoothApp", Class.App)

function class:_init(...)
	Class.App._init(self,...)
	self.connections = {}
end

--Connection is just a normal table whose only required field is "id" (a string).
--Connections are stored in self.connections and indexed by their ids.
--Everything else is up to the programmer.
function class:new_connection(id)
	id = id or "BT_connection"..dynawa.unique_id()
	assert(type(id)=="string","Connection id is not string but "..tostring(id))
	local conn = {id = id}
	if self.connections[id] then
		error("Connection '"..id.."' already registered for "..self)
	end
	self.connections[conn.id] = conn
	return conn
end

function class:delete_connection(id)
	if type(id) ~= "string" then
		id = assert(id.id)
		assert(type(id) == "string")
	end
	assert(self.connections[id],"Unknown connection "..id)
	self.connections[id] = nil
end

function class:new_socket(protocol)
	local sock = Class.BluetoothSocket(protocol)
	sock.app = self
	return sock
end

function class:handle_bt_event_turned_on()
	--BT hardware was just turned on
end

function class:handle_bt_event_turning_off()
	--BT hardware WILL BE turned off now
end

return class

