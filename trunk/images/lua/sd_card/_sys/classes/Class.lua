--Class

local metatable0 = {
	__tostring = function(self)
		if self._tostring then
			return self:_tostring()
		end
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

	__index = function (o, key)
		if rawget(o,"__superclasses") then --It's a class
			local mro = rawget(o,"__mro")
			if mro ~= "Class" then
				for i = 2, #mro do
					local val = rawget(mro[i],key)
					if val ~= nil then
						return val
					end
				end
			end
			return rawget(Class,key)
		else --It's an instance
			local class = o.__instance_class
			for i, class in ipairs (rawget(class,"__mro")) do
				local val = rawget(class,key)
				if val ~= nil then
					return val
				end
			end
			return rawget(Class, key)
		end
	end
}

local invalid_metatable = {
	__index = function (self)
		error("Attempt to access deleted object")
	end
}

rawset(_G,"Class", {
	__superclasses = {},
    __name = "Class",
    __mro = "Class",
})

--Class.__index = Class

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
		return assert(self.__instance_class)
	end
end

function Class:_name()
	assert(self:_is_class(),"This is an instance")
	return rawget(self,"__name")
end

function Class:_delete(o)
	assert(o,"Instance not specified")
	assert(not o:_is_class(),"This is not an instance")
	if o:_class() ~= self and self ~= Class then
		error("_delete("..o..") called on "..self)
	end
	--o:_del() -- #todo recursive
	o.__deleted = true
	setmetatable(o,invalid_metatable)
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

--[[local search_metatable = {								--THE ORIGINAL
	__index = function (class, key)
		for _, super in ipairs(class.__superclasses) do
			local val = super[key]
			if val then
				return val
			end
		end
	end
}]]

local search_metatable = {
	__index = function (class, key)
		for i, class in ipairs (class.__mro) do
			local val = rawget(class[key])
			if val ~= nil then
				return val
			end
		end
		return Class[key]
	end
}

if dynawa.debug then
	search_metatable.__tostring = metatable0.__tostring
	search_metatable.__concat = metatable0.__concat
end


local function mro_goodhead(item, lists)
	for i, list in ipairs(lists) do
		for j = 2, #list do
			if list[j] == item then
				return false
			end
		end
	end
	return true
end

local table_copy = function(tbl)
	local copy = {}
	for k,v in pairs(tbl) do
		copy[k] = v
	end
	return copy
end

local function mro(self)
	if rawget(self,"__mro") then
		return (rawget(self,"__mro"))
	end
	local result = {self}
	local supers = self.__superclasses
	if #supers == 0 then --supertrivial
		return result
	end
	if #supers == 11111111111 then --trivial ************************************** #todo
		result[2] = super[1]
		return result
	end
	--real work
	local lists = {}
	for _,super in ipairs(supers) do
		table.insert(lists,table_copy(assert(super.__mro)))
		--log("list ".._.." has "..#(super.__mro).." items from "..super)
	end
	table.insert(lists,table_copy(supers))
	while (#lists > 0) do
		local goodhead = nil
		for i, list in ipairs(lists) do
			--log("list "..i.." of "..#lists.." for "..self)
			if mro_goodhead(assert(list[1]), lists) then
				goodhead = list[1]
				break
			end
		end
		if not goodhead then
			return nil
		end
		table.insert(result, goodhead)
		for i = #lists, 1, -1 do
			local list = lists[i]
			if assert(list[1]) == goodhead then
				table.remove(list,1)
				if #list == 0 then
					local l1 = #lists
					table.remove(lists, i)
					local l2 = #lists
					--log(l1.." - "..l2)
				end
			end
		end
	end
	return result
end

local function new_class (name, c, ...)
	c = c or {}
	c.__name = name
	local supers = {...}
	--#todo check for duplicates in supers
	--#todo Class MUST NOT be explicitly declared as super
	c.__superclasses = supers

	if dynawa.debug then
		c.__tostring = metatable0.__tostring
		c.__concat = metatable0.__concat
	end

	c.__mro = mro(c)
	if not c.__mro then
		error("Class inheritance is ambiguous (MRO cannot resolve, see http://www.python.org/download/releases/2.3/mro/ )")
	end
	
	setmetatable(c,metatable0)
	--[[
	log ("MRO for "..c..":")
	for _, class in ipairs(c.__mro) do
		log("   "..class)
	end
	]]
	return c
end

local function recursive_init(o,c,args)
	local coroutines = {}
	for i, class in ipairs(c.__mro) do
		if rawget(class,"_init") then
			local cor = coroutine.create(function () class._init(o,args) end)
			assert(coroutine.resume(cor))
			assert(coroutine.status(cor)=="suspended","_init() of "..class.." did not yield")
			table.insert(coroutines,cor)
		end
	end
	if #coroutines > 0 then
		--log(#coroutines.." cors to resume for new "..c.__name)
		for i = #coroutines,1,-1 do
			local cor = coroutines[i]
			assert(coroutine.resume(cor))
			assert(coroutine.status(cor)=="dead","_init() did not finish (yielded for 2nd time?)")
		end
	end
end

local function new_instance (self, args)
	args = args or {}
	local o = {__instance_class = self}
	setmetatable(o, metatable0)
    recursive_init(o,self,args)
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
