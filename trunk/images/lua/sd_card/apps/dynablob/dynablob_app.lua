app.name = "DynaBlob"
app.id = "fuxoft.dynablob"

function app:start()
	self.window = self:new_window()
	self:init_indices()
	self:init_skelets()
end

function app:switching_to_front()
	self.window:push()
	self.run_id = dynawa.unique_id()
	self:re_color()
	self.blob = {count = 0, skelet = self.skelets[1]}
	self:animate()
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

function app:animate()
	local blob = self.blob
	self.window:fill()
	local count,wait_ms = blob.skelet.animate(self,blob.count)
	assert(count)
	assert(wait_ms >= 100)
	blob.count = count
	--local eyes = {"eye_rb","eye_lb","eye_top","eye_rt","eye_closed","eye_right","eye_center","eye_squint","eye_blood1","eye_blood2","eye_smaller"}
	dynawa.devices.timers:timed_event{delay = wait_ms, receiver = self, run_id = self.run_id}
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
	local dx = 80
	window:show_bitmap_at(sprite.bitmap, math.floor(0.5 + cx - sprite.half_size.w + dx), math.floor(128.5 - cy - sprite.half_size.h))
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

function app:init_skelets()
	self.skelets = {}
	self.skelets[1] = {
		animate = function(self,count)
			local diff = count % 20
			if diff > 10 then
				diff = 20 - diff
			end
			diff = diff - 5
			local jmp = count % 3
			self:put_sprite("blob_4",0,8)
			self:put_sprite("blob_3",diff, 22 + jmp)
			self:put_sprite("blob_3",diff * 2, 37)
			self:put_sprite("blob_2",diff,48)
			local eyediff = 10
			local eye = "eye_rb"
			self:put_sprite(eye,diff + eyediff,48)
			self:put_sprite(eye,diff - eyediff,48)
			self:put_sprite("mouth2",diff * 0.5,28)
			return count + 1, 200
		end
	}
end

return app
