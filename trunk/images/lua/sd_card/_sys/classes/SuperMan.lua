local Object = Class:get_by_name("Object")
local class = Class("SuperMan",nil,Object)

function class:start()
	--Input manager
	self.button_manager = Class:get_by_name("InputManager")()
end

Class:add_public(class)

return class

