dynawa.version = {wristOS="0.1", settings_revision = 20100303}
package.loaded.dynawa = dynawa

local uid_last, uid_chars = {}, {}
string.gsub("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz","(.)", function(ch)
	table.insert(uid_chars,ch)
end)

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
	dynawa.is_busy = true
	local ticks = dynawa.ticks()
	if ticks - busy_last > 200 then
		busy_count = (busy_count + 1) % 4
		busy_last = ticks
	end
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

dynawa.unique_id = function(num)
	num=num or 1
	local nums=uid_last
	local chars=uid_chars
	if not nums[num] then
		nums[num]=1
	else
		nums[num]=nums[num]+1
		if not chars[nums[num]] then
			nums[num]=1
			return dynawa.unique_id(num+1)
		end
	end
	local result = {}
	for i,num in ipairs(nums) do 
		table.insert(result,assert(chars[num]))
	end
	return table.concat(result)
end

--FILE + serialization + global settings init
dynawa.dofile(dynawa.dir.sys.."file.lua")

dynawa.settings = dynawa.file.load_data(dynawa.dir.sys.."settings.data")
if not dynawa.settings or dynawa.settings.revision < dynawa.version.settings_revision then
	dynawa.settings = {
		revision = dynawa.version.settings_revision,
		default_font = "/_sys/fonts/default10.png",
		autostart = {},
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

local hw_vectors = {}
hw_vectors.button_down = function(event)
	dynawa.tch.devices.buttons["button"..event.button]:handle_event(event)
end

hw_vectors.button_up = hw_vectors.button_down

hw_vectors.button_hold = hw_vectors.button_down

_G.private_main_handler = function(hw_event)
	--log(tostring(hw_event.type))
	local handler = hw_vectors[hw_event.type]
	if handler then
		handler(hw_event)
	else
		log("No handler found for hw event "..hw_event.type..", ignored")
	end
end

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
-----------------------------------------------------------
-----------------------------------------------------------



--SCHEDULER (apps + tasks + messages) init
dynawa.dofile(dynawa.dir.sys.."scheduler.lua")

--This table maps the 5 buttons from integers to strings, according to watch rotation
local buttons_flip = {
	[false]={[0]="TOP","CONFIRM","BOTTOM","SWITCH","CANCEL"},
	[true]={[0]="BOTTOM","CONFIRM","TOP","CANCEL","SWITCH"}
}

--Called immediately after any button message is received from system
function dynawa.button_message(message)
	local button=buttons_flip[dynawa.display.flipped][assert(message.button)]
	assert(button)
	local receiver = dynawa.app.in_front
	dynawa.message.send {type=message.type, button = button, receiver=receiver} --Send to app in front
	dynawa.message.send {type=message.type, button = button, receiver=assert(dynawa.apps["/_sys/apps/core/"])} --Send to core app
end

-- Handle all messages in queue, including those new messages that are generated during the handling of the original messages!
local function dispatch_queue()
	local queue = assert(dynawa.message.queue)
	local sanity = 999
	assert(not _G.my,"There should be no active task at the start of dispatch_queue()")
	while #queue > 0 do
		sanity = sanity - 1
		assert(sanity>0,"Unable to purge message queue - probably infinite loop")
		local message=table.remove(queue,1)
		dynawa.message.dispatch(message)
	end
end

--This is the "real" main handler for incoming hardware messages
_G.private_main_handler = function(message)
	--rawset(_G,"my",nil) --At this time it already should be nil in ANY non-error state
	local typ = assert(message.type, "Message has no type")
	local vector = assert(dynawa.message_vectors[typ],"Unknown hardware message type: "..tostring(typ))
	if vector then
		local result = vector(message) --handle the conversion of incoming raw message to Lua message
	else
		log("Unknown message type: "..typ)
	end
	dispatch_queue()
	local app = dynawa.app.in_front
	if not app then --No app in front
		return
	end
	assert(app.screen, "App in front ("..app.name..") has no display")
	if app.screen_updates.full or dynawa.is_busy then
		--log("Updating full screen of "..app.name)
		dynawa.is_busy = nil
		dynawa.bitmap.show(app.screen,dynawa.display.flipped)
	else
		for i, params in ipairs(app.screen_updates) do
			--log("Partial render: "..table.concat(params,","))
			dynawa.bitmap.show_partial(app.screen,params[1],params[2],params[3],params[4],params[1],params[2],dynawa.display.flipped)
		end
		--dynawa.bitmap.show(app.screen,dynawa.display.flipped) --REMOVE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	end
	app.screen_updates = {pixels = 0}
end

dynawa.app.start("/_sys/apps/core/")]]

