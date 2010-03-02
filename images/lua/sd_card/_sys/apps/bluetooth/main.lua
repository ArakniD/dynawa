require("dynawa")
require ("dynawa")

local jump = {}

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

local function got_message(message)
	log("Got BT message:")
	for k,v in pairs(message) do
		log(tostring(k).."="..tostring(v))
	end
end

my.app.name = "Bluetooth"
dynawa.message.receive {message = "bluetooth", callback = got_message}
dynawa.message.receive{message = "your_menu", callback = your_menu}
dynawa.message.receive{message = "menu_result", callback = menu_result}

