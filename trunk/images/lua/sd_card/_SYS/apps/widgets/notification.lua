--included from widget/main.lua

my.globals.notification={}

local function full_redraw(notif)
	assert(notif.type == "notification")
	local bgbmp = assert(notif.app.screen)
	bgbmp = dynawa.bitmap.combine(bgbmp,my.globals.inactive_mask,0,0,true)
	dynawa.bitmap.combine(bgbmp,notif.bitmap,notif.start.x,notif.start.y)
	dynawa.event.send{type="display_bitmap", bitmap=bgbmp}
	log("Showing notification")
	return notif
end

my.globals.notification.new = function(notif0)
	local notif = {type="notification"}
	notif.autoclose = notif0.autoclose
	notif.text = assert(notif0.text)
	notif.app = assert(notif0.app)
	notif.id = notif0.id
	local textbmp = dynawa.bitmap.text_line(notif.text,nil,{255,255,255})
	local txtw,txth = dynawa.bitmap.info(textbmp)
	local w,h = txtw + 6, txth + 6
	local bmp = dynawa.bitmap.new(w,h, 0,0,128)
	dynawa.bitmap.border(bmp,1,{255,255,255})
	dynawa.bitmap.combine(bmp, textbmp, 3, 3)
	notif.bitmap = bmp
	notif.start = {x =  math.floor((dynawa.display.size.width - w) / 2), y = math.floor((dynawa.display.size.height - h) / 2)}
	notif.size = {width = w, height = h}
	full_redraw(notif)
	return notif
end

my.globals.notification.button_event = function(notif, event)
	if event.type == "button_down" then
		local event = {status = "dismissed"}
		my.globals.widget_result(notif,event)
		log("Notif dismissed")
		if notif.autoclose then
			log("Autoclosing")
			dynawa.event.send{type="close_widget"}
		end
	end
end

