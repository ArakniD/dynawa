--Task scheduler
dynawa.app={}
dynawa.apps={}
dynawa.task={}
dynawa.tasks={}
dynawa.hardware_vectors={}
dynawa.message={queue = {},listeners = {}}

--helper function to call task functions after correctly setting the "my" global
dynawa.call_task_function = function(task, fn, message)
	assert(task.app,"Not a valid task")
	local sender, reply_callback = message.sender, message.reply_callback
	assert(type(fn)=="function","Not a function")
	local my0 = _G.my
	rawset(_G,"my",task)
	local result = fn(message)
	if reply_callback then
		assert(sender,"Message with 'reply_callback' has no sender task. I don't know where to send the reply")
		assert(result,"Task "..task.id.." did not provide reply to 'reply_callback' message. You must return something other than nil!")
		dynawa.message.send{task = sender, callback = reply_callback, reply = result, original_message = message}
	end
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
	dynawa.busy()
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
	dynawa.dofile(task.id)
	rawset(_G,"my",my0)
end

dynawa.app.start = function(args)
	if type(args)=="string" then
		args={id=args}
	end
	assert(type(args.id)=="string","App identifier is not string but "..type(args.id))
	args.id = args.id:lower()
	assert(args.id:match("/$"),"App identifier "..args.id.." does not end with '/'")
	local app={id=args.id,name=args.id,tasks={},globals={}, flags={}}
	assert(not dynawa.apps[app.id],"App "..app.id.." cannot be started, is already running")
	dynawa.apps[app.id]=app
	dynawa.task.start{id=args.id.."main.lua",app=app}
	return app
end

dynawa.message.receive = function(args) --expects message OR messages, callback
	local task = assert(_G.my, "Must be called from running task")
	if args.message then
		assert(not args.messages, "You cannot register both 'message' and 'messages' at the same time")
		args.messages={args.message}
		args.message=nil
	end
	local messages = assert(args.messages,"Message type(s) not specified")
	assert(#messages > 0,"Zero message types specified")
	local callback = assert(args.callback,"Callback not specified")
	assert(type(callback)=="function","Callback is not a function but '"..type(callback).."'")
	local list=dynawa.message.listeners
	for i,ev_type in ipairs(messages) do
		assert(type(ev_type)=="string" and #ev_type > 0, "Message type identifier is not non-empty string but '"..tostring(ev_type).."'")
		if not list[ev_type] then
			list[ev_type]={}
		end
		list[ev_type][task]={callback=callback}
		--log("Task "..task.id.." wants messages: "..ev_type)
	end
end

dynawa.message.stop_receiving = function(args) --expects message OR messages, callback
	local task = assert(_G.my, "Must be called from running task")
	if args.message then
		assert(not args.messages, "You cannot deregister both 'message' and 'messages' at the same time")
		args.messages={args.message}
		args.message=nil
	end
	local messages = assert(args.messages,"Message(s) not specified")
	assert(#messages > 0,"Zero message types specified")
	for i,ev_type in ipairs(messages) do
		assert(type(ev_type)=="string" and #ev_type > 0, "Message type identifier is not non-empty string but '"..tostring(ev_type).."'")
		local callbacks = dynawa.message.listeners[ev_type]
		if callbacks and callbacks[my] then
			callbacks[task]=nil
		end
		--log("Task "..task.id.." doesn't want messages: "..ev_type)
	end
end

dynawa.message.send = function(message)
	--local typ=assert(message.type,"Message has no type")
	assert(not message.sender,"You must not specify message sender manually")
	if type(message) == "string" then
		message = {type=message}
	end
	assert(type(message)=="table", "Message is not a table nor a string")
	message.sender = _G.my		--This MAY BE NIL (message is sent from outside of any task)!
	table.insert(dynawa.message.queue,message)
end

dynawa.delayed_callback = function(args) --expects time, callback, [autorepeat:bool]
	if not args.task then
		args.task = assert(_G.my,"Task of target callback not specified.")
	end
	args.hardware = "timer"
	assert(args.time,"No time specified")
	assert(type(args.time)=="number","Time is not a number but "..type(args.time))
	if args.time < 0 then
		args.time = 0
	end
	assert(args.callback,"No callback function specified")
	assert(type(args.callback)=="function","Callback is not a function but "..type(args.callback))
	local handle = assert(dynawa.timer.start(args.time,args.autorepeat))
	args.handle = handle
	dynawa.hardware_vectors[handle] = args
	return handle
end

dynawa.cancel_callback = function(handle) --expects time, callback, [autorepeat:bool]
	assert(type(handle) == "userdata", "Handle is not userdata")
	dynawa.hardware_vectors[handle] = nil
	dynawa.timer.cancel(handle)
end

--Dispatches single message IMMEDIATELY (bypasses message queue)
--This should never be called directly from apps!
dynawa.message.dispatch = function (message)
	local call_task_function = dynawa.call_task_function
	--log("QUEUE: Dispatching message of type "..tostring(message.type).." from "..tostring((message.sender or {}).id).." to "..tostring((message.receiver or {}).id))
	local listeners = assert(dynawa.message.listeners)
	local typ=message.type
	local handled = false
	if typ then
		if listeners[typ] then
			if message.receiver then --Send it only to tasks belonging to this app
				local receiver = message.receiver
				for task, params in pairs(listeners[typ]) do
					if task.app == receiver then
						call_task_function(task,params.callback,message)
						handled = true
					end
				end
			else
				for task, params in pairs(listeners[typ]) do
					call_task_function(task,params.callback,message)
					handled = true
				end
			end
		end
		if not handled then
			if message.reply_callback then
				--message with reply_callback was not handled. Report it to caller.
				dynawa.message.send{task = assert(message.sender,"No sender in original message"), callback = message.reply_callback, original_message = message}
			end
			log("Unhandled message of type '"..typ.."' from "..tostring((message.sender or {}).id).." to "..tostring((message.receiver or {}).id))
		end
	else --message doesn't have type, must have "callback" and "task"
		assert (message.callback,"Message doesn't have callback specified")
		assert (message.task,"Message doesn't have task specified")
		call_task_function(message.task,message.callback,message)
	end
end

