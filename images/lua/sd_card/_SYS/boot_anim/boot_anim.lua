--Animation during booting

local bitmaps = {}
local frame = 0

rawset(_G, "boot_anim", function()
	dynawa.bitmap.show(bitmaps[frame])
	frame = (frame + 1) % 4
end)

for i = 0,3 do
	bitmaps[i] = dynawa.bitmap.from_png_file(dynawa.dir.sys.."boot_anim/boot_anim"..i..".png")
end
boot_anim()
