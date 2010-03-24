--Class

local metatable0 = {
	__tostring = function(self)
		if self:_is_class() then
			local name = self:_name()
			if not name then
				return "[anonymous class]"
			else
				return "[class "..name.."]"
			end
		else --instance
			return ("["..(self:_class():_name() or "anonymous class").." instance]")
		end
	end,

	__concat = function (o1,o2)
		return (tostring(o1)..tostring(o2))
	end,
}

rawset(_G,"Class", {
	__superclasses = {},
    __name = "Class",
})

metatable0.__index = metatable0
Class.__index = Class
if dynawa.debug then
	Class.__concat = metatable0.__concat
	Class.__tostring = metatable0.__tostring
end
setmetatable(Class,metatable0)

function Class:_is_class()
	return not not rawget(self,"__superclasses")
end

function Class:_super()
	return assert(rawget(self,"__superclasses"),"This is an instance")
end

function Class:_class()
	if self:_is_class() then
		return Class
	else
		return getmetatable(self)
	end
end

function Class:_name()
	assert(self:_is_class(),"This is an instance")
	return rawget(self,"__name")
end

local function recursive_call_cleanup(supers, o)
	for _, super in ipairs(supers) do
		local func = rawget(super,"_cleanup")
		if func then
			log("Calling cleanup in "..super)
			func(o)
		end
		recursive_call_cleanup(super.__superclasses, o)
	end
end

local function recursive_call_init(supers, o)
	for _, super in ipairs(supers) do
		local func = rawget(super,"_init")
		recursive_call_init(super.__superclasses, o)
		if func then
			log("Calling init in "..super)
			func(o)
		end
	end
end

function Class:_delete(o)
	assert(o,"Instance not specified")
	assert(not o:_is_class(),"This is not an instance")
	if o:_class() ~= self and self ~= Class then
		error("_delete("..o..") called on "..self)
	end
	recursive_call_cleanup(self:_super(), o)
	--#todo invalidate object
end

function Class:_new()

end

local public_classes = {}

function Class:add_public(class)
	assert(self == Class)
	local name = class:_name()
	assert(name,"Public class must have a name")
	assert(not public_classes[name], "Class "..name.." is already registered as public")
	assert(class)
	public_classes[name] = class
end

function Class:get_by_name(name)
	assert(self == Class)
	return public_classes[assert(name)]
end

local search_metatable = {
	__index = function (class, key)
		for _, super in ipairs(class.__superclasses) do
			local val = super[key]
			if val then
				return val
			end
		end
	end
}

if dynawa.debug then
		search_metatable.__tostring = metatable0.__tostring
		search_metatable.__concat = metatable0.__concat
end

local function new_class (name, c, ...)
    c = c or {}
   	c.__name = name
    local supers = {...}
    c.__superclasses = supers
	c.__index = c
    if #supers == 0 then
    	setmetatable(c,Class)
    elseif #supers == 1 then
    	setmetatable(c,supers[1])
    else
    	setmetatable(c,search_metatable)
    end
    if dynawa.debug then
		c.__tostring = metatable0.__tostring
		c.__concat = metatable0.__concat
	end
    return c
end

local function new_instance (self, o, bad)
	assert(not bad, "Extraneous argument(s) while creating instance")
	local o = o or {}
	setmetatable(o, self)
    recursive_call_init({self},o)
	return o
end


function Class:_new (...)
	assert(self:_is_class(), "This is an instance")
    if self == Class then
        return new_class(...)
    else
        return new_instance(self, ...)
    end
end

return Class

