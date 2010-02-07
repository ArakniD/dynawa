require("dynawa")

my.app.name = "System Widget"

local current_widget = nil
my.globals.inactive_mask = assert(dynawa.bitmap.from_png_file(my.dir.."inactive_mask.png"))

dofile (my.dir.."menu.lua")

local function new_widget(event)
	local app=assert(event.sender.app)
	local widget
	if event.menu then
		widget = event.menu
		widget.type = "menu"
	else
		error("Got unknown widget type from "..app.name)
	end
	widget.app = app
	local result = my.globals[widget.type].new(widget)
	current_widget = result
	dynawa.event.send{type="me_to_front"}
end

local function widget_cancelled()
	if not current_widget then
		return
	end
	dynawa.event.send{type="widget_done", status = "cancelled", receiver = current_widget.app}
	dynawa.event.send{type="app_to_front", app = current_widget.app}
	dynawa.event.send{type="display_bitmap", bitmap = nil}
	current_widget = nil
end

local function button_event(event)
	if not current_widget then
		return
	end
	if event.type == "button_down" and (event.button == "CANCEL" or event.button == "SWITCH") then
		widget_cancelled()
		return
	end
	my.globals[current_widget.type].button_event (current_widget, event)
end

dynawa.event.receive{event="new_widget", callback=new_widget}
dynawa.event.receive{event="you_are_now_in_back", callback=widget_cancelled}
dynawa.event.receive{events={"button_down","button_up","button_hold"}, callback=button_event}

