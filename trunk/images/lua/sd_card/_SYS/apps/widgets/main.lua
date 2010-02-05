my.app.name = "System Widgets"

local scr = dynawa.bitmap.new(160,128,255,255,0)

local function new_widget(event)
	local app=assert(event.sender.app)
	local scr = app.screen or dynawa.bitmap.new(160,128,255,255,0)
	local widget = dynawa.bitmap.new(50,30,0,0,80)
	scr = dynawa.bitmap.combine(scr,widget,20,10,true)
	dynawa.event.send{type="display_bitmap", bitmap=scr}
	dynawa.event.send{type="me_to_front"}
end

local function now_in_back(event)
	dynawa.event.send{type="display_bitmap", bitmap = nil}
end

dynawa.event.receive{event="new_widget", callback=new_widget}
dynawa.event.receive{event="you_are_now_in_back", callback=now_in_back}

