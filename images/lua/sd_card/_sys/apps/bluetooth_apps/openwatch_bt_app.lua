app.name = "OpenWatch"
app.id = "dynawa.bt.openwatch"

local function to_word(num) --Convert integer to 2 byte word
	return string.char(math.floor(num / 256))..string.char(num%256)
end

local function from_word(bytes) --Convert 2 byte word to int
	return (bytes:sub(1)):byte() * 256 + (bytes:sub(2)):byte()
end

local function safe_string(str)
	local result = {}
	for chr in str:gmatch(".") do
		if chr >=" " and chr <= "~" then 
			table.insert(result,chr)
		else
			table.insert(result,string.format("\\%03d",string.byte(chr)))
		end
	end
	return table.concat(result)
end

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
	log(socket.." got "..#data_in.." bytes of data")
	--log("Got "..#data_in.." bytes of data: "..safe_string(data_in))
	
	while #data_in > 2 and (string.byte(data_in) < 180 or string.byte(data_in) > 183) do
		data_in = data_in.sub(2)
	end
	if #data_in < 3 then
		log("No chunk found in this data")
		return
	end
	local len1,len2,data_in = data_in:match("(.)(.)(.*)")
	assert(data_in, "Header mismatch")
	local len = (len1:byte() % 4) * 256 + len2:byte()
	assert(len > 0, "Zero length")
	assert(len == #data_in, string.format("Chunk size is %s but should be %s according to its header.", #data_in, len))
	self:activity_chunk_received(activity, data_in)
end

function app:activity_chunk_received(activity, chunk)
	local socket = assert(activity.socket)
	log("Chunk is "..#chunk.." bytes")
	local file_id, piece_n_str, of_str, piece = chunk:match("^P(...)(..)(..)(.*)$")
	if piece then --It's P chunk
		local piece_n = from_word(piece_n_str)
		local of = from_word(of_str)
		if piece_n == 1 then
			activity.receiver = {pieces = {piece}, file_id = file_id}
		else
			assert(activity.receiver.file_id == file_id, "Mismatched file_id for piece "..piece_n)
			table.insert(activity.receiver.pieces, piece)
			assert(#activity.receiver.pieces == piece_n, "Wrong piece_n: "..piece_n)
		end
		log("Acknowledging piece "..piece_n.." of "..of)
		local ack = table.concat({"A",file_id,piece_n_str})
		self:activity_send_chunk(activity, ack)
		if piece_n == of then --binstring is complete
			local binstring = table.concat(activity.receiver.pieces)
			activity.receiver = nil
			self:activity_got_binstring(activity, binstring)
		end
		return
	end
	assert(chunk:match("^A.....$"), "Not Ack chunk")
	if not activity.sender or chunk ~= activity.sender.waiting_for_ack then
		log("Unexpected Ack chunk received (ignored)")
		return
	end
	log("Ack OK")
	activity.sender.waiting_for_ack = nil
	if #activity.sender.pieces > 0 then
		self:activity_send_piece(activity)
	end
end

function app:activity_got_binstring(activity, binstring)
	--log("Parsing binstring: "..safe_string(binstring))
	local value, rest = self:binstring_to_value(binstring)
	assert (rest == "", #rest.." unconsumed bytes after binstring parsing")
	log("Parsed result: OK")
	--log("PARSED RESULT VALUE: "..dynawa.file.serialize(value))
	if type(value) == "table" and value.command then
		if value.command == "echo" then
			log("Echoing back...")
			self:activity_send_data(activity,assert(value.data))
		elseif value.command == "time_sync" then
			local time = assert(value.time)
			local t0 = os.time()
			log (string.format("Time sync: %+d seconds",time - t0))
			dynawa.time.set(time)
		else
			self.events:generate_event{type = "from_phone", data = value}
		end
	end
end

function app:binstring_to_value(binstring)
	local typ = binstring:sub(1,1)
	if typ == "T" then
		return true, binstring:sub(2)
	elseif typ == "F" then
		return false, binstring:sub(2)
	elseif typ == "$" then
		local len, rest = binstring:match("^%$(%d*):(.*)$")
		len = assert(tonumber(len), "String length is nil")
		return rest:sub(1,len), rest:sub(len+1)
	elseif typ == "#" then
		local num,rest = binstring:match("^#(.-);(.*)$")
		num = tonumber(num)
		assert(num, "Expected a number but parsed string to nil")
		return num, rest
	elseif typ == "@" then
		local array = {}
		local rest = binstring:sub(2)
		local item
		while true do
			if rest:sub(1,1) == ";" then
				return array, rest:sub(2)
			end
			item, rest = self:binstring_to_value(rest)
			table.insert(array, item)
		end
		error("WTF?")
	elseif typ == "*" then
		local hash = {}
		local rest = binstring:sub(2)
		local key, val
		while true do
			if rest:sub(1,1) == ";" then
				return hash, rest:sub(2)
			end
			key, rest = self:binstring_to_value(rest)
			assert(type(key)=="string", "Hash key is not string but "..tostring(key))
			val, rest = self:binstring_to_value(rest)
			hash[key] = val
		end
		error("WTF?")
	else
		error("Unknown value type: "..typ)
	end
end

function app:handle_event_socket_connected(socket)
	log(self.." socket connected: "..socket)
	socket.activity.status = "connected"
	socket.activity.reconnect_delay = nil
	self:info("Succesfully connected to "..socket.activity.name)
	self:activity_send_data(socket.activity,"HELLO")	
end

function app:send_data_test(data)
	local id, activity = next(self.activities)
	if not id then
		dynawa.popup:error("Not connected (no Activity)")
		return
	end
	if activity.status ~= "connected" then
		dynawa.popup:error("Not connected - Activity status is '"..tostring(activity.status).."'")
		return
	end
	self:activity_send_data(activity, data)
end

function app:activity_send_data(activity, data)
	data = table.concat(self:encode_data(data, {}))
	if not activity.sender then
		activity.sender = {pieces={}}
	end
	self:split_data(data, 100, activity.sender.pieces)
	if not activity.sender.waiting_for_ack then
		self:activity_send_piece(activity)
	else
		log("Cannot send piece - still waiting for Ack chunk for previous sent piece")
	end
end

function app:encode_data(data, parts)
	assert(parts)
	local typ = type(data)
	if typ == "string" then
		table.insert(parts,"$"..#data..":")
		table.insert(parts,data)
	elseif typ == "boolean" then
		if data then
			table.insert(parts,"T")
		else
			table.insert(parts,"F")
		end
	elseif typ == "number" then
		table.insert(parts, "#"..data..";")
	elseif typ == "table" then
		if type(next(data)) == "number" then --It's an array
			table.insert(parts,"@")
			for i,elem in ipairs(data) do
				self:encode_data(elem,parts)
			end
		else --It's hash table
			table.insert(parts,"*")
			for key,elem in pairs(data) do
				assert(type(key) == "string", "Hash table key is not string")
				self:encode_data(key,parts)
				self:encode_data(elem,parts)
			end
		end
		table.insert(parts,";")
	else
		error("Unable to encode data type: "..typ)
	end
	return parts
end

function app:activity_send_piece(activity)
	assert(activity.sender.pieces)
	local piece = assert(table.remove(activity.sender.pieces, 1))
	activity.sender.waiting_for_ack = "A"..piece:sub(2,6)
	self:activity_send_chunk(activity, piece)
end

function app:split_data(data, piece_size, pieces)
	local file_id = string.char(math.random(256)-1)..string.char(math.random(256)-1)..string.char(math.random(256)-1)
	local size = #data
	assert(size > 0, "Empty data")
	local n_pieces = math.floor(size / piece_size) + 1
	log("Split to "..n_pieces.." pieces...")
	for n_piece = 1,n_pieces do
		local f, t = (n_piece - 1) * piece_size + 1, n_piece * piece_size
		local substr = data:sub(f,t)
		substr = table.concat({"P",file_id,to_word(n_piece),to_word(n_pieces),substr})
		--log(string.format("Piece %s: %s",n_piece, safe_string(substr)))
		table.insert(pieces,substr)
	end
	return pieces
end

function app:activity_send_chunk(activity, chunk)
	assert (#chunk <= 1023 and #chunk > 0)
	local header = to_word((180*256) + #chunk)
	local data = header..chunk
	log("Sending chunk with header: "..safe_string(data))
	assert(activity.socket):send(data)
end

function app:handle_event_socket_disconnected(socket,prev_state)
	log(socket.." disconnected")
	local activity = socket.activity
	if prev_state == "connected" then
		self:info("Disconnected from "..activity.name)
	end
	activity.socket = nil
	socket:_delete()
	self:should_reconnect(activity)
end

function app:should_reconnect(activity)
	assert(not activity.__deleted)
	activity.status = "waiting_for_reconnect"
	activity.reconnect_delay = math.min((activity.reconnect_delay or 1000) * 2, 8000)
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
	--#todo destroy the socket!
	local activity = assert(socket.activity)
	self:should_reconnect(activity)
end

function app:handle_event_socket_find_service_result(sock0,channel)
	log ("Find_service_result channel = "..tostring(channel))
	local activity = sock0.activity
	if channel == 0 then
		--[[
		self:should_reconnect(activity)
		return
		--]]
		-- android donut dyno workaround
		channel = 15
	end
	activity.channel = channel
	local socket = self:new_socket("rfcomm")
	activity.socket = socket
	socket.activity = activity
	activity.status = "connecting"
	socket:connect(activity.bdaddr, activity.channel)
end

function app:start()
	self.events = Class.EventSource("openwatch")
end

function app:info(txt)
	--[[if self.last_info == txt then
		return
	end
	self.last_info = txt]]
	dynawa.popup:open{text = txt, autoclose = true}
	dynawa.devices.vibrator:alert()
end

