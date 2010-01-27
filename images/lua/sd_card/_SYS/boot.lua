--This is the primary entry point into Lua!
--DO NOT MODIFY THIS FILE.
--Use "override.lua" to tune-up the boot process.

print("START0")
assert(dynawa, "Dynawa library not detected")

--[[local bmp = {
	[0] = dynawa.bitmap.new(160, 128, 0, 0, 255),
	dynawa.bitmap.new(160, 128, 0, 255, 0),
	dynawa.bitmap.new(160, 128, 255, 255, 0, 0),
	dynawa.bitmap.new(160, 128, 0, 255, 255)
}
for i=1,25 do
	dynawa.bitmap.show(bmp[i%4])
end
local i=0
while true do
	dynawa.bitmap.show(bmp[i%4])
	local str=tostring(io.read(1))
	io.write("GOT CHAR "..string.byte(str).."\n")
	io.output():flush()
	i=i+1
end--]]

--Note the following function can be called more than once because of "soft reboot".
--The flag "dynawa.already_booted" can be used to determine if this is the case.
function _G.boot_init()
	dynawa.debug = nil
	dynawa.dir = {root="/"}
	dynawa.dir.sys=dynawa.dir.root .. "_SYS/"
	_G.log = function() end
	
	--Try loading the (potential) boot override script stored in the default path
	local override,err = loadfile("override.lua")
	
	if (not override) and (not (err or ""):match("No such file or directory")) then
		--Override script exists but cannot be loaded
		error(err)
	end
	
	if override then
		--Execute the override script and clear its chunk to save memory
		override()
		override = nil
	end

	_G.handle_event = false
	--Disallow unintended creating of global variables
	local mt=getmetatable(_G)
	if not mt then
		mt={}
		setmetatable(_G,mt)
	end
	mt.__newindex=function(table,key,value)
		error("Attempt to create global variable '"..key.."' (forgot to use 'local'?)")
	end

	if dynawa.debug.main_handler then		--We are in debug mode, use the main loop wrapper
		_G.handle_event = dynawa.debug.main_handler
		dynawa.version=nil 					--Forces the WristOS to be reloaded later in main_handler (by xpcall)
	else									--Not in debug mode
		dofile(dynawa.dir.sys.."wristos.lua") 
		_G.handle_event = _G.private_main_handler
	end
	
	dynawa.already_booted = true
end

--The following dummy definition should be overridden by either override.lua or wristos.lua, if all compiles well
function _G.private_main_handler(event)
	print("DUMMY_PRIVATE_MAIN_HANDLER")
	return nil
end

--Here we go...
boot_init()
