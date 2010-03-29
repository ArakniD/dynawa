--Initialize public classes

local function load_classes(classes)
	for i,classname in ipairs(classes) do
		local filename = dynawa.dir.sys.."classes/"..classname..".lua"
		dynawa.busy(i/#classes)
		log("Compiling class "..classname.."...")
		local class = dofile(filename)
		assert(class, "Class file "..filename.." returned nothing")
		assert(class:_is_class(), "Class file "..filename.." did not return a class")
		assert(class:_name() == classname)
		if dynawa.debug and dynawa.debug.pc_classinfo then
			dynawa.debug.pc_classinfo(class)
		end
	end
end

local function tch_init()
	dynawa.tch.devices = {}
	--#todo DeviceNodes
	dynawa.tch.devices.buttons = {}
	local DeviceButton = Class:get_by_name("DeviceButton")
	dynawa.tch.button_manager = Class:get_by_name("ButtonManager")()
	for i = 0, 4 do
		local button = DeviceButton(i)
		dynawa.tch.devices.buttons[button.name] = button
		button.event_source:register_for_events(dynawa.tch.button_manager)
	end
	dynawa.tch.devices.display = {width = 160, height = 128, flipped = false}
end

local function class_check()
	--Class
	assert(Class:_name() == "Class")
	assert(Class:_is_class())
	assert(Class:_class() == Class)

	--Object
	local Object = assert(Class:get_by_name("Object"))
	local object = Object()

	assert(Object:_name() == "Object")
	assert(Object:_is_class())
	assert(Object:_class() == Class)

	assert(not object:_is_class())
	assert(object:_class() == Object)
	assert(not object:_is_class())
	local stat,err = pcall(object._super,object)
	assert (err:match("called on instance"))

	local Bitmap = Class("Bitmap", {typebitmap = "bitmap"}, Object)

	function Bitmap:is_bitmap()
		return true
	end

	function Bitmap:_init()
		self.bitmap_init = true
	end

	local bitmap = Bitmap()
	assert(bitmap.bitmap_init)
	assert(bitmap:is_bitmap())
	assert(type(bitmap.handle_event == "function"))
	----------------------------
	assert("x"..Class == "x[class Class]")
	assert("x"..Bitmap == "x[class Bitmap]")
	assert("x"..Object == "x[class Object]")
	assert("x"..bitmap == "x[instance of Bitmap]")
	assert(("x"..Class()):match("class AnonymousClass"))

	local AnotherBitmap = Class:_new("AnotherBitmap", {}, Bitmap)
	local anotherBitmap = AnotherBitmap()

	assert(AnotherBitmap:_name() == "AnotherBitmap")
	assert(AnotherBitmap:_class() == Class)
	assert(anotherBitmap:_class() == AnotherBitmap)
	----------------------------

	local YetAnotherBitmap = Class:_new("YetAnotherBitmap", nil, AnotherBitmap)

	local yetAnotherBitmap = YetAnotherBitmap:_new()
end

load_classes{
	"Class",
	"Object",
	"EventSource",
	"Device",
	"DeviceButton",
	"InputManager",
	"Window",
	"WindowManager",
	"MenuItem",
	"Menu",
	"SuperMan",
}

if dynawa.debug then
	class_check()
end

Class:get_by_name("SuperMan"):_new()

