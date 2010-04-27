app.name = "Bluetooth MBW150"

function app:handle_bt_event_turned_on()
	--#todo Select only devices that are mine
	for bdaddr,device in pairs(dynawa.bluetooth_manager.devices) do
		log("Connecting to "..device.name)
		dynawa.devices.bluetooth.cmd:set_link_key(bdaddr, device.link_key)
		local conn = self:new_connection()
		conn.bdaddr = bdaddr
		conn.name = device.name
		self:connection_start(conn)
	end
end

function app:connection_start(conn)
	local socket = assert(self:new_socket("sdp"))
	assert(socket._c)
	assert(conn.bdaddr)
    dynawa.devices.bluetooth.cmd:find_service(socket._c, conn.bdaddr)
end
