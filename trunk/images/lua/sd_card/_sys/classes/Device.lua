--Device

local Object = Class:get_by_name("Object")
local class = Class:_new("Device", {name = "unnamed"}, Object)

function class:_init(args)
	coroutine.yield()
	assert(args.name,"Device must have a name")
	self.name = args.name
end

function class:_tostring()
	return("[Device "..tostring(self.name).."]")
end

Class:add_public(class)

return class
