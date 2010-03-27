--Device

local Object = Class:get_by_name("Object")
local class = Class("Device", {name = "unnamed"}, Object)

function class:_init(name)
	Object._init(self)
	assert(name,"Device must have a name")
	self.name = name
end

function class:__tostring()
	return("[Device "..tostring(self.name).."]")
end

Class:add_public(class)

return class
