app.name = "DynaBlob"
app.id = "fuxoft.dynablob"

function app:start()
	self.window = self:new_window()
	self:init_indices()
end

function app:switching_to_front()
	self.window:push()
	self.run_id = dynawa.unique_id()
	self:re_color()
	self:animate(0)
end

function app:re_color()
	local color = {math.random(200)+55, math.random(200)+55, math.random(200)+55}
	local full = dynawa.bitmap.new(160,128,color[1],color[2],color[3])
	for id, sprite in pairs(self.sprites) do
		if id:match("^blob_.*") then
			sprite.bitmap = dynawa.bitmap.mask(full, sprite.bitmap,0,0)
		end
	end
end

function app:animate(count)
	self.window:fill()
	--self:put_sprite("testmark",0,0)
	self:put_sprite("blob_4",80,120)
	self:put_sprite("blob_3",80,105)
	self:put_sprite("blob_3",80,90)
	self:put_sprite("blob_2",80,80)
	local eye = {"eye_rb","eye_lb","eye_top","eye_rt","eye_closed","eye_right","eye_center","eye_squint","eye_blood1","eye_blood2","eye_smaller"}
	eye = eye[math.random(#eye)]
	self:put_sprite(eye,80-10,80)
	self:put_sprite(eye,80+10,80)
	if math.random(5) == 1 then
		self:put_sprite("mouth1",80,100)
	else
		self:put_sprite("mouth2",80,100)
	end
	dynawa.devices.timers:timed_event{delay = 200, receiver = self, run_id = self.run_id}
end

function app:handle_event_timed_event(event)
	if self.run_id ~= event.run_id then
		return
	end
	if not self.window.in_front then
		self.run_id = nil
		return
	end
	self:animate(0)
end

function app:put_sprite(sprid, cx, cy, window)
	window = window or self.window
	local sprite = self.sprites[sprid]
	if not sprite then
		error("Uknown sprite id: "..sprid)
	end
	local dx = math.random(5) - 3
	local dy = math.random(5) - 3
	window:show_bitmap_at(sprite.bitmap, cx - sprite.half_size.w + dx, cy - sprite.half_size.h + dy)
end

function app:init_indices()
	local parts = assert(dynawa.bitmap.from_png_file(self.dir.."parts.png"))
	local indices = {
		["testmark"] = {0,0,4,4},
		["blob_1"] = {9,63,49,64},
		["blob_2"] = {6,100,58,149},
		["blob_3"] = {68,66,141,114},
		["blob_4"] = {75,127,145,150},
		["blob_5"] = {151,74,174,98},
		["blob_6"] = {162,109,197,155},
		["blob_7"] = {205,58,329,164},
		["eye_rb"] = {15,0,25,11},
		["eye_top"] = {25,0,35,11},
		["eye_lb"] = {35,0,45,11},
		["eye_closed"] = {45,3,54,6},
		["eye_rt"] = {72,0,82,11},
		["eye_right"] = {82,0,92,11},
		["eye_center"] = {92,0,102,11},
		["eye_squint"] = {102,0,112,11},
		["eye_blood1"] = {112,0,122,11},
		["eye_blood2"] = {122,0,132,11},
		["eye_smaller"] = {132,0,142,9},
		["mouth1"] = {0,19,14,29},
		["mouth2"] = {15,23,29,27},
	}
	self.sprites = {}
	for id, ind in pairs(indices) do
		local x,y = ind[1],ind[2]
		local w,h = ind[3] - x, ind[4] - y
		assert(w>0)
		assert(h>0)
		self.sprites[id] = {bitmap = dynawa.bitmap.copy(parts,x,y,w,h),size = {w=w,h=h}, half_size = {w=math.floor(w/2), h=math.floor(h/2)}}
	end
end

return app
