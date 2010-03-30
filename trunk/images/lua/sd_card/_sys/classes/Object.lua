--Object

local class = Class("Object")

function class:_init()
end

function class:handle_event(ev)
	error("Unhandled event of type '"..tostring((ev or {}).type).."' in "..self)
end

return class

