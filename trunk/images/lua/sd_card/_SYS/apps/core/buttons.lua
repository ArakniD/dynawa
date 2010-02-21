require("dynawa")
local buttons = {}

local function receive(event)
	local button = assert(event.button)
	local typ = assert(event.type)
	if typ == "button_up" then
		buttons[button] = nil
	elseif typ == "button_down" then
		buttons[button] = "DOWN"
	elseif typ == "button_hold" then
		buttons[button] = "HOLD"
	end
end

local function button_matrix(event)
	return buttons
end

dynawa.event.receive{events={"button_up","button_down","button_hold"}, callback=receive}
dynawa.event.receive{event="button_matrix", callback = button_matrix}

