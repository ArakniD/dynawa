--Animation during booting

local bitmaps = {}
local frame = 0
local n_frames = 4

rawset(_G, "boot_anim", function()
	dynawa.bitmap.show(bitmaps[frame])
	frame = (frame + 1) % n_frames
end)

for i = 0,n_frames - 1 do
	--bitmaps[i] = dynawa.bitmap.from_png_file(dynawa.dir.sys.."boot_anim/boot_anim"..i..".png")
	bitmaps[i] = dynawa.bitmap.new(160,128,(i*249)%256,(i*75)%256,(i*91)%256)
	--dynawa.bitmap.combine(bitmaps[i],dynawa.bitmap.new(80,64,0,255,0,255),0,64)
end
boot_anim()
