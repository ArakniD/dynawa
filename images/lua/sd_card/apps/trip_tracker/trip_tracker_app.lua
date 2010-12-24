app.name = "Trip Tracker"
app.id = "dynawa.trip_tracker"

function app:start()
	self.prefs = self:load_data() or {units = "metric", default_screen = "basic"}
	self.run_id = false
	self.values = {timestamp = -99999}
	self:gfx_init()
--[[	dynawa.app_manager:after_app_start("dynawa.dyno", function(dyno)
		dyno.events:register_for_events(self, function(ev)
			return (ev.data and ev.data.command == "geo_update" and )
		end)
	end)]]
--	self:handle_event_timed_event()
end

function app:update_screen()
	self.window:fill()
	local screen = assert(self.screen)
	if screen == "basic" then
		local lines = {}
		for line,name in ipairs({"latitude","longitude","accuracy","altitude","speed","bearing","timestamp"}) do
			local str = name..": "..tostring(self.values[name])
			local txtbmp = dynawa.bitmap.text_line(str,"/_sys/fonts/default10.png")
			self.window:show_bitmap_at(txtbmp, 0, 11*line - 11)
		end
--[[		local speed = math.random(140)
		local spd1 = math.floor(speed / 100)
		local spd2 = math.floor(speed / 10) % 10
		local spd3 = speed % 10
		local x,y = 15,15
		self.window:show_bitmap_at(self.gfx[spd3],x+36,y)
		if spd1 + spd2 > 0 then
			self.window:show_bitmap_at(self.gfx[spd2],x+18,y)
		end
		if spd1 > 0 then
			self.window:show_bitmap_at(self.gfx[spd1],x,y)
		end]]
	elseif screen == "xxbasic" then
		local speed = math.random(140)
		local spd1 = math.floor(speed / 100)
		local spd2 = math.floor(speed / 10) % 10
		local spd3 = speed % 10
		local x,y = 15,15
--		self.window:show_bitmap_at(dynawa.bitmap.new(20,20,255,0,0),10,10)
		self.window:show_bitmap_at(self.gfx[spd3],x+36,y)
		if spd1 + spd2 > 0 then
			self.window:show_bitmap_at(self.gfx[spd2],x+18,y)
		end
		if spd1 > 0 then
			self.window:show_bitmap_at(self.gfx[spd1],x,y)
		end
	else
		error("WTF")
	end
end

function app:handle_response(resp)
	self.values = {timestamp = dynawa.ticks()}
	local vals = self.values
	vals.accuracy = resp.accuracy
	vals.latitude = resp.location.latitude
	vals.longitude = resp.location.longitude
	vals.altitude = resp.altitude
	vals.speed = resp.speed
	vals.bearing = resp.bearing
	self:update_screen()
end

function app:geo_start()
	local geo_app = dynawa.app_manager:app_by_id("dynawa.geo_request")
	if not geo_app then
		dynawa.popup:error("Trip Tracker is unable to find a running Geo Request App.")
		return
	end
	local request = {method = "gps", updates = {time = 3000}, id = self.id, callback = function (reply, req)
		log("Got Geo update: "..dynawa.file.serialize(reply))
		self:handle_response(reply)
		if not self.window.in_front then --#todo PREDELAT NA "switching_to_back"!
			local request = {updates = "cancel", method = "all", id = self.id}
			geo_app:make_request(request)
		end
	end}
	geo_app:make_request(request)
end

function app:switching_to_front()
	self:update_screen()
	self.window:push()
	self:geo_start()
end

function app:going_to_sleep()
	return "remember"
end

function app:gfx_init()
	self.gfx = {}
	local bmp = assert(dynawa.bitmap.from_png_file(self.dir.."gfx.png"))
	for i = 0,9 do
		self.gfx[i] = dynawa.bitmap.copy(bmp,17*i,0,16,24)
	end
	self.window = self:new_window()
	self.screen = self.prefs.default_screen
end
