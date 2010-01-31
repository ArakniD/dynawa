--Animation during booting

local bitmaps = {}
local frame = 0
local n_frames = 2

rawset(_G, "boot_anim", function()
	dynawa.bitmap.show(bitmaps[frame])
	frame = (frame + 1) % n_frames
end)

for i = 0,n_frames - 1 do
	bitmaps[i] = dynawa.bitmap.from_png_file(dynawa.dir.sys.."boot_anim/boot_anim"..i..".png")
end
boot_anim()
