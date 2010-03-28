dynawa.tch.devices = {}
--#todo DeviceNodes
dynawa.tch.devices.buttons = {}
local DeviceButton = Class:get_by_name("DeviceButton")
for i = 0, 4 do
	local button = DeviceButton(i)
	dynawa.tch.devices.buttons[button.name] = button
end
dynawa.tch.devices.display = {width = 160, height = 128, flipped = false}

