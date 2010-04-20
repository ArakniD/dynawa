self.name = "Button Test App"
self.screen = _dynawa.bitmap.new (160,128,80,0,0)
self.count = 0

local function tests()
	local function dotest(rept, fn)
		rept = math.floor(rept)
		--collectgarbage("stop")
		collectgarbage("collect")
		local t0 = _dynawa.ticks()
		for i = 1,rept do
			fn(i)
		end
		local t= _dynawa.ticks() - t0
		log("...took "..(math.floor(t * 100 / rept)/100 .." ms"))
		--collectgarbage("restart")
		--log("mem: "..math.floor(collectgarbage("count")))
	end

	log("Creating constant table {11,22,33}")
	dotest(500, function()
		local x = {11,22,33}
	end)

	log("Creating constant table {x=1,y=2}")
	dotest(500, function()
		local x = {x=11,y=22,z=33}
	end)

	log("Creating constant table {x='eleven',y='twentytwo',z='thirtythree'}")
	dotest(500, function()
		local x = {x="eleven",y="twentytwo",z="thirtythree"}
	end)

	log("Create new fullscreen bitmap / direct call to bitmap.new()")
	dotest(30,function()
		local bmap = _dynawa.bitmap.new(160,128,0,0,0)
	end)

	local bmapnew = _dynawa.bitmap.new
	log("Create new fullscreen bitmap / direct call fn in local var")
	dotest(30,function()
		local bmap = bmapnew(160,128,0,0,0)
	end)

	log("Create new fullscreen bitmap / call thru WristOS.bitmap.new{}")
	dotest(30,function()
		local bmap = WristOS.bitmap.new{size = {160,128}, color = {0,0,0}}
	end)
	
	log("Put existing fullscreen bitmap to screen")
	local scr = _dynawa.bitmap.new(160,128,0,0,0)
	dotest(100,function()
		_dynawa.bitmap.show(scr)
	end)
	
	local overlay = _dynawa.bitmap.new(100,100,10,100,200)
	log("Combine 100x100 bitmap with fullscreen bitmap / direct call bitmap.combine()")
	local scr = _dynawa.bitmap.new(160,128,0,0,0)
	dotest(100,function()
		_dynawa.bitmap.combine(scr,overlay,50,50)
	end)
	
	log("Combine 100x100 bitmap with fullscreen bitmap / call thru WristOS.bitmap.combine{}")
	local scr = _dynawa.bitmap.new(160,128,0,0,0)
	dotest(100,function()
		WristOS.bitmap.combine{bitmap = scr,overlay=overlay,at={50,50}}
	end)
	
	local bmap_s = WristOS.new_bitmap(scr)
	local bmap_o = WristOS.new_bitmap(overlay)
	
	log("Combine 100x100 bitmap with fullscreen bitmap as objects")
	dotest(100, function()
		bmap_s:combine(bmap_o,50,50)
	end)

	log("Creating simple object")
	local App = Class:get_by_name("App")
	dotest(100, function()
		local x = App:new{name="prdel"}
	end)
	
	local function paramtest1(x)
		local y=1
		if x==69 then
			local y=2
		end
		return y
	end

	log("Calling and comparing with number param")
	local App = Class:get_by_name("App")
	dotest(1000, function()
		local x = paramtest1(69)
	end)
	
	local function paramtest2(x)
		local y=1
		if x=="this_is_a_long_string_instead_of_sixty_nine" then
			local y=2
		end
		return y
	end

	log("Calling and comparing with string param")
	local App = Class:get_by_name("App")
	dotest(1000, function()
		local x = paramtest2("this_is_a_long_string_instead_of_sixty_nine")
	end)
	
	WristOS.dofile("/dynawa_class.lua")
	
	log("Creating AnotherBitmap._new({bitmap=bmp})")
	dotest(1000, function()
		local x = Class.AnotherBitmap:_new({bitmap = scr})
	end)
	
end

function self:scroll_line(text)
	local line, width, height = WristOS.bitmap.text_line{line = text}
	self.screen = _dynawa.bitmap.copy(self.screen,0,height,160,128)
	local line2 = _dynawa.bitmap.combine(_dynawa.bitmap.new(160,height,math.random(200),math.random(200),math.random(200)),line,0,0)
	_dynawa.bitmap.combine(self.screen,line2,0,128-height)
	self:display_bitmap(self.screen)
end

function self:button_event(msg)
	self.count = self.count + 1
	self:scroll_line(self.count..": "..msg.button.." "..msg.action)
	if msg.button == "CANCEL" and msg.action == "button_down" then
		tests()
	end
end

self:scroll_line("BUTTONS+SCROLLING TEST APP :)")
self:to_front()

