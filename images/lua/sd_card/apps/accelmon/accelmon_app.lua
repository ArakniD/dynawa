app.name = "Accelerometer Monitor"
app.id = "dynawa.accelmon"

function app:display(bitmap, x, y)
	assert(bitmap and x and y)
	self.window:show_bitmap_at(bitmap, x, y)
end

function app:update(message)
	if not self.window.in_front then
        return
    end
    local xyz = dynawa.x.accel_stats()

    local txtbmp = dynawa.bitmap.text_line(string.format("%d %d %s", xyz.x, xyz.y, xyz.z),"/_sys/fonts/default15.png") 
     local x = 10
     local y = 10
     self:display(self.bmp_blank,x,y) 
     self:display(txtbmp,x,y) 

    log("accel [" .. xyz.x .. ", " .. xyz.y .. ", " .. xyz.z .. "]")
	dynawa.devices.timers:timed_event{delay = 500, receiver = self}
end

function app:handle_event_timed_event(event)
	self:update(event)
end

function app:switching_to_back()
	Class.App.switching_to_back(self)
end

function app:switching_to_front()
	if not self.window then
		self.window = self:new_window()
		self.window:show_bitmap(dynawa.bitmap.new(160,128))
	end
	self.window:push()
	self:update()
end

function app:gfx_init()
     self.bmp_blank = dynawa.bitmap.new(118, 15) 
end

function app:start()
	self:gfx_init()
end

