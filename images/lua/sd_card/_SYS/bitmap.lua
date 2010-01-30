--BITMAP system init (also printing)

dynawa.display={flipped=false}

dynawa.bitmap.info = function(bmap)
	assert(type(bmap)=="userdata")
	local peek=dynawa.peek
	local width=peek(2,bmap) + (256*peek(3,bmap))
	local height=peek(4,bmap) + (256*peek(5,bmap))
	
	--log("Bmap bytes:"..res)
	--log("peek(5,bmp) = "..peek(5,bmp))
	return width, height
end

dynawa.bitmap.pixel = function(bmap, x, y)
	local w,h = dynawa.bitmap.info(bmap)
	assert (x >= 0)
	assert (y >= 0)
	assert (x < w)
	assert (y < h)
	local offset = (w * y + x) * 4 + 8
	local peek = dynawa.peek
	--log("offset = "..offset)
	return peek (offset, bmap), peek (offset + 1, bmap), peek (offset + 2, bmap), peek (offset + 3, bmap)
end

dynawa.bitmap.parse_font = function (bmap)
	local chars={}
	local char=32
	local x=0
	local lastx=-1
	local _w,height = dynawa.bitmap.info(bmap)
	local done = false
	repeat
		x=x+1
		local r,g,b,a = dynawa.bitmap.pixel(bmap,x,0)
		if r+g+b+a == 1020 then
			--log ("Char "..char.." x="..x)
			local width = x-lastx-1
			assert(width >= 1)
			--log("Char dimensions: "..width.."x"..height)
			chars[char] = dynawa.bitmap.copy(bmap,lastx,0,width,height)
			lastx = x
			char = char + 1
			if char % 5 == 0 then
				boot_anim()
			end
			if char > 128 or x > 500 then error("FUCK") end
			r,g,b,a = dynawa.bitmap.pixel(bmap,x,1)
			if r+g+b+a == 1020 then
				done = true
			end
		end
	until done
	assert (char==128)
	return chars
end

local bm=dynawa.bitmap.from_png_file("/_sys/fonts/default.png")
--[[for i=0,10 do
	log("peek "..i..": "..dynawa.peek(i,bm))
end]]
dynawa.bitmap.parse_font(bm)
--[[for x=0,20 do
	local r,g,b,a = dynawa.bitmap.pixel(bm,x,0)
	log("Pixel at x="..x..": b="..b..", a="..a..", sum="..r+g+b+a)
end]]
log("font parsed")

