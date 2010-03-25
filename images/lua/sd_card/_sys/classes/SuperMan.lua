--SuperMan

local class = Class:_new("SuperMan")

function class:_init()
	dynawa.tch = {}
	dynawa.tch.superman = self
	dynawa.tch.devices = {}
	--#todo DeviceNodes
	dynawa.tch.devices.buttons = {}
	local DeviceButton = Class:get_by_name("DeviceButton")
	for i = 0, 4 do
		local obj = DeviceButton:_new(i)
		dynawa.tch.devices.buttons[obj.name] = obj
	end
end

Class:add_public(class)

return class

