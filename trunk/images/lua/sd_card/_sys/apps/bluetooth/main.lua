require("dynawa")
require ("dynawa")

local device_bdaddr = string.char(0x37, 0xb0, 0x87, 0xcc, 0x1f, 0x00) -- SGH-I780
local jump = {}

local request_count = 1

local mbw150_response_count
local mbw150_request = {
    "AT*SEAUDIO=0,0\r",
    "AT+CIND=?\r",
    "AT+CIND?\r",
    "AT+CMER=3,0,0,1\r",
    "AT+CCWA=1\r",
    "AT+CLIP=1\r",
    "AT+GCLIP=1\r",
    "AT+CSCS=\"UTF-8\"\r",
    "AT*SEMMIR=2\r",
    "AT*SEVOL?\r",
    "ATE0\r",
    "AT+CCLK?\r",
    --"AT+CHUP",
}

local cmd = {
    SET_LINK_KEY = 3,
    INQUIRY = 4,
    SOCKET_NEW = 100,
    SDP_SEARCH = 200,
    LISTEN = 300,
    CONNECT = 301,
    SEND = 400,
}

local event = {
    BT_STARTED = 100,
    BT_STOPPED = 101,
    BT_LINK_KEY_NOT = 110,
    BT_LINK_KEY_REQ = 111,
    BT_RFCOMM_CONNECTED = 115,
    BT_RFCOMM_DISCONNECTED = 116,
    BT_DATA = 120,
    BT_SDP_RES = 130,
}

local function bdaddr2str(bdaddr)
    return string.format("%02x:%02x:%02x:%02x:%02x:%02x", string.byte(bdaddr, 1, -1))
end

-- Socket class
local bt_socket = {
    -- constants
    -- socket protocol
    PROTO_HCI = 1,
    PROTO_L2CAP = 2,
    PROTO_SDP = 3,
    PROTO_RFCOMM = 4,

    -- socket state
    INITIALIZED = 1,

    -- (static) constructor
    new = function() 
        socket = {
            listen = function()
            end,
            connect = function()
            end,
            close = function()
            end,
            state = bt.socket.INITIALIZED,
        }
        socket.handle = dynawa.bt.cmd(cmd.SOCKET_NEW, socket)    -- allocate socket mem
        return socket 
    end,
}

local function find_service()
    local socket = bt_socket.new(bt_socket.PROTO_SDP)
 
    dynawa.bt.cmd(cmd.SDP_SEARCH, socket, message.bdaddr)    -- sdp_search
end

local menu_result = function(message)
	local val = assert(message.value)
	assert(val.jump,"Menu item value has no 'jump'")
	--log("Jump: "..val.jump)
	jump[val.jump](val)
end

local your_menu = function(message)
	local menu = {
		banner = "Bluetooth debug menu",
		items = {
			{
				text = "BT on", value = {jump = "btcmd", command = 1},
			},
			{
				text = "BT off", value = {jump = "btcmd", command = 2},
			},
			{
				text = "Pairing", value = {jump = "pairing"},
			},
			{
				text = "Something else", value = {jump = "something_else"},
			},
		},
	}
	return menu
end

jump.btcmd = function(args)
	log("Doing bt.cmd "..args.command)
	dynawa.bt.cmd(args.command)
	log("Done")
end

jump.pairing = function(args)
	log("NOT doing pairing...")
end

jump.something_else = function(args)
	log("NOT doing something else")
end

local function reconnect(message)
    dynawa.bt.cmd(cmd.SDP_SEARCH, new_request(), message.bdaddr)    -- sdp_search
end

local function new_request()
    local request = {id = request_count}
    request_count = request_count + 1
    return request 
end

local function got_message(message)
	log("Got BT message "..message.subtype)
    --[[
	for k,v in pairs(message) do
		log(tostring(k).."="..tostring(v))
	end
    --]]

    if message.subtype == event.BT_STARTED then -- 100: EVENT_BT_STARTED
		log("EVENT_BT_STARTED")

        local link_key = my.globals.prefs.devices[device_bdaddr]
        if link_key then
            dynawa.bt.cmd(cmd.SET_LINK_KEY, device_bdaddr, link_key)
        end
        dynawa.bt.cmd(cmd.SDP_SEARCH, new_request, device_bdaddr)    -- sdp_search
        --dynawa.bt.cmd(cmd.INQUIRY)      -- inquiry
    elseif message.subtype == event.BT_STOPPED then
		log("EVENT_BT_STOPPED")
    elseif message.subtype == event.BT_LINK_KEY_NOT then
		log("EVENT_BT_LINK_KEY_NOT")
        local bdaddr = message.bdaddr
        local link_key = message.link_key
		log("bdaddr " .. bdaddr2str(bdaddr))
        my.globals.prefs.devices[bdaddr] = link_key
        dynawa.file.save_data(my.globals.prefs)
    elseif message.subtype == event.BT_LINK_KEY_REQ then
		log("EVENT_BT_LINK_KEY_REQ")
        local bdaddr = message.bdaddr
		log("bdaddr " .. bdaddr2str(bdaddr))
        local link_key = my.globals.prefs.devices[bdaddr]
        if link_key then
            dynawa.bt.cmd(cmd.SET_LINK_KEY, bdaddr, link_key)
        end
    elseif message.subtype == event.BT_RFCOMM_CONNECTED then
		log("EVENT_BT_RFCOMM_CONNECTED")
        local request = message.request
        local handle = message.handle
		log("request " .. request.id)
		log("handle " .. tostring(handle))
        mbw150_response_count = 1
        dynawa.bt.cmd(cmd.RFCOMM_SEND, new_request(), handle, "AT*SEAM=\"MBW-150\",13\r")
    elseif message.subtype == event.BT_RFCOMM_DISCONNECTED then
		log("EVENT_BT_RFCOMM_DISCONNECTED")
        local request = message.request
        local handle = message.handle
		log("request " .. request.id)
		log("handle " .. tostring(handle))

        dynawa.delayed_callback{time=10 * 1000, callback=reconnect, bdaddr=device_bdaddr}
    elseif message.subtype == event.BT_DATA then
		log("EVENT_BT_DATA")
        local request = message.request
        local data = message.data
		log("request " .. request.id)
        if not data then
		    log("empty data")
            data = "OK"
        else
            log(data)
            if string.sub(data, -4) == "OK\r\n" then
                local request = mbw150_request[mbw150_response_count]
                if request then
                    data = request
                    mbw150_response_count = mbw150_response_count + 1
                end
            end
        end
        log(data)
        dynawa.bt.cmd(cmd.RFCOMM_SEND, new_request(), message.handle, data)
    elseif message.subtype == event.BT_SDP_RES then
		log("EVENT_BT_SDP_RES")
        local request = message.request
        local channel = message.channel
		log("request " .. request.id)
		log("channel " .. channel)
        if channel > 0 then
            local bdaddr = string.char(0x37, 0xb0, 0x87, 0xcc, 0x1f, 0x00)
            dynawa.bt.cmd(cmd.RFCOMM_CONNECT, new_request(), bdaddr, channel)
        end
    end
end

my.app.name = "Bluetooth"
dynawa.message.receive {message = "bluetooth", callback = got_message}
dynawa.message.receive{message = "your_menu", callback = your_menu}
dynawa.message.receive{message = "menu_result", callback = menu_result}
my.globals.prefs = dynawa.file.load_data() or {devices = {}}
