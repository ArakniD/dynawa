require ("dynawa")
local function receive_bitmap(args)
	local task = assert(args.sender,"Unknown event sender")
	local bitmap = assert(args.bitmap,"No bitmap received")
	task.app.screen = bitmap
	log(task.app.name.." updated display")
end

dynawa.event.receive{event = "display_bitmap", callback = receive_bitmap}
