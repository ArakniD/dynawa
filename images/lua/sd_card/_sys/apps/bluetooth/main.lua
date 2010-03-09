require("dynawa")
require ("dynawa")

local device_bdaddr = string.char(0x37, 0xb0, 0x87, 0xcc, 0x1f, 0x00) -- SGH-I780
local jump = {}

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

local function bdaddr2str(bdaddr)
    return string.format("%02x:%02x:%02x:%02x:%02x:%02x", string.byte(bdaddr, 1, -1))
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
    dynawa.bt.cmd(5, message.bdaddr)    -- sdp_search
end

local function got_message(message)
	log("Got BT message "..message.subtype)
    --[[
	for k,v in pairs(message) do
		log(tostring(k).."="..tostring(v))
	end
    --]]

    if message.subtype == 100 then -- 100: EVENT_BT_STARTED
		log("EVENT_BT_STARTED")

        local link_key = my.globals.prefs.devices[device_bdaddr]
        if link_key then
            dynawa.bt.cmd(3, device_bdaddr, link_key)
        end
        dynawa.bt.cmd(5, device_bdaddr)    -- sdp_search
        --dynawa.bt.cmd(4)      -- inquiry
    elseif message.subtype == 101 then -- 101: EVENT_BT_STOPPED
		log("EVENT_BT_STOPPED")
    elseif message.subtype == 110 then -- 110: EVENT_BT_LINK_KEY_NOT
		log("EVENT_BT_LINK_KEY_NOT")
        local bdaddr = message.bdaddr
        local link_key = message.link_key
		log("bdaddr " .. bdaddr2str(bdaddr))
        my.globals.prefs.devices[bdaddr] = link_key
        dynawa.file.save_data(my.globals.prefs)
    elseif message.subtype == 111 then -- 110: EVENT_BT_LINK_KEY_REQ
		log("EVENT_BT_LINK_KEY_REQ")
        local bdaddr = message.bdaddr
		log("bdaddr " .. bdaddr2str(bdaddr))
        local link_key = my.globals.prefs.devices[bdaddr]
        if link_key then
            dynawa.bt.cmd(3, bdaddr, link_key)
        end
    elseif message.subtype == 115 then -- 115: EVENT_BT_RFCOMM_CONNECTED
		log("EVENT_BT_RFCOMM_CONNECTED")
        local handle = message.handle
		log("handle " .. tostring(handle))
        mbw150_response_count = 1
        dynawa.bt.cmd(10, handle, "AT*SEAM=\"MBW-150\",13\r")
    elseif message.subtype == 116 then -- 116: EVENT_BT_RFCOMM_DISCONNECTED
		log("EVENT_BT_RFCOMM_DISCONNECTED")
        local handle = message.handle
		log("handle " .. tostring(handle))

        --dynawa.bt.cmd(5, device_bdaddr)    -- sdp_search
        dynawa.delayed_callback{time=10 * 1000, callback=reconnect, bdaddr=device_bdaddr}
    elseif message.subtype == 120 then -- 120: EVENT_BT_DATA
		log("EVENT_BT_DATA")
        local data = message.data
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
        dynawa.bt.cmd(10, message.handle, data)
    elseif message.subtype == 130 then -- 130: EVENT_BT_SDP_RES
		log("EVENT_BT_SDP_RES")
        local channel = message.channel
		log("channel " .. channel)
        if channel > 0 then
            local bdaddr = string.char(0x37, 0xb0, 0x87, 0xcc, 0x1f, 0x00)
            dynawa.bt.cmd(6, bdaddr, channel)
        end
    end
end

my.app.name = "Bluetooth"
dynawa.message.receive {message = "bluetooth", callback = got_message}
dynawa.message.receive{message = "your_menu", callback = your_menu}
dynawa.message.receive{message = "menu_result", callback = menu_result}
my.globals.prefs = dynawa.file.load_data() or {devices = {}}
