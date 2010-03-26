--EventSource

local Object = Class:get_by_name("Object")

local class = Class:_new("EventSource",nil,Object)

function class:_init()
	coroutine.yield()
	self._event_listeners = {}
end

function class:generate_event(event)
	assert(type(event)=="table")
	for object, filter in pairs(self._event_listeners) do
		if (filter == true) or (filter(event)) then
			event.source = self
			listener.object:handle_event(event)
		end
	end
end

function class:is_listener(object)
	assert(object)
	return not not self._event_listeners[object]
end

function class:register_for_events(object,filter)
	assert(not self._event_listeners[object], "This object is already my listener")
	self._event_listeners[object] = filter or true
end

function class:unregister_for_events(object)
	assert(self._event_listeners[object], "This object is not my listener")
	self._event_listeners[object] = nil
end

Class:add_public(class)

return class

