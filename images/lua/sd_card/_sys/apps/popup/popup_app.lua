app.name = "Popup"
app.id = "dynawa.popup"

function app:error(text)
	assert(type(text)=="string")
	self:open{style="error", text=text}
end

function app:info(text)
	assert(type(text)=="string")
	self:open{text=text}
end

function app:open(args)
	dynawa.busy()
	--text, style
	if self.window then
		self:switching_to_back()
	end
	local autoclose = args.autoclose
	if autoclose and type(autoclose) ~= "number" then
		autoclose = 5000 --Default autoclose interval
	end
	self.window = self:new_window()
	local his_win = dynawa.window_manager:peek()
	local his_bmp = (his_win or {}).bitmap
	local wsize --Window size
	if not his_bmp then
		wsize = dynawa.devices.display.size
		his_bmp = dynawa.bitmap.new(wsize.w, wsize.h, 0,0,0)
	else
		wsize = assert(his_win.size)
	end
	local bgcolor = args.bgcolor or {0,40,0}
	local bmp,w,h
	if args.bitmap then --Bitmap supplied by caller, don't render it
		bmp = args.bitmap
		w,h = dynawa.bitmap.info(bmp)
	else
		if args.style == "error" then
			bgcolor = {128,0,0}
		end
		local textbmp = dynawa.bitmap.text_lines{width = math.floor(wsize.w * 0.85), autoshrink = true, center = true, text = assert(args.text)}
		local sw0,sh0 = dynawa.bitmap.info(textbmp)
		w,h = sw0+8, sh0+8
		bmp = dynawa.bitmap.new(w,h, unpack(bgcolor))
		dynawa.bitmap.border(bmp, 2, {255,255,255})
		dynawa.bitmap.border(bmp, 1, {0,0,0})
		dynawa.bitmap.combine(bmp, textbmp, 4, 4)
	end
	
	local start_w, start_h = math.floor((wsize.w - w) / 2), math.floor((wsize.h - h) / 2)
	local screen = dynawa.bitmap.combine(his_bmp, self.mesh, 0,0, true)
	dynawa.bitmap.combine(screen, bmp, start_w, start_h)
	self.window:show_bitmap(screen)
	self.window:push()
	self.window.on_confirm = args.on_confirm
	self.timestamp = dynawa.ticks()
	if autoclose then 
		dynawa.devices.timers:timed_event{delay = autoclose, receiver = self, window_id = assert(self.window.id)}
	end
end

function app:handle_event_timed_event(event) --Autoclose still valid?
	local window_id = assert(event.window_id)
	if self.window and self.window.id == window_id then
		self:switching_to_back()
	end
end

function app:switching_to_back()
	self.window:pop()
	self.window:_delete()
	self.window = false
end

function app:handle_event_button(event)
	if assert(event.action) == "button_down" and dynawa.ticks() - self.timestamp > 250 then
		if event.button == "confirm" or event.button == "cancel" then
			local on_confirm = self.window.on_confirm
			self:switching_to_back()
			if on_confirm and event.button == "confirm" then
				on_confirm()
			end
		end
	end
end

function app:start()
	self.window = false
	dynawa.popup = self
	self.mesh = assert(dynawa.bitmap.from_png_file(self.dir.."mesh.png"))
end

