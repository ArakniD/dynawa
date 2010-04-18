app.name = "Popup"
app.id = "dynawa.popup"

function app:open(args)
	--text, style
	if self.window then
		self:switching_to_back()
	end
	self.window = self:new_window()
	local his_win = dynawa.window_manager:peek()
	local his_bmp = (his_win or {}).bitmap
	if not his_bmp then
		his_bmp = dynawa.bitmap.new(dynawa.devices.display.size.w, dynawa.devices.display.size.h, 0,0,0)
	end
	local bgcolor = {0,40,0}
	if args.style == "error" then
		bgcolor = {128,0,0}
	end
	local dsize = dynawa.devices.display.size
	local textbmp = dynawa.bitmap.text_lines{width = math.floor(dsize.w * 0.8), autoshrink = true, center = true, text = assert(args.text)}
	local sw0,sh0 = dynawa.bitmap.info(textbmp)
	local w,h = sw0+8, sh0+8
	local bmp = dynawa.bitmap.new(w,h, unpack(bgcolor))
	dynawa.bitmap.border(bmp, 2, {255,255,255})
	dynawa.bitmap.border(bmp, 1, {0,0,0})
	dynawa.bitmap.combine(bmp, textbmp, 4, 4)
	local start_w, start_h = math.floor((dsize.w - w) / 2), math.floor((dsize.h - h) / 2)
	local screen = dynawa.bitmap.combine(his_bmp, self.mesh, 0,0, true)
	dynawa.bitmap.combine(screen, bmp, start_w, start_h)
	self.window:show_bitmap(screen)
	self.window:push()
	self.timestamp = dynawa.ticks()
end

function app:switching_to_front()
	error("Popup App is being switched to_front??? Something is very wrong")
end

function app:switching_to_back()
	self.window:pop()
	self.window:_delete()
	self.window = false
end

function app:handle_event_button(event)
	if assert(event.action) == "button_down" and dynawa.ticks() - self.timestamp > 999 then
		if event.button == "confirm" or event.button == "cancel" then
			self:switching_to_back()
		end
	end
end

function app:start()
	self.window = false
	dynawa.popup = self
	self.mesh = assert(dynawa.bitmap.from_png_file(self.dir.."mesh.png"))
end

