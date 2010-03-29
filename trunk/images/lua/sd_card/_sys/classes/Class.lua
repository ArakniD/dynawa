--Class


local function tostring_default (self)
	local fn = rawget(self,"__tostring")
	if fn and fn ~= tostring_default and type(fn)=="function" then
		return tostring(fn(self))
	end
	if self:_is_class() then
		return "[class "..self:_name().."]"
	else --instance
		local name = self.name
		if not name and self.id then
			name = "#"..self.id
		end
		local clsname = assert(self:_class():_name())
		if name then
			return "["..name.." ("..clsname..")]"
		else
			return "[instance of "..clsname.."]"
		end
	end
end

local metatable0 = {
	__tostring = tostring_default,
	
	__concat = function (o1,o2)
		return (tostring(o1)..tostring(o2))
	end,
	
	__call = function (c, ...)
		return c:_new(...)
	end
}

local invalid_metatable = {
	__index = function (self)
		error("Attempt to access deleted object")
	end,
	__newindex = function (self)
		error("Attempt to modify deleted object")
	end,
}

rawset(_G,"Class", {
    __name = "Class",
})

local function add_metamethods(c)
	c.__index = c
	c.__tostring = metatable0.__tostring
	c.__concat = metatable0.__concat
	c.__call = metatable0.__call
end

add_metamethods(Class)

setmetatable(Class,metatable0)

function Class:_is_class()
	return not not rawget(self,"__index")
end

function Class:_super()
	assert(self:_is_class(),"_super() called on instance")
	if self == Class then
		return Class
	end
	return assert(getmetatable(self))
end

function Class:_class()
	if self:_is_class() then
		return Class
	else
		return assert(getmetatable(self))
	end
end

function Class:_name()
	assert(self:_is_class(),"_name() called on instance")
	return self.__name
end

function Class:_delete(o)
	assert(not o:_is_class(),"_delete() called on class")
	if o._del then
		o:_del()
	end
	o.__deleted = true
	setmetatable(o,invalid_metatable)
end

local public_classes = {}

function Class:add_public(class)
	assert(self == Class, "add_public() can only be called on _G.Class")
	local name = assert(class:_name())
	assert(name,"Public class must have a name")
	assert(not public_classes[name], "Class "..name.." is already registered as public")
	assert(class)
	public_classes[name] = class
end

function Class:get_by_name(name)
	assert(self == Class, "get_by_name() can only be called on _G.Class")
	return assert(public_classes[name])
end

local anonymous_class_number = 1

local function new_class (name, c, super)
	c = c or {}
	if not name then
		name = "AnonymousClass"..anonymous_class_number
		anonymous_class_number = anonymous_class_number + 1
	end
	c.__name = name
	assert(super ~= Class)
	super = super or Class
	assert(super:_is_class(),"Supplied superclass is not a class")
	
	add_metamethods(c)
	setmetatable(c,super)
	return c
end

local function new_instance (self, ...)
	local o = {}
	setmetatable(o, self)
	if self._init then
		self._init(o,...)
	end
	return o
end

function Class:_new (...)
	assert(self:_is_class(), "_new() can only be called on a class, not on an instance")
	if self == Class then
		return new_class(...)
	else
		return new_instance(self, ...)
	end
end

return Class
