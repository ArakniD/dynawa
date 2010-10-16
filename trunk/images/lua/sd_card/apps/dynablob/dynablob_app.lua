app.name = "DynaBlob"
app.id = "fuxoft.dynablob"

function app:start()
	self.sprites = {}
	self.parts_bitmap = assert(dynawa.bitmap.from_png_file(self.dir.."parts.png"))
	self:init_indices()
end

function app:init_indices()
	local indices = {
		["blob/1"] = {9,63,49,64},
		["blob/2"] = {6,100,58,149},
		["blob/3"] = {68,66,141,114},
		["blob/4"] = {75,127,145,150},
		["eye"] = {0,0,6,6},	
	}
	self.sprite_indices = {}
	for id, ind in pairs(indices) do
		local x,y = ind[1],ind[2]
		local w,h = ind[3] - x, ind[4] - y
		assert(w>0)
		assert(h>0)
		self.sprite_indices[id] = {top_left = {x=x,y=y}, size = {w=w,h=h}, center = {x=math.floor(w/2) + x, y=math.floor(h/2) + y}}
	end
end

return app
