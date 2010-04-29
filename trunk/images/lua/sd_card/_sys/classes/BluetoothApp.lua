local class = Class("BluetoothApp", Class.App)

function class:_init(...)
	Class.App._init(self,...)
	self.activities = {}
end

--Activity is just a normal table whose only required field is "id" (a string).
--Activities are stored in self.activities and indexed by their ids.
--Everything else is up to the programmer.
function class:new_activity(id)
	id = id or "BT_activity"..dynawa.unique_id()
	assert(type(id)=="string","Activity id is not string but "..tostring(id))
	local conn = {id = id, app = self}
	if self.activities[id] then
		error("Activity '"..id.."' already registered for "..self)
	end
	self.activities[conn.id] = conn
	log("New activity id: "..conn.id)
	return conn
end

function class:delete_activity(id)
	if type(id) ~= "string" then
		id = assert(id.id)
		assert(type(id) == "string")
	end
	assert(self.activities[id],"Unknown activity "..id)
	log("Deleting "..(self.activities[id].name) or ("activity "..id))
	self.activities[id] = nil
end

local protocol_codes = {
	hci = 1,
	l2cap = 2,
	sdp = 3,
	rfcomm = 4,
}

function class:new_socket(protocol)
	local proto = protocol_codes[protocol]
	if not proto then
		error("Unknown BT socket protocol: "..protocol)
	end
	local sock = Class.BluetoothSocket(proto)
	sock.app = self
	return sock
end

function class:handle_event_socket_connected(socket)
	log(socket.." connected")
end

function class:handle_event_socket_data(socket,data)
	log(string.format("%s got %s bytes of data: '%q'", tostring(socket), #data, data))
end

function class:handle_event_socket_disconnected(socket)
	log(socket.." disconnected")
end

function class:handle_event_socket_find_service_result(socket,channel)
	log ("Find_service_result channel = "..tostring(channel))
end

function class:handle_bt_event_turned_on()
	--BT hardware was just turned on
end

function class:handle_bt_event_turning_off()
	--BT hardware *WILL BE* turned off now
end

return class

