app.name = "OpenWatch"
app.id = "dynawa.bt.openwatch"

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
			if not activity.socket.__deleted then
				log("Trying to close "..activity.socket)
				activity.socket:close()
			end
			activity.socket = nil
			self:delete_activity(activity)
		end
		activity.status = nil
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
	log("Got "..#data_in.." bytes of data: "..string.format("%q",data_in))
	--[[if data_in:match("^%+SENDING .+") then
		data_out = "+RECEIVING\r"
		else
			activity.receiver = {}
		end
	end]]
	local head, rest
	socket.linebuffer = socket.linebuffer or {}
	repeat
		head,rest = data_in:match("(.-)\r(.*)")
		if head then
			table.insert(socket.linebuffer, head)
			self:activity_line_received(activity,table.concat(socket.linebuffer))
			socket.linebuffer = {}
			data_in = rest
		else --No endline
			table.insert(socket.linebuffer,data_in)
		end
	until not rest
end

function app:activity_line_received(activity, line)
	local receiver = activity.receiver
	local socket = assert(activity.socket)
	log("Line received:"..line)
	if line:match("^%+SENDING (.+)$") then
		socket:send("+RECEIVING\r")
		return
	end
	if not receiver then
	
	end
end

function app:handle_event_socket_connected(socket)
	log(self.." socket connected: "..socket)
	socket:send("HELLO_FROM_TCH1\r")
	socket.activity.status = "connected"
	socket.activity.reconnect_delay = nil
end

function app:send_data_test(args)
	local data = assert(args.data)
	local id, activity = next(self.activities)
	if not id then
		dynawa.popup:error("Not connected (no Activity)")
		return
	end
	if activity.status ~= "connected" then
		dynawa.popup:error("Not connected - Activity status is '"..tostring(activity.status).."'")
		return
	end
	self:send_data(data, activity)
end

function app:send_data(data, activity)
	self:_send_line("+SENDING KockaLezeDirou", activity)
	self:_send_data(data, activity)
end

function app:_send_data(data, activity)
	local typ = type(data)
	if typ == "boolean" or typ == "nil" then
		self:_send_line("!"..tostring(data),activity)
	elseif typ == "number" then
		self:_send_line("#"..tostring(data),activity)
	elseif typ == "string" then
		self:_send_line("$"..#data, activity)
		self:_send_line(data, activity)
	elseif typ == "table" then
		local items = {}
		for k,v in pairs(data) do
			table.insert(items,{k,v})
		end
		if #items == #data then --array - #todo ignore??? Too slow!
			self:_send_line("@"..#data, activity)
			for i = 1, #data do
				self:_send_data(data[i], activity)
			end
		else --table
			self:_send_line("*"..#items, activity)
			for i, item in ipairs(items) do
				self:_send_data(item[1], activity)
				self:_send_data(item[2], activity)
			end
		end
	else
		error("Unable to serialize: "..tostring(data))
	end
end

function app:_send_line(line, activity)
	assert(activity.socket):send(line.."\r")
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

function app:handle_event_socket_error(socket,error)
	log("BT error '"..tostring(error).."' in "..socket)
	local activity = assert(socket.activity)
	self:should_reconnect(activity)
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

