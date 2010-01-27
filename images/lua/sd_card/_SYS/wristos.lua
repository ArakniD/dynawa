dynawa.version = {wristOS="0.1"}
package.loaded.dynawa = dynawa
--create the table for handling the lowest level incoming hardware events
local tbl={}
dynawa.event_vectors = tbl
tbl.button_down = function (event)
	dynawa.button_event(event)
end
tbl.button_up = tbl.button_down
tbl.button_hold = tbl.button_down

--DISPLAY init
dynawa.display={flipped=false}

--This table maps the 5 buttons from integers to strings, according to watch rotation
local buttons_flip = {
	[false]={[0]="TOP","MIDDLE","BOTTOM","SWITCH","CANCEL"},
	[true]={[0]="BOTTOM","MIDDLE","TOP","CANCEL","SWITCH"}
}

--Called immediately after any button event is received from system
function dynawa.button_event(event)
	local button=buttons_flip[dynawa.display.flipped][assert(event.button)]
	assert(button)
	log(event.type.." "..button)
end

dofile(dynawa.dir.sys.."scheduler.lua")

--This is the "real" main handler for incoming hardware events
_G.private_main_handler = function(event)
	local typ = assert(event.type, "Event has no type")
	local vector = assert(dynawa.event_vectors[typ])
	if vector then
		local result = vector(event)
		return result
	end
	log("Unknown event type: "..typ)
end

