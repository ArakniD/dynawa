require("dynawa")
local buttons = {}

local function receive(message)
	local button = assert(message.button)
	local typ = assert(message.type)
	if typ == "button_up" then
		buttons[button] = nil
	elseif typ == "button_down" then
		buttons[button] = "DOWN"
	elseif typ == "button_hold" then
		buttons[button] = "HOLD"
	end
end

local function button_matrix(message)
	return buttons
end

dynawa.message.receive{messages={"button_up","button_down","button_hold"}, callback=receive}
dynawa.message.receive{message="button_matrix", callback = button_matrix}

