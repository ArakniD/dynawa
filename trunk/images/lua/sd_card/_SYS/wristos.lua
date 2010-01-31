dynawa.version = {wristOS="0.1"}
package.loaded.dynawa = dynawa

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
		log("Timer "..handle.." should fire but its vector is unknown")
		log("known vectors:")
		for k,v in pairs(dynawa.hardware_vectors) do
			log("id:"..tostring(k))
		end
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
	dynawa.event.send {type=event.type,button=button}
end

-- Handle all events in queue, including those new events that are generated during the handling of the original events!
local function dispatch_queue()
	local queue = assert(dynawa.event.queue)
	local listeners = assert(dynawa.event.listeners)
	local sanity = 999
	while #queue > 0 do
		sanity = sanity - 1
		assert(sanity>0,"Unable to purge event queue, probably infinite loop")
		local event=table.remove(queue,1)
		--log("QUEUE: Dispatching event of type "..tostring(event.type))
		local typ=event.type
		if typ and listeners[typ] then
			for task, params in pairs(listeners[typ]) do
				rawset(_G,"my",task)
				params.callback(event)
				rawset(_G,"my",nil)
			end
		else --event doesn't have type, must have "callback" and "task"
			assert (event.callback,"Event doesn't have callback specified")
			assert (event.task,"Event doesn't have task specified")
			rawset(_G,"my",event.task)
			event.callback(event)
			rawset(_G,"my",nil)			
		end
	end
end

--This is the "real" main handler for incoming hardware events
_G.private_main_handler = function(event)
	local typ = assert(event.type, "Event has no type")
	local vector = assert(dynawa.event_vectors[typ],"Unknown hardware event type: "..tostring(typ))
	if vector then
		local result = vector(event) --handle the conversion of incoming raw event to Lua event
	else
		log("Unknown event type: "..typ)
	end
	dispatch_queue()
end

dynawa.app.start("/_sys/apps/core/")

--Discard boot animation script and bitmaps
boot_anim()
_G.boot_anim = nil
	

