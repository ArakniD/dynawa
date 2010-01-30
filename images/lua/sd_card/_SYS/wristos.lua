dynawa.version = {wristOS="0.1"}
package.loaded.dynawa = dynawa

--Start boot animation
dofile(dynawa.dir.sys.."boot_anim/boot_anim.lua")	

--create the table for handling the lowest level incoming hardware events
local tbl={}
dynawa.event_vectors = tbl
tbl.button_down = function (event)
	dynawa.button_event(event)
end
tbl.button_up = tbl.button_down
tbl.button_hold = tbl.button_down

--DISPLAY + BITMAP init
dofile(dynawa.dir.sys.."bitmap.lua")

--SCHEDULER (apps + tasks + events) init
dofile(dynawa.dir.sys.."scheduler.lua")

--This table maps the 5 buttons from integers to strings, according to watch rotation
local buttons_flip = {
	[false]={[0]="TOP","MIDDLE","BOTTOM","SWITCH","CANCEL"},
	[true]={[0]="BOTTOM","MIDDLE","TOP","CANCEL","SWITCH"}
}

--Called immediately after any button event is received from system
function dynawa.button_event(event)
	local button=buttons_flip[dynawa.display.flipped][assert(event.button)]
	assert(button)
	dynawa.event.send {type=event.type,button=button}
end

local function dispatch_queue()
	local queue = assert(dynawa.event.queue)
	local listeners = assert(dynawa.event.listeners)
	local sanity = 999
	while #queue > 0 do
		sanity = sanity - 1
		assert(sanity>0,"Unable to uprge event queue, probably infinite loop")
		local event=table.remove(queue,1)
		--log("QUEUE: Dispatching event "..event.type)
		local typ=assert(event.type)
		if listeners[typ] then
			for task, params in pairs(listeners[typ]) do
				rawset(_G,"my",task)
				params.callback(event)
				rawset(_G,"my",nil)
			end
		end
	end
end

--This is the "real" main handler for incoming hardware events
_G.private_main_handler = function(event)
	local typ = assert(event.type, "Event has no type")
	local vector = assert(dynawa.event_vectors[typ])
	if vector then
		local result = vector(event) --handle the conversion of incoming raw event to Lua event
	else
		log("Unknown event type: "..typ)
	end
	dispatch_queue()
end

dynawa.app.start("/_sys/apps/core/")

--Discard boot animation script
_G.boot_anim = nil
	

