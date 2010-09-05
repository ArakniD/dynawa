app.name = "Sandman"
app.id = "dynawa.sandman"

--Handles sleep mode after period of button inactivity

function app:start()
	dynawa.devices.buttons:register_for_events(self, function(event)
		return (event.action == "button_down")
	end)
	self.sleeping = false
	self.last_timestamp = -1
	self.last_handle = false
	self:activity()
end

function app:activity(force)
	--log("Sandman: Activity")
	if self.sleeping then
		--log("Waking up!")
		assert(not dynawa.window_manager:peek(),"There should be no windows on stack during sleep")
		--dynawa.window_manager:stack_cleanup()
		dynawa.devices.display.power(1)
		self.sleeping = false
		self:activity()
		dynawa.window_manager:show_default()
	else
		local delay = assert(dynawa.settings.display.autosleep) * 1000
		--log("Auto sleep delay = "..delay)
		local tstamp = dynawa.ticks()
		if not force and (tstamp - self.last_timestamp < 500) then
			--Ignore activity if not sleeping and received it less then 500 ms after previous activity and not "forced".
			--log("Sandman: Activity ignored")
			return
		end
		if self.last_handle then
			dynawa.devices.timers:cancel(self.last_handle)
		end
		if delay == 0 then --Autosleep off
			return
		end
		self.last_timestamp = tstamp
		--log("Sandman: Next timed @ "..tstamp)
		self.last_handle = dynawa.devices.timers:timed_event{delay = delay, timestamp = tstamp, receiver = self}
	end
end

function app:handle_event_timed_event(event)
	log("Sandman: Timed event "..event.timestamp.." x "..tostring(self.last_timestamp))
	if event.timestamp ~= self.last_timestamp then
		--New timed event was triggered by Sandman AFTER his previous event fired! Ignore previous event.
		return
	end
	log("Going to sleep")
	dynawa.window_manager:stack_cleanup()
	self.sleeping = true
	self.last_timestamp, self.last_handle = -1, false
	dynawa.devices.display.power(0)
end

function app:handle_event_button(event)
	--local t = dynawa.ticks()
	--log("Button down at "..t)
	self:activity()
end

local function time_to_text(num)
	if num == 0 then
		return "No autosleep"
	end
	if num >= 60 then
		return ((num / 60).." minutes")
	end
	return (num.." seconds")
end

function app:switching_to_front()
	local times = {0,5,10,15,20,30,45,60,120,300}
	local menudef = {
		banner = "Display autosleep: "..time_to_text(assert(dynawa.settings.display.autosleep)),
		items = {},
	}
	for i,time in ipairs(times) do
		local item = {
			text = time_to_text(time),
			value = {
				time = time
			}
		}
		table.insert(menudef.items, item)
	end
	menudef.item_selected = function(_self,args)
		local value = assert(args.item.value)
		dynawa.settings.display.autosleep = assert(value.time)
		self:activity(true) --Forced activity to guarantee the change of the value
		dynawa.file.save_settings()
		args.menu.window:pop()
		args.menu:_delete()
		dynawa.popup:info("Autosleep changed to: "..time_to_text(value.time))
	end
	local menuwin = self:new_menuwindow(menudef)
	menuwin:push()
end
