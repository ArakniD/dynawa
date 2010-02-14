require("dynawa")

local function new_widget(event)
	local app=assert(event.sender.app)
	local widget
	if event.menu then
		widget = event.menu
		widget.type = "menu"
	elseif event.notification then
		widget = event.notification
		widget.type = "notification"
	else
		error("Unknown widget type")
	end
	widget.app = app
	if not widget.id then
		widget.id = dynawa.unique_id()
	end
	local result = my.globals[widget.type].new(widget)
	my.globals.current_widget = assert(result)
	log("Widget to front")
	dynawa.event.send{type="me_to_front"}
end

my.globals.widget_result = function (widget,event)
	event.id = widget.id --not mandatory
	event.receiver = assert(widget.app)
	event.type = "widget_result"
	assert(event.status, "Widget_result event has no status")
	dynawa.event.send(event)
end

local function widget_closed()
	local current_widget = my.globals.current_widget
	if current_widget then
		if my.app.in_front then
			dynawa.event.send{type="app_to_front", app = current_widget.app}
		end
		dynawa.event.send{type="display_bitmap", bitmap = nil}
		my.globals.current_widget = nil
	end
end

local function button_event(event)
	local current_widget = my.globals.current_widget
	if not current_widget then
		return
	end
	if event.type == "button_down" and (event.button == "CANCEL" or event.button == "SWITCH") then
		widget_closed()
		return
	end
	my.globals[current_widget.type].button_event (current_widget, event)
end

my.app.name = "System Widget"
my.globals.current_widget = nil
my.globals.inactive_mask = assert(dynawa.bitmap.from_png_file(my.dir.."inactive_mask.png"))
dynawa.dofile (my.dir.."menu.lua")
dynawa.dofile (my.dir.."notification.lua")
dynawa.event.receive{event="new_widget", callback=new_widget}
dynawa.event.receive{event="close_widget", callback=widget_closed}
dynawa.event.send{type = "set_flags", flags = {ignore_app_switch = true}}
dynawa.event.receive{events={"button_down","button_up","button_hold"}, callback=button_event}

