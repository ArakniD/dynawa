app.name = "Bluetooth MBW150"

function app:handle_bt_event_turned_on()
	--#todo Select only devices that are mine
	for bdaddr,device in pairs(dynawa.bluetooth_manager.devices) do
		log("Connecting to "..device.name)
		--dynawa.devices.bluetooth.cmd:set_link_key(bdaddr, device.link_key)
		local act = self:new_activity()
		act.bdaddr = bdaddr
		act.name = device.name
		self:activity_start(act)
	end
end

function app:activity_start(act)
	assert(act)
	local socket = assert(self:new_socket("sdp"))
	socket.activity = act
	assert(socket._c)
	assert(act.bdaddr)
	act.channel = false
	act.status = "finding_service"
    dynawa.devices.bluetooth.cmd:find_service(socket._c, act.bdaddr)
end

function app:handle_event_socket_connected(socket)
	log(self.." socket connected: "..socket)
	local data_out = "AT*SEAM=\"MBW-150\",13\r"
	socket:send(data_out)
end
