local class = Class("Accelerometer", Class.EventSource)

function class:_init()
	Class.EventSource._init(self,"accelerometer")
end

function class:handle_hw_event(event)
	--So far, there is only one accelerometer HW event, signalling "the state was changed"
	--self:broadcast_update()
    event.type = nil
    log ("-----Accelerometer HW event:")
    for k,v in pairs(event) do
        log (k.." = "..tostring(v))
    end
    log("-----------")
end

function class:status()
	local status = assert(dynawa.x.accel_stats(), "No accelerometer status")
	return status
end

function class:broadcast_update() --Broadcast the change
	local event = self:status()
	event.type = "accelerometer_status"
	self:generate_event(event)
end

return class

