app.name = "HandsFree BT"
app.id = "dynawa.handsfree"

local SDP = Class.BluetoothSocket.SDP

local service = {
	{
		SDP.UINT16(0x0000), -- Service record handle attribute
		SDP.UINT32(0x00000000)
	},
	{
		SDP.UINT16(0x0001), -- Service class ID list attribute
		{
	--[[ FF HTC Desire
			SDP.UUID16(0x1108), -- Head-Set
			SDP.UUID16(0x110b), -- Audio Sink
	--]]

			SDP.UUID16(0x111e), -- Hands-Free
			SDP.UUID16(0x1203) -- Generic Audio
		}
	},
	{
		SDP.UINT16(0x0004), -- Protocol descriptor list attribute
		{
			{
				SDP.UUID16(0x0100), -- L2CAP
			},
			{
				SDP.UUID16(0x0003), -- RFCOMM
				SDP.RFCOMM_CHANNEL() -- channel
			}
		}
	},
	{
		SDP.UINT16(0x0009), -- Profile descriptor list attribute
		{
			{
				SDP.UUID16(0x111e), -- Hands-Free
				--SDP.UINT16(0x0105) -- Version
				SDP.UINT16(0x0101) -- Version
			}
		}
	},
    {
        SDP.UINT16(0x0311), -- SupportedFeatures
        {
            --SDP.UUID16(0x001e) -- 
            SDP.UUID16(0x0004) -- CLIP
        }
    }
	--[[
		{
			SDP.UINT16(0x0005), -- Browse group list
			{
				SDP.UUID16(0x1002) -- PublicBrowseGroup
			}
		}
	--]]
}

app.parser_state_machine = {
	[1] = {
		{"^+BRSF:", nil, nil, nil},
		{"^OK$", 2, "AT+CIND=?\r", nil},
	},
	[2] = {
		{"^%+CIND:", nil, nil,  
			-- +CIND: ("service",(0-1)),("call",(0-1)),("callsetup",(0-3)),("callheld",(0->)),("signal",(0-5)),("roam",(0-1)),("battchg",(0-5))
			function(app, socket, data)
				assert(not next(socket.indicators_enum))
				for ind, val_min, val_max in string.gfind(data, '%("(%a+)",%(([^%-,]+)[%-,]([^%)]+)%)%)') do
					val_min, val_max = tonumber(val_min), tonumber(val_max)
					log("ind [" .. ind .. "] min " .. val_min .. " max " .. val_max)
					table.insert(socket.indicators_enum, {ind, val_min, val_max})
				end 
			end
		},
		{"^OK$", 3, "AT+CIND?\r", nil},
	},
	[3] = {
		{"^%+CIND:", nil, nil,
		    -- +CIND: 1,0,0,0,4,0,4
			function(app, socket, data)
				local ind_index = 1
				for val in string.gfind(data, "%d+") do
					local ind_data = socket.indicators_enum[ind_index]
						val = assert(tonumber(val))

					if ind_data then
						log("ind [" .. ind_data[1] .. "] batch val = " .. val)
						socket.indicators[ind_data[1]] = val
					else
						error("Indicator index "..ind_index.." out of bounds for +CIND batch response, val = "..val)
					end 
					ind_index = ind_index + 1
				end
				if socket.indicators_enum[ind_index] then
					error("Too few values received in +CIND batch response, expecting at least "..ind_index)
				end
			end
		},
		{"^OK$", 4, "AT+CMER=3,0,0,1\r", nil},
	},
	[4] = {
		{"^OK$", 5, "AT+CLIP=1\r", nil},
	},
	[5] = {
		{"^OK$", 6, nil,
			function (app,socket, data)
				assert(app.activities[socket].status == "negotiating")
				app.activities[socket].status = "connected"
			end
		},
	},
	[6] = {
		{"^%+CIEV:", nil, nil, 
			-- +CIEV: 3,1
			function(app, socket, data)
				local ind_index, val = string.match(data, '(%d+),(%d+)')
				ind_index, val = assert(tonumber(ind_index)), assert(tonumber(val))
				local ind_data = socket.indicators_enum[ind_index]
				if ind_data then
					local ind_id = assert(ind_data[1])
					local ind_handler = app.ind_handlers[ind_id]
					if ind_handler then
						socket.indicators[ind_id] = val
						ind_handler(app, socket, ind_id, val)
					else
						error("No handler for indicator " .. ind_id)   
					end
				else
					error("Invalid indicator index " .. ind_index)
				end
			end
		},
		{"^RING", nil, nil, nil},
		{"^%+CLIP:", nil, nil,
			-- +CLIP: "+420222562062",145
			function(app, socket, data)
				local phone_number, format = string.match(data, '"([^"]*)",(%d+)')
				format = tonumber(format)
				log("phone number " .. phone_number .. " " .. format)
			end
		},
		--[[ "format" explained (145 on HTC Desire):
		- values 128-143: The phone number format may be a national or international
format, and may contain prefix and/or escape digits. No changes on the number
presentation are required.
		- values 144-159: The phone number format is an international number, including
the country code prefix. If the plus sign ("+") is not included as part of the
number and shall be added by the AG as needed.
		- values 160-175: National number. No prefix nor escape digits included.
		]]

		-- Catch-all
		{".*", nil, nil,
			function (app, socket, data)
				log("*** Incoming HF command not understood: "..data)
			end
		},
	},
}

