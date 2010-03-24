--Initialize public classes

local function load_classes(classes)
	for i,classname in ipairs(classes) do
		local filename = dynawa.dir.sys.."classes/"..classname..".lua"
		dynawa.busy(i/#classes)
		local class = dofile(filename)
		assert(class, "Class file "..filename.." returned nothing")
		assert(class:_is_class(), "Class file "..filename.." did not return a class")
		--todo: Analyze classes & generate reports
	end
end

local function class_check()
	--Class
	assert(Class:_name() == "Class")
	assert(Class:_is_class())
	assert(Class:_class() == Class)

	--Object
	local Object = assert(Class:get_by_name("Object"))
	local object = Object:_new()

	assert(Object:_name() == "Object")
	assert(Object:_is_class())
	assert(#Object.__superclasses == 0)
	assert(Object:_class() == Class)

	assert(object:_class() == Object)
	assert(not object:_is_class())
	local stat,err = pcall(object._super,object)
	assert (err:match("This is an instance"))

	--assert(Object:tuk() == "forbidden") -- Jde zavolat, ale je to nesmysl
	----------------------------------------------

	local function check_list(list, check_list)
		if #list ~= #check_list then
		    return false
		end
		
		local t = {}
		for i, e in ipairs(list) do
		    t[e] = true
		end
		for i, e in ipairs(check_list) do
		    if not t[e] then
		        return false
		    end
		end
		return true
	end	
	
	local Bitmap = Class:_new("Bitmap", {typebitmap = "bitmap"}, Object)

	function Bitmap:is_bitmap()
		return true
	end

	function Bitmap:_init()
		self.bitmap_init = true
	end

	local bitmap = Bitmap:_new()
	assert(bitmap:is_bitmap())
	assert(type(bitmap.handle_event == "function"))
	----------------------------

	local AnotherBitmap = Class:_new("AnotherBitmap", {}, Bitmap)
	local anotherBitmap = AnotherBitmap:_new()

	assert(AnotherBitmap:_name() == "AnotherBitmap")
	assert(check_list(AnotherBitmap.__superclasses, {Bitmap}))
	assert(AnotherBitmap:_class() == Class)
	assert(check_list(anotherBitmap.__superclasses, {Bitmap}))
	assert(anotherBitmap:_class() == AnotherBitmap)
	----------------------------

	local YetAnotherBitmap = Class:_new("YetAnotherBitmap", nil, AnotherBitmap)

	local yetAnotherBitmap = YetAnotherBitmap:_new()
	----------------------------

	local Menu = Class:_new("Menu", nil, Object)

	function Menu:_init()
		self.menu_init = true
	end

	function Menu:is_menu()
		return true
	end

	----------------------------
	-- vicenasobna dedicnost (pomale ale potencialne mozne - http://www.lua.org/pil/16.3.html)
	local Mrdnik = Class:_new("Mrdnik", nil, Bitmap, Menu)

	local mrdnik = Mrdnik:_new()
	assert(check_list(Mrdnik.__superclasses, {Menu, Bitmap}))
	local mrdnikclass = assert(mrdnik:_class())
	assert(check_list((mrdnik:_class()).__superclasses, {Menu, Bitmap}))
	assert(mrdnik:is_bitmap())
	assert(mrdnik:is_menu())
	assert(type(mrdnik.handle_event == "function"))
	assert(mrdnik.bitmap_init)
	assert(mrdnik.menu_init)

	assert("X"..Class == "X[class Class]")
	assert("X"..Object == "X[class Object]")
	assert("X"..object == "X[Object instance]")
	assert("X"..Bitmap == "X[class Bitmap]")
	assert("X"..AnotherBitmap == "X[class AnotherBitmap]")
	assert("X"..Mrdnik == "X[class Mrdnik]")
	assert("X"..mrdnik == "X[Mrdnik instance]")
	Class:_delete(mrdnik)
	local Anonym = Class:_new(nil,nil, Bitmap)
	assert("X"..Anonym == "X[anonymous class]")
	assert("X"..(Anonym:_new()) == "X[anonymous class instance]")
end

load_classes{
	"Class",
	"Object"
}

if dynawa.debug then
	class_check()
end

