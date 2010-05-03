app.name = "OpenWatch"

function app:handle_bt_event_turned_on()
	--#todo
	--currently, all activities are created and deletes with BT on/off, for each paired device!
	for bdaddr,device in pairs(dynawa.bluetooth_manager.devices) do
		log("Connecting to "..device.name)
		--dynawa.devices.bluetooth.cmd:set_link_key(bdaddr, device.link_key)
		local act = self:new_activity()
		act.bdaddr = bdaddr
		act.name = device.name.." "..act.id
		self:activity_start(act)
	end
end

function app:handle_bt_event_turning_off()
	for id, activity in pairs(self.activities) do
		if activity.socket.__deleted then
			activity.socket = nil
		end
		if activity.socket then
			log("Trying to close "..activity.socket)
			activity.socket:close()
			activity.socket = nil
			self:delete_activity(activity)
		end
	end
end

function app:activity_start(act)
	assert(act)
	local socket = assert(self:new_socket("sdp"))
	act.socket = socket
	socket.activity = act
	assert(socket._c)
	assert(act.bdaddr)
	act.channel = false
	act.status = "finding_service"
    dynawa.devices.bluetooth.cmd:find_service(socket._c, act.bdaddr)
end

function app:handle_event_socket_data(socket, data_in)
	assert(data_in)
	local activity = assert(socket.activity)
	--log(socket.." got "..#data_in.." bytes of data")
	local data_out
	log("Got "..#data_in.." bytes of data: "..data_in)
	if data_in:match("%+RECEIVING") then
		data_out = "#69\r"
	end
	if data_out then
		log(activity.name.." sending " .. #data_out.." bytes of data")
		socket:send(data_out)
	end
end

function app:handle_event_socket_connected(socket)
	log(self.." socket connected: "..socket)
	--socket:send("+SENDING 98765\r")
	socket.activity.status = "connected"
end

function app:handle_event_socket_disconnected(socket)
	log(socket.." disconnected")
	local activity = socket.activity
	activity.socket = nil
	socket:_delete()
	self:should_reconnect(activity)
end

function app:should_reconnect(activity)
	assert(not activity.__deleted)
	activity.status = "waiting_for_reconnect"
	activity.reconnect_delay = math.min((activity.reconnect_delay or 1000) * 2, 15000)
	log("Waiting "..activity.reconnect_delay.." ms before trying to reconnect "..activity.name)
	dynawa.devices.timers:timed_event{delay = activity.reconnect_delay, receiver = self, what = "attempt_reconnect", activity = activity}
end

function app:handle_event_timed_event(message)
	assert(message.what == "attempt_reconnect")
	local activity = assert(message.activity)
	if activity.__deleted then
		return
	end
	if activity.status ~= "waiting_for_reconnect" then
		return
	end
	log("Trying to reconnect "..activity.name)
	self:activity_start(activity)
end

function app:handle_event_socket_find_service_result(sock0,channel)
	log ("Find_service_result channel = "..tostring(channel))
	local activity = sock0.activity
	if channel == 0 then
		self:should_reconnect(activity)
		return
	end
	activity.channel = channel
	local socket = self:new_socket("rfcomm")
	activity.socket = socket
	socket.activity = activity
	activity.status = "connecting"
	socket:connect(activity.bdaddr, activity.channel)
end