app.default_ind_handler = function(app, socket, ind, val)
	log("ind <" .. ind .. "> changed to: " .. val)
end

app.ind_handlers = {
	service = app.default_ind_handler,
	call = app.default_ind_handler,
	callsetup = app.default_ind_handler,
	callheld = app.default_ind_handler,
	signal = app.default_ind_handler,
	roam = app.default_ind_handler,
	battchg = app.default_ind_handler,
}

function app:log(socket, msg)
	log(msg)
end

function app:start()
	self.activities = {}
	self.socket = nil

	dynawa.bluetooth_manager.events:register_for_events(self)

	if dynawa.bluetooth_manager.hw_status == "on" then
		self:server_start()
	end
end

function app:server_start()
	local socket = assert(self:new_socket("rfcomm"))
	self.socket = socket
	socket:listen(nil)
	--socket:listen(1)
	socket:advertise_service(service)
end

function app:server_stop()
	self.socket:close()
	self.socket = nil
	self.activities = {}
end

function app:handle_bt_event_turned_on()
	self:server_start()
end

function app:handle_bt_event_turning_off()
	self:server_stop()
end

function app:handle_event_socket_connection_accepted(socket, connection_socket)
	log(socket.." connection accepted " .. connection_socket)
	if self.activities[connection_socket] then
		error("Connection already established to this socket: "..connection_socket)
	end
	--[[
	for k,v in pairs(connection_socket) do
		log("Socket key: "..tostring(k))
	end
	self.activities[connection_socket] = {status = "negotiating", name = assert(dynawa.bluetooth_manager.prefs.devices[socket.bdaddr].name)}
	--]]
	local bdaddr = assert(connection_socket.remote_bdaddr)
	self.activities[connection_socket] = {status = "negotiating", bdaddr = bdaddr}
	connection_socket.parser_state = 1
	connection_socket.indicators = {}
	connection_socket.indicators_enum = {}
end

function app:handle_event_socket_data(socket, data_in)
	local data_out = {}

	if not data_in then
		self:log(socket, "got empty data")
		--table.insert(data_out, "OK")
	else
		--self:log(socket, string.format("got: %q",data_in))
		for line in string.gfind(data_in, "[^\r\n]+") do
			local state_transitions = self.parser_state_machine[socket.parser_state]
			if state_transitions then
				for i, transition in ipairs(state_transitions) do
				    if string.match(line, transition[1]) then
						-- next state
						if transition[2] then
							self:log(socket, "state " .. socket.parser_state .. " -> " .. transition[2])
							socket.parser_state = transition[2]
						end
						-- response string
						if transition[3] then
							table.insert(data_out, transition[3])
						end
						-- state handler
						if transition[4] then
							transition[4](self, socket, line)
						end
						break
				    end
				end
			end
		end
	end
	if #data_out > 0 then
		local response = table.concat(data_out)
		self:log(socket, "sending " .. response)
		socket:send(response)
	end
end

function app:handle_event_socket_connected(socket)
	log(socket.." connected")
	socket:send("AT+BRSF=4\r")
end

function app:handle_event_socket_disconnected(socket,prev_state)
	log("Socket "..socket.." disconnected")
	if not self.activities[socket] then
		error("Disconnect event received from unknown socket "..socket)
	end
	self.activities[socket].state = "disconnected" --Just to be sure if it's cached somewhere...
	self.activities[socket] = nil
end

function app:handle_event_socket_error(socket,error)
	error("Socket error "..socket..": "..error)
end

--[[
function app:call_answer(socket)
	socket:send("ATA\r")
end

function app:call_reject(socket)
	socket:send("AT+CHUP\r")
end
--]]

function app:activity_items()
	local items = {}
	for socket, act in pairs(self.activities) do
		local color = {0,255,0}
		if act.status ~= "connected" then
			color = {255,0,0}
		end
		local name = assert(dynawa.bluetooth_manager.prefs.devices[act.bdaddr].name)
		local item = {text = name.." ("..act.status..")", textcolor = color}
--[[		item.selected = function(_self,args)
			self:activity_menuitem_selected(_self,args)
		end]]
		table.insert(items,item)
	end
	table.sort(items, function(a,b)
		return (a.text < b.text)
	end)
	return items
end

function app:status_text()
	local n = 0
	for socket, act in pairs(self.activities) do
		if act.status == "connected" then
			n = n + 1
		end
	end
	return (n.." phones connected")
end

