app.name = "HandsFree BT"
app.id = "dynawa.hf"

local SDP = Class.BluetoothSocket.SDP

local service = {
    {
        SDP.UINT16(0x0000), -- Service record handle attribute
        SDP.UINT32(0x00000000)
    },
    {
        SDP.UINT16(0x0001), -- Service class ID list attribute
        {
            SDP.UUID16(0x111e) -- Handsfree
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
        SDP.UINT16(0x0005), -- Browse group list
        {
            SDP.UUID16(0x1002) -- PublicBrowseGroup
        }
    }
}

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
        --{"CCLK", 14, nil, nil},
        {"CCLK", 14, nil, 
            function(socket, data)
                -- example: +CCLK: "2010/03/11,23:45:14+00"
                local year, month, day, hour, min, sec = string.match(data, "CCLK: \"(%d+)/(%d+)/(%d+),(%d+):(%d+):(%d+)")
                local time = os.time({["year"]=year, ["month"]=month, ["day"]=day, ["hour"]=hour, ["min"]=min, ["sec"]=sec})
                log("time " .. time)
                dynawa.time.set(time)
            end 
        },
    },
    --{ "X", "AT+CHUP" },
}

function app:log(socket, msg)
    log(msg)
end

function app:start()
	self.activities = {}
	self.socket = nil
	self.num_activities = 0

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
end

function app:handle_bt_event_turned_on()
	self:server_start()
end

function app:handle_bt_event_turning_off()
	self:server_stop()
end

function app:handle_event_socket_connection_accepted(socket, connection_socket)
	log(socket.." connection accepted " .. connection_socket)
	self.num_activities = self.num_activities + 1

    connection_socket.parser_state = 1
end

function app:handle_event_socket_data(socket, data_in)
    local data_out

    if not data_in then
        self:log(socket, "got empty data")
        --data_out = "OK"
    else
        self:log(socket, "got " .. data_in)
        local state_transitions = self.parser_state_machine[socket.parser_state]
        if state_transitions then
            for i, transition in ipairs(state_transitions) do
                if string.match(data_in, transition[1]) then
                    -- next state
                    if transition[2] then
                        self:log(socket, "state " .. socket.parser_state .. " -> " .. transition[2])
                        socket.parser_state = transition[2]
                    end
                    -- response string
                    if transition[3] then
                        data_out = transition[3]
                    end
                    -- state handler
                    if transition[4] then
                        transition[4](socket, data_in)
                    end
                    break
                end
            end
        end
    end
    if data_out then
        self:log(socket, "sending " .. data_out)
        socket:send(data_out)
    end
end

function app:handle_event_socket_connected(socket)
    log(socket.." connected")
    socket:send("AT+BRSF=4\r")
end

function app:handle_event_socket_disconnected(socket,prev_state)
	self.num_activities = self.num_activities - 1
end

function app:handle_event_socket_error(socket,error)
end

function app:status_text()
	return self.num_activities
end
