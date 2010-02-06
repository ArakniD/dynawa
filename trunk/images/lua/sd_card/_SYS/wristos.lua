dynawa.version = {wristOS="0.1"}
package.loaded.dynawa = dynawa

local _unique_id_number = 0
dynawa.unique_id = function()
	_unique_id_number = _unique_id_number + 1
	return _unique_id_number
end

--Start boot animation
dofile(dynawa.dir.sys.."boot_anim/boot_anim.lua")	

--create the table for handling the lowest level incoming hardware events
-----------------------------------------------------------
-----------------------------------------------------------
local tbl={}
dynawa.event_vectors = tbl
tbl.button_down = function (event)
	dynawa.button_event(event)
end
tbl.button_up = tbl.button_down
tbl.button_hold = tbl.button_down
tbl.timer_fired = function (event)
	local handle = assert(event.handle,"HW event of type timer_fired has no handle")
	local event = dynawa.hardware_vectors[handle]
	if not event then
		log("Timer "..tostring(handle).." should fire but its vector is unknown")
		--[[log("known vectors:")
		for k,v in pairs(dynawa.hardware_vectors) do
			log("id:"..tostring(k))
		end]]
	else
		if not event.autorepeat then
			dynawa.hardware_vectors[handle] = nil
		end
		dynawa.event.send(event)
	end
end

tbl=nil
-----------------------------------------------------------
-----------------------------------------------------------

--DISPLAY + BITMAP init
dofile(dynawa.dir.sys.."bitmap.lua")

--SCHEDULER (apps + tasks + events) init
dofile(dynawa.dir.sys.."scheduler.lua")

--This table maps the 5 buttons from integers to strings, according to watch rotation
local buttons_flip = {
	[false]={[0]="TOP","CONFIRM","BOTTOM","SWITCH","CANCEL"},
	[true]={[0]="BOTTOM","CONFIRM","TOP","CANCEL","SWITCH"}
}

--Called immediately after any button event is received from system
function dynawa.button_event(event)
	local button=buttons_flip[dynawa.display.flipped][assert(event.button)]
	assert(button)
	local receiver = dynawa.app.in_front
	dynawa.event.send {type=event.type, button = button, receiver=receiver} --Send to app in front
	dynawa.event.send {type=event.type, button = button, receiver=assert(dynawa.apps["/_sys/apps/core/"])} --Send to core app
end

-- Handle all events in queue, including those new events that are generated during the handling of the original events!
local function dispatch_queue()
	--[[if _G.my then
		log("_G.my is ".._G.my.id)
	else
		log("_G.my is nil")
	end]]

	local queue = assert(dynawa.event.queue)
	local sanity = 999
	assert(not _G.my,"There should be no active task at the start of dispatch_queue()")
	while #queue > 0 do
		sanity = sanity - 1
		assert(sanity>0,"Unable to purge event queue - probably infinite loop")
		local event=table.remove(queue,1)
		dynawa.event.dispatch(event)
	end
end

--This is the "real" main handler for incoming hardware events
_G.private_main_handler = function(event)
	--rawset(_G,"my",nil) --At this time it already should be nil in ANY non-error status
	local previous_display = (dynawa.app.in_front or {}).screen
	dynawa._app_switched = nil
	local typ = assert(event.type, "Event has no type")
	local vector = assert(dynawa.event_vectors[typ],"Unknown hardware event type: "..tostring(typ))
	if vector then
		local result = vector(event) --handle the conversion of incoming raw event to Lua event
	else
		log("Unknown event type: "..typ)
	end
	dispatch_queue()
	local new_display = (dynawa.app.in_front or {}).screen
	--log("new_d="..tostring(new_display).." prev="..tostring(previous_display))
	if new_display ~= previous_display then
		dynawa.bitmap.show(new_display,dynawa.display.flipped)
	end
end

dynawa.app.start("/_sys/apps/core/")

--Discard boot animation script and bitmaps
_G.boot_anim = nil
	

