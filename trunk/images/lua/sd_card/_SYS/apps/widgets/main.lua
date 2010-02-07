require("dynawa")

my.app.name = "System Widget"

local current_widget = nil
local inactive_mask = dynawa.bitmap.from_png_file(my.dir.."inactive_mask.png")

dofile (my.dir.."menu.lua")

local function new_widget(event)
	local app=assert(event.sender.app)
	local scr = assert(app.screen)
	scr = dynawa.bitmap.combine(scr,inactive_mask,0,0,true)
	local widget = my.globals.menu.new()
	widget.app = app
	dynawa.bitmap.combine(scr,widget.bitmap,5,5)
	current_widget = widget
	dynawa.event.send{type="display_bitmap", bitmap=scr}
	dynawa.event.send{type="me_to_front"}
end

local function widget_cancelled()
	if not current_widget then
		return
	end
	dynawa.event.send{type="widget_done", status = "cancelled", id=current_widget.id, receiver = current_widget.app}
	dynawa.event.send{type="app_to_front", app = current_widget.app}
	dynawa.event.send{type="display_bitmap", bitmap = nil}
	current_widget = nil
end

local function button_down(event)
	if event.button == "CANCEL" or event.button == "SWITCH" then
		widget_cancelled()
		return
	end
end

dynawa.event.receive{event="new_widget", callback=new_widget}
dynawa.event.receive{event="you_are_now_in_back", callback=widget_cancelled}
dynawa.event.receive{event="button_down", callback=button_down}

