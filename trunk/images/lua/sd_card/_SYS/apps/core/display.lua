require ("dynawa")

local display_size = dynawa.display.size
local pixel_limit = display_size.width * display_size.height * 1.00

local function receive_bitmap(args)
	local task = assert(args.sender,"Unknown event sender")
	local app = assert(task.app)
	local bitmap = args.bitmap
	local at = args.at
	if not at then --full screen
		if not bitmap and app.in_front then
			error("App "..app.name.." wants to disable its screen while being in front")
		end
		if bitmap then
			local w,h = dynawa.bitmap.info(bitmap)
			if w ~= display_size.width or h ~= display_size.height then
				error("App "..app.name.." wants full screen update but bitmap has dimensions "..w.."x"..h)
			end
			app.screen_updates = {full=true}
		else
			app.screen_updates = nil
		end
		app.screen = bitmap
		log("Setting "..app.name.."'s display to "..tostring(bitmap))
	else  --region update
		assert (bitmap, "You must provide a bitmap when doing region update")
		local x = assert(at[1], "Missing first coordinate")
		local y = assert(at[2], "Missing second coordinate")
		assert(app.screen,"App "..app.name.." wants to do region update but has no screen")
		dynawa.bitmap.combine(app.screen,bitmap,x,y)
		local updates = app.screen_updates
		if updates.full then 
			return
		end
		local w,h = dynawa.bitmap.info(bitmap)
		updates.pixels = updates.pixels + (w * h)
		if updates.pixels >= pixel_limit then
			app.screen_updates = {full=true}
			return
		end
		table.insert(updates,{x,y,w,h})
	end
end

dynawa.event.receive{event = "display_bitmap", callback = receive_bitmap}

