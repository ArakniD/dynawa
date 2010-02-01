--Task scheduler
dynawa.app={}
dynawa.apps={}
dynawa.task={}
dynawa.tasks={}
dynawa.hardware_vectors={}
dynawa.event={queue = {},listeners = {}}

dynawa.task.start = function(args) --expects id,app
	if type(args)=="string" then
		args={id=args}
	end
	assert(type(args.id)=="string","Task identifier is not string but "..type(args.id))
	args.id = args.id:lower()
	assert(args.id:match("%.lua$"),"Task identifier "..args.id.." does not end with '.lua'")
	local task={id=args.id}
	assert(not dynawa.tasks[task.id],"Task "..task.id.." cannot be started, is already running")
	dynawa.tasks[task.id] = task
	local app=assert(args.app or (_G.my or {}).app,"Unable to determine parent app for task "..task.id)
	assert(app.id, "Invalid app (doesn't have id)")
	task.app = app
	task.dir = app.id
	rawset(_G,"my",task)
	dofile(task.id)
	rawset(_G,"my",nil)
end

dynawa.app.start = function(args)
	if type(args)=="string" then
		args={id=args}
	end
	assert(type(args.id)=="string","App identifier is not string but "..type(args.id))
	args.id = args.id:lower()
	assert(args.id:match("/$"),"App identifier "..args.id.." does not end with '/'")
	local app={id=args.id,name=args.id}
	assert(not dynawa.apps[app.id],"App "..app.id.." cannot be started, is already running")
	dynawa.apps[app.id]=app
	dynawa.task.start{id=args.id.."main.lua",app=app}
end

dynawa.event.receive = function(args) --expects event OR events, callback
	local task = assert(_G.my, "Must be called from running task")
	if args.event then
		assert(not args.events, "You cannot register both 'event' and 'events' at the same time")
		args.events={args.event}
		args.event=nil
	end
	local events = assert(args.events,"Event type(s) not specified")
	assert(#events > 0,"Zero event types specified")
	local callback = assert(args.callback,"Callback not specified")
	assert(type(callback)=="function","Callback is not a function but '"..type(callback).."'")
	local list=dynawa.event.listeners
	for i,ev_type in ipairs(events) do
		assert(type(ev_type)=="string" and #ev_type > 0, "Event type identifier is not non-empty string but '"..tostring(ev_type).."'")
		if not list[ev_type] then
			list[ev_type]={}
		end
		list[ev_type][task]={callback=callback}
		log("Task "..task.id.." wants events: "..ev_type)
	end
end

dynawa.event.stop_receiving = function(args) --expects event OR events, callback
	local task = assert(_G.my, "Must be called from running task")
	if args.event then
		assert(not args.events, "You cannot deregister both 'event' and 'events' at the same time")
		args.events={args.event}
		args.event=nil
	end
	local events = assert(args.events,"Event(s) not specified")
	assert(#events > 0,"Zero event types specified")
	for i,ev_type in ipairs(events) do
		assert(type(ev_type)=="string" and #ev_type > 0, "Event type identifier is not non-empty string but '"..tostring(ev_type).."'")
		local callbacks = dynawa.event.listeners[ev_type]
		if callbacks and callbacks[my] then
			callbacks[task]=nil
		end
		log("Task "..task.id.." doesn't want events: "..ev_type)
	end
end

dynawa.event.send = function(event)
	--local typ=assert(event.type,"Event has no type")
	table.insert(dynawa.event.queue,event)
end

dynawa.delayed_callback = function(args) --expects time, callback, [autorepeat:bool]
	if not args.task then
		args.task = assert(_G.my,"Task of target callback not specified.")
	end
	assert(args.time,"No time specified")
	assert(type(args.time)=="number","Time is not a number but "..type(args.time))
	if args.time < 0 then
		args.time = 0
	end
	assert(args.callback,"No callback function specified")
	assert(type(args.callback)=="function","Callback is not a function but "..type(args.callback))
	local timer_id = assert(dynawa.timer.start(args.time,args.autorepeat))
	timer_id = assert(tonumber(tostring(timer_id):match("0x........")))
	dynawa.hardware_vectors[timer_id] = args
end

