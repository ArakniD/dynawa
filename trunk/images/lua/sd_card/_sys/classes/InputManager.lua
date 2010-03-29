--Handles raw input events for SuperMan
local Object = Class:get_by_name("Object")
local class = Class("InputManager",nil,Object)

function class:_init()
	Object._init(self)
	
	local EventSource = Class:get_by_name("EventSource")
	
	self.virtual_buttons = {}
	for i, name in ipairs{"top","confirm","bottom","switch","cancel"} do
		local v_button = EventSource(name)
		self.virtual_buttons[name] = v_button
	end
	
	self.actions = {}
	for i, name in ipairs{"switch","menu","superman"} do
		local action = EventSource(name)
		self.actions[name] = action
	end
	
	for button = 0, 4 do
		dynawa.tch.devices.buttons["button"..button].event_source:register_for_events(self)
	end

	self.buttons_flip = {
		[false]={[0]="top","confirm","bottom","switch","cancel"},
		[true]={[0]="bottom","confirm","top","cancel","switch"},
	}
end

function class:generate_action(act)
	assert(act)
	self.actions[act]:generate_event {type = "action", action = act}
end

function class:handle_event(event)
	local typ = assert(event.type)
	if typ == "button_up" or typ == "button_down" or typ == "button_hold" then
		local event2 = {type = "virtual_button", subtype = typ}
		event2.button_name = self.buttons_flip[dynawa.tch.devices.display.flipped][assert(event.button_number)]
		self.virtual_buttons[event2.button_name]:generate_event(event2)
		if typ == "button_down" then
			if event2.button_name == "cancel" then
				self:generate_action("menu")
			elseif event2.button_name == "switch" then
				self:generate_action("superman")
			end
		end
		-- #todo switch action
	else
		log("Event of type "..typ.." unhandled in "..self)
	end
end

Class:add_public(class)

return class

