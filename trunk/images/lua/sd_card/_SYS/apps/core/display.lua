require ("dynawa")

local function receive_bitmap(args)
	local task = assert(args.sender,"Unknown event sender")
	local bitmap = args.bitmap
	if not bitmap and task.app.in_front then
		error("App "..task.app.name.." cleared its screen while being in front")
	end
	task.app.screen = bitmap
	--log(task.app.name.." updated display")
end

dynawa.event.receive{event = "display_bitmap", callback = receive_bitmap}

