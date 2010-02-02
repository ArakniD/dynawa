--BITMAP system init (also printing)

dynawa.display={flipped=false}
dynawa.display.size={width=160,height=128}

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
	local white = dynawa.bitmap.new(20,20,255,255,255)
	local mask = assert(dynawa.bitmap.mask)
	local chars={}
	local widths={}
	local char=32
	local x=0
	local lastx=-1
	local total_width,height = dynawa.bitmap.info(bmap)
	local done = false
	repeat
		x=x+1
		local r,g,b,a = dynawa.bitmap.pixel(bmap,x,0)
		if r+g+b+a == 1020 then
			--log ("Char "..char.." x="..x)
			local width = x-lastx-1
			assert(width >= 1)
			--log("Char dimensions: "..width.."x"..height)
			local char_str = string.char(char)
			local char_bmp = dynawa.bitmap.copy(bmap,lastx+1,0,width,height)
			char_bmp = mask(char_bmp,white,0,0)
			chars[char_str] = char_bmp
			widths[char_str] = width
			lastx = x
			char = char + 1
			if char % 8 == 0 then
				boot_anim()
			end
			if char > 128 or x > total_width then error("FUCK") end
			r,g,b,a = dynawa.bitmap.pixel(bmap,x,1)
			if r+g+b+a == 1020 then
				done = true
			end
		end
	until done
	assert (char==128)
	return {chars=chars,widths=widths,height=height}
end

--Actually display app's screen. Not to be called from user apps
dynawa.display.update_screen = function()
	local app = assert(dynawa.app.in_front,"No app 'in front', cannot show its screen")
	local bitmap = assert(app.screen,"App in front ("..app.name..") does not have its screen")
	dynawa.bitmap.show(bitmap,dynawa.display.flipped)
	dynawa._display_updated = true
end

--This is called from the app do display its screen
dynawa.display.app_screen = function(bitmap)
	local w,h = dynawa.bitmap.info(bitmap)
	assert(w == dynawa.display.size.width and h == dynawa.display.size.height, "Invalid bitmap size")
	local task = assert(_G.my,"Current task unknown, cannot determine current app")
	local app = task.app
	app.display = bitmap
	if bitmap then
		--log("App "..app.id.." wants to display something")
		assert(type(bitmap)=="userdata","This is not bitmap but "..tostring(bitmap))
		app.screen = bitmap
		if not dynawa.app.in_front then
			dynawa.app.to_front(app)
		end
		if app == dynawa.app.in_front then
			dynawa.display.update_screen()
		end
	else --parameter was nil, app wants to be invisible
		--#todo
	end
end

--Load and parse font
dynawa.bitmap.default_font = dynawa.bitmap.parse_font(dynawa.bitmap.from_png_file("/_sys/fonts/default10.png"))

dynawa.bitmap.text_line = function(line,font)
	assert(type(line)=="string","First parameter is not string")
	font = font or assert(dynawa.bitmap.default_font)
	local x = 0
	local bmaps = {}
	local xs = {}
	for i=1, #line do
		local chr = line:sub(i,i)
		table.insert(bmaps,font.chars[chr])
		table.insert(xs,x)
		x = x + font.widths[chr] + 1
	end
	local width = x - 1
	local height = assert(font.height)
	local result = dynawa.bitmap.new(width,height,255,255,0,0)
	local combine = dynawa.bitmap.combine
	for i = 1, #line do
		combine(result, bmaps[i], xs [i], 0)
	end
	return result, width, height
end

local screen = dynawa.bitmap.new(160,128,0,0,0)
dynawa.bitmap.combine(screen,dynawa.bitmap.text_line("TEXT1 text2"),0,120)
dynawa.bitmap.show(screen)

