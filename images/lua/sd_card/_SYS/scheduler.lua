--Task scheduler
dynawa.app={}
dynawa.apps={}
dynawa.task={}
dynawa.tasks={}
dynawa.hardware_vectors={}
dynawa.event={queue = {},listeners = {}}

--private helper function to call task functions after correctly setting the "my" global
local function call_task_function(task, fn, ...)
	assert(task.app,"Not a valid task")
	assert(type(fn)=="function","Not a function")
	local my0 = _G.my
	rawset(_G,"my",task)
	local result = fn(...)
	rawset(_G,"my",my0)
	return result
end

--Tries to determine the app based on its table, its id or currently running task
local function get_app(app0)
	local app = app0
	if type(app) == "string" then
		app = assert(dynawa.apps[app], "'"..app0.."' app is not running")
	end
	if not app then
		local task=assert(_G.my,"App not specified and current task not defined")
		app = assert(task.app,"App not specified in task struct")
	end
	assert(type(app)=="table","Cannot identify the following app: '"..tostring(app0).."'")
	return app
end

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
	assert(app.id, "Invalid app (doesn't have name)")
	task.app = app
	task.dir = app.id
	app.tasks[task.id] = task
	task.globals = app.globals
	local my0 = _G.my
	rawset(_G,"my",task)
	dofile(task.id)
	rawset(_G,"my",my0)
end

dynawa.app.start = function(args)
	if type(args)=="string" then
		args={id=args}
	end
	assert(type(args.id)=="string","App identifier is not string but "..type(args.id))
	args.id = args.id:lower()
	assert(args.id:match("/$"),"App identifier "..args.id.." does not end with '/'")
	local app={id=args.id,name=args.id,tasks={},globals={}}
	assert(not dynawa.apps[app.id],"App "..app.id.." cannot be started, is already running")
	dynawa.apps[app.id]=app
	dynawa.task.start{id=args.id.."main.lua",app=app}
	return app
end

dynawa.app.to_front = function (app)
	local app = get_app(app)
	log("App "..app.id.." to front")
	dynawa.app.in_front = app
	dynawa._display_updated = nil
	dynawa._app_switched = true
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
	--timer_id = assert(tonumber(tostring(timer_id):match("0x........")))
	dynawa.hardware_vectors[timer_id] = args
end

--Dispatches single event IMMEDIATELY
--This should never be called directly from apps!
dynawa.event.dispatch = function (event)
	--log("QUEUE: Dispatching event of type "..tostring(event.type))
	local listeners = assert(dynawa.event.listeners)
	local typ=event.type
	if typ then
		if listeners[typ] then
			for task, params in pairs(listeners[typ]) do
				call_task_function(task,params.callback,event)
			end
		else
			log("Unhandled event of type '"..typ.."'")
		end
	else --event doesn't have type, must have "callback" and "task"
		assert (event.callback,"Event doesn't have callback specified")
		assert (event.task,"Event doesn't have task specified")
		call_task_function(event.task,event.callback,event)
	end
end

