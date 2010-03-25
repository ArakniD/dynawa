--Device

local Object = Class:get_by_name("Object")
local class = Class:_new("Device", {name = "unnamed"}, Object)

function class:_init(name)
	Object._init(self)
	assert(name,"Device must have a name")
	self.name = name
	getmetatable(self).__tostring = function(obj)
		return("[Device "..tostring(self.name).."]")
	end
end

Class:add_public(class)

return class
