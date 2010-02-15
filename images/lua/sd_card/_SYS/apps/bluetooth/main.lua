require("dynawa")

my.globals.superman_menu = {
	{
		text = "BT on",
		callback = function()
			log("BT on")
			dynawa.bt.cmd(1)
			log("done")
		end
	},
	{
		text = "BT off",
		callback = function()
			log("BT off")
			dynawa.bt.cmd(2)
			log("done")
		end
	},
	{
		text = "Do something",
		callback = function()
			log("Did something!")
		end
	},
	{
		text = "Do something else",
		callback = function()
			log("Did something else!")
		end
	},
}

local function got_event(event)
	log("Got BT event:")
	for k,v in pairs(event) do
		log(tostring(k).."="..tostring(v))
	end
end

dynawa.event.receive {event = "bluetooth", callback = got_event}

