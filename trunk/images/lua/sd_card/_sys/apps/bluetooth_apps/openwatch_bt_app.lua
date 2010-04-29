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
		if activity.socket then
			log("Trying to close "..activity.socket)
			activity.socket:close()
			activity.socket = nil
			self:delete_activity(activity)
		end
	end
end

app.parser_state_machine = {
	[1] = {
		{"%*SEAM", 2, "AT*SEAUDIO=0,0\r", nil},
		{"OK", 2, "AT*SEAUDIO=0,0\r", nil},
	},
	[2] = {
		{"ERR", 3, "AT+CIND=?\r", nil},
	},
	[3] = {
		{"%+CIND:", 4, "AT+CIND?\r",  nil},
	},
	[4] = {
		{"%+CIND:", 5, "AT+CMER=3,0,0,1\r", nil},
	},
	[5] = {
		{"OK", 6, "AT+CCWA=1\r", nil},
	},
	[6] = {
		{"OK", 7, "AT+CLIP=1\r", nil},
	},
	[7] = {
		{"OK", 8, "AT+GCLIP=1\r", nil},
	},
	[8] = {
		{"OK", 9, "AT+CSCS=\"UTF-8\"\r", nil},
	},
	[9] = {
		{"OK", 10, "AT*SEMMIR=2\r", nil},
	},
	[10] = {
		{"OK", 11, "AT*SEVOL?\r", nil},
	},
	[11] = {
		{"SEVOL", 12, "ATE0\r", nil},
	},
	[12] = {
		{"OK", 13, "AT+CCLK?\r", nil},
	},
	[13] = {
		{"CCLK", 14, nil, 
		function(activity, data)
	-- example: +CCLK: "2010/03/11,23:45:14+00"
			local year, month, day, hour, min, sec = string.match(data, "CCLK: \"(%d+)/(%d+)/(%d+),(%d+):(%d+):(%d+)")
			local time = os.time({["year"]=year, ["month"]=month, ["day"]=day, ["hour"]=hour, ["min"]=min, ["sec"]=sec})
			log("time " .. time)
			dynawa.time.set(time)
		end 
		},
	},
}

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
	log(socket.." got "..#data_in.." bytes of data")
	local data_out
	local activity = assert(socket.activity)
	log(activity.name.." got data: ".. data_in)
	local state_transitions = self.parser_state_machine[socket.parser_state]
	if state_transitions then
		for i, transition in ipairs(state_transitions) do
			if string.match(data_in, transition[1]) then
				-- next state
				if transition[2] then
					log(activity.name.. " state " .. socket.parser_state .. " -> " .. transition[2])
					socket.parser_state = transition[2]
				end
				-- response string
				if transition[3] then
					data_out = transition[3]
				end
				-- state handler
				if transition[4] then
					activity.status = "connected"
					activity.reconnect_delay = false
					transition[4](activity, data_in)
					log("Memory used: "..(collectgarbage("count")*1024))
				end
				break
			end
		end
	end
	if data_out then
		log(activity.name.." sending " .. #data_out.." bytes of data")
		socket:send(data_out)
	end
end

function app:handle_event_socket_connected(socket)
	log(self.." socket connected: "..socket)
	socket.parser_state = 1
	local data_out = "AT*SEAM=\"MBW-150\",13\r"
	socket.activity.status = "negotiating"
	socket:send(data_out)
end

function app:handle_event_socket_disconnected(socket)
	log(socket.." disconnected")
	local activity = socket.activity
	activity.socket = nil
	socket:delete()
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

