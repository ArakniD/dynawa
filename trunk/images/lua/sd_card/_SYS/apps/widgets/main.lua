require("dynawa")

my.app.name = "System Widget"

my.globals.current_widget = nil
my.globals.inactive_mask = assert(dynawa.bitmap.from_png_file(my.dir.."inactive_mask.png"))

dofile (my.dir.."menu.lua")
dofile (my.dir.."notification.lua")

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
	local result = my.globals[widget.type].new(widget)
	my.globals.current_widget = assert(result)
	log("Widget to front")
	dynawa.event.send{type="me_to_front"}
end

my.globals.widget_done = function (widget,event)
	event.id = widget.id --not mandatory
	event.receiver = assert(widget.app)
	event.type = "widget_done"
	assert(event.status, "Widget_done event has no status")
	dynawa.event.send(event)
	dynawa.event.send{type="app_to_front", app = widget.app}
	dynawa.event.send{type="display_bitmap", bitmap = nil}
	my.globals.current_widget = nil
end

local function widget_cancelled()
	local current_widget = my.globals.current_widget
	if not current_widget then
		return
	end
	my.globals.widget_done(current_widget,{status = "cancelled"})
end

local function button_event(event)
	local current_widget = my.globals.current_widget
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
dynawa.event.send{type = "set_flags", flags = {ignore_app_switch = true}}
dynawa.event.receive{events={"button_down","button_up","button_hold"}, callback=button_event}

