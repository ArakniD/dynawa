dynawa.version = {wristOS="0.6", settings_revision = 20100419.1}

dynawa.dofile = function(...)
	dynawa.busy()
	return dofile(...)
end

local busy_count = assert(dynawa.bitmap.from_png_file(dynawa.dir.sys.."busy_anim.png"),"Cannot load busy animation")
local busy_bitmaps = {}
local busy_last = 0
for i = 0,3 do
	busy_bitmaps[i] = dynawa.bitmap.copy(busy_count,0,32*i,54,32)
end
busy_count = 0
dynawa.busy = function(percentage) --todo: Rewrite!
	local ticks = dynawa.ticks()
	if ticks - busy_last > 200 then
		dynawa.is_busy = true
		busy_count = (busy_count + 1) % 4
		busy_last = ticks
		--start + 4, wide 46, high 8
		dynawa.bitmap.show_partial(busy_bitmaps[busy_count],nil,nil,nil,nil,53,48)	
		if percentage then
			local prog1 = math.floor(percentage * 46)
			if prog1 == 0 then
				prog1 = 1
			end
			dynawa.bitmap.show_partial(dynawa.bitmap.new(prog1,8,0,255,0),nil,nil,nil,nil,57,69)
		end
	end
end

local _unique_id = 0
dynawa.unique_id = function()
	_unique_id = _unique_id + 1
	return (":".._unique_id)
end

--FILE + serialization + global settings init
dynawa.dofile(dynawa.dir.sys.."file.lua")

dynawa.settings = dynawa.file.load_data(dynawa.dir.sys.."settings.data")
if not dynawa.settings or dynawa.settings.revision < dynawa.version.settings_revision then
	dynawa.settings = {
		revision = dynawa.version.settings_revision,
		default_font = "/_sys/fonts/default10.png",
		autostart = {"/_sys/apps/clock/clock_app.lua"},
		switchable = {"dynawa.clock","dynawa.bluetooth"},
		superman = {
			shortcuts = {},
		},
	}
	dynawa.file.save_settings()
end

--DISPLAY + BITMAP init
dynawa.dofile(dynawa.dir.sys.."bitmap.lua")

--Classes
dynawa.dofile(dynawa.dir.sys.."classes/init.lua")

dynawa.devices = {}
--#todo DeviceNodes
dynawa.devices.buttons = Class.Buttons()
dynawa.devices.display = {size = {w = 160, h = 128}, flipped = false}

dynawa.devices.timers = Class.Timers()

dynawa.app_manager = Class.AppManager()

local hw_vectors = {}
hw_vectors.button_down = function(event)
	dynawa.devices.buttons.raw:generate_event(event)
end

hw_vectors.button_up = hw_vectors.button_down

hw_vectors.button_hold = hw_vectors.button_down

hw_vectors.timer_fired = function (message)
	local handle = assert(message.handle,"HW message of type timer_fired has no handle")
	dynawa.devices.timers:dispatch_timed_event(handle)
end

_G.private_main_handler = function(hw_event)
	--log(tostring(hw_event.type))

	local handler = hw_vectors[hw_event.type]
	if handler then
		handler(hw_event)
	else
		log("No handler found for hw event '"..hw_event.type.."', ignored")
	end
	dynawa.window_manager:update_display()
end

dynawa.app_manager:start_everything()

--[[

--create the table for handling the lowest level incoming hardware messages
-----------------------------------------------------------
-----------------------------------------------------------
local tbl={}
dynawa.message_vectors = tbl
tbl.button_down = function (message)
	dynawa.button_message(message)
end

tbl.button_up = tbl.button_down

tbl.button_hold = tbl.button_down

tbl.timer_fired = function (message)
	local handle = assert(message.handle,"HW message of type timer_fired has no handle")
	local message = dynawa.hardware_vectors[handle]
	if not message then
		log("Timer "..tostring(handle).." should fire but its vector is unknown")
	else
		assert(message.hardware == "timer")
		if not message.autorepeat then
			dynawa.hardware_vectors[handle] = nil
		end
		message.sender = nil
		dynawa.message.send(message)
	end
end

tbl.bluetooth = function (message)
	message.receiver = dynawa.apps["/_sys/apps/bluetooth/"]
	dynawa.message.send(message)
end

tbl=nil
--]]


